//! Tracks Research Project progress earned through Ascension.

const std = @import("std");
const Allocator = std.mem.Allocator;

const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");
const tower_growth = @import("tower_growth.zig");

//

const quest_type = @intFromEnum(tables.quest.Type.tower);

/// Creates the first Research Project tasks. `sync` adds later tasks after
/// their prerequisite rewards are claimed.
pub fn initialize(player: *Player, allocator: Allocator) Allocator.Error!void {
    _ = try sync(player, allocator);
}

/// Refreshes active tasks from saved player state. Claiming a prerequisite
/// reward, rather than merely completing it, unlocks the next tasks in the UI.
pub fn sync(player: *Player, allocator: Allocator) Allocator.Error!bool {
    var changed = false;
    for (tables.research_project.list) |definition| {
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
        });
        changed = true;
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
        changed = true;
    }

    return changed;
}

pub fn enteredAscension(player: *Player) void {
    player.research_project.ascensions +|= 1;
    refreshActive(player);
}

pub fn completedAscension(player: *Player, difficulty: u32) void {
    if (difficulty >= 1 and difficulty <= player.research_project.clears_by_difficulty.len)
        player.research_project.clears_by_difficulty[difficulty - 1] +|= 1;
    refreshActive(player);
}

pub fn purchasedShopGood(player: *Player, discounted: bool) void {
    player.research_project.shop_purchases +|= 1;
    if (discounted)
        player.research_project.discounted_shop_purchases +|= 1;
    refreshActive(player);
}

pub fn collectedMusicalNotes(player: *Player, count: u32) void {
    player.research_project.musical_notes +|= count;
    refreshActive(player);
}

pub fn usedEnhancementMachine(player: *Player) void {
    player.research_project.enhancement_machine_uses +|= 1;
    refreshActive(player);
}

pub fn activatedHarmonySkills(player: *Player, count: u32) void {
    if (count == 0)
        return;
    player.research_project.harmony_skills +|= count;
    refreshActive(player);
}

/// Rechecks active tasks after another system changes relevant player state,
/// such as discovering an Anecdote through a Monolith event.
pub fn refresh(player: *Player) void {
    refreshActive(player);
}

pub fn triggeredSurpriseNote(player: *Player) void {
    player.research_project.surprise_notes +|= 1;
    refreshActive(player);
}

pub fn triggeredButterfliesInside(player: *Player) void {
    player.research_project.butterflies_inside +|= 1;
    refreshActive(player);
}

pub fn triggeredPotentialBoost(player: *Player) void {
    player.research_project.potential_boosts +|= 1;
    refreshActive(player);
}

pub fn refreshedPotentials(player: *Player) void {
    player.research_project.potential_refreshes +|= 1;
    refreshActive(player);
}

pub fn restockedShop(player: *Player) void {
    player.research_project.shop_restocks +|= 1;
    refreshActive(player);
}

pub fn savedRecord(player: *Player, rating: u8) void {
    player.research_project.highest_record_rating = @max(
        player.research_project.highest_record_rating,
        rating,
    );
    refreshActive(player);
}

pub fn claimable(player: *const Player, id: u32) ?*const Player.Quest {
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

/// Claims a completed task and lets `sync` expose anything it unlocks.
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
        .inventory = true,
        .quests = true,
        .research_project = true,
    });

    if (id == 0) {
        const quests = player.quests.entries[0..player.quests.len];
        for (quests) |*quest| {
            if (quest.quest_type != quest_type or
                quest.claimed or
                quest.progress_current < quest.progress_max)
                continue;

            try claimQuest(player, allocator, quest, receipt);
        }

        _ = try sync(player, allocator);

        return true;
    }

    const quest = findMut(player, id).?;
    try claimQuest(player, allocator, quest, receipt);
    _ = try sync(player, allocator);

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

fn refreshActive(player: *Player) void {
    for (player.quests.entries[0..player.quests.len]) |*quest| {
        if (quest.quest_type != quest_type)
            continue;
        const definition = tables.research_project.get(quest.id) orelse
            continue;
        quest.progress_current = progressFor(player, definition);
    }
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
