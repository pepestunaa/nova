const std = @import("std");

const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

pub fn has(player: *const Player, id: u32) bool {
    return isUnlocked(&player.tower_growth.details, id);
}

pub fn isUnlocked(details: []const u32, id: u32) bool {
    const node = tables.tower_growth.get(id) orelse
        return false;

    return isNodeUnlocked(details, node.group, node.node_id);
}

pub fn isNodeUnlocked(details: []const u32, group_id: u32, node_id: u32) bool {
    if (group_id == 0 or node_id == 0)
        return false;
    const group_index = group_id - 1;
    if (group_index >= details.len or node_id > @bitSizeOf(u32))
        return false;

    return details[group_index] & (@as(u32, 1) << @intCast(node_id - 1)) != 0;
}

pub fn setUnlocked(details: []u32, id: u32) void {
    const node = tables.tower_growth.get(id) orelse unreachable;

    std.debug.assert(node.group != 0 and node.group <= details.len);
    std.debug.assert(node.node_id != 0 and node.node_id <= @bitSizeOf(u32));

    details[node.group - 1] |= @as(u32, 1) << @intCast(node.node_id - 1);
}

/// Applies the server-owned effects of Monolith Research. The client receives
/// unlocked nodes for display, while rolls, prices, and rewards are derived
/// here so reconnecting cannot change an Ascension.
pub const Modifiers = struct {
    starting_coins: u32 = 0,
    starting_notes: u8 = 0,

    shop_good_count: u8 = 2,
    shop_rerolls: u8 = 0,
    shop_reroll_price: u32 = 100,
    shop_discount_tier: u8 = 0,

    potential_rerolls: u8 = 0,
    potential_reroll_price: u32 = 100,
    potential_level_cap_bonus: u8 = 0,
    potential_bonus_chance_per_thousand: u16 = 0,
    potential_bonus_levels: u8 = 0,
    potential_bonus_limit: u8 = 0, // 0 means unlimited.

    enable_end_strengthen: bool = false,
    enable_shop_strengthen: bool = false,
    first_strengthen_free: bool = false,
    strengthen_discount: u32 = 0,
    strengthen_bonus_chance_per_thousand: u16 = 0,
    strengthen_bonus_limit: u8 = 0,

    extra_note_chance_per_thousand: u16 = 0,
    surprise_note_chance_per_thousand: u16 = 0,
    surprise_note_drops: u8 = 0,
    surprise_note_limit: u8 = 0,
    boss_note_drops: u8 = 0,
    scratch_coin_chance_per_thousand: u16 = 0,
    scratch_coin_amount: u32 = 0,
    scratch_coin_limit: u8 = 5,
    battle_event_chance_per_thousand: u16 = 0,
    battle_event_limit: u8 = 0,

    journey_ticket_multiplier_per_thousand: u16 = 1000,
    journey_ticket_weekly_limit: u32 = 2000,
    support_disc_capacity: u8 = 0,
    restrict_notes_to_matching_element: bool = false,
    strengthen_bonus_applies_to_all: bool = false,
    defer_new_potential_bonus_consumption: bool = false,

    pub fn init(details: []const u32, difficulty: u32) Modifiers {
        var result: Modifiers = .{};

        // The starting currency nodes replace one another. An official capture
        // with all 3 unlocked began at 400: the base 200 plus the final
        // 200, not the combined 550.
        if (isUnlocked(details, 10702))
            result.starting_coins = 200
        else if (isUnlocked(details, 10403))
            result.starting_coins = 100
        else if (isUnlocked(details, 10103)) result.starting_coins = 50;
        if (isUnlocked(details, 10102)) result.starting_notes = 3;

        // "Unexpected Joy" (10202, `TowerExtraReward`) is still unknown. A
        // controlled before-and-after capture showed no change to the starting
        // bag, rooms, or settlement rewards, so implementing it would be a guess.

        // Monolith Premium tiers replace one another instead of stacking.
        if (difficulty >= 5 and isUnlocked(details, 20702))
            result.shop_good_count = 8
        else if (difficulty >= 4 and isUnlocked(details, 20402))
            result.shop_good_count = 6
        else if (isUnlocked(details, 10402)) result.shop_good_count = 4;
        if (isUnlocked(details, 20902)) result.shop_rerolls += 1;
        if (isUnlocked(details, 30601)) result.shop_rerolls += 1;
        if (difficulty >= 5 and isUnlocked(details, 20802))
            result.shop_discount_tier = 3
        else if (difficulty >= 4 and isUnlocked(details, 20502))
            result.shop_discount_tier = 2
        else if (difficulty >= 3 and isUnlocked(details, 20202)) result.shop_discount_tier = 1;

        if (isUnlocked(details, 20901)) result.potential_rerolls = 1;
        if (isUnlocked(details, 30702))
            result.potential_reroll_price = 40
        else if (isUnlocked(details, 30401))
            result.potential_reroll_price = 60
        else if (isUnlocked(details, 30101)) result.potential_reroll_price = 70;
        if (isUnlocked(details, 30301))
            result.potential_level_cap_bonus = 6
        else if (isUnlocked(details, 20601)) result.potential_level_cap_bonus = 4;

        if (difficulty >= 7 and isUnlocked(details, 30901)) {
            result.potential_bonus_chance_per_thousand = 300;
            result.potential_bonus_levels = 2;
            result.potential_bonus_limit = 10;
        } else if (difficulty >= 7 and isUnlocked(details, 30801)) {
            result.potential_bonus_chance_per_thousand = 200;
            result.potential_bonus_levels = 1;
        } else if (difficulty >= 6 and isUnlocked(details, 30201)) {
            result.potential_bonus_chance_per_thousand = 100;
            result.potential_bonus_levels = 1;
        } else if (difficulty >= 5 and isUnlocked(details, 20801)) {
            result.potential_bonus_chance_per_thousand = 50;
            result.potential_bonus_levels = 1;
            result.potential_bonus_limit = 1;
        }

        result.enable_end_strengthen = difficulty >= 2 and isUnlocked(details, 10601);
        result.enable_shop_strengthen = difficulty >= 4 and isUnlocked(details, 20301);
        result.first_strengthen_free = isUnlocked(details, 10801);
        if (isUnlocked(details, 30402))
            result.strengthen_discount = 60
        else if (isUnlocked(details, 30102)) result.strengthen_discount = 30;
        if (difficulty >= 7 and isUnlocked(details, 30802)) {
            result.strengthen_bonus_chance_per_thousand = 300;
            result.strengthen_bonus_limit = 5;
        } else if (difficulty >= 6 and isUnlocked(details, 30502)) {
            result.strengthen_bonus_chance_per_thousand = 200;
            result.strengthen_bonus_limit = 2;
        } else if (difficulty >= 6 and isUnlocked(details, 30202)) {
            result.strengthen_bonus_chance_per_thousand = 100;
            result.strengthen_bonus_limit = 1;
        }

        if (difficulty >= 4 and isUnlocked(details, 20401))
            result.extra_note_chance_per_thousand = 600
        else if (difficulty >= 3 and isUnlocked(details, 20101))
            result.extra_note_chance_per_thousand = 450
        else if (difficulty >= 2 and isUnlocked(details, 10401))
            result.extra_note_chance_per_thousand = 300
        else if (isUnlocked(details, 10101)) result.extra_note_chance_per_thousand = 150;
        if (difficulty >= 6 and isUnlocked(details, 30501)) {
            result.surprise_note_chance_per_thousand = 200;
            result.surprise_note_drops = 2;
            result.surprise_note_limit = 4;
        } else if (difficulty >= 4 and isUnlocked(details, 20501)) {
            result.surprise_note_chance_per_thousand = 100;
            result.surprise_note_drops = 2;
            result.surprise_note_limit = 2;
        } else if (difficulty >= 3 and isUnlocked(details, 20201)) {
            result.surprise_note_chance_per_thousand = 100;
            result.surprise_note_drops = 1;
            result.surprise_note_limit = 2;
        }
        if (difficulty >= 7 and isUnlocked(details, 30701))
            result.boss_note_drops = 3
        else if (difficulty >= 5 and isUnlocked(details, 20701))
            result.boss_note_drops = 2
        else if (difficulty >= 3 and isUnlocked(details, 10701)) result.boss_note_drops = 1;
        if (difficulty >= 3 and isUnlocked(details, 10802)) {
            result.scratch_coin_chance_per_thousand = 500;
            result.scratch_coin_amount = 50;
        } else if (difficulty >= 2 and isUnlocked(details, 10503)) {
            result.scratch_coin_chance_per_thousand = 300;
            result.scratch_coin_amount = 30;
        } else if (isUnlocked(details, 10203)) {
            result.scratch_coin_chance_per_thousand = 100;
            result.scratch_coin_amount = 10;
        }
        if (difficulty >= 4 and isUnlocked(details, 20503)) {
            result.battle_event_chance_per_thousand = 300;
            result.battle_event_limit = 5;
        } else if (difficulty >= 3 and isUnlocked(details, 10901)) {
            result.battle_event_chance_per_thousand = 200;
            result.battle_event_limit = 3;
        }

        if (isUnlocked(details, 20403))
            result.journey_ticket_multiplier_per_thousand = 2000
        else if (isUnlocked(details, 20102))
            result.journey_ticket_multiplier_per_thousand = 1600
        else if (isUnlocked(details, 10501)) result.journey_ticket_multiplier_per_thousand = 1300;

        if (isUnlocked(details, 40201))
            result.journey_ticket_multiplier_per_thousand = @intCast(
                @as(u32, result.journey_ticket_multiplier_per_thousand) * 3 / 2,
            );
        if (isUnlocked(details, 10201)) result.journey_ticket_weekly_limit += 500;
        if (isUnlocked(details, 10502)) result.journey_ticket_weekly_limit += 1000;
        if (isUnlocked(details, 20302))
            result.support_disc_capacity = 3
        else if (isUnlocked(details, 10602)) result.support_disc_capacity = 2;

        result.restrict_notes_to_matching_element = difficulty >= 8 and isUnlocked(details, 40101);
        result.strengthen_bonus_applies_to_all = difficulty >= 8 and isUnlocked(details, 40301);
        result.defer_new_potential_bonus_consumption = difficulty >= 8 and isUnlocked(details, 40401);

        return result;
    }
};

