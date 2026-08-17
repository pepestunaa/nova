const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const net = std.Io.net;

const agent_zone = @import("agent_zone.zig");
const Auth = @import("auth.zig");
const PlayerCache = @import("store/PlayerCache.zig");
const session = @import("session.zig");

//

const log = std.log.scoped(.@"game-server");

const accept_delay: Io.Timeout = .{
    .duration = .{ .raw = .fromSeconds(1), .clock = .awake },
};

pub fn serve(
    io: Io,
    gpa: Allocator,
    address: net.IpAddress,
    sdk_server_address: []const u8,
) Io.Cancelable!u8 {
    var server = address.listen(io, .{ .reuse_address = true }) catch |err| switch (err) {
        error.Canceled => |e| return e,
        error.AddressInUse => {
            log.err("address {f} is already in use", .{address});
            return 1;
        },
        else => |e| {
            log.err("failed to listen at {f}: {t}", .{ address, e });
            return 1;
        },
    };
    defer server.deinit(io);

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
        if (server.accept(io)) |stream| {
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
