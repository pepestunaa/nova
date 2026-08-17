const std = @import("std");

//

pub fn enumFieldName(
    output: []u8,
    comptime display_name: []const u8,
    id: anytype,
    existing: []const [:0]const u8,
) [:0]const u8 {
    @memcpy(output[0..display_name.len], display_name);
    const length = display_name.len;
    output[length] = 0;
    var result: [:0]const u8 = output[0..length :0];

    for (existing) |name| {
        if (!std.mem.eql(u8, name, result))
            continue;

        const suffix = std.fmt.bufPrint(output[length..], "_{d}", .{id}) catch
            @compileError("enum field-name buffer is too small");
        output[length + suffix.len] = 0;
        result = output[0 .. length + suffix.len :0];

        break;
    }

    return result;
}

pub fn isDigit(byte: u8) bool {
    return byte >= '0' and byte <= '9';
}

pub fn parseUnsigned(comptime Int: type, comptime text: []const u8) Int {
    return std.fmt.parseInt(Int, text, 10) catch
        @compileError("expected an unsigned decimal integer, found '" ++ text ++ "'");
}
