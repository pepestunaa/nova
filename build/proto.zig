const std = @import("std");
const Allocator = std.mem.Allocator;
const fatal = std.process.fatal;
const Io = std.Io;

//

pub fn main(init: std.process.Init) void {
    const io = init.io;
    const gpa = init.gpa;

    const args = init.minimal.args.toSlice(init.arena.allocator()) catch
        fatal("couldn't obtain cli arguments", .{});

    if (args.len <= 1) fatal("no input files", .{});

    var enum_names: std.ArrayList([]const u8) = .empty;
    for (args[1..]) |path| {
        const content = Io.Dir.readFileAlloc(.cwd(), io, path, gpa, .unlimited) catch |err|
            fatal("couldn't read input file '{s}': {t}", .{ path, err });
        defer gpa.free(content);

        var lexer: Lexer = .init(path, content);
        while (lexer.next() catch |err| fatal("failed to parse input file '{s}': {t}", .{ path, err })) |token| {
            if (std.meta.activeTag(token) == .keyword and token.keyword == .@"enum") {
                const name = lexer.expect(.name) catch |err|
                    fatal("failed to parse enum in '{s}': {t}", .{ path, err });
                enum_names.append(init.arena.allocator(), init.arena.allocator().dupe(u8, name.name) catch
                    fatal("out of memory", .{})) catch fatal("out of memory", .{});
            }
        }
    }
    const enums: EnumSymbols = .{ .names = enum_names.items };

    var stdout_buffer: [4096]u8 = undefined;
    var stdout = Io.File.writerStreaming(.stdout(), io, &stdout_buffer);

    var cwd_buffer: [Io.Dir.max_path_bytes]u8 = undefined;
    const cwd_len = Io.Dir.cwd().realPath(io, &cwd_buffer) catch |err|
        fatal("couldn't determine the working directory: {t}", .{err});
    const cwd_path = cwd_buffer[0..cwd_len];

    writeOutputFileHeader(&stdout.interface) catch |err|
        fatal("couldn't write output: {t}", .{err});

    for (args[1..]) |path| {
        const content = Io.Dir.readFileAlloc(.cwd(), io, path, gpa, .unlimited) catch |err|
            fatal("couldn't read input file '{s}': {t}", .{ path, err });

        defer gpa.free(content);

        if (content[content.len - 1] != '\n')
            fatal("input file '{s}' doesn't have a terminating newline", .{path});

        var arena: std.heap.ArenaAllocator = .init(gpa);
        defer arena.deinit();

        writeGeneratedCodeForProto(arena.allocator(), &stdout.interface, content, cwd_path, path, enums) catch |err|
            fatal("failed to generate code for '{s}': {t}", .{ path, err });
    }

    stdout.interface.flush() catch fatal("failed to write to stdout", .{});
}

fn writeOutputFileHeader(out: *Io.Writer) !void {
    try out.writeAll(
        \\const std = @import("std");
        \\
        \\const proto = @import("proto");
        \\
        \\pub const FieldDesc = struct {
        \\    number: u29,
        \\    encoding: proto.Encoding,
        \\    is_packed: bool,
        \\    is_implicit: bool,
        \\    oneof: ?[]const u8,
        \\};
        \\
    );
}

fn writeGeneratedCodeForProto(
    arena: Allocator,
    out: *Io.Writer,
    input_proto: []const u8,
    cwd_path: []const u8,
    input_path: []const u8,
    enums: EnumSymbols,
) !void {
    const relative_path = std.fs.path.relative(
        arena,
        cwd_path,
        null,
        cwd_path,
        input_path,
    ) catch input_path;
    const display_path = try arena.dupe(u8, relative_path);
    for (display_path) |*byte| {
        if (byte.* == '\\') byte.* = '/';
    }
    try out.print("\n// {s}\n\n", .{display_path});
    var l: Lexer = .init(display_path, input_proto);

    while (!l.isAtEnd()) {
        const keyword = try l.expect(.keyword);
        switch (keyword.keyword) {
            .syntax => {
                try l.expectPunct(.equal_sign);
                const syntax = try l.expect(.quoted);
                if (!std.mem.eql(u8, syntax.quoted, "proto3")) {
                    std.log.err(
                        "{f}",
                        .{Diagnostic.custom(&l, syntax, "unsupported syntax; this compiler only supports \"proto3\"")},
                    );
                    return error.UnsupportedSyntax;
                }
                try l.expectPunct(.semicolon);
            },
            .package => {
                while (true) {
                    _ = try l.expect(.name);
                    const p = try l.expect(.punct);
                    switch (p.punct) {
                        .semicolon => break,
                        .dot => continue,
                        else => {
                            std.log.err(
                                "{f}",
                                .{Diagnostic.unexpected(&l, p)},
                            );

                            return error.UnexpectedToken;
                        },
                    }
                }
            },
            .option => {
                _ = try l.expect(.name);
                try l.expectPunct(.equal_sign);
                _ = try l.expect(.quoted);
                try l.expectPunct(.semicolon);
            },
            .import => {
                const import_or_visibility = try l.next() orelse
                    return error.EndOfFile;
                if (std.meta.activeTag(import_or_visibility) != .quoted) {
                    if (std.meta.activeTag(import_or_visibility) != .name or
                        (!std.mem.eql(u8, import_or_visibility.name, "public") and
                            !std.mem.eql(u8, import_or_visibility.name, "weak")))
                    {
                        std.log.err(
                            "{f}",
                            .{Diagnostic.unexpected(&l, import_or_visibility)},
                        );

                        return error.UnexpectedToken;
                    }
                    _ = try l.expect(.quoted);
                }
                try l.expectPunct(.semicolon);
            },
            .@"enum" => try compileEnum(&l, .zero, out),
            .message => try compileMessage(arena, &l, .zero, out, enums),
            else => {
                std.log.err(
                    "{f}",
                    .{Diagnostic.unexpected(&l, keyword)},
                );

                return error.UnexpectedToken;
            },
        }
    }
}

