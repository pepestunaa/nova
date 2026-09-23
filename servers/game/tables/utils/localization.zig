const comptime_utils = @import("comptime.zig");

//

pub fn get(comptime table: anytype, comptime key: []const u8) []const u8 {
    const field_name = normalizedFieldName(key);
    return @field(table, field_name.bytes[0..field_name.len]);
}

fn normalizedFieldName(comptime key: []const u8) struct {
    bytes: [key.len * 2]u8,
    len: usize,
} {
    var output: [key.len * 2]u8 = undefined;
    var length: usize = 0;

    for (key, 0..) |byte, key_index| {
        if (isUpper(byte) and key_index != 0 and isLower(key[key_index - 1])) {
            output[length] = '_';
            length += 1;
        }

        output[length] = if (isLetter(byte)) toLower(byte) else if (comptime_utils.isDigit(byte)) byte else '_';
        length += 1;
    }

    return .{
        .bytes = output,
        .len = length,
    };
}

fn isUpper(byte: u8) bool {
    return byte >= 'A' and byte <= 'Z';
}

fn isLower(byte: u8) bool {
    return byte >= 'a' and byte <= 'z';
}

fn isLetter(byte: u8) bool {
    return isUpper(byte) or isLower(byte);
}

fn toLower(byte: u8) u8 {
    return if (isUpper(byte)) byte + ('a' - 'A') else byte;
}
