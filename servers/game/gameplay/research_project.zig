//! Tracks Research Project progress earned through Ascension.

const std = @import("std");
const Allocator = std.mem.Allocator;

const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");
const tower_growth = @import("tower_growth.zig");

//

const quest_type = @intFromEnum(tables.quest.Type.tower);
const QuestSet = std.bit_set.IntegerBitSet(tables.research_project.list.len);

pub const ChangeSet = struct {
    entries: [tables.research_project.list.len]Player.Quest = undefined,
    len: usize = 0,

    pub fn slice(changes: *const ChangeSet) []const Player.Quest {
        return changes.entries[0..changes.len];
    }
};

/// Creates every Research Project task whose prerequisites are already
/// claimed. Later groups are added during request finalization.
pub fn initialize(player: *Player, allocator: Allocator) Allocator.Error!void {
    var changed: QuestSet = .empty;
    try syncPlayer(player, allocator, &changed);
}

/// Reconciles active tasks once after all actions in the request have run.
/// Claiming a prerequisite reward, rather than merely completing it, unlocks
/// the next tasks in the UI.
pub fn reconcile(
    mutation: *Mutation,
    allocator: Allocator,
    changes: *ChangeSet,
) Allocator.Error!void {
    changes.* = .{};
    var changed: QuestSet = .empty;
    var explicitly_changed = mutation.researchProjectQuestIterator();
    while (explicitly_changed.next()) |index|
        changed.set(index);

    try syncPlayer(mutation.player, allocator, &changed);

    var iterator = changed.iterator(.{});
    while (iterator.next()) |index| {
        const id = tables.research_project.list[index].id;
        changes.entries[changes.len] = find(mutation.player, id).?.*;
        changes.len += 1;
    }
}

fn syncPlayer(
    player: *Player,
    allocator: Allocator,
    changed: *QuestSet,
) Allocator.Error!void {
    for (tables.research_project.list, 0..) |definition, index| {
        if (find(player, definition.id) != null)
            continue;
        if (!prerequisitesClaimed(player, &definition))
            continue;

        try player.quests.append(allocator, .{
            .id = definition.id,
            .quest_type = quest_type,
            .condition = @intFromEnum(definition.condition),
            .condition_param = definition.condition_param,
            .progress_max = definition.target,
            .progress_current = progressFor(player, &definition),
        });
        changed.set(index);
    }

    for (player.quests.entries[0..player.quests.len]) |*quest| {
        if (quest.quest_type != quest_type)
            continue;
        const definition = tables.research_project.get(quest.id) orelse
            continue;
        const progress = progressFor(player, definition);
        if (quest.progress_current == progress)
            continue;
        quest.progress_current = progress;
        changed.set(indexOf(definition.id));
    }
}

pub fn enteredAscension(mutation: *Mutation) void {
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.ascensions +|= 1;
}

pub fn completedAscension(mutation: *Mutation, difficulty: u32) void {
    const current = mutation.read();
    if (difficulty == 0 or difficulty > current.research_project.clears_by_difficulty.len)
        return;
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.clears_by_difficulty[difficulty - 1] +|= 1;
}

pub fn purchasedShopGood(mutation: *Mutation, discounted: bool) void {
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.shop_purchases +|= 1;
    if (discounted)
        player.research_project.discounted_shop_purchases +|= 1;
}

pub fn collectedMusicalNotes(mutation: *Mutation, count: u32) void {
    if (count == 0)
        return;
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.musical_notes +|= count;
}

pub fn usedEnhancementMachine(mutation: *Mutation) void {
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.enhancement_machine_uses +|= 1;
}

pub fn activatedHarmonySkills(mutation: *Mutation, count: u32) void {
    if (count == 0)
        return;
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.harmony_skills +|= count;
}

pub fn triggeredSurpriseNote(mutation: *Mutation) void {
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.surprise_notes +|= 1;
}

pub fn triggeredButterfliesInside(mutation: *Mutation, count: u32) void {
    if (count == 0)
        return;
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.butterflies_inside +|= count;
}

pub fn triggeredPotentialBoost(mutation: *Mutation) void {
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.potential_boosts +|= 1;
}

pub fn refreshedPotentials(mutation: *Mutation) void {
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.potential_refreshes +|= 1;
}

pub fn restockedShop(mutation: *Mutation) void {
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.shop_restocks +|= 1;
}

pub fn savedRecord(mutation: *Mutation, rating: u8) void {
    if (rating <= mutation.read().research_project.highest_record_rating)
        return;
    const player = mutation.modify(.{ .research_project = true });
    player.research_project.highest_record_rating = @max(
        player.research_project.highest_record_rating,
        rating,
    );
}