fn compileEnum(l: *Lexer, unscoped: Indentation, out: *Io.Writer) !void {
    const name = try l.expect(.name);
    const scoped = unscoped.increment();

    try out.print("{f}pub const {s} = enum(i32) {{\n", .{ unscoped, name.name });
    try l.expectPunct(.open_curly);

    while (true) {
        const token = try l.next() orelse
            return error.EndOfFile;
        if (std.meta.activeTag(token) == .punct and token.punct == .close_curly)
            break;

        if (std.meta.activeTag(token) != .name) {
            std.log.err(
                "{f}",
                .{Diagnostic.unexpected(l, token)},
            );
            return error.UnexpectedToken;
        }

        try l.expectPunct(.equal_sign);
        const discriminant = try l.expect(.number);
        try l.expectPunct(.semicolon);

        try out.print("{f}{s} = {s},\n", .{ scoped, token.name, discriminant.number });
    }

    try out.print("{f}_,\n", .{scoped});
    try out.print("{f}}};\n\n", .{unscoped});
}

const Encoding = enum {
    normal,
    zigzag,
    fixed,
    pack,
};

const ValueKind = enum {
    var_int,
    fixed64,
    bytes,
    fixed32,
    message,

    fn wireType(kind: ValueKind) u3 {
        return switch (kind) {
            .var_int => 0,
            .fixed64 => 1,
            .bytes, .message => 2,
            .fixed32 => 5,
        };
    }
};

const Primitive = enum {
    bool,
    int32,
    sint32,
    sint64,
    fixed32,
    sfixed32,
    fixed64,
    sfixed64,
    int64,
    uint32,
    uint64,
    string,
    bytes,
    float,
    double,

    pub fn format(p: Primitive, w: *Io.Writer) !void {
        try w.writeAll(switch (p) {
            .bool => "bool",
            .sint32 => "i32",
            .sint64 => "i64",
            .fixed32 => "u32",
            .fixed64 => "u64",
            .sfixed32 => "i32",
            .sfixed64 => "i64",
            .int32 => "i32",
            .int64 => "i64",
            .uint32 => "u32",
            .uint64 => "u64",
            .string, .bytes => "[]const u8",
            .float => "f32",
            .double => "f64",
        });
    }

    pub fn encoding(p: Primitive) Encoding {
        return switch (p) {
            .bool,
            .int32,
            .int64,
            .uint32,
            .uint64,
            .string,
            .bytes,
            .float,
            .double,
            => .normal,
            .sint32, .sint64 => .zigzag,
            .fixed32, .fixed64, .sfixed32, .sfixed64 => .fixed,
        };
    }
};

const FieldDesc = struct {
    field: Field,
    name: []const u8,
    number: []const u8,
    encoding: Encoding,
    is_packed: bool,
    is_implicit: bool,
    oneof: ?[]const u8,
};

const Indentation = enum(u32) {
    zero = 0,
    _,

    pub fn format(i: Indentation, writer: *Io.Writer) !void {
        try writer.splatByteAll(' ', i.toInt());
    }

    pub fn increment(i: Indentation) Indentation {
        return @enumFromInt(i.toInt() + 4);
    }

    pub fn toInt(i: Indentation) u32 {
        return @intFromEnum(i);
    }
};

