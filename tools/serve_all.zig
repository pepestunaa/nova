const std = @import("std");
const Io = std.Io;
const process = std.process;

const common = @import("common");

//

const log = std.log.scoped(.serve_all);

pub fn main(init: process.Init) u8 {
    const args = init.minimal.args.toSlice(init.arena.allocator()) catch {
        log.err("unable to read command-line arguments", .{});
        return 1;
    };

    const separator_index = findSeparator(args) orelse {
        log.err("missing internal server/options separator", .{});
        return 2;
    };

    const server_args = args[1..separator_index];
    const user_args = args[separator_index + 1 ..];

    const server_specs = parseServerSpecs(init.arena.allocator(), server_args) catch {
        log.err("invalid internal server list", .{});
        return 2;
    };

    if (containsHelp(user_args)) {
        printUsage(server_specs);
        return 0;
    }

    const servers = routeArguments(
        init.arena.allocator(),
        server_specs,
        user_args,
    ) catch |err| switch (err) {
        error.InvalidArguments => return 2,
        else => {
            log.err("unable to prepare server arguments: {t}", .{err});
            return 1;
        },
    };

    return supervise(init.gpa, init.io, servers) catch |err| {
        log.err("unable to supervise servers: {t}", .{err});
        return 1;
    };
}

const Server = struct {
    name: []const u8,
    argv: [][]const u8,
};

const ServerSpec = struct {
    name: []const u8,
    executable: []const u8,
    peer_options: []const [:0]const u8,
};

fn parseServerSpecs(
    arena: std.mem.Allocator,
    args: []const [:0]const u8,
) (std.mem.Allocator.Error || error{InvalidArguments})![]const ServerSpec {
    if (args.len == 0)
        return error.InvalidArguments;

    var specs = try arena.alloc(ServerSpec, args.len / 3);
    var len: usize = 0;
    var index: usize = 0;
    while (index < args.len) {
        if (args.len - index < 3)
            return error.InvalidArguments;

        const peer_option_count = std.fmt.parseInt(usize, args[index + 2], 10) catch
            return error.InvalidArguments;
        const peer_option_start = index + 3;
        if (peer_option_count > args.len - peer_option_start)
            return error.InvalidArguments;

        specs[len] = .{
            .name = args[index],
            .executable = args[index + 1],
            .peer_options = args[peer_option_start..][0..peer_option_count],
        };
        len += 1;
        index = peer_option_start + peer_option_count;
    }

    return specs[0..len];
}

fn routeArguments(
    arena: std.mem.Allocator,
    server_specs: []const ServerSpec,
    user_args: []const [:0]const u8,
) (std.mem.Allocator.Error || error{InvalidArguments})![]Server {
    const server_count = server_specs.len;
    const servers = try arena.alloc(Server, server_count);
    const counts = try arena.alloc(usize, server_count);
    @memset(counts, 1);

    const stride = user_args.len + 1;
    const argv_storage = try arena.alloc([]const u8, server_count * stride);

    for (servers, server_specs, 0..) |*server, spec, index| {
        server.name = spec.name;
        server.argv = argv_storage[index * stride ..][0..stride];
        server.argv[0] = spec.executable;
    }

    var user_index: usize = 0;
    while (user_index < user_args.len) {
        const argument = user_args[user_index];
        if (!std.mem.startsWith(u8, argument, "--") or argument.len == 2) {
            log.err(
                "expected a namespaced option, found '{s}'",
                .{argument},
            );
            return error.InvalidArguments;
        }

        const option = argument[2..];
        const match = findServer(server_specs, option) orelse {
            log.err(
                "option '{s}' does not match a registered server namespace",
                .{argument},
            );
            return error.InvalidArguments;
        };
        if (match.option.len == 0) {
            log.err("missing child option in '{s}'", .{argument});
            return error.InvalidArguments;
        }

        const child_option = try std.fmt.allocPrint(
            arena,
            "--{s}",
            .{match.option},
        );
        appendArgument(servers, counts, stride, match.index, child_option);

        for (server_specs, 0..) |spec, index| {
            if (index == match.index or !acceptsPeerOption(spec, option))
                continue;

            appendArgument(servers, counts, stride, index, argument);
        }

        user_index += 1;
        if (user_index < user_args.len and
            !std.mem.startsWith(u8, user_args[user_index], "--"))
        {
            const value = user_args[user_index];
            appendArgument(
                servers,
                counts,
                stride,
                match.index,
                value,
            );
            for (server_specs, 0..) |spec, index| {
                if (index == match.index or !acceptsPeerOption(spec, option))
                    continue;

                appendArgument(servers, counts, stride, index, value);
            }
            user_index += 1;
        }
    }

    for (servers, counts) |*server, count|
        server.argv = server.argv[0..count];

    return servers;
}

