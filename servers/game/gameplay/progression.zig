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
