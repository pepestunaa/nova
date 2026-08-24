const std = @import("std");
const Allocator = std.mem.Allocator;

const Player = @import("../store/Player.zig");
const TalentIndex = Player.Character.TalentNodes.Index;

const tables = @import("../tables.zig");

//

// `CharacterAdvance` currently provides advancement requirements and costs
// only, the table has no reward fields (at least yet).

pub const max_item_changes = tables.character_progression.max_item_changes;
pub const max_talent_changes = tables.character_progression.max_talent_changes;

pub const Error = error{
    InvalidCharacter,
    InvalidItems,
    InvalidTalent,
    LevelCapReached,
    MaximumReached,
    ConditionsNotMet,
    PlayerLevelNotMet,
    InsufficientResources,
    TalentAlreadyUnlocked,
    TalentGroupLocked,
    TalentGroupComplete,
} || Allocator.Error;

pub const ItemAmount = struct {
    id: u32,
    quantity: i32,
};

pub const Receipt = struct {
    items: [max_item_changes]ItemAmount = undefined,
    item_count: u8 = 0,
    gold: i32 = 0,
    unlocked_advance_skin: bool = false,
};

pub const TalentReceipt = struct {
    cost: ItemAmount = .{ .id = 0, .quantity = 0 },
    nodes: [max_talent_changes]u32 = undefined,
    node_count: u8 = 0,
    key_talent_id: u32 = 0,

    pub fn slice(receipt: *TalentReceipt) []u32 {
        return receipt.nodes[0..receipt.node_count];
    }
};

pub fn upgrade(
    player: *Player,
    character_id: u32,
    items: []const ItemAmount,
    receipt: *Receipt,
) Error!void {
    receipt.* = .{};
    if (items.len == 0 or items.len > max_item_changes)
        return error.InvalidItems;

    const character = player.characters.getMut(character_id) orelse
        return error.InvalidCharacter;
    const cap = tables.character_progression.levelCap(@intCast(character.advance())) orelse
        return error.InvalidCharacter;
    if (character.level() >= cap)
        return error.LevelCapReached;

    var total_exp: u64 = 0;
    for (items) |item| {
        if (item.quantity <= 0 or player.itemQuantity(item.id) < item.quantity)
            return error.InsufficientResources;
        const item_exp = tables.character_progression.expItem(item.id) orelse
            return error.InvalidItems;
        total_exp = std.math.add(
            u64,
            total_exp,
            std.math.mul(u64, item_exp, @intCast(item.quantity)) catch
                return error.InvalidItems,
        ) catch
            return error.InvalidItems;
    }

    var level: u8 = @intCast(character.level());
    var exp: u32 = character.exp();
    var remaining_exp = total_exp;
    while (level < cap and remaining_exp != 0) {
        const needed = tables.character_progression.levelCost(level + 1) orelse
            return error.InvalidCharacter;
        const missing = needed - exp;
        if (remaining_exp < missing) {
            exp += @intCast(remaining_exp);
            remaining_exp = 0;
        } else {
            remaining_exp -= missing;
            level += 1;
            exp = 0;
        }
    }

    const used_exp = total_exp - remaining_exp;
    const gold_u64 = std.math.divCeil(
        u64,
        used_exp * tables.character_progression.level_gold_per_1000_exp,
        1000,
    ) catch unreachable;
    const gold = std.math.cast(i32, gold_u64) orelse
        return error.InvalidItems;
    if (player.resourceQuantity(tables.character_progression.gold_id) < gold)
        return error.InsufficientResources;

    for (items, 0..) |item, index| {
        player.consumeItem(item.id, item.quantity) catch unreachable;
        receipt.items[index] = .{ .id = item.id, .quantity = -item.quantity };
    }
    receipt.item_count = @intCast(items.len);
    player.consumeResource(tables.character_progression.gold_id, gold) catch unreachable;
    receipt.gold = -gold;
    character.bits.level = @enumFromInt(level);
    character.bits.exp = @enumFromInt(exp);
}