const Field = struct {
    name: []const u8,
    modifier: Modifier,
    type: Type,

    pub const Type = union(enum) {
        primitive: Primitive,
        custom: []const u8,

        pub fn fromToken(t: Lexer.Token, l: *Lexer) !Field.Type {
            if (std.meta.activeTag(t) != .name) {
                std.log.err("{f}", .{Diagnostic.unexpected(l, t)});
                return error.UnexpectedToken;
            }

            return .{
                .primitive = std.meta.stringToEnum(Primitive, t.name) orelse
                    return .{ .custom = t.name },
            };
        }

        pub fn encoding(t: Type) Encoding {
            return switch (t) {
                .custom => .normal,
                .primitive => |p| p.encoding(),
            };
        }

        pub fn format(t: Type, writer: *Io.Writer) !void {
            switch (t) {
                .primitive => |p| try writer.print("{f}", .{p}),
                .custom => |name| {
                    const unqualified = std.mem.trimStart(u8, name, ".");
                    const zig_name = if (std.mem.startsWith(u8, unqualified, "proto."))
                        unqualified["proto.".len..]
                    else if (std.mem.startsWith(u8, unqualified, "google.protobuf."))
                        unqualified["google.protobuf.".len..]
                    else
                        unqualified;
                    try writer.print("{s}", .{zig_name});
                },
            }
        }

        pub fn formatDecoded(t: Type, enums: EnumSymbols, writer: *Io.Writer) !void {
            try t.format(writer);
            if (std.meta.activeTag(t) == .custom and !t.isEnum(enums))
                try writer.writeAll(".Decoded");
        }

        pub fn isEnum(t: Type, enums: EnumSymbols) bool {
            return switch (t) {
                .primitive => false,
                .custom => |name| enums.contains(name),
            };
        }

        pub fn isPackable(t: Type, enums: EnumSymbols) bool {
            return switch (t) {
                .custom => t.isEnum(enums),
                .primitive => |primitive| switch (primitive) {
                    .string, .bytes => false,
                    else => true,
                },
            };
        }

        pub fn valueKind(t: Type, enums: EnumSymbols) ValueKind {
            return switch (t) {
                .custom => if (t.isEnum(enums)) .var_int else .message,
                .primitive => |primitive| switch (primitive) {
                    .bool, .int32, .int64, .uint32, .uint64, .sint32, .sint64 => .var_int,
                    .fixed32, .sfixed32, .float => .fixed32,
                    .fixed64, .sfixed64, .double => .fixed64,
                    .string, .bytes => .bytes,
                },
            };
        }

        pub fn formatImplicitDefault(t: Type, enums: EnumSymbols, writer: *Io.Writer) !void {
            switch (t) {
                .custom => {
                    if (!t.isEnum(enums)) return error.NonScalarImplicitField;
                    try writer.writeAll(" = @enumFromInt(0)");
                },
                .primitive => |primitive| try writer.writeAll(switch (primitive) {
                    .bool => " = false",
                    .string, .bytes => " = \"\"",
                    else => " = 0",
                }),
            }
        }
    };

    pub const Modifier = enum {
        singular,
        optional,
        required,
        repeated,
        oneof,

        pub fn fromToken(t: Lexer.Token, l: *Lexer) !Field.Modifier {
            if (std.meta.activeTag(t) != .keyword) {
                std.log.err(
                    "{f}",
                    .{Diagnostic.unexpected(l, t)},
                );

                return error.UnexpectedToken;
            }

            return switch (t.keyword) {
                .optional => .optional,
                .required => .required,
                .repeated => .repeated,
                else => {
                    std.log.err(
                        "{f}",
                        .{Diagnostic.unexpected(l, t)},
                    );

                    return error.UnexpectedToken;
                },
            };
        }
    };

    pub fn format(field: Field, enums: EnumSymbols, writer: *Io.Writer) !void {
        try writer.print("{s}: ", .{field.name});

        switch (field.modifier) {
            .singular => {
                if (field.type.isEnum(enums) or std.meta.activeTag(field.type) == .primitive) {
                    try writer.print("{f}", .{field.type});
                    try field.type.formatImplicitDefault(enums, writer);
                } else {
                    try writer.print("?{f} = null", .{field.type});
                }
            },
            .required => try writer.print("{f}", .{field.type}),
            .optional => try writer.print("?{f} = null", .{field.type}),
            .repeated => try writer.print("std.ArrayList({f}) = .empty", .{field.type}),
            .oneof => try writer.print("?{f} = null", .{field.type}),
        }
    }

    pub fn formatDecoded(
        field: Field,
        enums: EnumSymbols,
        field_number: []const u8,
        writer: *Io.Writer,
    ) !void {
        try writer.print("{s}: ", .{field.name});

        switch (field.modifier) {
            .singular => {
                if (field.type.isEnum(enums) or std.meta.activeTag(field.type) == .primitive) {
                    try field.type.format(writer);
                    try field.type.formatImplicitDefault(enums, writer);
                } else {
                    try writer.writeByte('?');
                    try field.type.formatDecoded(enums, writer);
                    try writer.writeAll(" = null");
                }
            },
            .required => try field.type.formatDecoded(enums, writer),
            .optional, .oneof => {
                try writer.writeByte('?');
                try field.type.formatDecoded(enums, writer);
                try writer.writeAll(" = null");
            },
            .repeated => {
                try writer.writeAll("proto.Iterator(");
                try field.type.formatDecoded(enums, writer);
                try writer.print(", {s}, .{t}) = .empty", .{ field_number, field.type.encoding() });
            },
        }
    }
};

const EnumSymbols = struct {
    names: []const []const u8,

    fn contains(enums: EnumSymbols, type_name: []const u8) bool {
        const unqualified = std.mem.trimStart(u8, type_name, ".");
        const short_name = if (std.mem.lastIndexOfScalar(u8, unqualified, '.')) |dot|
            unqualified[dot + 1 ..]
        else
            unqualified;
        for (enums.names) |name| if (std.mem.eql(u8, name, short_name))
            return true;

        return false;
    }
};

