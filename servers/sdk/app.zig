const std = @import("std");
const Io = std.Io;
const net = std.Io.net;

const AccountStore = @import("AccountStore.zig");
const config: @import("Config.zig") = @import("config");
const connection = @import("connection.zig");

//

const log = std.log.scoped(.@"sdk-server");

const accept_delay: Io.Timeout = .{
    .duration = .{ .raw = .fromSeconds(1), .clock = .awake },
};

pub fn serve(
    io: Io,
    gpa: std.mem.Allocator,
    address: net.IpAddress,
    game_server_address: []const u8,
) Io.Cancelable!u8 {
    var accounts = AccountStore.load(gpa, io, config.initial_uid) catch |err| {
        log.err("failed to load account store: {t}", .{err});
        return 1;
    };
    defer accounts.deinit(gpa);

    var server = address.listen(io, .{ .reuse_address = true }) catch |err| {
        log.err("failed to listen at {f}: {t}", .{ address, err });
        return 1;
    };

    defer server.deinit(io);

    var connection_group: Io.Group = .init;
    defer connection_group.cancel(io);

    log.info("listening at http://{f}", .{address});
    defer log.info("shutting down...", .{});

    while (true) {
        if (server.accept(io)) |stream| {
            connection_group.concurrent(
                io,
                connection.run,
                .{ io, gpa, stream, game_server_address, &accounts },
            ) catch |err| switch (err) {
                error.ConcurrencyUnavailable => {
                    log.warn(
                        "concurrency limit reached. dropping connection from {f}",
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

            else => |e| log.debug("accept failed: {t}", .{e}),
        }
    }

    return 0;
}
