const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn player_name_edit_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.PlayerNameEditReq);
    gameplay.player_profile.setNickname(scope.mutation(), request.Name) catch |err| switch (err) {
        error.InvalidNickname => return scope.reject(.invalid_req),
        else => |other| return other,
    };

    try scope.respond(proto.pb.PlayerNameEditResp{ .ResetTime = scope.now });
}