fn compileMessage(arena: Allocator, l: *Lexer, unscoped: Indentation, out: *Io.Writer, enums: EnumSymbols) !void {
    const name = try l.expect(.name);
    const scoped = unscoped.increment();

    try out.print("{f}pub const {s} = struct {{\n", .{ unscoped, name.name });
    try out.print("{f}pub const message_name = \"{s}\";\n", .{ scoped, name.name });

    try l.expectPunct(.open_curly);

    var field_descs: std.ArrayList(FieldDesc) = .empty;

    while (true) {
        const token = try l.next() orelse
            return error.EndOfFile;
        const token_kind = std.meta.activeTag(token);

        if (token_kind == .punct and token.punct == .close_curly)
            break;

        switch (token) {
            .keyword => |keyword| switch (keyword) {
                .message => try compileMessage(arena, l, scoped, out, enums),
                .@"enum" => try compileEnum(l, scoped, out),
                .oneof => try compileOneof(arena, l, scoped, out, &field_descs, enums),
                .optional, .required, .repeated => try compileField(
                    arena,
                    l,
                    scoped,
                    out,
                    &field_descs,
                    try .fromToken(token, l),
                    try .fromToken(try l.next() orelse
                        return error.EndOfFile, l),
                    enums,
                    null,
                ),
                else => {
                    std.log.err(
                        "{f}",
                        .{Diagnostic.unexpected(l, token)},
                    );

                    return error.UnexpectedToken;
                },
            },
            .name => try compileField(
                arena,
                l,
                scoped,
                out,
                &field_descs,
                .singular,
                try .fromToken(token, l),
                enums,
                null,
            ),
            else => {
                std.log.err(
                    "{f}",
                    .{Diagnostic.unexpected(l, token)},
                );

                return error.UnexpectedToken;
            },
        }
    }

    for (field_descs.items) |desc| {
        try out.print(
            "{f}pub const {s}_field_desc: FieldDesc = .{{ .number = {s}, .encoding = .{t}, .is_packed = {any}, .is_implicit = {any}, .oneof = ",
            .{ scoped, desc.name, desc.number, desc.encoding, desc.is_packed, desc.is_implicit },
        );
        if (desc.oneof) |oneof| try out.print("\"{s}\"", .{oneof}) else try out.writeAll("null");
        try out.writeAll(" };\n");
    }

    try writeMessageEncoder(out, scoped, field_descs.items, enums);

    try out.print("{f}pub const Decoded = struct {{\n", .{scoped});
    const decoded_scoped = scoped.increment();
    for (field_descs.items) |desc| {
        try decoded_scoped.format(out);
        try desc.field.formatDecoded(enums, desc.number, out);
        try out.writeAll(",\n");
    }
    for (field_descs.items) |desc| {
        try out.print(
            "{f}pub const {s}_field_desc: FieldDesc = .{{ .number = {s}, .encoding = .{t}, .is_packed = {any}, .is_implicit = {any}, .oneof = ",
            .{ decoded_scoped, desc.name, desc.number, desc.encoding, desc.is_packed, desc.is_implicit },
        );
        if (desc.oneof) |oneof| try out.print("\"{s}\"", .{oneof}) else try out.writeAll("null");
        try out.writeAll(" };\n");
    }
    try out.print("{f}}};\n", .{scoped});

    try out.print("{f}}};\n\n", .{unscoped});
}

fn writeMessageEncoder(
    out: *Io.Writer,
    scoped: Indentation,
    fields: []const FieldDesc,
    enums: EnumSymbols,
) !void {
    try out.print("\n{f}pub fn encode(message: *const @This(), writer: *std.Io.Writer) proto.EncodeError!void {{\n", .{scoped});
    const body = scoped.increment();
    if (hasOneof(fields))
        try out.print("{f}try message.validateOneofs();\n", .{body});
    if (fields.len == 0)
        try out.print("{f}_ = writer;\n", .{body});
    for (fields) |field|
        try writeEncodeField(out, body, field, enums);
    try out.print("{f}}}\n", .{scoped});

    try out.print("\n{f}pub fn encodingLength(message: *const @This()) usize {{\n", .{scoped});
    try out.print("{f}var total: usize = 0;\n", .{body});
    for (fields) |field|
        try writeLengthField(out, body, field, enums);
    try out.print("\n{f}return total;\n", .{body});
    try out.print("{f}}}\n", .{scoped});

    if (hasOneof(fields))
        try writeOneofValidator(out, scoped, fields);
}

fn hasOneof(fields: []const FieldDesc) bool {
    for (fields) |field| if (field.oneof != null) return true;
    return false;
}

fn writeOneofValidator(out: *Io.Writer, scoped: Indentation, fields: []const FieldDesc) !void {
    const body = scoped.increment();
    try out.print(
        "\n{f}fn validateOneofs(message: *const @This()) error{{ConflictingOneofFields}}!void {{\n",
        .{scoped},
    );

    for (fields, 0..) |field, index| {
        const group = field.oneof orelse continue;
        var seen = false;
        for (fields[0..index]) |previous| {
            if (previous.oneof) |previous_group| {
                if (std.mem.eql(u8, group, previous_group)) {
                    seen = true;
                    break;
                }
            }
        }
        if (seen) continue;

        try out.print("{f}var active_{d}: u32 = 0;\n", .{ body, index });
        for (fields) |member| {
            if (member.oneof) |member_group| {
                if (std.mem.eql(u8, group, member_group))
                    try out.print(
                        "{f}active_{d} += @intFromBool(message.{s} != null);\n",
                        .{ body, index, member.name },
                    );
            }
        }
        try out.print(
            "{f}if (active_{d} > 1) return error.ConflictingOneofFields;\n",
            .{ body, index },
        );
    }

    try out.print("{f}}}\n", .{scoped});
}

