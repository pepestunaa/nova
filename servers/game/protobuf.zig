const std = @import("std");
const Io = std.Io;

pub const pb = @import("stella_sora_proto");
pub const PacketId = @import("net_msg_id").PacketId;

//

pub const Encoding = enum {
    normal,
    zigzag,
    fixed,
};

pub const DecodeError = error{
    OutOfBounds,
    InvalidFieldNumber,
    InvalidWireType,
    VarIntOverflow,
};

pub fn decode(comptime Message: type, data: []const u8) DecodeError!Message {
    var result: Message = .{};
    try decodeBorrowedMessage(Message, &result, data);

    return result;
}

pub const EncodeError = Io.Writer.Error || error{ConflictingOneofFields};

pub fn encode(comptime Message: type, w: *Io.Writer, message: *const Message) EncodeError!void {
    return message.encode(w);
}

pub fn encodingLength(comptime Message: type, message: *const Message) usize {
    return message.encodingLength();
}

pub fn varIntLength(value: u64) usize {
    var remaining = value;

    var length: usize = 1;
    while (remaining >= 0x80) : (remaining >>= 7) length += 1;

    return length;
}

pub fn writeVarInt(w: *Io.Writer, value: u64) Io.Writer.Error!void {
    var remaining = value;
    while (remaining >= 0x80) : (remaining >>= 7) {
        try w.writeByte(@intCast(0x80 | (remaining & 0x7F)));
    } else try w.writeByte(@intCast(remaining & 0x7F));
}

pub fn writeVarIntField(w: *Io.Writer, tag: u32, value: u64) Io.Writer.Error!void {
    try writeVarInt(w, tag);
    try writeVarInt(w, value);
}

pub fn writeFixed32(w: *Io.Writer, value: u32) Io.Writer.Error!void {
    try w.writeInt(u32, value, .little);
}

pub fn writeFixed32Field(w: *Io.Writer, tag: u32, value: u32) Io.Writer.Error!void {
    try writeVarInt(w, tag);
    try writeFixed32(w, value);
}

pub fn writeFixed64(w: *Io.Writer, value: u64) Io.Writer.Error!void {
    try w.writeInt(u64, value, .little);
}

pub fn writeFixed64Field(w: *Io.Writer, tag: u32, value: u64) Io.Writer.Error!void {
    try writeVarInt(w, tag);
    try writeFixed64(w, value);
}

pub fn writeBytesField(w: *Io.Writer, tag: u32, value: []const u8) Io.Writer.Error!void {
    try writeVarInt(w, tag);
    try writeVarInt(w, @intCast(value.len));
    try w.writeAll(value);
}

pub fn zigZag32(value: i32) u32 {
    const unsigned: u32 = @bitCast(value);
    const sign: u32 = @bitCast(value >> 31);
    return (unsigned << 1) ^ sign;
}

pub fn zigZag64(value: i64) u64 {
    const unsigned: u64 = @bitCast(value);
    const sign: u64 = @bitCast(value >> 63);
    return (unsigned << 1) ^ sign;
}

fn decodeBorrowedMessage(comptime Message: type, result: *Message, data: []const u8) DecodeError!void {
    @setEvalBranchQuota(100_000);

    const fields = @typeInfo(Message).@"struct".fields;
    if (fields.len == 0)
        return;

    const FieldNumber = comptime blk: {
        var field_names: [fields.len][:0]const u8 = undefined;
        var field_numbers: [fields.len]u32 = undefined;

        for (fields, 0..) |field, index| {
            field_names[index] = field.name;
            field_numbers[index] = @field(Message, field.name ++ "_field_desc").number;
        }

        break :blk @Enum(u32, .exhaustive, &field_names, &field_numbers);
    };

    var cursor: BorrowedCursor = .{ .data = data };
    while (!cursor.empty()) {
        const wire_tag: BorrowedWireTag = @bitCast(try readBorrowedVarInt(&cursor, u32));
        if (wire_tag.field_number == 0)
            return error.InvalidFieldNumber;

        const field_number = std.enums.fromInt(FieldNumber, wire_tag.field_number) orelse {
            try skipBorrowedValue(&cursor, wire_tag.wire_type);

            continue;
        };

        switch (field_number) {
            inline else => |number| {
                const field_name = @tagName(number);
                const desc = @field(Message, field_name ++ "_field_desc");
                const FieldType = @FieldType(Message, field_name);

                if (BorrowedRepeated(FieldType)) |_| {
                    try decodeBorrowedRepeated(
                        FieldType,
                        &@field(result.*, field_name),
                        wire_tag.wire_type,
                        &cursor,
                    );
                } else {
                    if (wire_tag.wire_type != BorrowedWireType.of(FieldType, desc.encoding))
                        return error.InvalidWireType;
                    if (desc.oneof) |oneof| clearBorrowedOneof(Message, result, oneof);
                    @field(result.*, field_name) = try decodeBorrowedValue(FieldType, desc.encoding, &cursor);
                }
            },
        }
    }
}