const ServerMatch = struct {
    index: usize,
    option: []const u8,
};

fn findServer(server_specs: []const ServerSpec, option: []const u8) ?ServerMatch {
    var best: ?ServerMatch = null;
    for (server_specs, 0..) |spec, index| {
        if (option.len <= spec.name.len or
            option[spec.name.len] != '-' or
            !std.mem.eql(u8, option[0..spec.name.len], spec.name))
            continue;

        if (best == null or spec.name.len > server_specs[best.?.index].name.len) {
            best = .{
                .index = index,
                .option = option[spec.name.len + 1 ..],
            };
        }
    }

    return best;
}

fn acceptsPeerOption(spec: ServerSpec, option: []const u8) bool {
    for (spec.peer_options) |peer_option|
        if (std.mem.eql(u8, peer_option, option))
            return true;

    return false;
}

fn appendArgument(
    servers: []Server,
    counts: []usize,
    stride: usize,
    server_index: usize,
    argument: []const u8,
) void {
    std.debug.assert(counts[server_index] < stride);
    servers[server_index].argv[counts[server_index]] = argument;
    counts[server_index] += 1;
}

fn findSeparator(args: []const [:0]const u8) ?usize {
    for (args[1..], 1..) |argument, index|
        if (std.mem.eql(u8, argument, "--"))
            return index;

    return null;
}

fn containsHelp(args: []const [:0]const u8) bool {
    for (args) |argument| {
        if (std.mem.eql(u8, argument, "--help") or
            std.mem.eql(u8, argument, "-h"))
            return true;
    }

    return false;
}

fn printUsage(server_specs: []const ServerSpec) void {
    std.debug.print(
        \\Usage:
        \\  zig build serve-all -- [--<server>-<option> [value]]...
        \\
        \\The server namespace is removed before forwarding each option:
        \\  --game-server-address 127.0.0.1:20002
        \\      game-server receives: --address 127.0.0.1:20002
        \\      sdk-server receives: --game-server-address 127.0.0.1:20002
        \\  --sdk-server-address 127.0.0.1:20001
        \\      sdk-server receives: --address 127.0.0.1:20001
        \\
        \\Registered server namespaces:
        \\
    , .{});

    for (server_specs) |spec| {
        std.debug.print("  {s}", .{spec.name});
        if (spec.peer_options.len != 0) {
            std.debug.print(" (receives", .{});
            for (spec.peer_options, 0..) |option, index|
                std.debug.print("{s} --{s}", .{ if (index == 0) "" else ",", option });
            std.debug.print(")", .{});
        }
        std.debug.print("\n", .{});
    }
}

fn supervise(
    gpa: std.mem.Allocator,
    io: Io,
    servers: []const Server,
) !u8 {
    const select_buffer = try gpa.alloc(
        SupervisionEvent,
        servers.len + 2,
    );
    defer gpa.free(select_buffer);

    var select: Io.Select(SupervisionEvent) = .init(io, select_buffer);
    defer select.cancelDiscard();

    for (servers) |server|
        try select.concurrent(
            .server,
            spawnAndWait,
            .{ io, server.name, server.argv },
        );
    try select.concurrent(
        .shutdown,
        common.io.waitForShutdown,
        .{io},
    );

    var remaining_servers = servers.len;
    var first_exit_code: ?u8 = null;
    var shutdown_requested = false;
    var completed_count: usize = 0;
    const completed_servers = try gpa.alloc(Completed, servers.len);
    defer gpa.free(completed_servers);

    switch (try select.await()) {
        .server => |result| try handleServerExit(
            result,
            &remaining_servers,
            &first_exit_code,
            completed_servers,
            &completed_count,
        ),
        .shutdown => |result| {
            try result;
            shutdown_requested = true;
        },
        .grace_timeout => unreachable,
    }

    if (remaining_servers == 0)
        return finishSupervision(
            shutdown_requested,
            remaining_servers,
            first_exit_code,
            completed_servers[0..completed_count],
            false,
        );

    try select.concurrent(
        .grace_timeout,
        waitForGracePeriod,
        .{io},
    );

    while (remaining_servers != 0) switch (try select.await()) {
        .server => |result| try handleServerExit(
            result,
            &remaining_servers,
            &first_exit_code,
            completed_servers,
            &completed_count,
        ),
        .shutdown => |result| {
            try result;
            shutdown_requested = true;
        },
        .grace_timeout => |result| {
            try result;
            break;
        },
    };

    return finishSupervision(
        shutdown_requested,
        remaining_servers,
        first_exit_code,
        completed_servers[0..completed_count],
        remaining_servers != 0,
    );
}

const SupervisionEvent = union(enum) {
    server: SpawnError!Completed,
    shutdown: Io.Cancelable!void,
    grace_timeout: Io.Cancelable!void,
};

