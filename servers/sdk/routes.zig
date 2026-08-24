const std = @import("std");
const Io = std.Io;

const Account = @import("Account.zig");
const client_code = @import("routes/client_code.zig");
const common = @import("routes/common.zig");
const internal_account = @import("routes/internal_account.zig");
const server_list = @import("routes/server_list.zig");
const user = @import("routes/user.zig");

//

const GetPath = enum {
    @"/common/client-code",
    @"/meta/serverlist.html",
};

const PostPath = enum {
    @"/common/config",
    @"/user/quick-login",
    @"/user/login",
    @"/user/detail",
    @"/internal/account/validate",
};

pub fn dispatch(
    io: Io,
    gpa: std.mem.Allocator,
    accounts: *Account.Store,
    game_server_address: []const u8,
    request: *std.http.Server.Request,
) !void {
    return switch (request.head.method) {
        .GET => switch (std.meta.stringToEnum(GetPath, request.head.target) orelse
            return request.respond("", .{ .status = .not_found })) {
            .@"/common/client-code" => client_code.get(request),
            .@"/meta/serverlist.html" => server_list.get(
                io,
                request,
                game_server_address,
            ),
        },
        .POST => switch (std.meta.stringToEnum(PostPath, request.head.target) orelse
            return request.respond("", .{ .status = .not_found })) {
            .@"/common/config" => common.config(request),
            .@"/user/quick-login" => user.quickLogin(io, accounts, request),
            .@"/user/login" => user.login(io, gpa, accounts, request),
            .@"/user/detail" => user.detail(io, accounts, request),
            .@"/internal/account/validate" => internal_account.validate(
                io,
                accounts,
                request,
            ),
        },
        else => request.respond("", .{ .status = .not_found }),
    };
}
