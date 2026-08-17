//! Handles Research Project reward claims.

const change_info = @import("../view/change_info.zig");
const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const research_project_notify = @import("../notify/research_project.zig");
const Scope = @import("../Scope.zig");

//

pub fn quest_tower_reward_receive_req(scope: *Scope) !void {
    const log = scope.logger(.quest_tower_reward_receive_req);

    const request = try scope.source.read(proto.pb.UI32);
    const player = scope.playerMut();
    var receipt: gameplay.research_project.RewardReceipt = .{};
    const claimed = try gameplay.research_project.claim(
        player,
        scope.gpa,
        request.Value,
        &receipt,
    );
    if (!claimed)
        return scope.reject(.invalid_req);

    scope.markDirty();

    var change: change_info.ResearchProject = .{};
    try scope.respond(try change.build(&receipt, scope.arena));
    try research_project_notify.send(scope);

    log.info("claimed Research Project quest {d}", .{request.Value});
}
