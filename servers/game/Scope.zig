const Scope = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Auth = @import("auth.zig");
const Mutation = @import("gameplay/mutation.zig");
const net_msg_id = @import("net_msg_id");
const Player = @import("store/Player.zig");
const PlayerCache = @import("store/PlayerCache.zig");
const proto = @import("proto");
const Save = @import("store/player/Save.zig");
const Session = @import("session.zig");
const tables = @import("tables.zig");

//

io: Io,
gpa: Allocator,
arena: Allocator,
timestamp: Io.Timestamp,
now: i64,
source: Source,
sink: Sink,
/// Player state stays read-only until a gameplay operation starts a mutation.
player: *const Player,
mutation_state: Mutation,
session: ?Session,
auth: *Auth,
player_cache: *PlayerCache,
player_entry: ?*PlayerCache.Entry = null,

pub const Error = Source.ReadError || Sink.SendError || Save.LoadError || error{
    InvalidMutationState,
    UnmappedResponse,
};

pub fn loadPlayer(scope: *Scope, uid: u64) Save.LoadError!void {
    if (scope.player_entry != null and scope.player.uid.? != uid) {
        // Login may replace the session's player, but not after the request
        // has changed persistent state.
        std.debug.assert(!scope.mutation_state.isDirty());
        scope.releasePlayer();
    }
    if (scope.player_entry == null) {
        const entry = try scope.player_cache.acquire(scope.gpa, scope.io, uid);
        scope.player_entry = entry;
        scope.player = &entry.player;
        scope.mutation_state.rebind(&entry.player);
    }
}

pub fn deinit(scope: *Scope) void {
    scope.releasePlayer();
}

pub fn releasePlayer(scope: *Scope) void {
    const entry = scope.player_entry orelse
        return;
    scope.player_entry = null;
    if (scope.mutation_state.isDirty()) {
        scope.player_cache.rollback(scope.gpa, scope.io, entry);
    }
    scope.player_cache.release(scope.gpa, scope.io, entry);
}

pub fn mutation(scope: *Scope) *Mutation {
    return &scope.mutation_state;
}

/// Returns a logger that adds the current player ID to every message. Requests
/// received before login use `uid=?`.
pub fn logger(scope: *const Scope, comptime log_scope: @EnumLiteral()) Logger(log_scope) {
    return .{ .scope = scope };
}

pub fn playerId(scope: *const Scope) ?u64 {
    if (scope.player.uid) |uid|
        return uid;
    const current = scope.session orelse
        return null;

    return switch (current.player_id) {
        .none => null,
        else => @intFromEnum(current.player_id),
    };
}

pub fn Logger(comptime log_scope: @EnumLiteral()) type {
    return struct {
        scope: *const Scope,

        pub fn err(entry: @This(), comptime format: []const u8, args: anytype) void {
            @branchHint(.cold);
            entry.emit(.err, format, args);
        }

        pub fn warn(entry: @This(), comptime format: []const u8, args: anytype) void {
            entry.emit(.warn, format, args);
        }

        pub fn info(entry: @This(), comptime format: []const u8, args: anytype) void {
            entry.emit(.info, format, args);
        }

        pub fn debug(entry: @This(), comptime format: []const u8, args: anytype) void {
            entry.emit(.debug, format, args);
        }

        fn emit(entry: @This(), comptime level: std.log.Level, comptime format: []const u8, args: anytype) void {
            if (comptime !std.log.logEnabled(level, log_scope)) return;

            const scoped = std.log.scoped(log_scope);
            if (entry.scope.playerId()) |uid| {
                switch (level) {
                    .err => scoped.err("[uid={d}] " ++ format, .{uid} ++ args),
                    .warn => scoped.warn("[uid={d}] " ++ format, .{uid} ++ args),
                    .info => scoped.info("[uid={d}] " ++ format, .{uid} ++ args),
                    .debug => scoped.debug("[uid={d}] " ++ format, .{uid} ++ args),
                }
            } else {
                switch (level) {
                    .err => scoped.err("[uid=?] " ++ format, args),
                    .warn => scoped.warn("[uid=?] " ++ format, args),
                    .info => scoped.info("[uid=?] " ++ format, args),
                    .debug => scoped.debug("[uid=?] " ++ format, args),
                }
            }
        }
    };
}

