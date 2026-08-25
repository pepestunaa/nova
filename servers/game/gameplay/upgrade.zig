const std = @import("std");

const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

//

pub const gold_id = 1;

pub const max_item_changes = @max(
    tables.character_progression.max_item_changes,
    tables.disc_progression.exp_item_count,
    tables.disc_progression.max_costs,
);

pub const ItemAmount = struct {
    id: u32,
    quantity: i32,
};

pub const Receipt = struct {
    items: [max_item_changes]ItemAmount = undefined,
    item_count: u8 = 0,
    gold: i32 = 0,
};

pub fn validateItemQuantities(
    player: *const Player,
    items: []const ItemAmount,
) error{ InvalidItems, InsufficientResources }!void {
    for (items, 0..) |item, index| {
        var first = true;
        for (items[0..index]) |previous| {
            if (previous.id == item.id) {
                first = false;
                break;
            }
        }
        if (!first)
            continue;

        var required: i32 = 0;
        for (items[index..]) |candidate| {
            if (candidate.id != item.id)
                continue;
            required = std.math.add(i32, required, candidate.quantity) catch
                return error.InvalidItems;
        }
        if (player.itemQuantity(item.id) < required)
            return error.InsufficientResources;
    }
}
