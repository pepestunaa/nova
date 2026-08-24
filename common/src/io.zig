const std = @import("std");
const debug = std.debug;
const Io = std.Io;

const termination = @import("io/termination.zig");

//

var shutdown_handler_active = false;

pub fn waitForShutdown(io: Io) Io.Cancelable!void {
    debug.assert(!@atomicRmw(
        bool,
        &shutdown_handler_active,
        .Xchg,
        true,
        .seq_cst,
    ));
    defer _ = @atomicRmw(bool, &shutdown_handler_active, .Xchg, false, .seq_cst);

    const wrap = struct {
        var handler_io: Io = undefined;
        var event: Io.Event = .unset;

        fn onShutdown() void {
            event.set(handler_io);
        }
    };

    wrap.handler_io = io;
    termination.setup(&wrap.onShutdown);
    defer termination.clear();

    return wrap.event.wait(io);
}

const RunWithTimeoutError = Io.Timeout.Error || Io.Cancelable || Io.ConcurrentError;

fn RunWithTimeoutResult(comptime Result: type) type {
    return switch (@typeInfo(Result)) {
        .error_union => |u| (RunWithTimeoutError || u.error_set)!u.payload,
        else => |T| RunWithTimeoutError!T,
    };
}

/// Spawns a concurrent task and waits for its completion until `timeout`.
pub fn runWithTimeout(
    io: Io,
    timeout: Io.Timeout,
    function: anytype,
    args: std.meta.ArgsTuple(@TypeOf(function)),
) RunWithTimeoutResult(@typeInfo(@TypeOf(function)).@"fn".return_type.?) {
    const Args = @TypeOf(args);
    const Result = @typeInfo(@TypeOf(function)).@"fn".return_type.?;
    const ExtendedResult = RunWithTimeoutResult(Result);

    const Awaiter = struct {
        io: Io,
        event: Io.Event,
        result: Result,

        pub fn complete(awaiter: *@This(), result: Result) void {
            awaiter.result = result;
            awaiter.event.set(awaiter.io);
        }
    };

    const Wrapped = struct {
        fn start(awaiter: *Awaiter, start_args: Args) void {
            awaiter.complete(@call(.auto, function, start_args));
        }
    };

    var awaiter: Awaiter = .{ .io = io, .event = .unset, .result = undefined };
    var future = try io.concurrent(Wrapped.start, .{ &awaiter, args });

    awaiter.event.waitTimeout(io, timeout) catch |wait_err| switch (wait_err) {
        error.Canceled, error.Timeout => {
            future.cancel(io);

            return switch (@typeInfo(Result)) {
                .error_union => awaiter.result catch |child_err| switch (@as(
                    @typeInfo(ExtendedResult).error_union.error_set,
                    child_err,
                )) {
                    error.Canceled, error.Timeout => wait_err,
                    else => |e| return e,
                },
                else => awaiter.result,
            };
        },
    };

    future.await(io);

    return awaiter.result;
}
