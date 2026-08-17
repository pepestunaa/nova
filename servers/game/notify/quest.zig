const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const reward = @import("../gameplay/reward.zig");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

pub fn refreshLineupTutorial(scope: *Scope) !void {
    var changes: gameplay.quest.AssistChanges = .{};
    gameplay.quest.refreshAssist(scope.playerMut(), &changes);
    for (changes.slice()) |state| {
        var progress: [1]proto.pb.QuestProgress = .{.{
            .Cur = state.progress_current,
            .Max = state.progress_max,
        }};
        const update: proto.pb.Quest = .{
            .Id = state.id,
            .Status = if (state.claimed) 2 else if (state.progress_current >= state.progress_max) 1 else 0,
            .Expire = state.expires_at,
            .Type = @enumFromInt(state.quest_type),
            .Progress = .fromOwnedSlice(&progress),
        };
        try scope.sink.sendProto(.quest_change_notify, &update);
    }
}

pub fn sendNewTrekkerAffinityQuests(scope: *Scope, receipt: *const reward.GachaReceipt) !void {
    for (receipt.new_card_ids[0..receipt.new_card_count]) |card_id| {
        const card = tables.gacha.maybeClassifyCard(card_id) orelse
            continue;
        if (card.kind != .character)
            continue;

        const definitions = tables.affinity_quest.forCharacter(@intCast(card_id));
        for (definitions) |definition| {
            var progress: [1]proto.pb.QuestProgress = .{.{ .Max = definition.target }};
            const update: proto.pb.Quest = .{
                .Id = definition.id,
                .Type = .Affinity,
                .Progress = .fromOwnedSlice(&progress),
            };
            try scope.sink.sendProto(.quest_change_notify, &update);
        }
    }
}