pub fn claimable(player: *const Player, id: u32) ?*const Player.Quest {
    if (tables.research_project.get(id) == null)
        return null;
    const quest = find(player, id) orelse
        return null;
    if (quest.claimed or quest.progress_current < quest.progress_max)
        return null;

    return quest;
}

pub const RewardReceipt = struct {
    resources: [max_reward_deltas]RewardDelta = undefined,
    resource_count: usize = 0,
    items: [max_reward_deltas]RewardDelta = undefined,
    item_count: usize = 0,

    pub const RewardDelta = struct {
        id: u32,
        quantity: i32,
    };
};

pub const max_reward_deltas = tables.research_project.list.len * 2;

/// Claims a completed task. Request finalization exposes anything it unlocks.
pub fn claim(
    mutation: *Mutation,
    allocator: Allocator,
    id: u32,
    receipt: *RewardReceipt,
) Allocator.Error!bool {
    receipt.* = .{};

    const current = mutation.read();
    if (id == 0) {
        var found = false;
        for (current.quests.slice()) |quest| {
            if (quest.quest_type == quest_type and
                tables.research_project.get(quest.id) != null and
                !quest.claimed and
                quest.progress_current >= quest.progress_max)
            {
                found = true;
                break;
            }
        }
        if (!found)
            return false;
    } else if (claimable(current, id) == null) {
        return false;
    }

    const player = mutation.modify(.{
        .research_project = true,
    });

    if (id == 0) {
        const quests = player.quests.entries[0..player.quests.len];
        for (quests) |*quest| {
            if (quest.quest_type != quest_type or
                tables.research_project.get(quest.id) == null or
                quest.claimed or
                quest.progress_current < quest.progress_max)
                continue;

            try claimQuest(player, allocator, quest, receipt);
            mutation.recordResearchProjectQuest(quest.id);
        }

        return true;
    }

    const quest = findMut(player, id).?;
    try claimQuest(player, allocator, quest, receipt);
    mutation.recordResearchProjectQuest(id);

    return true;
}

fn claimQuest(
    player: *Player,
    allocator: Allocator,
    quest: *Player.Quest,
    receipt: *RewardReceipt,
) Allocator.Error!void {
    const definition = tables.research_project.get(quest.id) orelse
        return;
    quest.claimed = true;

    for (definition.rewards) |reward| {
        if (reward.quantity == 0)
            continue;
        if (tables.item.isResource(reward.item_id)) {
            try player.addResource(allocator, reward.item_id, reward.quantity);
            appendDelta(
                receipt.resources[0..],
                &receipt.resource_count,
                reward.item_id,
                reward.quantity,
            );
        } else {
            try player.addItem(allocator, reward.item_id, reward.quantity);
            appendDelta(
                receipt.items[0..],
                &receipt.item_count,
                reward.item_id,
                reward.quantity,
            );
        }
    }
}

fn appendDelta(
    entries: []RewardReceipt.RewardDelta,
    count: *usize,
    id: u32,
    quantity: i32,
) void {
    for (entries[0..count.*]) |*entry| {
        if (entry.id != id)
            continue;

        entry.quantity +|= quantity;

        return;
    }

    std.debug.assert(count.* < entries.len);
    entries[count.*] = .{ .id = id, .quantity = quantity };
    count.* += 1;
}

fn progressFor(player: *const Player, definition: *const tables.research_project.Definition) u32 {
    const state = &player.research_project;
    const progress: u32 = switch (definition.condition) {
        .activate_nodes => activatedNodeCount(player, definition),
        .enter_ascension => state.ascensions,
        .clear_difficulty => clearsAtLeast(&state.clears_by_difficulty, definition.condition_param),
        .shop_purchase => state.shop_purchases,
        .musical_note => state.musical_notes,
        .record_rating => @intFromBool(state.highest_record_rating >= definition.condition_param),
        .enhancement_machine => state.enhancement_machine_uses,
        .harmony_skill => state.harmony_skills,
        .monolith_log => anecdoteCount(player),
        .discounted_shop_purchase => state.discounted_shop_purchases,
        .surprise_note => state.surprise_notes,
        .butterflies_inside => state.butterflies_inside,
        .potential_boost => state.potential_boosts,
        .refresh_potentials => state.potential_refreshes,
        .restock_shop => state.shop_restocks,
    };

    return @min(progress, definition.target);
}

fn activatedNodeCount(
    player: *const Player,
    definition: *const tables.research_project.Definition,
) u32 {
    var count: u32 = 0;

    for (definition.required_nodes[0..definition.required_node_count]) |node_id| {
        if (tower_growth.has(player, node_id)) count += 1;
    }

    return count;
}

fn clearsAtLeast(clears: []const u32, minimum_difficulty: u32) u32 {
    if (minimum_difficulty == 0 or minimum_difficulty > clears.len)
        return 0;

    var total: u32 = 0;
    for (clears[minimum_difficulty - 1 ..]) |count|
        total +|= count;

    return total;
}

