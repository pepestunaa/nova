const std = @import("std");

const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn player_login_req(scope: *Scope) !void {
    const log = scope.logger(.player_login_req);

    const request = try scope.source.read(proto.pb.LoginReq);

    const auth_method: []const u8 = if (request.Account != null)
        "regular"
    else if (request.Official != null)
        "official"
    else if (request.OfficialOverseas != null)
        "official overseas"
    else if (request.Token != null)
        "token"
    else
        "none";

    log.info(
        "platform: {d}, language: '{s}', channel '{s}', version: '{s}', auth: '{s}'",
        .{
            @intFromEnum(request.Platform),
            request.Language,
            request.Channel,
            request.Version,
            auth_method,
        },
    );

    const credentials: ?struct { uid: u64, token: []const u8 } = if (request.OfficialOverseas) |auth|
        .{
            .uid = std.fmt.parseInt(u64, auth.Uid, 10) catch {
                log.warn("received non-numeric overseas account UID '{s}'", .{auth.Uid});
                return scope.reject(.token_expire);
            },
            .token = auth.Token,
        }
    else if (request.Official) |auth|
        .{
            .uid = auth.Uid,
            .token = auth.Token,
        }
    else
        null;

    const account_credentials = credentials orelse
        return scope.reject(.token_expire);
    if (!try scope.auth.validate(
        account_credentials.uid,
        account_credentials.token,
    ))
        return scope.reject(.token_expire);

    try scope.loadPlayer(account_credentials.uid);
    if (scope.player.is_registered)
        try gameplay.missions.login(scope.mutation(), scope.gpa, scope.now);

    try scope.respond(proto.pb.LoginResp{ .Token = scope.rotateSessionToken() });
}