fn decodeBorrowedValue(
    comptime T: type,
    comptime encoding: Encoding,
    cursor: *BorrowedCursor,
) DecodeError!T {
    if (BorrowedOptional(T)) |Child|
        return try decodeBorrowedValue(Child, encoding, cursor)
    else if (T == []const u8) {
        return try cursor.take(try readBorrowedVarInt(cursor, usize));
    } else switch (@typeInfo(T)) {
        .int => return switch (encoding) {
            .normal => try readBorrowedVarInt(cursor, T),
            .zigzag => zagBorrowed(try readBorrowedVarInt(cursor, T)),
            .fixed => try cursor.takeInt(T),
        },
        .bool => return (try readBorrowedVarInt(cursor, u8)) != 0,
        .float => |float| return @bitCast(try cursor.takeInt(@Int(.unsigned, float.bits))),
        .@"enum" => return @enumFromInt(try readBorrowedVarInt(cursor, i32)),
        .@"struct" => {
            const bytes = try cursor.take(try readBorrowedVarInt(cursor, usize));
            var value: T = .{};
            try decodeBorrowedMessage(T, &value, bytes);
            return value;
        },
        else => @compileError("unsupported decoded protobuf type: " ++ @typeName(T)),
    }
}

fn decodeBorrowedRepeated(
    comptime RepeatedType: type,
    repeated: *RepeatedType,
    first_wire_type: BorrowedWireType,
    cursor: *BorrowedCursor,
) DecodeError!void {
    const Item = RepeatedType.Item;
    const item_wire_type = BorrowedWireType.of(Item, RepeatedType.encoding);

    if (first_wire_type == .length_prefixed and item_wire_type != .length_prefixed) {
        repeated.* = .{
            .data = try cursor.take(try readBorrowedVarInt(cursor, usize)),
            .mode = .packed_values,
            .wire_type = item_wire_type,
        };
        return;
    }
    if (first_wire_type != item_wire_type)
        return error.InvalidWireType;

    const start = cursor.index;
    try skipBorrowedValue(cursor, first_wire_type);

    while (!cursor.empty()) {
        const tag_start = cursor.index;
        const wire_tag: BorrowedWireTag = @bitCast(try readBorrowedVarInt(cursor, u32));
        if (wire_tag.field_number != RepeatedType.field_number) {
            cursor.index = tag_start;
            break;
        }
        if (wire_tag.wire_type != first_wire_type)
            return error.InvalidWireType;
        try skipBorrowedValue(cursor, first_wire_type);
    }

    repeated.* = .{
        .data = cursor.data[start..cursor.index],
        .mode = .field_sequence,
        .wire_type = first_wire_type,
    };
}

pub fn Iterator(
    comptime T: type,
    comptime number: u29,
    comptime value_encoding: Encoding,
) type {
    return struct {
        const Self = @This();

        data: []const u8,
        mode: BorrowedMode,
        wire_type: BorrowedWireType,

        pub const protobuf_repeated_iterator = true;
        pub const Item = T;
        pub const field_number = number;
        pub const encoding = value_encoding;

        pub const empty: Self = .{
            .data = &.{},
            .mode = undefined,
            .wire_type = undefined,
        };

        pub fn next(iterator: *Self) DecodeError!?Item {
            if (iterator.data.len == 0) return null;

            var cursor: BorrowedCursor = .{ .data = iterator.data };
            const item = try decodeBorrowedValue(Item, encoding, &cursor);

            if (!cursor.empty() and iterator.mode == .field_sequence) {
                const wire_tag: BorrowedWireTag = @bitCast(try readBorrowedVarInt(&cursor, u32));
                if (wire_tag.field_number != field_number or wire_tag.wire_type != iterator.wire_type)
                    return error.InvalidWireType;
            }

            iterator.data = iterator.data[cursor.index..];

            return item;
        }
    };
}

const BorrowedMode = enum {
    field_sequence,
    packed_values,
};

