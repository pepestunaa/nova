const Allocator = @import("std").mem.Allocator;

const achievement = @import("achievement.zig");
const Mutation = @import("mutation.zig");
const quest = @import("quest.zig");
const research_project = @import("research_project.zig");

//

pub const Changes = struct {
    achievements: achievement.ChangeSet = .{},
    lineup_tutorial: quest.AssistChanges = .{},
};

/// Reconciles every derived system affected by this request. Protocol
/// notifications are built separately from the returned change sets.
pub fn finalize(
    mutation: *Mutation,
    allocator: Allocator,
    now: i64,
    changes: *Changes,
) Allocator.Error!void {
    changes.* = .{};

    if (mutation.affects(.acquisitions))
        try achievement.refreshCollection(
            mutation,
            allocator,
            now,
            &changes.achievements,
        );
    if (mutation.affects(.characters) or mutation.affects(.discs))
        try achievement.refreshProgression(
            mutation,
            allocator,
            now,
            &changes.achievements,
        );

    if (mutation.affects(.acquisitions) or
        mutation.affects(.characters) or
        mutation.affects(.discs) or
        mutation.affects(.tutorials))
    {
        quest.refreshAssist(mutation.player, &changes.lineup_tutorial);
        if (changes.lineup_tutorial.len != 0)
            mutation.affect(.{ .quests = true });
    }

    if (mutation.affects(.research_project) or
        mutation.affects(.ascension) or
        mutation.affects(.tower_growth))
        research_project.refresh(mutation.player);

    mutation.finish();
}
