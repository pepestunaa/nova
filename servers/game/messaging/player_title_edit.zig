const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn player_title_edit_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.PlayerTitleEditReq);
    gameplay.player_profile.setTitle(scope.mutation(), request.TitlePrefix, request.TitleSuffix) catch |err| switch (err) {
        error.TitleNotOwned => return scope.reject(.title_not_found),
    };

    try scope.respond(proto.pb.Nil{});
}
