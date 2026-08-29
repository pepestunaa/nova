const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn player_skin_show_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.PlayerSkinShowReq);
    gameplay.player_profile.setProfileSkin(scope.mutation(), request.SkinId) catch |err| switch (err) {
        error.SkinNotOwned => return scope.reject(.invalid_req),
    };

    try scope.respond(proto.pb.Nil{});
}