fn writeEncodeField(out: *Io.Writer, indent: Indentation, desc: FieldDesc, enums: EnumSymbols) !void {
    switch (desc.field.modifier) {
        .singular => if (desc.is_implicit) {
            try out.print("{f}if (", .{indent});
            try formatNonDefaultCondition(out, desc.field.type, enums, desc.name);
            try out.writeAll(") {\n");
            const body = indent.increment();
            try out.print("{f}const value = message.{s};\n", .{ body, desc.name });
            try writeTaggedValue(out, body, desc, enums);
            try out.print("{f}}}\n", .{indent});
        } else {
            try writeOptionalEncodeField(out, indent, desc, enums);
        },
        .optional, .oneof => try writeOptionalEncodeField(out, indent, desc, enums),
        .required => {
            try out.print("{f}{{\n", .{indent});
            const body = indent.increment();
            try out.print("{f}const value = message.{s};\n", .{ body, desc.name });
            try writeTaggedValue(out, body, desc, enums);
            try out.print("{f}}}\n", .{indent});
        },
        .repeated => if (desc.is_packed)
            try writePackedEncodeField(out, indent, desc, enums)
        else {
            try out.print("{f}for (message.{s}.items) |value| {{\n", .{ indent, desc.name });
            try writeTaggedValue(out, indent.increment(), desc, enums);
            try out.print("{f}}}\n", .{indent});
        },
    }
}

fn writeOptionalEncodeField(out: *Io.Writer, indent: Indentation, desc: FieldDesc, enums: EnumSymbols) !void {
    try out.print("{f}if (message.{s}) |value| {{\n", .{ indent, desc.name });
    try writeTaggedValue(out, indent.increment(), desc, enums);
    try out.print("{f}}}\n", .{indent});
}

fn writePackedEncodeField(out: *Io.Writer, indent: Indentation, desc: FieldDesc, enums: EnumSymbols) !void {
    const body = indent.increment();
    try out.print("{f}if (message.{s}.items.len != 0) {{\n", .{ indent, desc.name });
    try writePackedLengthDeclaration(out, body, desc, enums);
    try out.print("{f}try proto.writeVarInt(writer, {d});\n", .{ body, fieldTag(desc, enums, true) });
    try out.print("{f}try proto.writeVarInt(writer, @intCast(packed_length));\n", .{body});
    try out.print("{f}for (message.{s}.items) |value| {{\n", .{ body, desc.name });
    try writeRawValue(out, body.increment(), desc.field.type, enums);
    try out.print("{f}}}\n", .{body});
    try out.print("{f}}}\n", .{indent});
}

fn writeLengthField(out: *Io.Writer, indent: Indentation, desc: FieldDesc, enums: EnumSymbols) !void {
    switch (desc.field.modifier) {
        .singular => if (desc.is_implicit) {
            try out.print("{f}if (", .{indent});
            try formatNonDefaultCondition(out, desc.field.type, enums, desc.name);
            try out.writeAll(") {\n");
            const body = indent.increment();
            try out.print("{f}const value = message.{s};\n", .{ body, desc.name });
            try writeTaggedLength(out, body, desc, enums);
            try out.print("{f}}}\n", .{indent});
        } else {
            try writeOptionalLengthField(out, indent, desc, enums);
        },
        .optional, .oneof => try writeOptionalLengthField(out, indent, desc, enums),
        .required => {
            try out.print("{f}{{\n", .{indent});
            const body = indent.increment();
            try out.print("{f}const value = message.{s};\n", .{ body, desc.name });
            try writeTaggedLength(out, body, desc, enums);
            try out.print("{f}}}\n", .{indent});
        },
        .repeated => if (desc.is_packed) {
            const body = indent.increment();
            try out.print("{f}if (message.{s}.items.len != 0) {{\n", .{ indent, desc.name });
            try writePackedLengthDeclaration(out, body, desc, enums);
            try out.print(
                "{f}total += {d} + proto.varIntLength(@intCast(packed_length)) + packed_length;\n",
                .{ body, tagLength(fieldTag(desc, enums, true)) },
            );
            try out.print("{f}}}\n", .{indent});
        } else {
            try out.print("{f}for (message.{s}.items) |value| {{\n", .{ indent, desc.name });
            try writeTaggedLength(out, indent.increment(), desc, enums);
            try out.print("{f}}}\n", .{indent});
        },
    }
}

fn writeOptionalLengthField(out: *Io.Writer, indent: Indentation, desc: FieldDesc, enums: EnumSymbols) !void {
    try out.print("{f}if (message.{s}) |value| {{\n", .{ indent, desc.name });
    try writeTaggedLength(out, indent.increment(), desc, enums);
    try out.print("{f}}}\n", .{indent});
}

fn writeTaggedValue(out: *Io.Writer, indent: Indentation, desc: FieldDesc, enums: EnumSymbols) !void {
    const tag = fieldTag(desc, enums, false);
    switch (desc.field.type.valueKind(enums)) {
        .var_int => {
            try out.print("{f}try proto.writeVarIntField(writer, {d}, ", .{ indent, tag });
            try formatVarIntValue(out, desc.field.type, enums);
            try out.writeAll(");\n");
        },
        .fixed32 => {
            try out.print("{f}try proto.writeFixed32Field(writer, {d}, ", .{ indent, tag });
            try formatFixedValue(out, desc.field.type);
            try out.writeAll(");\n");
        },
        .fixed64 => {
            try out.print("{f}try proto.writeFixed64Field(writer, {d}, ", .{ indent, tag });
            try formatFixedValue(out, desc.field.type);
            try out.writeAll(");\n");
        },
        .bytes => try out.print("{f}try proto.writeBytesField(writer, {d}, value);\n", .{ indent, tag }),
        .message => {
            try out.print("{f}try proto.writeVarInt(writer, {d});\n", .{ indent, tag });
            try out.print("{f}try proto.writeVarInt(writer, @intCast(value.encodingLength()));\n", .{indent});
            try out.print("{f}try value.encode(writer);\n", .{indent});
        },
    }
}

