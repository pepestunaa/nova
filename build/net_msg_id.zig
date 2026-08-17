const std = @import("std");
const Io = std.Io;
const fatal = std.process.fatal;

const raw = @import("net_msg_id");

//

pub fn main(init: std.process.Init) void {
    @setEvalBranchQuota(2_000_000);

    comptime validateSource();

    var output_buffer: [4096]u8 = undefined;
    var output = Io.File.writerStreaming(.stdout(), init.io, &output_buffer);

    output.interface.writeAll(
        \\pub const PacketId = enum(i16) {
        \\
    ) catch fatal("couldn't write PacketId header", .{});

    inline for (raw.packets) |packet| {
        output.interface.print("    {s} = {d},\n", .{ packet.name, packet.id }) catch
            fatal("couldn't write packet ID", .{});
    }

    output.interface.writeAll(
        \\    _,
        \\};
        \\
        \\pub const MessageName = struct {
        \\    id: PacketId,
        \\    message_name: []const u8,
        \\};
        \\
        \\pub const message_names = [_]MessageName{
        \\
    ) catch fatal("couldn't write message-name header", .{});

    inline for (raw.packets) |packet| {
        output.interface.print(
            "    .{{\n        .id = .{s},\n        .message_name = \"{s}\",\n    }},\n",
            .{ packet.name, packet.message_name },
        ) catch fatal("couldn't write message name", .{});
    }

    output.interface.writeAll(
        \\};
        \\
        \\pub const ResponseIds = struct {
        \\    success: PacketId,
        \\    failure: PacketId,
        \\};
        \\
        \\const RequestResponses = struct {
        \\    request: PacketId,
        \\    responses: ResponseIds,
        \\};
        \\
        \\const request_responses = [_]RequestResponses{
        \\
    ) catch fatal("couldn't write request-response header", .{});

    inline for (raw.request_responses) |route| {
        output.interface.print(
            "    .{{\n        .request = .{s},\n        .responses = .{{\n            .success = .{s},\n            .failure = .{s},\n        }},\n    }},\n",
            .{ route.request, route.success, route.failure },
        ) catch fatal("couldn't write request responses", .{});
    }

    output.interface.writeAll(
        \\};
        \\
        \\/// Returns the success and failure packets associated with a request.
        \\pub fn responsesFor(request: PacketId) ?ResponseIds {
        \\    const needle = @intFromEnum(request);
        \\    var low: usize = 0;
        \\    var high: usize = request_responses.len;
        \\    while (low < high) {
        \\        const middle = low + (high - low) / 2;
        \\        const candidate = request_responses[middle];
        \\        const candidate_id = @intFromEnum(candidate.request);
        \\        if (needle < candidate_id) {
        \\            high = middle;
        \\        } else if (needle > candidate_id) {
        \\            low = middle + 1;
        \\        } else {
        \\            return candidate.responses;
        \\        }
        \\    }
        \\
        \\    return null;
        \\}
    ) catch
        fatal("couldn't write NetMsgId footer", .{});
    output.interface.flush() catch
        fatal("couldn't flush output", .{});
}

fn validateSource() void {
    var previous_id: ?i16 = null;
    for (raw.packets) |packet| {
        const id = std.math.cast(i16, packet.id) orelse
            @compileError(std.fmt.comptimePrint(
                "NetMsgId packet '{s}' has out-of-range ID {d}",
                .{ packet.name, packet.id },
            ));
        if (previous_id) |previous| {
            if (id <= previous) @compileError(std.fmt.comptimePrint(
                "NetMsgId packet IDs must be unique and ascending; '{s}' has ID {d} after {d}",
                .{ packet.name, id, previous },
            ));
        }
        previous_id = id;
    }

    var previous_request_id: ?i16 = null;
    for (raw.request_responses) |route| {
        const request_id = packetIdForName(route.request);
        _ = packetIdForName(route.success);
        _ = packetIdForName(route.failure);

        if (!std.mem.endsWith(u8, route.request, "_req")) @compileError(std.fmt.comptimePrint(
            "NetMsgId request route '{s}' does not name a request packet",
            .{route.request},
        ));
        if (!std.mem.endsWith(u8, route.success, "_succeed_ack")) @compileError(std.fmt.comptimePrint(
            "NetMsgId success route '{s}' does not name a success packet",
            .{route.success},
        ));
        if (!std.mem.endsWith(u8, route.failure, "_failed_ack")) @compileError(std.fmt.comptimePrint(
            "NetMsgId failure route '{s}' does not name a failure packet",
            .{route.failure},
        ));

        if (previous_request_id) |previous| {
            if (request_id <= previous) @compileError(std.fmt.comptimePrint(
                "NetMsgId requests must be unique and ascending; '{s}' has ID {d} after {d}",
                .{ route.request, request_id, previous },
            ));
        }
        previous_request_id = request_id;
    }
}

fn packetIdForName(comptime name: []const u8) i16 {
    for (raw.packets) |packet| {
        if (std.mem.eql(u8, packet.name, name))
            return @intCast(packet.id);
    }

    @compileError("NetMsgId refers to unknown packet '" ++ name ++ "'");
}
