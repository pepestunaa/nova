const std = @import("std");
const Io = std.Io;

const config: @import("../Config.zig") = @import("config");
const crypto = @import("../crypto.zig");

//

const server_meta_key: crypto.Key = key: {
    std.debug.assert(config.server_meta_key.len == crypto.key_length);
    break :key config.server_meta_key[0..crypto.key_length].*;
};

pub fn get(
    io: Io,
    request: *std.http.Server.Request,
    game_server_address: []const u8,
) !void {
    var agent_buffer: [256]u8 = undefined;
    const agent = try encodeAgent(&agent_buffer, game_server_address);

    var plaintext: [256]u8 = undefined;
    var cursor: usize = 0;

    try writeFieldVarInt(&plaintext, &cursor, 1, 1);
    try writeBytes(&plaintext, &cursor, 2, agent);

    var encrypted: [512]u8 = undefined;
    const body = try crypto.encryptCbcPkcs7(
        io,
        &encrypted,
        plaintext[0..cursor],
        &server_meta_key,
    );
    try request.respond(body, .{ .status = .ok });
}

fn encodeAgent(
    buffer: []u8,
    game_server_address: []const u8,
) ![]const u8 {
    var cursor: usize = 0;
    try writeBytes(buffer, &cursor, 1, "Astralis");
    try writeBytesParts(
        buffer,
        &cursor,
        2,
        &.{ "http://", game_server_address, "/agent-zone-1/" },
    );
    try writeFieldVarInt(buffer, &cursor, 3, 1); // `ServerStatus.Normal`.
    try writeFieldVarInt(buffer, &cursor, 4, 1); // Local zone.

    return buffer[0..cursor];
}

fn writeBytesParts(
    out: []u8,
    cursor: *usize,
    field_number: u32,
    parts: []const []const u8,
) !void {
    var len: usize = 0;
    for (parts) |part| len = std.math.add(usize, len, part.len) catch
        return error.ResponseTooLarge;

    try writeVarInt(out, cursor, (@as(u64, field_number) << 3) | 2);
    try writeVarInt(out, cursor, len);

    for (parts) |part| {
        if (out.len - cursor.* < part.len)
            return error.ResponseTooLarge;
        @memcpy(out[cursor.*..][0..part.len], part);
        cursor.* += part.len;
    }
}

fn writeBytes(out: []u8, cursor: *usize, field_number: u32, bytes: []const u8) !void {
    try writeVarInt(out, cursor, (@as(u64, field_number) << 3) | 2);
    try writeVarInt(out, cursor, bytes.len);
    if (out.len - cursor.* < bytes.len)
        return error.ResponseTooLarge;
    @memcpy(out[cursor.*..][0..bytes.len], bytes);
    cursor.* += bytes.len;
}

fn writeFieldVarInt(out: []u8, cursor: *usize, field_number: u32, value: u64) !void {
    try writeVarInt(out, cursor, @as(u64, field_number) << 3);
    try writeVarInt(out, cursor, value);
}

fn writeVarInt(out: []u8, cursor: *usize, value: u64) !void {
    var remaining = value;
    while (remaining >= 0x80) : (remaining >>= 7) {
        if (cursor.* == out.len)
            return error.ResponseTooLarge;
        out[cursor.*] = @intCast(0x80 | (remaining & 0x7f));
        cursor.* += 1;
    }
    if (cursor.* == out.len)
        return error.ResponseTooLarge;
    out[cursor.*] = @intCast(remaining);
    cursor.* += 1;
}