fn writeRawValue(out: *Io.Writer, indent: Indentation, field_type: Field.Type, enums: EnumSymbols) !void {
    switch (field_type.valueKind(enums)) {
        .var_int => {
            try out.print("{f}try proto.writeVarInt(writer, ", .{indent});
            try formatVarIntValue(out, field_type, enums);
            try out.writeAll(");\n");
        },
        .fixed32 => {
            try out.print("{f}try proto.writeFixed32(writer, ", .{indent});
            try formatFixedValue(out, field_type);
            try out.writeAll(");\n");
        },
        .fixed64 => {
            try out.print("{f}try proto.writeFixed64(writer, ", .{indent});
            try formatFixedValue(out, field_type);
            try out.writeAll(");\n");
        },
        .bytes, .message => unreachable,
    }
}

fn writeTaggedLength(out: *Io.Writer, indent: Indentation, desc: FieldDesc, enums: EnumSymbols) !void {
    const tag_len = tagLength(fieldTag(desc, enums, false));
    switch (desc.field.type.valueKind(enums)) {
        .var_int => {
            try out.print("{f}total += {d} + proto.varIntLength(", .{ indent, tag_len });
            try formatVarIntValue(out, desc.field.type, enums);
            try out.writeAll(");\n");
        },
        .fixed32 => {
            try out.print("{f}_ = value;\n", .{indent});
            try out.print("{f}total += {d};\n", .{ indent, tag_len + 4 });
        },
        .fixed64 => {
            try out.print("{f}_ = value;\n", .{indent});
            try out.print("{f}total += {d};\n", .{ indent, tag_len + 8 });
        },
        .bytes => try out.print(
            "{f}total += {d} + proto.varIntLength(@intCast(value.len)) + value.len;\n",
            .{ indent, tag_len },
        ),
        .message => {
            try out.print("{f}const encoded_length = value.encodingLength();\n", .{indent});
            try out.print(
                "{f}total += {d} + proto.varIntLength(@intCast(encoded_length)) + encoded_length;\n",
                .{ indent, tag_len },
            );
        },
    }
}

fn writePackedLengthDeclaration(out: *Io.Writer, indent: Indentation, desc: FieldDesc, enums: EnumSymbols) !void {
    switch (desc.field.type.valueKind(enums)) {
        .var_int => {
            try out.print("{f}var packed_length: usize = 0;\n", .{indent});
            try out.print("{f}for (message.{s}.items) |value|\n", .{ indent, desc.name });
            try out.print("{f}    packed_length += proto.varIntLength(", .{indent});
            try formatVarIntValue(out, desc.field.type, enums);
            try out.writeAll(");\n");
        },
        .fixed32 => try out.print(
            "{f}const packed_length = message.{s}.items.len * 4;\n",
            .{ indent, desc.name },
        ),
        .fixed64 => try out.print(
            "{f}const packed_length = message.{s}.items.len * 8;\n",
            .{ indent, desc.name },
        ),
        .bytes, .message => unreachable,
    }
}

fn formatNonDefaultCondition(out: *Io.Writer, field_type: Field.Type, enums: EnumSymbols, name: []const u8) !void {
    switch (field_type) {
        .custom => try out.print("@intFromEnum(message.{s}) != 0", .{name}),
        .primitive => |primitive| switch (primitive) {
            .bool => try out.print("message.{s}", .{name}),
            .string, .bytes => try out.print("message.{s}.len != 0", .{name}),
            else => try out.print("message.{s} != 0", .{name}),
        },
    }
    _ = enums;
}

fn formatVarIntValue(out: *Io.Writer, field_type: Field.Type, enums: EnumSymbols) !void {
    switch (field_type) {
        .custom => {
            std.debug.assert(field_type.isEnum(enums));
            try out.writeAll("@bitCast(@as(i64, @intFromEnum(value)))");
        },
        .primitive => |primitive| try out.writeAll(switch (primitive) {
            .bool => "@intFromBool(value)",
            .int32, .int64 => "@bitCast(@as(i64, value))",
            .uint32, .uint64 => "value",
            .sint32 => "proto.zigZag32(value)",
            .sint64 => "proto.zigZag64(value)",
            else => unreachable,
        }),
    }
}

fn formatFixedValue(out: *Io.Writer, field_type: Field.Type) !void {
    const primitive = field_type.primitive;
    try out.writeAll(switch (primitive) {
        .fixed32, .fixed64 => "value",
        .sfixed32, .sfixed64, .float, .double => "@bitCast(value)",
        else => unreachable,
    });
}

fn fieldTag(desc: FieldDesc, enums: EnumSymbols, is_packed: bool) u32 {
    const field_number = std.fmt.parseInt(u29, desc.number, 10) catch unreachable;
    const wire_type: u3 = if (is_packed)
        2
    else
        desc.field.type.valueKind(enums).wireType();
    return (@as(u32, field_number) << 3) | wire_type;
}

fn tagLength(tag: u32) usize {
    var remaining = tag;
    var length: usize = 1;
    while (remaining >= 0x80) : (remaining >>= 7) length += 1;
    return length;
}

fn compileOneof(
    arena: Allocator,
    l: *Lexer,
    scoped: Indentation,
    out: *Io.Writer,
    field_descs: *std.ArrayList(FieldDesc),
    enums: EnumSymbols,
) !void {
    const oneof = try l.expect(.name);
    try l.expectPunct(.open_curly);

    while (true) {
        const token = try l.next() orelse return error.EndOfFile;
        if (std.meta.activeTag(token) == .punct and token.punct == .close_curly) break;

        try compileField(
            arena,
            l,
            scoped,
            out,
            field_descs,
            .oneof,
            try .fromToken(token, l),
            enums,
            oneof.name,
        );
    }
}

