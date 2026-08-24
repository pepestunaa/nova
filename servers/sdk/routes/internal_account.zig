const std = @import("std");
const Io = std.Io;

const Account = @import("../Account.zig");

//

const max_request_body_size = 128;

pub fn validate(
    io: Io,
    accounts: *Account.Store,
    request: *std.http.Server.Request,
) !void {
    var body_buffer: [max_request_body_size]u8 = undefined;
    const body = readBody(request, &body_buffer) catch
        return request.respond("", .{ .status = .bad_request });

    var parse_buffer: [256]u8 = undefined;
    var parse_allocator: std.heap.FixedBufferAllocator = .init(&parse_buffer);
    const parsed = std.json.parseFromSlice(
        struct { uid: u64, token: []const u8 },
        parse_allocator.allocator(),
        body,
        .{ .ignore_unknown_fields = true },
    ) catch return request.respond("", .{ .status = .bad_request });
    defer parsed.deinit();

    const token = Account.Token.init(parsed.value.token) catch
        return request.respond("", .{ .status = .unauthorized });
    const account = accounts.getByUid(io, parsed.value.uid) orelse
        return request.respond("", .{ .status = .unauthorized });
    if (!account.hasToken(&token))
        return request.respond("", .{ .status = .unauthorized });

    try request.respond("", .{ .status = .no_content });
}

fn readBody(request: *std.http.Server.Request, storage: []u8) ![]const u8 {
    const body_len_u64 = request.head.content_length orelse
        return error.UnsupportedRequestBody;
    const body_len = std.math.cast(usize, body_len_u64) orelse
        return error.RequestBodyTooLarge;
    if (body_len > storage.len)
        return error.RequestBodyTooLarge;

    var reader_buffer: [256]u8 = undefined;
    const reader = try request.readerExpectContinue(&reader_buffer);
    const body = storage[0..body_len];
    try reader.readSliceAll(body);

    return body;
}
