const builtin = @import("builtin");

const std = @import("std");
const debug = std.debug;
const ArenaAllocator = std.heap.ArenaAllocator;
const DebugAllocator = std.heap.DebugAllocator;
const Io = std.Io;
const net = std.Io.net;
const process = std.process;

const app = @import("app.zig");
const common = @import("common");
const cli = common.cli;
const runUntilShutdown = common.io.runUntilShutdown;
const config: @import("Config.zig") = @import("config");

//

const log = std.log.scoped(.@"sdk-server");

const is_debug = builtin.mode == .Debug;

pub const std_options: std.Options = .{
    .unexpected_error_tracing = false,
    .http_disable_tls = true,
};

const Args = struct {
    address: []const u8 = config.listen_address,
    game_server_address: []const u8 = config.game_server_address,
};

pub fn main(init: process.Init.Minimal) u8 {
    var debug_allocator: DebugAllocator(.{
        .never_unmap = true,
        .retain_metadata = true,
    }) = .init;
    defer if (is_debug) debug.assert(.ok == debug_allocator.deinit());

    const gpa = if (is_debug)
        debug_allocator.allocator()
    else
        std.heap.smp_allocator;

    var args_arena: ArenaAllocator = .init(gpa);
    defer if (is_debug) args_arena.deinit();

    const args_slice = init.args.toSlice(args_arena.allocator()) catch
        fatal("unable to collect command line arguments", .{});

    var cli_diag: cli.Diagnostic = undefined;
    const args = cli.parseArguments(Args, args_slice[1..], &cli_diag) orelse
        fatal("{f}\nusage: {s} {f}", .{ cli_diag, args_slice[0], cli.Usage(Args) });

    const address = net.IpAddress.parseLiteral(args.address) catch |err|
        fatal("invalid listen address provided: {t}", .{err});

    var threaded: Io.Threaded = .init(gpa, .{});
    defer threaded.deinit();
    const io = threaded.io();

    common.printStartupSplash();

    return runUntilShutdown(
        io,
        app.serve,
        .{ io, gpa, address, args.game_server_address },
    ) catch |err| switch (err) {
        error.Canceled => return 0,
    };
}

// Same as std.process.fatal, except it uses scoped log.
fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    log.err(fmt, args);
    process.exit(1);
}