fn compileField(
    arena: Allocator,
    l: *Lexer,
    scoped: Indentation,
    out: *Io.Writer,
    field_descs: *std.ArrayList(FieldDesc),
    modifier: Field.Modifier,
    field_type: Field.Type,
    enums: EnumSymbols,
    oneof: ?[]const u8,
) !void {
    const field: Field = .{
        .modifier = modifier,
        .type = field_type,
        .name = try l.expectNameOrKeyword(),
    };

    try l.expectPunct(.equal_sign);
    const field_number = (try l.expect(.number)).number;

    const punct = try l.expectPuncts(&.{ .semicolon, .open_square });
    const explicit_packed = switch (punct) {
        .semicolon => null,
        .open_square => parse_attr: { // [packed = true];
            const attr = try l.expect(.name);
            if (!std.mem.eql(u8, attr.name, "packed")) {
                std.log.err("{f}", .{
                    Diagnostic.custom(l, attr, "unsupported field attribute"),
                });

                return error.UnexpectedToken;
            }

            try l.expectPunct(.equal_sign);

            const boolean = try l.expect(.name);
            if (!std.mem.eql(u8, boolean.name, "true") and !std.mem.eql(u8, boolean.name, "false")) {
                std.log.err(
                    "{f}",
                    .{Diagnostic.unexpected(l, boolean)},
                );

                return error.UnexpectedToken;
            }

            try l.expectPunct(.close_square);
            try l.expectPunct(.semicolon);

            break :parse_attr std.mem.eql(u8, boolean.name, "true");
        },
    };
    const is_packed = explicit_packed orelse (modifier == .repeated and field_type.isPackable(enums));

    try field_descs.append(arena, .{
        .field = field,
        .name = field.name,
        .number = field_number,
        .encoding = field.type.encoding(),
        .is_packed = is_packed,
        .is_implicit = modifier == .singular and (field_type.isEnum(enums) or std.meta.activeTag(field_type) == .primitive),
        .oneof = oneof,
    });

    try scoped.format(out);
    try field.format(enums, out);
    try out.writeAll(",\n");
}

const Diagnostic = struct {
    where: Placement,
    kind: union(enum) {
        unexpected: Lexer.Token,
        custom: []const u8,
    },

    pub fn unexpected(l: *const Lexer, t: Lexer.Token) Diagnostic {
        return .{
            .where = .extract(l, t.size()),
            .kind = .{ .unexpected = t },
        };
    }

    pub fn custom(l: *const Lexer, t: Lexer.Token, message: []const u8) Diagnostic {
        return .{
            .where = .extract(l, t.size()),
            .kind = .{ .custom = message },
        };
    }

    pub fn customNoToken(l: *const Lexer, width: usize, message: []const u8) Diagnostic {
        return .{
            .where = .extract(l, width),
            .kind = .{ .custom = message },
        };
    }

    pub fn format(d: Diagnostic, w: *Io.Writer) !void {
        try w.print("{s}:{d}:{d}: ", .{ d.where.file, d.where.line, d.where.pos });
        switch (d.kind) {
            .unexpected => |token| {
                try w.print("unexpected {f}\n", .{token});
            },
            .custom => |message| {
                try w.print("{s}\n", .{message});
            },
        }

        try w.print("{s}\n", .{d.where.region});
        try w.splatByteAll(' ', d.where.pos);
        try w.splatByteAll('^', d.where.width);
        try w.writeByte('\n');
    }

    const Placement = struct {
        region: []const u8,
        file: []const u8,
        line: usize,
        pos: usize,
        width: usize,

        fn extract(l: *const Lexer, unit_width: usize) Placement {
            const cur_pos = l.start.len - l.content.len - unit_width;

            const line_end = cur_pos + unit_width + (std.mem.findScalar(u8, l.content, '\n') orelse l.content.len);
            const line_beginning = if (std.mem.findScalarLast(u8, l.start[0..cur_pos], '\n')) |nl| nl + 1 else 0;

            return .{
                .file = l.filename,
                .region = l.start[line_beginning..line_end],
                .line = l.line,
                .pos = cur_pos - line_beginning,
                .width = unit_width,
            };
        }
    };
};