const BorrowedCursor = struct {
    data: []const u8,
    index: usize = 0,

    fn empty(cursor: *const BorrowedCursor) bool {
        return cursor.index == cursor.data.len;
    }

    fn take(cursor: *BorrowedCursor, len: usize) DecodeError![]const u8 {
        const end = std.math.add(usize, cursor.index, len) catch
            return error.OutOfBounds;
        if (end > cursor.data.len)
            return error.OutOfBounds;

        const bytes = cursor.data[cursor.index..end];
        cursor.index = end;

        return bytes;
    }

    fn takeByte(cursor: *BorrowedCursor) DecodeError!u8 {
        return (try cursor.take(1))[0];
    }

    fn takeInt(cursor: *BorrowedCursor, comptime T: type) DecodeError!T {
        return std.mem.readInt(T, (try cursor.take(@sizeOf(T)))[0..@sizeOf(T)], .little);
    }
};

const BorrowedWireTag = packed struct(u32) {
    wire_type: BorrowedWireType,
    field_number: u29,
};

const BorrowedWireType = enum(u3) {
    var_int = 0,
    int64 = 1,
    length_prefixed = 2,
    int32 = 5,
    _,

    fn of(comptime T: type, comptime encoding: Encoding) BorrowedWireType {
        if (BorrowedOptional(T)) |Child| return of(Child, encoding);

        return switch (@typeInfo(T)) {
            .int => |int| switch (encoding) {
                .normal, .zigzag => .var_int,
                .fixed => switch (int.bits) {
                    32 => .int32,
                    64 => .int64,
                    else => @compileError("invalid fixed protobuf integer: " ++ @typeName(T)),
                },
            },
            .bool, .@"enum" => .var_int,
            .float => |float| switch (float.bits) {
                32 => .int32,
                64 => .int64,
                else => @compileError("unsupported protobuf float: " ++ @typeName(T)),
            },
            .pointer => if (T == []const u8)
                .length_prefixed
            else
                @compileError("unsupported protobuf pointer: " ++ @typeName(T)),
            .@"struct" => .length_prefixed,
            else => @compileError("unsupported decoded protobuf type: " ++ @typeName(T)),
        };
    }
};

fn readBorrowedVarInt(cursor: *BorrowedCursor, comptime T: type) DecodeError!T {
    const int = @typeInfo(T).int;
    var shift: u6 = 0;
    var result: u64 = 0;

    for (0..10) |byte_index| {
        const byte = try cursor.takeByte();
        if (byte_index == 9 and byte > 1)
            return error.VarIntOverflow;

        result |= @as(u64, byte & 0x7f) << shift;
        if ((byte & 0x80) == 0) {
            return switch (int.signedness) {
                .unsigned => std.math.cast(T, result) orelse error.VarIntOverflow,
                .signed => @bitCast(@as(@Int(.unsigned, int.bits), @truncate(result))),
            };
        }
        if (byte_index != 9) shift += 7;
    }

    return error.VarIntOverflow;
}

fn skipBorrowedValue(cursor: *BorrowedCursor, wire_type: BorrowedWireType) DecodeError!void {
    switch (wire_type) {
        .var_int => _ = try readBorrowedVarInt(cursor, u64),
        .int32 => _ = try cursor.take(4),
        .int64 => _ = try cursor.take(8),
        .length_prefixed => _ = try cursor.take(try readBorrowedVarInt(cursor, usize)),
        _ => return error.InvalidWireType,
    }
}

fn clearBorrowedOneof(comptime Message: type, result: *Message, comptime oneof: []const u8) void {
    inline for (@typeInfo(Message).@"struct".fields) |field| {
        const desc = @field(Message, field.name ++ "_field_desc");
        if (desc.oneof) |group| {
            if (comptime std.mem.eql(u8, group, oneof))
                @field(result.*, field.name) = null;
        }
    }
}

fn BorrowedRepeated(comptime T: type) ?type {
    return switch (@typeInfo(T)) {
        .@"struct" => if (@hasDecl(T, "protobuf_repeated_iterator")) T.Item else null,
        else => null,
    };
}

fn BorrowedOptional(comptime T: type) ?type {
    return switch (@typeInfo(T)) {
        .optional => |optional| optional.child,
        else => null,
    };
}

inline fn zagBorrowed(value: anytype) @TypeOf(value) {
    const T = @TypeOf(value);
    const Unsigned = @Int(.unsigned, @bitSizeOf(T));
    const unsigned: Unsigned = @bitCast(value);

    return @bitCast((unsigned >> 1) ^ -%(unsigned & 1));
}
