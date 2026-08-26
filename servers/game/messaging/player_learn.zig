const Scope = @import("../Scope.zig");
const proto = @import("proto");

//

pub fn player_learn_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.NewbieInfo);
    if (scope.player.guideStep(request.GroupId) == request.StepId)
        return scope.respond(proto.pb.Nil{});

    try scope.mutation().modify(.{ .tutorials = true }).learn(
        scope.gpa,
        request.GroupId,
        request.StepId,
    );

    try scope.respond(proto.pb.Nil{});
}
