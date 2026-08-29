const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn player_head_icon_set_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.PlayerHeadIconSetReq);
    gameplay.player_profile.setHeadIcon(scope.mutation(), request.HeadIcon) catch |err| switch (err) {
        error.IconNotOwned => return scope.reject(.invalid_req),
    };

    try scope.respond(proto.pb.Nil{});
}
