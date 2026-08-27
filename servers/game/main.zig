const builtin = @import("builtin");

const std = @import("std");
const Allocator = std.mem.Allocator;
const debug = std.debug;
const DebugAllocator = std.heap.DebugAllocator;
const Io = std.Io;
const net = std.Io.net;
const process = std.process;

const agent_zone = @import("agent_zone.zig");
const Auth = @import("auth.zig");
const common = @import("common");
const config: @import("Config.zig") = @import("config");
const PlayerCache = @import("store/PlayerCache.zig");
const session = @import("session.zig");

//

pub const std_options: std.Options = .{
    .unexpected_error_tracing = false,
    .http_disable_tls = true,
};

//

const log = std.log.scoped(.@"game-server");

const is_debug = builtin.mode == .Debug;
var debug_allocator: DebugAllocator(.{
    .never_unmap = true,
    .retain_metadata = true,
}) = .init;

const accept_delay: Io.Timeout = .{
    .duration = .{ .raw = .fromSeconds(1), .clock = .awake },
};

const Args = struct {
    address: []const u8 = config.listen_address,
    sdk_server_address: []const u8 = config.sdk_server_address,
};

pub fn main(init: process.Init.Minimal) u8 {
    const gpa = if (is_debug)
        debug_allocator.allocator()
    else
        std.heap.smp_allocator;
    defer if (is_debug) debug.assert(.ok == debug_allocator.deinit());

    var args_arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
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

    var server = io.concurrent(
        serve,
        .{ io, gpa, address, args.sdk_server_address },
    ) catch |err| process.fatal("unable to start game server: {t}", .{err});
    defer server.cancel(io) catch |err| switch (err) {
        error.Canceled => {},
    };

    common.io.waitForShutdown(io) catch |err| switch (err) {
        error.Canceled => {},
    };

    return 0;
}

fn serve(
    io: Io,
    gpa: Allocator,
    address: net.IpAddress,
    sdk_server_address: []const u8,
) Io.Cancelable!void {
    var listener = address.listen(io, .{ .reuse_address = true }) catch |err| switch (err) {
        error.Canceled => |e| return e,
        error.AddressInUse => process.fatal("address {f} is already in use", .{address}),
        else => process.fatal("failed to listen at {f}: {t}", .{ address, err }),
    };
    defer listener.deinit(io);

    var clients: Io.Group = .init;
    var http_client: std.http.Client = .{ .allocator = gpa, .io = io };
    var auth: Auth = .{
        .http = &http_client,
        .sdk_server_address = sdk_server_address,
    };
    var sessions: session.Store = .{};
    const restored_sessions = sessions.load(io, gpa) catch |err| blk: {
        log.warn("could not restore saved sessions: {t}", .{err});
        break :blk 0;
    };
    var player_cache: PlayerCache = .{};
    defer player_cache.deinit(gpa);
    defer sessions.deinit(gpa);
    defer http_client.deinit();
    defer {
        clients.cancel(io);
        sessions.save(io) catch |err|
            log.warn("could not save active sessions: {t}", .{err});
    }

    log.info("agent-zone listener ready at http://{f}", .{address});
    if (restored_sessions != 0)
        log.info("restored {d} active session(s)", .{restored_sessions});
    defer log.info("shutting down...", .{});

    while (true) {
        if (listener.accept(io)) |stream| {
            clients.concurrent(
                io,
                agent_zone.run,
                .{ io, gpa, stream, &auth, &sessions, &player_cache },
            ) catch |err| switch (err) {
                error.ConcurrencyUnavailable => {
                    log.warn(
                        "connection limit reached; dropping {f}",
                        .{stream.socket.address},
                    );
                    stream.close(io);
                },
            };
        } else |err| switch (err) {
            error.Canceled => |e| return e,
            error.SystemResources,
            error.SystemFdQuotaExceeded,
            error.ProcessFdQuotaExceeded,
            => try accept_delay.sleep(io),
            else => |e| log.warn("accept failed: {t}", .{e}),
        }
    }
}

//

test {
    _ = @import("gameplay/gacha.zig");
    _ = @import("gameplay/mall.zig");
    _ = @import("gameplay/progression.zig");
    _ = @import("gameplay/research_project.zig");
    _ = @import("Scope.zig");
    _ = @import("session.zig");
    _ = @import("store/Player.zig");
    _ = @import("store/PlayerCache.zig");
}
