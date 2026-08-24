const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const net = std.Io.net;

const Auth = @import("auth.zig");
const config: @import("Config.zig") = @import("config");
const net_msg_id = @import("net_msg_id");
const Player = @import("store/Player.zig");
const PlayerCache = @import("store/PlayerCache.zig");
const proto = @import("proto");
const session = @import("session.zig");
const tables = @import("tables.zig");

const messaging = @import("messaging.zig");
const Scope = messaging.Scope;

//

const log = std.log.scoped(.agent_zone);

const max_body_size = config.recv_buffer_size;
const http_buffer_size = 4096;
const packet_id_size = @sizeOf(i16);
const session_prefix_size = @sizeOf(i64) + @sizeOf(u16);
const ike_key: session.Key = key: {
    std.debug.assert(config.server_garble_key.len == session.key_length);
    break :key config.server_garble_key[0..session.key_length].*;
};

const Buffers = struct {
    /// Reuses the request ciphertext buffer for the encrypted response.
    cipher: [@max(config.recv_buffer_size, config.send_buffer_size)]u8 = undefined,
    plain: [config.recv_buffer_size]u8 = undefined,
    /// Holds response packets before framing and encryption.
    staging: [config.send_buffer_size - session.overhead]u8 = undefined,
    /// The HTTP body goes straight into `cipher`; this buffer only handles
    /// transfer-encoding framing.
    body: [1024]u8 = undefined,
};

pub fn run(
    io: Io,
    gpa: Allocator,
    stream: net.Stream,
    auth: *Auth,
    sessions: *session.Store,
    player_cache: *PlayerCache,
) Io.Cancelable!void {
    defer stream.close(io);

    var read_buffer: [http_buffer_size]u8 = undefined;
    var write_buffer: [http_buffer_size]u8 = undefined;
    var buffers: Buffers = .{};
    var stream_reader = stream.reader(io, &read_buffer);
    var stream_writer = stream.writer(io, &write_buffer);
    var server: std.http.Server = .init(&stream_reader.interface, &stream_writer.interface);

    while (true) {
        var request = server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            error.ReadFailed => switch (stream_reader.err.?) {
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

        handle(
            io,
            gpa,
            auth,
            sessions,
            player_cache,
            stream.socket.address,
            &request,
            &buffers,
        ) catch |err| switch (err) {
            error.WriteFailed => return,
            error.ReadFailed => switch (stream_reader.err.?) {
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
                    "failed to handle HTTP request from {f}: {t}",
                    .{ stream.socket.address, e },
                );
                return;
            },
        };
    }
}

