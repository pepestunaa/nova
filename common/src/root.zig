const std = @import("std");

pub const io = @import("io.zig");
pub const cli = @import("cli.zig");
pub const mem = @import("mem.zig");

//

// TODO: Add a startup splash.
pub fn printStartupSplash() void {
    std.debug.print("", .{});
}

test {
    _ = mem;
}
