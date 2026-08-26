const achievement = @import("../gameplay/achievement.zig");
const change_info = @import("../view/change_info.zig");
const Player = @import("../store/Player.zig");
const player_store = @import("../store/Player.zig");
const proto = @import("proto");
const reward = @import("../gameplay/reward.zig");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn achievement_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    const now = scope.now;
    var changes: achievement.ChangeSet = .{};
    try achievement.refresh(scope.mutation(), scope.gpa, now, &changes);

    const states = scope.player.achievements.slice();
    const entries = try scope.arena.alloc(proto.pb.Achievement, states.len);
    const progress = try scope.arena.alloc([1]proto.pb.QuestProgress, states.len);
    var entry_count: usize = 0;
    for (states) |state| {
        const definition = tables.achievement.get(state.id) orelse
            continue;
        progress[entry_count] = .{.{ .Cur = state.progress, .Max = definition.target }};
        entries[entry_count] = .{
            .Id = state.id,
            .Status = @intFromEnum(state.status),
            .Completed = state.completed_at,
            .Progress = .fromOwnedSlice(&progress[entry_count]),
        };
        entry_count += 1;
    }
    try scope.respond(proto.pb.Achievements{ .List = .fromOwnedSlice(entries[0..entry_count]) });
}

pub fn achievement_reward_receive_req(scope: *Scope) !void {
    const log = scope.logger(.achievement_reward_receive_req);

    const request = try scope.source.read(proto.pb.AchievementRewardReq);
    const mutation = scope.mutation();
    var receipt: reward.ResourceReceipt = .{};
    var claimed: usize = 0;

    var ids = request.Ids;
    while (try ids.next()) |id| {
        const current = findStateConst(mutation.read(), id) orelse
            continue;
        if (current.status != .reward_available)
            continue;

        const definition = tables.achievement.get(id) orelse
            continue;
        const player = mutation.modify(.{});
        const state = findState(player, id).?;
        state.status = .reward_received;
        try reward.grantResource(
            mutation,
            scope.gpa,
            &receipt,
            definition.reward_id,
            definition.reward_quantity,
        );
        claimed += 1;
    }

    var change: change_info.Resources = .{};
    try scope.respond(try change.build(&receipt, scope.arena));

    log.info("claimed {d} achievement reward(s)", .{claimed});
}

fn findState(player: *player_store, id: u32) ?*player_store.Achievement {
    for (player.achievements.entries[0..player.achievements.len]) |*state| {
        if (state.id == id)
            return state;
    }

    return null;
}

fn findStateConst(player: *const player_store, id: u32) ?*const player_store.Achievement {
    for (player.achievements.entries[0..player.achievements.len]) |*state| {
        if (state.id == id)
            return state;
    }

    return null;
}