fn handle(
    io: Io,
    gpa: Allocator,
    auth: *Auth,
    sessions: *session.Store,
    player_cache: *PlayerCache,
    client_address: net.IpAddress,
    request: *std.http.Server.Request,
    buffers: *Buffers,
) !void {
    if (request.head.method != .POST) {
        return try request.respond("", .{ .status = .method_not_allowed });
    }

    const request_token = if (findHeader(request, "X-Token")) |value|
        session.Token.fromSlice(value) orelse {
            log.warn(
                "received malformed X-Token from {f}",
                .{client_address},
            );

            // TODO: Send an error code maybe?
            return try request.respond("", .{ .status = .unauthorized }); // Idk if it's the correct way
        }
    else
        null;

    const now = Io.Timestamp.now(io, .real).toSeconds();
    const lookup: session.Store.Lookup = if (request_token) |token|
        sessions.lookup(io, token, now)
    else
        .unknown;

    const request_session: ?session = switch (lookup) {
        .unknown => null,
        .active, .expired => |value| value,
    };

    if (request_token != null and request_session == null) {
        log.warn(
            "received request with an unknown X-Token from {f}",
            .{client_address},
        );

        // TODO: Send an error code maybe?
        return try request.respond("", .{ .status = .unauthorized }); // Idk if it's the correct way
    }

    const content_length = request.head.content_length orelse {
        return try request.respond("", .{ .status = .bad_request });
    };
    const body_len = std.math.cast(usize, content_length) orelse {
        return try request.respond("", .{ .status = .payload_too_large });
    };
    if (body_len > max_body_size) {
        return try request.respond("", .{ .status = .payload_too_large });
    }

    const body_reader = try request.readerExpectContinue(&buffers.body);
    try body_reader.readSliceAll(buffers.cipher[0..body_len]);

    const plaintext = if (request_session) |value|
        session.decrypt(
            &buffers.plain,
            buffers.cipher[0..body_len],
            value.key,
        ) catch |err| {
            log.warn("could not decrypt session packet: {t}", .{err});

            return try request.respond(
                "",
                .{ .status = .bad_request },
            );
        }
    else
        session.decryptIke(
            &buffers.plain,
            buffers.cipher[0..body_len],
            &ike_key,
        ) catch |err| {
            log.warn("could not decrypt initial packet: {t}", .{err});

            return try request.respond(
                "",
                .{ .status = .bad_request },
            );
        };

    const packet = parseRequestPacket(plaintext, request_session != null) orelse {
        log.warn("received short packet plaintext", .{});

        return try respondPacketForRequest(
            request,
            io,
            request_session,
            "",
            buffers,
        );
    };
    const packet_id = packet.id;
    const packet_name = std.enums.tagName(proto.PacketId, packet_id) orelse "unknown";

    if (request_session) |value| if (value.restored) {
        const player_id = switch (value.player_id) {
            .none => 0,
            else => @intFromEnum(value.player_id),
        };
        log.info("resumed session for player {d} with {s}", .{ player_id, packet_name });
    };

    if (packet_id != .player_ping_req)
        logReceived(packet_name, packet.payload.len, request_session);

    if (request_session == null and packet_id != .ike_req) {
        log.warn("received non-IKE initial packet {s}", .{packet_name});

        return try respondPacketForRequest(
            request,
            io,
            null,
            "",
            buffers,
        );
    }

    if (lookup == .expired) {
        log.info("session expired during {s}; asking the client to log in again", .{packet_name});

        sessions.remove(io, request_token.?);

        return try respondTokenExpired(
            request,
            io,
            request_session,
            packet_id,
            buffers,
        );
    }

    // The client normally opens a new HTTP connection for every heartbeat.
    // Since lookup already refreshed the session, answer pings before creating
    // an arena or touching player state.
    if (packet_id == .player_ping_req) {
        return respondPing(request, io, request_session.?, now, buffers);
    }

    const player_id: ?u64 = if (request_session) |value| switch (value.player_id) {
        .none => null,
        else => @intFromEnum(value.player_id),
    } else null;
    var scratch_player: Player = .init(null);
    defer scratch_player.deinit(gpa);

    var request_arena: std.heap.ArenaAllocator = .init(gpa);
    defer request_arena.deinit();
    var response_staging_writer = Io.Writer.fixed(&buffers.staging);
    var response: Scope.Response = .{
        .writer = &response_staging_writer,
    };
    var scope: Scope = .{
        .io = io,
        .gpa = gpa,
        .arena = request_arena.allocator(),
        .source = .{ .id = packet_id, .body = packet.payload },
        .sink = .{ .response = &response },
        .player = &scratch_player,
        .session = request_session,
        .auth = auth,
        .player_cache = player_cache,
    };
    defer scope.deinit();
    if (player_id) |uid| scope.loadPlayer(uid) catch |err| {
        log.warn("failed to restore player {d}: {t}", .{ uid, err });

        sessions.remove(io, request_token.?);

        return try request.respond("", .{ .status = .unauthorized });
    };
    messaging.dispatch(&scope) catch |err| switch (err) {
        error.UnhandledMessage => {
            if (std.mem.eql(u8, packet_name, "unknown")) {
                log.warn("unknown packet ID {d}", .{@intFromEnum(packet_id)});
            } else {
                log.warn("unhandled packet {s}", .{packet_name});
            }

            return try respondPacketForRequest(request, io, request_session, "", buffers);
        },
        else => {
            log.warn("failed to process packet {s}: {t}", .{
                packet_name,
                err,
            });

            return try respondPacketForRequest(request, io, request_session, "", buffers);
        },
    };

    const response_body = try response.finish(scope.arena);
    try scope.commit();
    if (scope.session) |current_session| {
        var updated_session = current_session;
        updated_session.last_seen = now;
        updated_session.player_id = if (scope.player.uid) |uid|
            .fromInt(uid)
        else
            .none;

        // `lookup` already refreshed `last_seen`; only an identity change
        // needs the write lock.
        const is_new = request_session == null;
        const changed = is_new or
            !std.meta.eql(updated_session.token, request_session.?.token) or
            updated_session.player_id != request_session.?.player_id;

        if (changed) {
            if (request_token) |old_token| {
                if (!std.meta.eql(old_token, updated_session.token))
                    sessions.remove(io, old_token);
            }
            try sessions.put(io, gpa, updated_session);
        }

        // The table grows only during a handshake, which is also a convenient
        // time to discard abandoned sessions.
        if (is_new) {
            sessions.sweep(io, now);
            player_cache.sweep(gpa, io, now);
        }
    }

    scope.releasePlayer();

    try respondPacketForRequest(request, io, request_session, response_body, buffers);
}

