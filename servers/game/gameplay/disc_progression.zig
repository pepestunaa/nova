const std = @import("std");

const Player = @import("../store/Player.zig");
const progression = @import("progression.zig");
const tables = @import("../tables.zig");

//

pub const max_item_changes = progression.max_item_changes;

pub const Error = error{
    InvalidDisc,
    InvalidItems,
    LevelCapReached,
    LevelNotReached,
    MaximumPhaseReached,
    MaximumStarReached,
    PlayerLevelNotMet,
    InsufficientResources,
};

pub const ItemAmount = progression.ItemAmount;
pub const Receipt = progression.Receipt;

pub fn strengthen(
    player: *Player,
    disc_id: u32,
    items: []const ItemAmount,
    receipt: *Receipt,
) Error!void {
    receipt.* = .{};
    if (items.len == 0 or items.len > receipt.items.len)
        return error.InvalidItems;

    const definition = tables.disc.definition(disc_id) orelse
        return error.InvalidDisc;
    const disc = ownedDisc(player, disc_id) orelse
        return error.InvalidDisc;
    const cap = tables.disc_progression.phaseCap(definition.rarity, @intFromEnum(disc.phase)) orelse
        return error.InvalidDisc;
    if (@intFromEnum(disc.level) >= cap.level)
        return error.LevelCapReached;

    var total_exp: u64 = 0;
    for (items) |item| {
        if (item.quantity <= 0 or player.itemQuantity(item.id) < item.quantity)
            return error.InsufficientResources;
        const item_exp = tables.disc_progression.expItem(item.id) orelse
            return error.InvalidItems;
        total_exp = std.math.add(
            u64,
            total_exp,
            std.math.mul(u64, item_exp, @as(u64, @intCast(item.quantity))) catch
                return error.InvalidItems,
        ) catch
            return error.InvalidItems;
    }

    var level: u16 = @intFromEnum(disc.level);
    var exp: u32 = @intFromEnum(disc.exp);
    var remaining_exp = total_exp;
    while (level < cap.level and remaining_exp != 0) {
        const needed = tables.disc_progression.strengthenCost(definition.strengthen_group, level + 1) orelse
            return error.InvalidDisc;
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

    const gained_exp = total_exp - remaining_exp;
    const gold_factor = tables.disc_progression.strengthenGoldPer1000Exp(definition.rarity) orelse
        return error.InvalidDisc;
    const gold = std.math.cast(i32, std.math.divCeil(
        u64,
        gained_exp * gold_factor,
        1000,
    ) catch unreachable) orelse return error.InvalidItems;
    if (player.resourceQuantity(tables.disc_progression.gold_id) < gold)
        return error.InsufficientResources;

    for (items, 0..) |item, index| {
        player.consumeItem(item.id, item.quantity) catch unreachable;
        receipt.items[index] = .{ .id = item.id, .quantity = -item.quantity };
    }
    receipt.item_count = @intCast(items.len);
    player.consumeResource(tables.disc_progression.gold_id, gold) catch unreachable;
    receipt.gold = -gold;
    disc.level = @enumFromInt(level);
    disc.exp = @enumFromInt(exp);
}

pub fn promote(player: *Player, disc_id: u32, receipt: *Receipt) Error!void {
    receipt.* = .{};
    const definition = tables.disc.definition(disc_id) orelse
        return error.InvalidDisc;
    const disc = ownedDisc(player, disc_id) orelse
        return error.InvalidDisc;
    const current_phase: u8 = @intFromEnum(disc.phase);
    const current_cap = tables.disc_progression.phaseCap(definition.rarity, current_phase) orelse
        return error.InvalidDisc;
    if (@intFromEnum(disc.level) < current_cap.level)
        return error.LevelNotReached;

    const target_phase = std.math.add(u8, current_phase, 1) catch
        return error.MaximumPhaseReached;
    const target_cap = tables.disc_progression.phaseCap(definition.rarity, target_phase) orelse
        return error.MaximumPhaseReached;
    if (@intFromEnum(player.basic.level) < target_cap.player_level)
        return error.PlayerLevelNotMet;
    const cost = tables.disc_progression.promotion(definition.promote_group, target_phase) orelse
        return error.MaximumPhaseReached;
    try validateCosts(player, cost.costs[0..cost.cost_count], cost.gold);

    applyCosts(player, cost.costs[0..cost.cost_count], cost.gold, receipt);
    disc.phase = @enumFromInt(target_phase);
}

pub fn limitBreak(player: *Player, disc_id: u32, quantity: u32, receipt: *Receipt) Error!void {
    receipt.* = .{};
    const definition = tables.disc.definition(disc_id) orelse
        return error.InvalidDisc;
    const disc = ownedDisc(player, disc_id) orelse
        return error.InvalidDisc;
    const current_star: u8 = @intFromEnum(disc.star);
    const target_star = std.math.add(u32, current_star, quantity) catch
        return error.MaximumStarReached;
    if (quantity == 0 or target_star > tables.disc_progression.max_star)
        return error.MaximumStarReached;
    const cost = std.math.cast(i32, quantity) orelse
        return error.MaximumStarReached;
    if (player.itemQuantity(definition.transform_item_id) < cost)
        return error.InsufficientResources;

    player.consumeItem(definition.transform_item_id, cost) catch unreachable;
    receipt.items[0] = .{ .id = definition.transform_item_id, .quantity = -cost };
    receipt.item_count = 1;
    disc.star = @enumFromInt(target_star);
}

fn ownedDisc(player: *Player, id: u32) ?*Player.Disc {
    for (player.discs.entries[0..player.discs.len]) |*disc| {
        if (disc.id == id)
            return disc;
    }

    return null;
}

fn validateCosts(player: *const Player, costs: []const tables.disc_progression.Cost, gold: i32) Error!void {
    if (gold < 0 or player.resourceQuantity(tables.disc_progression.gold_id) < gold)
        return error.InsufficientResources;
    for (costs) |cost| {
        if (cost.quantity < 0 or player.itemQuantity(cost.item_id) < cost.quantity)
            return error.InsufficientResources;
    }
}

fn applyCosts(
    player: *Player,
    costs: []const tables.disc_progression.Cost,
    gold: i32,
    receipt: *Receipt,
) void {
    for (costs, 0..) |cost, index| {
        player.consumeItem(cost.item_id, cost.quantity) catch unreachable;
        receipt.items[index] = .{ .id = cost.item_id, .quantity = -cost.quantity };
    }
    receipt.item_count = @intCast(costs.len);
    player.consumeResource(tables.disc_progression.gold_id, gold) catch unreachable;
    receipt.gold = -gold;
}