pub fn canUnlock(details: []const u32, id: u32, player_level: u32) bool {
    const node = tables.tower_growth.get(id) orelse
        return false;
    if (isUnlocked(details, id))
        return false;
    if (!isGroupAvailable(details, node.group, player_level))
        return false;

    for (node.prerequisites[0..node.prerequisite_count]) |prerequisite|
        if (!isUnlocked(details, prerequisite)) return false;

    return true;
}

fn isGroupAvailable(details: []const u32, group_id: u32, player_level: u32) bool {
    const group = tables.tower_growth.getGroup(group_id) orelse
        return false;
    if (player_level < group.minimum_level) return false;

    for (tables.tower_growth.list) |node| {
        if (node.group == group.prerequisite_group and !isUnlocked(details, node.id))
            return false;
    }

    return true;
}

pub fn unlock(player: *Player, id: u32) error{ InvalidNode, LockedNode, InsufficientItems }!tables.tower_growth.Node {
    const node = tables.tower_growth.get(id) orelse
        return error.InvalidNode;
    if (!canUnlock(&player.tower_growth.details, id, @intFromEnum(player.basic.level)))
        return error.LockedNode;

    try player.consumeItem(node.cost_item_id, node.cost_item_quantity);
    setUnlocked(&player.tower_growth.details, id);

    return node;
}
