const std = @import("std");

const raw_entries = @import("tables/Config");

//

pub fn value(comptime id: []const u8) []const u8 {
    inline for (raw_entries) |entry| {
        if (std.mem.eql(u8, entry.id, id))
            return entry.value;
    }

    @compileError("missing Config entry '" ++ id ++ "'");
}

pub fn unsignedList(comptime T: type, comptime id: []const u8) []const T {
    var result: []const T = &.{};
    var values = std.mem.splitScalar(u8, value(id), ',');
    while (values.next()) |raw_value| {
        const parsed = std.fmt.parseInt(T, raw_value, 10) catch
            @compileError("invalid unsigned integer in Config entry '" ++ id ++ "'");
        result = result ++ [1]T{parsed};
    }
    if (result.len == 0)
        @compileError("empty Config integer list '" ++ id ++ "'");

    return result;
}
