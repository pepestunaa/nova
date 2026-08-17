const std = @import("std");
const Io = std.Io;
const net = std.Io.net;

const AccountStore = @import("AccountStore.zig");
const config: @import("Config.zig") = @import("config");
const routes = @import("routes.zig");

//

const log = std.log.scoped(.@"sdk-server");

pub fn run(
    io: Io,
    gpa: std.mem.Allocator,
    stream: net.Stream,
    game_server_address: []const u8,
    accounts: *AccountStore,
) Io.Cancelable!void {
    defer stream.close(io);

    var recv_buffer: [config.recv_buffer_size]u8 = undefined;
    var send_buffer: [config.send_buffer_size]u8 = undefined;
    var reader = stream.reader(io, &recv_buffer);
    var writer = stream.writer(io, &send_buffer);
    var server = std.http.Server.init(&reader.interface, &writer.interface);

    while (true) {
        var request = server.receiveHead() catch |err| {
            if (err == error.HttpConnectionClosing) return;

            if (err == error.ReadFailed) {
                if (reader.err) |read_err| switch (read_err) {
                    error.Canceled, error.ConnectionResetByPeer, error.Unexpected => return,
                    else => {},
                };
            }

            log.debug(
                "invalid HTTP request from {f}: {t}",
                .{ stream.socket.address, err },
            );

            return;
        };

        log.info(
            "{s} {s} from {f}",
            .{
                @tagName(request.head.method),
                request.head.target,
                stream.socket.address,
            },
        );

        routes.dispatch(io, gpa, accounts, game_server_address, &request) catch |err| switch (err) {
            error.WriteFailed => return,
            else => {
                log.warn(
                    "failed to serve {s}: {t}",
                    .{ request.head.target, err },
                );

                return;
            },
        };
    }
}
