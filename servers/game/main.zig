const std = @import("std");
const Io = std.Io;
const net = std.Io.net;
const process = std.process;

const app = @import("app.zig");
const common = @import("common");

//

const log = std.log.scoped(.@"game-server");

const config: @import("Config.zig") = @import("config");

pub const std_options: std.Options = .{
    .unexpected_error_tracing = false,
    .http_disable_tls = true,
};

const Args = struct {
    address: []const u8 = config.listen_address,
    sdk_server_address: []const u8 = config.sdk_server_address,
};

pub fn main(init: process.Init.Minimal) u8 {
    const gpa = std.heap.smp_allocator;

    var args_arena: std.heap.ArenaAllocator = .init(gpa);
    defer args_arena.deinit();
    const args_slice = init.args.toSlice(args_arena.allocator()) catch {
        log.err("unable to read command-line arguments", .{});

        return 1;
    };

    var diagnostic: common.cli.Diagnostic = undefined;
    const args = common.cli.parseArguments(Args, args_slice[1..], &diagnostic) orelse {
        log.err("{f}\nusage: {s} {f}", .{ diagnostic, args_slice[0], common.cli.Usage(Args) });

        return 1;
    };
    const address = net.IpAddress.parseLiteral(args.address) catch |err| {
        log.err("invalid listen address '{s}': {t}", .{ args.address, err });

        return 1;
    };
    _ = net.IpAddress.parseLiteral(args.sdk_server_address) catch |err| {
        log.err("invalid SDK server address '{s}': {t}", .{ args.sdk_server_address, err });

        return 1;
    };

    var threaded: Io.Threaded = .init(gpa, .{});
    defer threaded.deinit();
    const io = threaded.io();

    common.printStartupSplash();
    return common.io.runUntilShutdown(
        io,
        app.serve,
        .{ io, gpa, address, args.sdk_server_address },
    ) catch |err| switch (err) {
        error.Canceled => 0,
    };
}

test {
    _ = @import("store/Player.zig");
    _ = @import("store/PlayerCache.zig");
    _ = @import("Scope.zig");
    _ = @import("session.zig");
}