fn logReceived(packet_name: []const u8, payload_len: usize, request_session: ?session) void {
    const player_id: ?u64 = if (request_session) |current| switch (current.player_id) {
        .none => null,
        else => @intFromEnum(current.player_id),
    } else null;
    if (player_id) |uid| {
        log.debug("[uid={d}] received {s}, payload {d} bytes", .{ uid, packet_name, payload_len });
    } else {
        log.debug("[uid=?] received {s}, payload {d} bytes", .{ packet_name, payload_len });
    }
}

fn respondPing(
    request: *std.http.Server.Request,
    io: Io,
    request_session: session,
    now: i64,
    buffers: *Buffers,
) !void {
    var writer = Io.Writer.fixed(&buffers.staging);
    const pong: proto.pb.Pong = .{ .ServerTs = now };
    try Scope.writePacket(
        &writer,
        .player_ping_succeed_ack,
        proto.pb.Pong,
        &pong,
    );

    return respondPacketForRequest(
        request,
        io,
        request_session,
        writer.buffered(),
        buffers,
    );
}

const RequestPacket = struct {
    id: proto.PacketId,
    payload: []const u8,
};

/// Finds the packet ID in either an initial IKE packet or an authenticated
/// packet, where it follows an i64 timestamp and u16 sequence number.
fn parseRequestPacket(plaintext: []const u8, authenticated: bool) ?RequestPacket {
    const prefix_size: usize = if (authenticated) session_prefix_size else 0;
    if (plaintext.len < prefix_size + packet_id_size) return null;

    const id_offset = prefix_size;
    return .{
        .id = @enumFromInt(std.mem.readInt(i16, plaintext[id_offset..][0..packet_id_size], .big)),
        .payload = plaintext[id_offset + packet_id_size ..],
    };
}

/// Expires the client's token with `ErrTokenExpire`, then stops its ping timer.
/// The error's Relogin behavior returns the client to the login screen for a
/// fresh handshake.
fn respondTokenExpired(
    request: *std.http.Server.Request,
    io: Io,
    request_session: ?session,
    packet_id: proto.PacketId,
    buffers: *Buffers,
) !void {
    const expired: proto.pb.Error = .{
        .Code = @intFromEnum(tables.error_code.Code.token_expire),
    };

    var writer = Io.Writer.fixed(&buffers.staging);
    var response: Scope.Response = .{ .writer = &writer };

    if (net_msg_id.responsesFor(packet_id)) |responses|
        try response.append(responses.failure, proto.pb.Error, &expired);
    try response.append(.token_expire_notify, proto.pb.Error, &expired);

    // The request plaintext has been consumed, so its buffer can hold the
    // chained response.
    var chained: std.heap.FixedBufferAllocator = .init(&buffers.plain);
    const body = try response.finish(chained.allocator());

    return respondPacketForRequest(request, io, request_session, body, buffers);
}

/// Encrypts the response into `buffers.cipher` after the request body has been
/// consumed.
fn respondPacketForRequest(
    request: *std.http.Server.Request,
    io: Io,
    request_session: ?session,
    plaintext: []const u8,
    buffers: *Buffers,
) !void {
    const body = if (request_session) |value|
        try session.encrypt(io, &buffers.cipher, plaintext, value.key)
    else
        try session.encryptIke(io, &buffers.cipher, plaintext, &ike_key);
    try request.respond(body, .{ .status = .ok });
}

fn findHeader(request: *const std.http.Server.Request, name: []const u8) ?[]const u8 {
    var headers = request.iterateHeaders();
    while (headers.next()) |header| {
        if (std.ascii.eqlIgnoreCase(header.name, name))
            return header.value;
    }

    return null;
}