/// The Monolith Log displays completed event entries. Their type-12 tasks are
/// the saved source of truth; claiming the reward does not affect whether an
/// Anecdote has been discovered.
fn anecdoteCount(player: *const Player) u32 {
    var count: u32 = 0;
    for (player.quests.slice()) |quest| {
        if (quest.quest_type != @intFromEnum(tables.quest.Type.tower_event) or
            quest.progress_current < quest.progress_max or
            tables.star_tower_book.eventReward(quest.id) == null)
            continue;
        count += 1;
    }

    return count;
}

fn prerequisitesClaimed(
    player: *const Player,
    definition: *const tables.research_project.Definition,
) bool {
    for (definition.prerequisites[0..definition.prerequisite_count]) |id| {
        const quest = find(player, id) orelse
            return false;
        if (!quest.claimed)
            return false;
    }

    return true;
}

fn find(player: *const Player, id: u32) ?*const Player.Quest {
    for (player.quests.slice()) |*quest| {
        if (quest.quest_type == quest_type and quest.id == id)
            return quest;
    }

    return null;
}

fn findMut(player: *Player, id: u32) ?*Player.Quest {
    for (player.quests.entries[0..player.quests.len]) |*quest| {
        if (quest.quest_type == quest_type and quest.id == id)
            return quest;
    }

    return null;
}

fn indexOf(id: u32) usize {
    for (tables.research_project.list, 0..) |definition, index| {
        if (definition.id == id)
            return index;
    }
    unreachable;
}

//

test "Ascension participation reconciles once and does not repeat completed task changes" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try initialize(&player, testing.allocator);

    const participation = find(&player, 101).?;
    try testing.expectEqual(@as(u32, 0), participation.progress_current);

    var first_mutation: Mutation = .init(&player);
    enteredAscension(&first_mutation);
    var first_changes: ChangeSet = .{};
    try reconcile(&first_mutation, testing.allocator, &first_changes);

    try testing.expectEqual(@as(u32, 1), find(&player, 101).?.progress_current);
    try testing.expectEqual(@as(usize, 1), first_changes.len);
    try testing.expectEqual(@as(u32, 101), first_changes.slice()[0].id);
    first_mutation.finish();
    first_mutation.committed();

    var second_mutation: Mutation = .init(&player);
    enteredAscension(&second_mutation);
    var second_changes: ChangeSet = .{};
    try reconcile(&second_mutation, testing.allocator, &second_changes);

    try testing.expectEqual(@as(u32, 2), player.research_project.ascensions);
    try testing.expectEqual(@as(usize, 0), second_changes.len);
}

test "Butterflies Inside actions merge into one final task update" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try initialize(&player, testing.allocator);
    const definition = tables.research_project.get(701).?;
    try player.quests.append(testing.allocator, .{
        .id = definition.id,
        .quest_type = quest_type,
        .condition = @intFromEnum(definition.condition),
        .condition_param = definition.condition_param,
        .progress_max = definition.target,
    });

    var mutation: Mutation = .init(&player);
    triggeredButterfliesInside(&mutation, 1);
    triggeredButterfliesInside(&mutation, 2);
    var changes: ChangeSet = .{};
    try reconcile(&mutation, testing.allocator, &changes);

    try testing.expectEqual(@as(u32, 3), player.research_project.butterflies_inside);
    try testing.expectEqual(@as(u32, 3), find(&player, 701).?.progress_current);
    try testing.expectEqual(@as(usize, 1), changes.len);
    try testing.expectEqual(@as(u32, 701), changes.slice()[0].id);
}

test "claim all reports claimed tasks and newly unlocked tasks once" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try initialize(&player, testing.allocator);
    findMut(&player, 100).?.progress_current = find(&player, 100).?.progress_max;
    findMut(&player, 101).?.progress_current = find(&player, 101).?.progress_max;

    var mutation: Mutation = .init(&player);
    var receipt: RewardReceipt = .{};
    try testing.expect(try claim(
        &mutation,
        testing.allocator,
        0,
        &receipt,
    ));
    var changes: ChangeSet = .{};
    try reconcile(&mutation, testing.allocator, &changes);

    try testing.expect(find(&player, 100).?.claimed);
    try testing.expect(find(&player, 101).?.claimed);
    try testing.expect(find(&player, 200) != null);
    try testing.expect(find(&player, 201) == null);
    try testing.expect(find(&player, 202) != null);
    try testing.expect(find(&player, 203) != null);

    const expected_ids = [_]u32{ 100, 101, 200, 202, 203 };
    try testing.expectEqual(expected_ids.len, changes.len);
    for (changes.slice(), expected_ids) |quest, expected_id|
        try testing.expectEqual(expected_id, quest.id);
}