/// Saves the request's changes while the cache entry is still locked. If the
/// save fails, `deinit` restores the last good state.
pub fn commit(scope: *Scope) Save.SaveError!void {
    if (!scope.mutation_state.isDirty())
        return;
    try Save.save(scope.io, scope.player);
    scope.mutation_state.committed();
}

/// Creates the AES session negotiated by IKE.
pub fn createSession(scope: *Scope, key: Session.Key) []const u8 {
    std.debug.assert(scope.session == null);

    scope.session = .{
        .token = .random(scope.io),
        .player_id = .none,
        .key = key,
        .last_seen = scope.now,
    };

    return scope.session.?.token.slice();
}

pub fn rotateSessionToken(scope: *Scope) []const u8 {
    std.debug.assert(scope.session != null);

    scope.session.?.token = .random(scope.io);

    return scope.session.?.token.slice();
}

/// Sends this request's mapped success packet.
pub fn respond(scope: *const Scope, message: anytype) Error!void {
    const responses = net_msg_id.responsesFor(scope.source.id) orelse
        return error.UnmappedResponse;

    try scope.sink.sendProto(responses.success, &message);
}

/// Sends this request's mapped failure packet.
pub fn respondFailure(scope: *const Scope, message: anytype) Error!void {
    const responses = net_msg_id.responsesFor(scope.source.id) orelse
        return error.UnmappedResponse;

    try scope.sink.sendProto(responses.failure, &message);
}

/// Rejects a valid request with its mapped failure packet. I/O, decoding, and
/// server failures continue to propagate as Zig errors.
pub fn reject(scope: *const Scope, code: tables.error_code.Code) Error!void {
    try ensureUnmodified(&scope.mutation_state);
    try scope.respondFailure(proto.pb.Error{
        .Code = @intCast(@intFromEnum(code)),
    });
}

pub fn respondEmpty(scope: *const Scope) Error!void {
    const responses = net_msg_id.responsesFor(scope.source.id) orelse
        return error.UnmappedResponse;
    try scope.sink.sendEmpty(responses.success);
}

pub fn respondFailureEmpty(scope: *const Scope) Error!void {
    const responses = net_msg_id.responsesFor(scope.source.id) orelse
        return error.UnmappedResponse;
    try scope.sink.sendEmpty(responses.failure);
}

pub const Source = struct {
    id: proto.PacketId,
    body: []const u8,

    pub const ReadError = error{MalformedMessage};

    /// Decodes without allocating. Strings and repeated fields borrow from
    /// `body` and are valid only for this request.
    pub fn read(source: *const Source, comptime Message: type) ReadError!Message.Decoded {
        return proto.decode(Message.Decoded, source.body) catch
            error.MalformedMessage;
    }
};

/// Sends handler responses through the `NextPackage` chain used by agent-zone.
pub const Sink = struct {
    response: *Response,

    pub const SendError = Response.Error;

    pub fn sendProto(sink: *const Sink, id: proto.PacketId, message: anytype) SendError!void {
        try sink.response.append(id, @TypeOf(message.*), message);
    }

    pub fn sendEmpty(sink: *const Sink, id: proto.PacketId) SendError!void {
        try sink.response.appendEmpty(id);
    }
};