pub fn advance(
    player: *Player,
    allocator: Allocator,
    character_id: u32,
    receipt: *Receipt,
) Error!void {
    receipt.* = .{};
    const definition = tables.character_progression.character(character_id) orelse
        return error.InvalidCharacter;
    const character = player.characters.getMut(character_id) orelse
        return error.InvalidCharacter;
    const current_advance: u8 = @intCast(character.advance());
    const current_cap = tables.character_progression.levelCap(current_advance) orelse
        return error.InvalidCharacter;
    if (character.level() < current_cap)
        return error.ConditionsNotMet;

    const target_advance = std.math.add(u8, current_advance, 1) catch
        return error.MaximumReached;
    const required_player_level = tables.character_progression.advanceRequiredPlayerLevel(target_advance) orelse
        return error.MaximumReached;
    if (@intFromEnum(player.basic.level) < required_player_level)
        return error.PlayerLevelNotMet;
    const cost = tables.character_progression.advance(definition.advance_materials, target_advance) orelse
        return error.MaximumReached;
    try validateCosts(player, cost.costs[0..cost.cost_count], cost.gold);

    if (target_advance >= definition.advance_skin_unlock_level)
        receipt.unlocked_advance_skin = try player.unlockAdvanceSkin(allocator, character_id);

    applyCosts(player, cost.costs[0..cost.cost_count], cost.gold, receipt);
    character.bits.advance = @enumFromInt(target_advance);
}

pub fn upgradeSkill(
    player: *Player,
    character_id: u32,
    skill: Player.Character.Skill,
    receipt: *Receipt,
) Error!void {
    receipt.* = .{};
    const definition = tables.character_progression.character(character_id) orelse
        return error.InvalidCharacter;
    const character = player.characters.getMut(character_id) orelse
        return error.InvalidCharacter;
    const current_level = character.skillLevel(skill);
    const target_level = std.math.add(u8, current_level, 1) catch
        return error.MaximumReached;
    const cost = tables.character_progression.skillUpgrade(definition.skill_materials, target_level) orelse
        return error.MaximumReached;
    if (character.advance() < cost.required_advance)
        return error.ConditionsNotMet;
    try validateCosts(player, cost.costs[0..cost.cost_count], cost.gold);

    applyCosts(player, cost.costs[0..cost.cost_count], cost.gold, receipt);
    character.setSkillLevel(skill, target_level);
}

pub fn unlockTalentGroup(player: *Player, group_id: u32, receipt: *TalentReceipt) Error!void {
    receipt.* = .{};
    const group = tables.character_progression.talentGroup(group_id) orelse
        return error.InvalidTalent;
    const definition = tables.character_progression.character(group.character_id) orelse
        return error.InvalidCharacter;
    const character = player.characters.getMut(group.character_id) orelse
        return error.InvalidCharacter;
    try validateTalentGroup(character, &group);

    const group_talents = tables.character_progression.talents(&group);
    var unlocked_count: u8 = 0;
    for (group_talents) |talent| {
        if (talent.kind == 2 and character.hasTalent(TalentIndex.fromInt(talent.index)))
            unlocked_count += 1;
    }
    if (unlocked_count >= group.node_limit) {
        if (activateCore(character, &group, receipt))
            return;
        return error.TalentGroupComplete;
    }

    const fragments_per_node = tables.character_progression.fragmentsPerTalentNode(definition.grade) orelse
        return error.InvalidCharacter;
    const available = player.itemQuantity(definition.fragments_id);
    if (available < fragments_per_node)
        return error.InsufficientResources;
    const unlock_count: u8 = @intCast(@min(
        @divFloor(available, fragments_per_node),
        group.node_limit - unlocked_count,
    ));
    if (unlock_count == 0)
        return error.InsufficientResources;

    for (group_talents) |talent| {
        if (receipt.node_count == unlock_count or talent.kind != 2 or character.hasTalent(TalentIndex.fromInt(talent.index)))
            continue;
        if (!character.setTalent(TalentIndex.fromInt(talent.index))) unreachable;
        receipt.nodes[receipt.node_count] = talent.id;
        receipt.node_count += 1;
    }
    const consumed = fragments_per_node * unlock_count;
    player.consumeItem(definition.fragments_id, consumed) catch unreachable;
    receipt.cost = .{ .id = definition.fragments_id, .quantity = -consumed };
    _ = activateCore(character, &group, receipt);
    character.talent_background = group.background;
}

