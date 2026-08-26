const std = @import("std");
const Allocator = std.mem.Allocator;

const achievement = @import("achievement.zig");
const Mutation = @import("mutation.zig");
const quest = @import("quest.zig");
const research_project = @import("research_project.zig");

//

pub const Changes = struct {
    achievements: achievement.ChangeSet = .{},
    lineup_tutorial: quest.AssistChanges = .{},
    research_project: research_project.ChangeSet = .{},
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

    if (mutation.invalidates(.acquisitions))
        try achievement.refreshCollection(
            mutation,
            allocator,
            now,
            &changes.achievements,
        );
    if (mutation.invalidates(.characters) or mutation.invalidates(.discs))
        try achievement.refreshProgression(
            mutation,
            allocator,
            now,
            &changes.achievements,
        );

    if (mutation.invalidates(.acquisitions) or
        mutation.invalidates(.characters) or
        mutation.invalidates(.discs) or
        mutation.invalidates(.tutorials))
    {
        quest.refreshAssist(mutation.player, &changes.lineup_tutorial);
    }

    if (mutation.invalidates(.research_project) or
        mutation.invalidates(.tower_growth))
        try research_project.reconcile(
            mutation,
            allocator,
            &changes.research_project,
        );

    mutation.finish();
}

//

test "finalization ignores progression families unrelated to the mutation" {
    const testing = std.testing;
    const Player = @import("../store/Player.zig");

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try research_project.initialize(&player, testing.allocator);

    var mutation: Mutation = .init(&player);
    mutation.modify(.{}).basic.head_icon = 999;
    var changes: Changes = .{};
    try finalize(&mutation, testing.allocator, 1, &changes);

    try testing.expect(mutation.isFinalized());
    try testing.expectEqual(@as(usize, 0), changes.achievements.len);
    try testing.expectEqual(@as(usize, 0), changes.lineup_tutorial.len);
    try testing.expectEqual(@as(usize, 0), changes.research_project.len);
}

test "card acquisition carries all derived progression through finalization" {
    const testing = std.testing;
    const Player = @import("../store/Player.zig");
    const reward = @import("reward.zig");
    const tables = @import("../tables.zig");

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    const card_id = tables.gacha.newbieGachaPool(.b_trekker)[0].goods_id;
    const cards = [_]tables.gacha.Card{.{
        .id = card_id,
        .class = tables.gacha.classifyCard(card_id),
    }};
    try testing.expectEqual(tables.gacha.CardKind.character, cards[0].class.kind);

    var mutation: Mutation = .init(&player);
    var receipt: reward.GachaReceipt = .{};
    try reward.grantCards(
        &mutation,
        testing.allocator,
        &cards,
        100,
        &receipt,
    );

    try testing.expect(mutation.invalidates(.acquisitions));
    try testing.expect(mutation.invalidates(.characters));
    try testing.expect(player.characters.get(card_id) != null);
    try testing.expectEqual(@as(usize, 1), player.acquisitions.len);
    try testing.expectEqual(@as(u32, 1), player.acquisitions.slice()[0].count);

    const handbook_id = tables.handbook.defaultSkin(card_id).?.id;
    var has_handbook_entry = false;
    for (player.handbook.slice()) |entry|
        has_handbook_entry = has_handbook_entry or entry.handbook_id == handbook_id;
    try testing.expect(has_handbook_entry);

    var changes: Changes = .{};
    try finalize(&mutation, testing.allocator, 100, &changes);
    try testing.expect(mutation.isFinalized());
    try testing.expect(changes.achievements.dirty);

    var new_characters = mutation.newCharacterIterator();
    const character_index = tables.character.Index.fromId(card_id).?;
    try testing.expectEqual(
        @as(?usize, @intFromEnum(character_index)),
        new_characters.next(),
    );
    try testing.expectEqual(@as(?usize, null), new_characters.next());

    var handbook_types = mutation.handbookTypeIterator();
    try testing.expectEqual(
        @as(?usize, tables.handbook.skin_type),
        handbook_types.next(),
    );
    try testing.expectEqual(@as(?usize, null), handbook_types.next());
}