const Lexer = struct {
    filename: []const u8,
    start: []const u8,
    content: []const u8,
    line: usize = 1,

    pub fn init(filename: []const u8, content: []const u8) Lexer {
        return .{ .filename = filename, .start = content, .content = content };
    }

    pub fn isAtEnd(l: *Lexer) bool {
        l.skipWhitespaces();
        return l.content.len == 0;
    }

    pub fn next(l: *Lexer) !?Token {
        if (l.isAtEnd()) return null;

        if (l.content[0] == '.' and l.content.len > 1) switch (l.content[1]) {
            'a'...'z', 'A'...'Z', '_' => return .{ .name = l.consumeName() },
            else => {},
        };

        if (std.enums.fromInt(Token.Punct, l.content[0])) |punct| {
            l.content = l.content[1..];
            return .{ .punct = punct };
        }

        switch (l.content[0]) {
            '-', '0'...'9' => return .{ .number = l.consumeNumber() },
            'a'...'z', 'A'...'Z', '_' => {
                const name = l.consumeName();
                return if (std.meta.stringToEnum(Token.Keyword, name)) |keyword|
                    .{ .keyword = keyword }
                else
                    .{ .name = name };
            },
            '"' => return .{ .quoted = try l.consumeEnclosed('"') },
            else => {
                l.content = l.content[1..];
                std.log.err(
                    "{f}",
                    .{Diagnostic.customNoToken(l, 1, "unexpected character")},
                );

                return error.UnexpectedCharacter;
            },
        }
    }

    pub fn expectPunct(l: *Lexer, expected: Token.Punct) !void {
        const p = try l.expect(.punct);
        if (p.punct != expected) {
            std.log.err(
                "{f}",
                .{Diagnostic.unexpected(l, p)},
            );

            return error.UnexpectedToken;
        }
    }

    pub fn expect(l: *Lexer, expected_kind: std.meta.Tag(Token)) !Token {
        const t = try l.next() orelse
            return error.EndOfFile;

        if (std.meta.activeTag(t) != expected_kind) {
            std.log.err(
                "{f}",
                .{Diagnostic.unexpected(l, t)},
            );

            return error.UnexpectedToken;
        }

        return t;
    }

    pub fn expectPuncts(l: *Lexer, comptime variants: []const Token.Punct) !Token.Punct.Restricted(variants) {
        const R = Token.Punct.Restricted(variants);
        const t = try l.expect(.punct);

        return std.enums.fromInt(R, @intFromEnum(t.punct)) orelse {
            std.log.err(
                "{f}",
                .{Diagnostic.unexpected(l, t)},
            );

            return error.UnexpectedToken;
        };
    }

    // apparently, field names can consist of keywords...
    pub fn expectNameOrKeyword(l: *Lexer) ![]const u8 {
        switch (try l.next() orelse return error.EndOfFile) {
            .name => |name| return name,
            .keyword => |keyword| return @tagName(keyword),
            else => |t| {
                std.log.err(
                    "{f}",
                    .{Diagnostic.unexpected(l, t)},
                );

                return error.UnexpectedToken;
            },
        }
    }

    fn consumeNumber(l: *Lexer) []const u8 {
        const start = l.content;
        l.content = l.content[1..];
        while (l.content.len > 0) : (l.content = l.content[1..]) {
            switch (l.content[0]) {
                '0'...'9' => continue,
                else => break,
            }
        }

        return start[0 .. start.len - l.content.len];
    }

    fn consumeName(l: *Lexer) []const u8 {
        const start = l.content;
        while (l.content.len > 0) : (l.content = l.content[1..]) {
            switch (l.content[0]) {
                'a'...'z', 'A'...'Z', '0'...'9', '_', '.' => continue,
                else => break,
            }
        }

        return start[0 .. start.len - l.content.len];
    }

    fn consumeEnclosed(l: *Lexer, c: u8) ![]const u8 {
        l.content = l.content[1..];
        const start = l.content;

        while (l.content.len > 0) : (l.content = l.content[1..]) {
            if (l.content[0] == c)
                break;
        } else return error.UnclosedLiteral;

        l.content = l.content[1..];
        return start[0 .. start.len - l.content.len - 1];
    }

    fn skipWhitespaces(l: *Lexer) void {
        var skipping_line: bool = false; // indicates if we're skipping the rest of line (due to '//')

        while (l.content.len > 0) : (l.content = l.content[1..]) {
            switch (l.content[0]) {
                ' ', '\r', '\t' => continue,
                '\n' => {
                    l.line += 1;
                    skipping_line = false;
                },
                '/' => if (skipping_line) continue else if (l.content.len >= 2 and l.content[1] == '/') {
                    skipping_line = true;
                } else break,
                else => if (!skipping_line) break,
            }
        }
    }

    pub const Token = union(enum) {
        number: []const u8,
        name: []const u8,
        quoted: []const u8,
        keyword: Keyword,
        punct: Punct,

        pub const Keyword = enum {
            syntax,
            package,
            import,
            option,
            message,
            @"enum",
            optional,
            required,
            repeated,
            oneof,
        };

        pub const Punct = enum(u8) {
            semicolon = ';',
            open_curly = '{',
            close_curly = '}',
            equal_sign = '=',
            comma = ',',
            dot = '.',
            open_paren = '(',
            close_paren = ')',
            open_square = '[',
            close_square = ']',

            pub fn Restricted(comptime variants: []const Punct) type {
                var field_names: []const []const u8 = &.{};
                inline for (variants) |variant|
                    field_names = field_names ++ .{@tagName(variant)};

                var field_values: [field_names.len]u8 = undefined;
                inline for (variants, 0..) |variant, i|
                    field_values[i] = @intFromEnum(variant);

                return @Enum(u8, .exhaustive, field_names, &field_values);
            }
        };

        pub fn size(t: Token) usize {
            return switch (t) {
                .punct => 1,
                .quoted => |string| string.len + 2,
                .number, .name => |content| content.len,
                .keyword => |keyword| switch (keyword) {
                    inline else => |tag| @tagName(tag).len,
                },
            };
        }

        pub fn format(t: Token, w: *Io.Writer) !void {
            switch (t) {
                .punct => |p| try w.print("'{c}'", .{@intFromEnum(p)}),
                .quoted => |s| try w.print("\"{s}\"", .{s}),
                .name, .number => |n| try w.print("'{s}'", .{n}),
                .keyword => |kw| try w.print("'{s}'", .{@tagName(kw)}),
            }
        }
    };
};
