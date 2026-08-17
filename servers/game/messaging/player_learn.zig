const Scope = @import("../Scope.zig");
const proto = @import("proto");
const Player = @import("../store/Player.zig");

//

pub fn player_learn_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.NewbieInfo);
    try scope.playerMut().learn(scope.gpa, request.GroupId, request.StepId);

    scope.markDirty();

    try scope.respond(proto.pb.Nil{});
}