pub fn unlockTalent(player: *Player, talent_id: u32, receipt: *TalentReceipt) Error!void {
    receipt.* = .{};
    const talent = tables.character_progression.talent(talent_id) orelse
        return error.InvalidTalent;
    if (talent.kind != 2)
        return error.InvalidTalent;
    const group = tables.character_progression.talentGroup(talent.group_id) orelse
        return error.InvalidTalent;
    const definition = tables.character_progression.character(group.character_id) orelse
        return error.InvalidCharacter;
    const character = player.characters.getMut(group.character_id) orelse
        return error.InvalidCharacter;
    try validateTalentGroup(character, &group);
    if (character.hasTalent(TalentIndex.fromInt(talent.index)))
        return error.TalentAlreadyUnlocked;

    var unlocked_count: u8 = 0;
    for (tables.character_progression.talents(&group)) |entry| {
        if (entry.kind == 2 and character.hasTalent(TalentIndex.fromInt(entry.index)))
            unlocked_count += 1;
    }
    if (unlocked_count >= group.node_limit)
        return error.TalentGroupComplete;

    const fragments = tables.character_progression.fragmentsPerTalentNode(definition.grade) orelse
        return error.InvalidCharacter;
    if (player.itemQuantity(definition.fragments_id) < fragments)
        return error.InsufficientResources;

    player.consumeItem(definition.fragments_id, fragments) catch unreachable;
    if (!character.setTalent(TalentIndex.fromInt(talent.index))) unreachable;
    receipt.cost = .{ .id = definition.fragments_id, .quantity = -fragments };
    receipt.nodes[0] = talent.id;
    receipt.node_count = 1;
    _ = activateCore(character, &group, receipt);
}

pub fn setSkin(player: *Player, character_id: u32, skin_id: u32) Error!void {
    const definition = tables.character_progression.character(character_id) orelse
        return error.InvalidCharacter;
    const character = player.characters.getMut(character_id) orelse
        return error.InvalidCharacter;
    if (skin_id != definition.default_skin_id and
        (skin_id != definition.advance_skin_id or
            character.advance() < definition.advance_skin_unlock_level))
        return error.ConditionsNotMet;
    character.skin = skin_id;
}

pub fn setTalentBackground(player: *Player, character_id: u32, group_id: u32) Error!void {
    if (group_id == 0) {
        const character = player.characters.getMut(character_id) orelse
            return error.InvalidCharacter;
        character.talent_background = 0;
        return;
    }

    const group = tables.character_progression.talentGroup(group_id) orelse
        return error.InvalidTalent;
    const character = player.characters.getMut(group.character_id) orelse
        return error.InvalidCharacter;
    const key = tables.character_progression.talent(group.key_talent_id) orelse
        return error.InvalidTalent;
    if (!character.hasTalent(TalentIndex.fromInt(key.index)))
        return error.TalentGroupLocked;
    character.talent_background = group.background;
}

fn validateCosts(player: *const Player, costs: []const tables.character_progression.Cost, gold: i32) Error!void {
    if (gold < 0 or player.resourceQuantity(tables.character_progression.gold_id) < gold)
        return error.InsufficientResources;
    for (costs) |cost| {
        if (cost.quantity < 0 or player.itemQuantity(cost.item_id) < cost.quantity)
            return error.InsufficientResources;
    }
}

fn applyCosts(
    player: *Player,
    costs: []const tables.character_progression.Cost,
    gold: i32,
    receipt: *Receipt,
) void {
    for (costs, 0..) |cost, index| {
        player.consumeItem(cost.item_id, cost.quantity) catch unreachable;
        receipt.items[index] = .{ .id = cost.item_id, .quantity = -cost.quantity };
    }
    receipt.item_count = @intCast(costs.len);
    player.consumeResource(tables.character_progression.gold_id, gold) catch unreachable;
    receipt.gold = -gold;
}

fn validateTalentGroup(character: *const Player.Character, group: *const tables.character_progression.TalentGroup) Error!void {
    if (group.previous_group == 0)
        return;
    const previous = tables.character_progression.talentGroup(group.previous_group) orelse
        return error.InvalidTalent;
    const key = tables.character_progression.talent(previous.key_talent_id) orelse
        return error.InvalidTalent;
    if (!character.hasTalent(TalentIndex.fromInt(key.index)))
        return error.TalentGroupLocked;
}

fn activateCore(
    character: *Player.Character,
    group: *const tables.character_progression.TalentGroup,
    receipt: *TalentReceipt,
) bool {
    var ordinary_count: u8 = 0;
    for (tables.character_progression.talents(group)) |talent| {
        if (talent.kind == 2 and character.hasTalent(TalentIndex.fromInt(talent.index)))
            ordinary_count += 1;
    }
    if (ordinary_count < group.node_limit)
        return false;

    const key = tables.character_progression.talent(group.key_talent_id) orelse unreachable;
    if (!character.setTalent(TalentIndex.fromInt(key.index)))
        return false;
    receipt.nodes[receipt.node_count] = key.id;
    receipt.node_count += 1;
    receipt.key_talent_id = key.id;
    character.talent_background = group.background;

    return true;
}
