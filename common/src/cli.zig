const std = @import("std");
const Io = std.Io;

//

// The `slice` should *not* include argv0.
pub fn parseArguments(
    comptime Args: type,
    slice: []const [:0]const u8,
    diagnostic: *Diagnostic,
) ?Args {
    const fields = @typeInfo(Args).@"struct".fields;
    comptime var field_names: [fields.len][:0]const u8 = undefined;
    comptime var flags: [fields.len]u8 = undefined;

    inline for (fields, 0..) |field, i| {
        flags[i] = field.name[0];
        field_names[i] = field.name;
    }

    const Flag = @Enum(u8, .exhaustive, &field_names, &flags);

    var result: Args = .{};

    var arg_stack_buffer: [fields.len]Flag = undefined;
    var arg_stack = std.ArrayList(Flag).initBuffer(arg_stack_buffer[0..]);

    for (slice) |arg| {
        if (std.mem.startsWith(u8, arg, "--")) {
            const option = arg[2..];
            const separator = std.mem.indexOfScalar(u8, option, '=');
            const name = option[0..(separator orelse option.len)];
            const value = if (separator) |index| option[index + 1 ..] else null;

            var matched = false;
            inline for (fields) |field| {
                if (!matched and optionNameEql(field.name, name)) {
                    matched = true;

                    if (field.type == bool) {
                        if (value != null) {
                            diagnostic.* = .{ .unexpected_value = name };

                            return null;
                        }
                        @field(result, field.name) = true;
                    } else if (field.type == []const u8) {
                        if (value) |v| {
                            @field(result, field.name) = v;
                        } else {
                            arg_stack.appendBounded(@enumFromInt(field.name[0])) catch {
                                diagnostic.* = .too_much_options;

                                return null;
                            };
                        }
                    }
                }
            }

            if (!matched) {
                diagnostic.* = .{ .invalid_long_option = name };

                return null;
            }
        } else if (arg[0] == '-') {
            for (arg[1..]) |char| {
                const flag = std.enums.fromInt(Flag, char) orelse {
                    diagnostic.* = .{ .invalid_option = char };

                    return null;
                };

                switch (flag) {
                    inline else => |f| if (@FieldType(Args, @tagName(f)) == bool) {
                        @field(result, @tagName(f)) = true;
                    } else {
                        arg_stack.appendBounded(flag) catch {
                            diagnostic.* = .too_much_options;

                            return null;
                        };
                    },
                }
            }
        } else {
            if (arg_stack.items.len == 0) {
                diagnostic.* = .{ .redundant_argument = arg };

                return null;
            }

            switch (arg_stack.swapRemove(0)) {
                inline else => |flag| if (@FieldType(Args, @tagName(flag)) == []const u8) {
                    @field(result, @tagName(flag)) = arg;
                } else {
                    diagnostic.* = .{ .redundant_argument = arg };

                    return null;
                },
            }
        }
    }

    if (arg_stack.items.len != 0) {
        diagnostic.* = .{ .missing_argument = @intFromEnum(arg_stack.items[0]) };

        return null;
    }

    return result;
}

pub const Diagnostic = union(enum) {
    invalid_option: u8,
    invalid_long_option: []const u8,
    too_much_options: void,
    redundant_argument: []const u8,
    missing_argument: u8,
    unexpected_value: []const u8,

    pub fn format(diagnostic: Diagnostic, writer: *Io.Writer) !void {
        return switch (diagnostic) {
            .invalid_option => |char| writer.print("invalid option -- '{c}'", .{char}),
            .invalid_long_option => |name| writer.print("invalid option -- '--{s}'", .{name}),
            .too_much_options => writer.writeAll("too much options encountered"),
            .redundant_argument => |str| writer.print("unexpected trailing argument -- '{s}'", .{str}),
            .missing_argument => |char| writer.print("option requires an argument -- '{c}'", .{char}),
            .unexpected_value => |name| writer.print("option does not accept an argument -- '--{s}'", .{name}),
        };
    }
};

pub fn Usage(comptime Args: type) type {
    return struct {
        pub fn format(writer: *Io.Writer) !void {
            const fields = @typeInfo(Args).@"struct".fields;
            inline for (fields, 0..) |field, index| {
                if (index != 0) try writer.writeByte(' ');
                try writer.print("[-{c}|--", .{field.name[0]});
                try writeOptionName(writer, field.name);
                if (field.type == []const u8) {
                    try writer.writeByte(' ');
                    try writeOptionName(writer, field.name);
                }
                try writer.writeByte(']');
            }
        }
    };
}

fn optionNameEql(field_name: []const u8, option_name: []const u8) bool {
    if (field_name.len != option_name.len)
        return false;

    for (field_name, option_name) |field_char, option_char| {
        if ((if (field_char == '_') @as(u8, '-') else field_char) != option_char)
            return false;
    }

    return true;
}

fn writeOptionName(writer: *Io.Writer, field_name: []const u8) !void {
    for (field_name) |char|
        try writer.writeByte(if (char == '_') '-' else char);
}
