const Mutation = @import("../gameplay/mutation.zig");
const quest = @import("../gameplay/quest.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

pub fn sendLineupTutorial(scope: *Scope, changes: *const quest.AssistChanges) !void {
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

pub fn sendNewTrekkerAffinityQuests(scope: *Scope, mutation: *const Mutation) !void {
    var characters = mutation.newCharacterIterator();
    while (characters.next()) |raw_index| {
        const card_id = @as(tables.character.Index, @enumFromInt(raw_index)).id();
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
