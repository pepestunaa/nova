const std = @import("std");
const debug = std.debug;

//

pub const LimitedStringError = error{TooLongString};

/// Emits a useful compile error when a raw-persisted type contains implicit
/// padding. Explicit trailing `padding` fields are fine and let related
/// fields remain grouped in source order.
pub fn assertNoImplicitPadding(comptime T: type) void {
    switch (@typeInfo(T)) {
        .void, .bool => {},
        .int => if (@bitSizeOf(T) != 8 * @sizeOf(T))
            @compileError(std.fmt.comptimePrint(
                "{s} has {d} unused bit(s), raw-persisted scalars must occupy whole bytes",
                .{ @typeName(T), 8 * @sizeOf(T) - @bitSizeOf(T) },
            )),
        .array => |info| assertNoImplicitPadding(info.child),
        .@"struct" => |info| switch (info.layout) {
            .auto => @compileError(std.fmt.comptimePrint(
                "{s} uses automatic layout and cannot be persisted as raw bytes, use an extern or packed struct",
                .{@typeName(T)},
            )),
            .@"packed" => if (@bitSizeOf(T) != 8 * @sizeOf(T))
                @compileError(std.fmt.comptimePrint(
                    "{s} has {d} unused bit(s), raw-persisted packed structs must occupy whole bytes",
                    .{ @typeName(T), 8 * @sizeOf(T) - @bitSizeOf(T) },
                )),
            .@"extern" => {
                var expected_offset: usize = 0;
                inline for (info.fields, 0..) |field, index| {
                    assertNoImplicitPadding(field.type);

                    const actual_offset = @offsetOf(T, field.name);
                    if (actual_offset != expected_offset) {
                        const missing_bytes = actual_offset - expected_offset;

                        if (index != 0 and std.mem.eql(u8, info.fields[index - 1].name, "padding"))
                            @compileError(std.fmt.comptimePrint(
                                "{s} has {d} byte(s) of implicit padding before `{s}`, increase the preceding `padding` field by {d} byte(s)",
                                .{ @typeName(T), missing_bytes, field.name, missing_bytes },
                            ))
                        else
                            @compileError(std.fmt.comptimePrint(
                                "{s} has {d} byte(s) of implicit padding before `{s}`, reorder fields or add explicit padding (prefer trailing padding when practical)",
                                .{ @typeName(T), missing_bytes, field.name },
                            ));
                    }

                    expected_offset = actual_offset + @sizeOf(field.type);
                }
                if (expected_offset != @sizeOf(T)) {
                    const missing_bytes = @sizeOf(T) - expected_offset;
                    const last_field = info.fields[info.fields.len - 1];

                    if (std.mem.eql(u8, last_field.name, "padding")) {
                        @compileError(std.fmt.comptimePrint(
                            "{s} has {d} byte(s) of implicit trailing padding, change its trailing `padding` field from {d} to {d} byte(s)",
                            .{
                                @typeName(T),
                                missing_bytes,
                                @sizeOf(last_field.type),
                                @mod(
                                    @alignOf(T) - @mod(@offsetOf(T, "padding"), @alignOf(T)),
                                    @alignOf(T),
                                ),
                            },
                        ));
                    } else @compileError(std.fmt.comptimePrint(
                        "{s} has {d} byte(s) of implicit trailing padding, add an explicit trailing `padding` field",
                        .{ @typeName(T), missing_bytes },
                    ));
                }
            },
        },
        .@"enum" => |info| assertNoImplicitPadding(info.tag_type),
        else => @compileError(std.fmt.comptimePrint(
            "{s} cannot be persisted as raw bytes without a dedicated representation",
            .{@typeName(T)},
        )),
    }
}

pub fn LimitedString(comptime limit: usize) type {
    return extern struct {
        const String = @This();

        pub const max_length = limit;
        pub const empty: String = .{};

        bytes: [max_length + 1]u8 = @splat(0),

        comptime {
            assertNoImplicitPadding(@This());
        }

        pub fn init(value: []const u8) LimitedStringError!String {
            var string: String = .{};
            try string.set(value);

            return string;
        }

        pub fn constant(comptime value: []const u8) String {
            errdefer comptime unreachable;
            return try comptime String.init(value);
        }

        pub fn view(string: *const String) [:0]const u8 {
            debug.assert(string.bytes[max_length] == 0);
            return std.mem.span(@as([*:0]const u8, @ptrCast(&string.bytes)));
        }

        pub fn viewOrNull(string: *const String) ?[:0]const u8 {
            const v = string.view();
            return if (v.len > 0) v else null;
        }

        pub fn set(string: *String, value: []const u8) LimitedStringError!void {
            if (value.len > max_length) return error.TooLongString;

            @memcpy(string.bytes[0..value.len], value);
            @memset(string.bytes[value.len..], 0);
        }
    };
}