const Completed = struct {
    name: []const u8,
    term: process.Child.Term,
};

const SpawnError = process.SpawnError || process.Child.WaitError;

const shutdown_grace_seconds = 1;
const shutdown_grace_period: Io.Timeout = .{
    .duration = .{
        .raw = .fromSeconds(shutdown_grace_seconds),
        .clock = .awake,
    },
};

fn waitForGracePeriod(io: Io) Io.Cancelable!void {
    return shutdown_grace_period.sleep(io);
}

fn handleServerExit(
    result: SpawnError!Completed,
    remaining_servers: *usize,
    first_exit_code: *?u8,
    completed_servers: []Completed,
    completed_count: *usize,
) !void {
    const completed = try result;
    remaining_servers.* -= 1;
    if (first_exit_code.* == null)
        first_exit_code.* = exitCode(completed.term);
    completed_servers[completed_count.*] = completed;
    completed_count.* += 1;
}

fn finishSupervision(
    shutdown_requested: bool,
    remaining_servers: usize,
    first_exit_code: ?u8,
    completed_servers: []const Completed,
    grace_expired: bool,
) u8 {
    const clean_group_exit = remaining_servers == 0 and
        allExitedSuccessfully(completed_servers);

    if (!shutdown_requested and !clean_group_exit)
        for (completed_servers) |completed|
            logTermination(completed.name, completed.term);

    if (grace_expired)
        log.warn(
            "grace period expired; force-stopping {d} server(s)",
            .{remaining_servers},
        );

    return if (shutdown_requested)
        0
    else
        first_exit_code.?;
}

fn allExitedSuccessfully(completed_servers: []const Completed) bool {
    for (completed_servers) |completed| switch (completed.term) {
        .exited => |code| if (code != 0) return false,
        .signal, .stopped, .unknown => return false,
    };

    return true;
}

fn spawnAndWait(
    io: Io,
    name: []const u8,
    argv: []const []const u8,
) SpawnError!Completed {
    var child = process.spawn(io, .{
        .argv = argv,
        .stdin = .inherit,
        .stdout = .inherit,
        .stderr = .inherit,
    }) catch |err| {
        log.err("failed to start {s}: {t}", .{ name, err });
        return err;
    };
    defer child.kill(io);

    const term = child.wait(io) catch |err| switch (err) {
        error.Canceled => return err,
        else => {
            log.err("failed to wait for {s}: {t}", .{ name, err });
            return err;
        },
    };

    return .{
        .name = name,
        .term = term,
    };
}

fn logTermination(name: []const u8, term: process.Child.Term) void {
    switch (term) {
        .exited => |code| log.info(
            "{s} exited with code {d}",
            .{ name, code },
        ),
        .signal => |signal| log.warn(
            "{s} terminated from signal {t}",
            .{ name, signal },
        ),
        .stopped => |signal| log.warn(
            "{s} stopped from signal {t}",
            .{ name, signal },
        ),
        .unknown => |status| log.warn(
            "{s} terminated with status {d}",
            .{ name, status },
        ),
    }
}

fn exitCode(term: process.Child.Term) u8 {
    return switch (term) {
        .exited => |code| code,
        .signal, .stopped, .unknown => 1,
    };
}

//

test "routes declared peer options" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();

    const server_specs = [_]ServerSpec{
        .{
            .name = "sdk-server",
            .executable = "sdk",
            .peer_options = &.{"game-server-address"},
        },
        .{
            .name = "game-server",
            .executable = "game",
            .peer_options = &.{"sdk-server-address"},
        },
    };
    const args = [_][:0]const u8{
        "--game-server-address",
        "127.0.0.1:21002",
        "--sdk-server-address",
        "127.0.0.1:21001",
    };
    const servers = try routeArguments(arena.allocator(), &server_specs, &args);

    try std.testing.expectEqualStrings("sdk", servers[0].argv[0]);
    try std.testing.expectEqualStrings("--game-server-address", servers[0].argv[1]);
    try std.testing.expectEqualStrings("127.0.0.1:21002", servers[0].argv[2]);
    try std.testing.expectEqualStrings("--address", servers[0].argv[3]);
    try std.testing.expectEqualStrings("127.0.0.1:21001", servers[0].argv[4]);

    try std.testing.expectEqualStrings("game", servers[1].argv[0]);
    try std.testing.expectEqualStrings("--address", servers[1].argv[1]);
    try std.testing.expectEqualStrings("127.0.0.1:21002", servers[1].argv[2]);
    try std.testing.expectEqualStrings("--sdk-server-address", servers[1].argv[3]);
    try std.testing.expectEqualStrings("127.0.0.1:21001", servers[1].argv[4]);
}
