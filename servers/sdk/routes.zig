const std = @import("std");
const Io = std.Io;

const AccountStore = @import("AccountStore.zig");

//

pub fn dispatch(
    io: Io,
    gpa: std.mem.Allocator,
    accounts: *AccountStore,
    game_server_address: []const u8,
    request: *std.http.Server.Request,
) !void {
    if (request.head.method == .POST and std.mem.eql(u8, request.head.target, "/common/config")) {
        return try @import("routes/common.zig").config(request);
    }

    if (request.head.method == .GET and std.mem.eql(u8, request.head.target, "/common/client-code")) {
        return try @import("routes/client_code.zig").get(request);
    }

    if (request.head.method == .POST and std.mem.eql(u8, request.head.target, "/user/quick-login")) {
        return try @import("routes/user.zig").quickLogin(io, accounts, request);
    }

    if (request.head.method == .POST and std.mem.eql(u8, request.head.target, "/user/login")) {
        return try @import("routes/user.zig").login(io, gpa, accounts, request);
    }

    if (request.head.method == .POST and std.mem.eql(u8, request.head.target, "/user/detail")) {
        return try @import("routes/user.zig").detail(io, accounts, request);
    }

    if (request.head.method == .POST and std.mem.eql(u8, request.head.target, "/internal/account/validate")) {
        return try @import("routes/internal_account.zig").validate(io, accounts, request);
    }

    if (request.head.method == .GET and std.mem.eql(u8, request.head.target, "/meta/serverlist.html")) {
        return try @import("routes/server_list.zig").get(
            io,
            request,
            game_server_address,
        );
    }

    try request.respond("", .{ .status = .not_found });
}