/// Collects packet frames until the HTTP response is ready.
pub const Response = struct {
    const max_packets = 128;
    /// Every response declares `bytes NextPackage` as field 2047, whose
    /// protobuf tag is encoded as a normal varint.
    const next_package_tag = (2047 << 3) | 2;

    writer: *Io.Writer,
    frames: [max_packets]Frame = undefined,
    len: usize = 0,

    pub const Error = Allocator.Error || proto.EncodeError || error{
        TooManyPackets,
        CannotChainEmptyPacket,
    };

    const Frame = struct {
        start: u32,
        can_chain: bool,
    };

    fn frameEnd(response: *const Response, index: usize) usize {
        return if (index + 1 == response.len)
            response.writer.buffered().len
        else
            response.frames[index + 1].start;
    }

    fn beginFrame(response: *const Response) Response.Error!u32 {
        if (response.len == response.frames.len)
            return error.TooManyPackets;

        return std.math.cast(u32, response.writer.buffered().len) orelse
            error.TooManyPackets;
    }

    pub fn append(
        response: *Response,
        id: proto.PacketId,
        comptime Message: type,
        message: *const Message,
    ) Response.Error!void {
        const start = try response.beginFrame();
        try writePacket(response.writer, id, Message, message);
        response.frames[response.len] = .{ .start = start, .can_chain = true };
        response.len += 1;
    }

    pub fn appendEmpty(response: *Response, id: proto.PacketId) Response.Error!void {
        const start = try response.beginFrame();
        try response.writer.writeInt(i16, @intFromEnum(id), .big);
        response.frames[response.len] = .{ .start = start, .can_chain = false };
        response.len += 1;
    }

    /// Writes the buffered frames as a `NextPackage` chain. A single frame can
    /// use the staging buffer directly.
    pub fn finish(response: *const Response, arena: Allocator) Response.Error![]const u8 {
        if (response.len == 0)
            return &.{};
        if (response.len == 1)
            return response.writer.buffered();

        var encoded_lengths: [max_packets]usize = undefined;
        var index = response.len;
        while (index != 0) {
            index -= 1;
            var frame_len = response.frameEnd(index) - response.frames[index].start;
            if (index + 1 != response.len) {
                if (!response.frames[index].can_chain)
                    return error.CannotChainEmptyPacket;
                const next_len = encoded_lengths[index + 1];
                frame_len += varIntLen(next_package_tag) + varIntLen(next_len) + next_len;
            }
            encoded_lengths[index] = frame_len;
        }

        const total_len = encoded_lengths[0];
        const output = try arena.alloc(u8, total_len);

        var output_index: usize = 0;
        for (response.frames[0..response.len], 0..) |frame, frame_index| {
            const bytes = response.writer.buffered()[frame.start..response.frameEnd(frame_index)];
            @memcpy(output[output_index..][0..bytes.len], bytes);
            output_index += bytes.len;

            if (frame_index + 1 == response.len)
                continue;
            output_index += writeVarInt(output[output_index..], next_package_tag);
            output_index += writeVarInt(output[output_index..], encoded_lengths[frame_index + 1]);
        }

        std.debug.assert(output_index == total_len);

        return output[0..total_len];
    }
};

pub fn writePacket(
    writer: *Io.Writer,
    id: proto.PacketId,
    comptime Message: type,
    message: *const Message,
) proto.EncodeError!void {
    try writer.writeInt(i16, @intFromEnum(id), .big);
    try proto.encode(Message, writer, message);
}

fn varIntLen(value: usize) usize {
    var remaining = value;
    var len: usize = 1;
    while (remaining >= 0x80) : (len += 1) remaining >>= 7;

    return len;
}

fn writeVarInt(output: []u8, value: usize) usize {
    var remaining = value;
    var index: usize = 0;
    while (remaining >= 0x80) {
        output[index] = @intCast((remaining & 0x7f) | 0x80);
        remaining >>= 7;
        index += 1;
    }
    output[index] = @intCast(remaining);

    return index + 1;
}

fn ensureUnmodified(state: *const Mutation) error{InvalidMutationState}!void {
    if (state.isDirty())
        return error.InvalidMutationState;
}

//

test "protocol rejection cannot follow a persistent mutation" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    var state: Mutation = .init(&player);
    _ = state.modify(.{});

    try testing.expectError(
        error.InvalidMutationState,
        ensureUnmodified(&state),
    );
}
