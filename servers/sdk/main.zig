const builtin = @import("builtin");

const std = @import("std");
const debug = std.debug;
const ArenaAllocator = std.heap.ArenaAllocator;
const DebugAllocator = std.heap.DebugAllocator;
const Io = std.Io;
const net = std.Io.net;
const process = std.process;

const Account = @import("Account.zig");
const cli = common.cli;
const common = @import("common");
const config: @import("Config.zig") = @import("config");
const routes = @import("routes.zig");

//

pub const std_options: std.Options = .{
    .unexpected_error_tracing = false,
    .http_disable_tls = true,
};

//

const log = std.log.scoped(.@"sdk-server");

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
    game_server_address: []const u8 = config.game_server_address,
};

pub fn main(init: process.Init.Minimal) u8 {
    const gpa = if (is_debug)
        debug_allocator.allocator()
    else
        std.heap.smp_allocator;
    defer if (is_debug) debug.assert(.ok == debug_allocator.deinit());

    var args_arena: ArenaAllocator = .init(std.heap.page_allocator);
    defer args_arena.deinit();

    const args_slice = init.args.toSlice(args_arena.allocator()) catch
        process.fatal("unable to collect command line arguments", .{});

    var cli_diag: cli.Diagnostic = undefined;
    const args = cli.parseArguments(Args, args_slice[1..], &cli_diag) orelse
        process.fatal("{f}\nusage: {s} {f}", .{ cli_diag, args_slice[0], cli.Usage(Args) });

    const address = net.IpAddress.parseLiteral(args.address) catch |err|
        process.fatal("invalid listen address provided: {t}", .{err});

    var threaded: Io.Threaded = .init(gpa, .{});
    defer threaded.deinit();
    const io = threaded.io();

    common.printStartupSplash();

    var server = io.concurrent(
        serve,
        .{ io, gpa, address, args.game_server_address },
    ) catch |err| process.fatal("unable to start SDK server: {t}", .{err});
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
    gpa: std.mem.Allocator,
    address: net.IpAddress,
    game_server_address: []const u8,
) Io.Cancelable!void {
    var accounts = Account.Store.load(gpa, io, config.initial_uid) catch |err| switch (err) {
        error.Canceled => |e| return e,
        else => process.fatal("failed to load account store: {t}", .{err}),
    };
    defer accounts.deinit(gpa);

    var listener = address.listen(io, .{ .reuse_address = true }) catch |err| switch (err) {
        error.Canceled => |e| return e,
        else => process.fatal("failed to listen at {f}: {t}", .{ address, err }),
    };
    defer listener.deinit(io);

    var connections: Io.Group = .init;
    defer connections.cancel(io);

    log.info("listening at http://{f}", .{address});
    defer log.info("shutting down...", .{});

    while (true) {
        if (listener.accept(io)) |stream| {
            connections.concurrent(
                io,
                serveConnection,
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
}

fn serveConnection(
    io: Io,
    gpa: std.mem.Allocator,
    stream: net.Stream,
    game_server_address: []const u8,
    accounts: *Account.Store,
) Io.Cancelable!void {
    defer stream.close(io);

    var recv_buffer: [config.recv_buffer_size]u8 = undefined;
    var send_buffer: [config.send_buffer_size]u8 = undefined;
    var reader = stream.reader(io, &recv_buffer);
    var writer = stream.writer(io, &send_buffer);
    var server: std.http.Server = .init(&reader.interface, &writer.interface);

    while (true) {
        var request = server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            error.ReadFailed => switch (reader.err.?) {
                error.Canceled, error.ConnectionResetByPeer, error.Unexpected => return,
                else => |read_err| {
                    log.debug(
                        "failed to read HTTP request from {f}: {t}",
                        .{ stream.socket.address, read_err },
                    );
                    return;
                },
            },
            else => |e| {
                log.debug(
                    "invalid HTTP request from {f}: {t}",
                    .{ stream.socket.address, e },
                );
                return;
            },
        };

        log.info(
            "{t} {s} from {f}",
            .{
                request.head.method,
                request.head.target,
                stream.socket.address,
            },
        );

        routes.dispatch(io, gpa, accounts, game_server_address, &request) catch |err| switch (err) {
            error.WriteFailed => return,
            error.ReadFailed => switch (reader.err.?) {
                error.Canceled, error.ConnectionResetByPeer, error.Unexpected => return,
                else => |read_err| {
                    log.warn(
                        "failed to read HTTP request from {f}: {t}",
                        .{ stream.socket.address, read_err },
                    );
                    return;
                },
            },
            else => |e| {
                log.warn(
                    "failed to serve {s}: {t}",
                    .{ request.head.target, e },
                );
                return;
            },
        };
    }
}
