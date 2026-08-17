const std = @import("std");
const Io = std.Io;

const Account = @import("../store.zig").Account;
const AccountStore = @import("../AccountStore.zig");
const http = @import("../http.zig");

//

const max_request_body_size = 4096;
const parse_buffer_size = 1024;

const Authorization = struct {
    uid: u64,
    token: Account.Token,
};

fn userInfo(uid_buf: []u8, account: *const Account) struct {
    ID: []const u8,
    UID2: u8,
    PID: []const u8,
    Token: []const u8,
    Birthday: []const u8,
    RegChannel: []const u8,
    TransCode: []const u8,
    State: u8,
    DeviceID: []const u8,
    CreatedAt: i64,
} {
    return .{
        .ID = std.fmt.bufPrint(uid_buf, "{d}", .{account.uid}) catch unreachable,
        .UID2 = 0,
        .PID = "US-NOVA",
        .Token = account.token.view(),
        .Birthday = "",
        .RegChannel = "pc",
        .TransCode = "",
        .State = 1,
        .DeviceID = account.device_id.view(),
        .CreatedAt = account.created_at,
    };
}

pub fn login(
    io: Io,
    gpa: std.mem.Allocator,
    accounts: *AccountStore,
    request: *std.http.Server.Request,
) !void {
    var body_buffer: [max_request_body_size]u8 = undefined;
    const body = try readSmallBody(request, &body_buffer);

    var parse_buffer: [parse_buffer_size]u8 = undefined;
    var parse_allocator: std.heap.FixedBufferAllocator = .init(&parse_buffer);
    const parsed = std.json.parseFromSlice(
        struct { OpenID: []const u8, CheckAccount: u8 = 0 },
        parse_allocator.allocator(),
        body,
        .{ .ignore_unknown_fields = true },
    ) catch {
        return try respondLoginError(request, 100600, "Invalid login request");
    };
    defer parsed.deinit();

    const open_id = Account.OpenID.init(parsed.value.OpenID) catch {
        return try respondLoginError(request, 100902, "Device id too long");
    };

    if (parsed.value.CheckAccount == 1) {
        const account = accounts.fetch(io, open_id) orelse
            return try respondLoginError(request, 100902, "New Guest account login on American server and Korean server.");

        return try respondLoginSuccess(request, account, false);
    }

    const result = try accounts.getOrCreate(gpa, io, open_id);
    try respondLoginSuccess(request, result.account, result.is_new);
}

fn respondLoginSuccess(
    request: *std.http.Server.Request,
    account: Account,
    is_new: bool,
) !void {
    var uid_buf: [20]u8 = undefined;
    const response = .{
        .Code = @as(u16, 200),
        .Data = .{
            .AgeVerifyMethod = @as(u8, 0),
            .IsNew = @as(u8, if (is_new) 1 else 0),
            .UserInfo = userInfo(&uid_buf, &account),
            .Yostar = @as(?[]const u8, null),
        },
        .Msg = "OK",
    };

    try http.respondJson(request, response);
}

fn respondLoginError(request: *std.http.Server.Request, code: u32, msg: []const u8) !void {
    const response = .{ .Code = code, .Data = struct {}{}, .Msg = msg };
    try http.respondJson(request, response);
}

pub fn quickLogin(io: Io, accounts: *AccountStore, request: *std.http.Server.Request) !void {
    return detail(io, accounts, request);
}

pub fn detail(io: Io, accounts: *AccountStore, request: *std.http.Server.Request) !void {
    const authorization = findAuthorization(request) orelse {
        return try respondLoginError(request, 100403, "The login has expired, please log in again.");
    };

    var body_buffer: [1024]u8 = undefined;
    const body = try request.readerExpectContinue(&body_buffer);
    _ = try body.discardRemaining();

    const account = accounts.getByUid(io, authorization.uid) orelse {
        return try respondLoginError(request, 100403, "The login has expired, please log in again.");
    };
    if (!account.hasToken(&authorization.token)) {
        return try respondLoginError(request, 100403, "The login has expired, please log in again.");
    }

    var uid_buf: [20]u8 = undefined;
    const now = Io.Timestamp.now(io, .real).toSeconds();
    const response = .{
        .Code = @as(u16, 200),
        .Data = .{
            .AgeVerifyMethod = @as(u8, 0),
            .Destroy = @as(?[]const u8, null),
            .IsTestAccount = false,
            .Keys = @as(?[]const u8, null),
            .ServerNowAt = now,
            .UserInfo = userInfo(&uid_buf, &account),
            .Yostar = @as(?[]const u8, null),
            .YostarDestroy = @as(?[]const u8, null),
        },
        .Msg = "OK",
    };

    try http.respondJson(request, response);
}

fn findAuthorization(request: *std.http.Server.Request) ?Authorization {
    var headers_it = request.iterateHeaders();

    while (headers_it.next()) |header| {
        if (!std.ascii.eqlIgnoreCase(header.name, "authorization")) continue;

        var parse_buffer: [parse_buffer_size]u8 = undefined;
        var parse_allocator: std.heap.FixedBufferAllocator = .init(&parse_buffer);
        const parsed = std.json.parseFromSlice(
            struct { Head: struct { UID: []const u8, Token: []const u8 } },
            parse_allocator.allocator(),
            header.value,
            .{ .ignore_unknown_fields = true },
        ) catch break;
        defer parsed.deinit();

        const uid = std.fmt.parseInt(u64, parsed.value.Head.UID, 10) catch
            return null;
        const token = Account.Token.init(parsed.value.Head.Token) catch
            return null;
        return .{ .uid = uid, .token = token };
    }

    return null;
}

fn readSmallBody(request: *std.http.Server.Request, storage: []u8) ![]const u8 {
    const body_len_u64 = request.head.content_length orelse
        return error.UnsupportedRequestBody;
    const body_len = std.math.cast(usize, body_len_u64) orelse
        return error.RequestBodyTooLarge;
    if (body_len > storage.len)
        return error.RequestBodyTooLarge;

    var reader_buffer: [1024]u8 = undefined;
    const reader = try request.readerExpectContinue(&reader_buffer);
    const body = storage[0..body_len];
    try reader.readSliceAll(body);

    return body;
}
