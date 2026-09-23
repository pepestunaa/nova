const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn score_boss_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);

    const control = tables.score_boss.active(scope.now) orelse
        return scope.reject(.score_boss_not_open);

    try scope.respond(proto.pb.ScoreBossInfo{
        .ControlId = control.id,
    });
}
