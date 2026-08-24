const std = @import("std");
const Io = std.Io;

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
    const now = Io.Timestamp.now(scope.io, .real).toSeconds();
    var changes: achievement.ChangeSet = .{};
    const player = scope.playerMut();
    try achievement.refresh(player, scope.gpa, now, &changes);

    if (changes.dirty) scope.markDirty();

    const states = player.achievements.slice();
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
    const player = scope.playerMut();
    var receipt: reward.AchievementReceipt = .{};
    var claimed: usize = 0;

    var ids = request.Ids;
    while (try ids.next()) |id| {
        const state = findState(player, id) orelse
            continue;
        if (state.status != .reward_available)
            continue;

        const definition = tables.achievement.get(id) orelse
            continue;
        state.status = .reward_received;
        try reward.applyAchievementReward(
            player,
            scope.gpa,
            &receipt,
            definition.reward_id,
            definition.reward_quantity,
        );
        claimed += 1;
    }

    if (claimed != 0) scope.markDirty();

    var change: change_info.Achievement = .{};
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
