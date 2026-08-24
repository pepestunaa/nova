const generated = @import("generated/assets/disc_progression");

const lookup = @import("lookup.zig");

//

pub const Cost = struct {
    item_id: u32,
    quantity: i32,
};

pub const Promotion = struct {
    gold: i32,
    costs: [generated.max_costs]Cost,
    cost_count: u8,
};

pub const gold_id = 1;
pub const max_costs = generated.max_costs;
pub const max_level = generated.max_level;
pub const max_phase = generated.max_phase;
pub const max_exp = generated.max_exp;
pub const max_star = generated.max_star;
pub const exp_item_count = generated.exp_items.len;

const by_exp_item = lookup.Lookup(u32, lookup.fieldKeys(u32, &generated.exp_items, "item_id"));
const by_strengthen_group = lookup.Lookup(u32, lookup.fieldKeys(u32, &generated.strengthen_curves, "group"));
const by_promotion_group = lookup.Lookup(u32, lookup.fieldKeys(u32, &generated.promote_groups, "group"));

pub fn expItem(item_id: u32) ?u32 {
    const index = by_exp_item.find(item_id) orelse return null;
    return generated.exp_items[index].exp;
}

pub fn strengthenCost(group: u32, target_level: u16) ?u32 {
    if (target_level < 2 or target_level > max_level)
        return null;

    const index = by_strengthen_group.find(group) orelse
        return null;

    return generated.strengthen_curves[index].costs[target_level - 2];
}

pub fn phaseCap(rarity: u8, phase: u8) ?generated.PhaseCap {
    for (generated.phase_caps) |cap| {
        if (cap.rarity == rarity and cap.phase == phase)
            return cap;
    }

    return null;
}

pub fn promotion(group: u32, target_phase: u8) ?Promotion {
    if (target_phase == 0 or target_phase > max_phase)
        return null;

    const group_index = by_promotion_group.find(group) orelse return null;
    const mapping = generated.promote_groups[group_index];
    const step = generated.promote_shapes[mapping.shape][target_phase - 1];
    const materials = generated.promote_material_sets[mapping.materials];
    var costs: [generated.max_costs]Cost = undefined;
    for (step.costs.entries[0..step.costs.count], 0..) |cost, index| costs[index] = .{
        .item_id = materials[cost.material],
        .quantity = cost.quantity,
    };

    return .{
        .gold = step.gold,
        .costs = costs,
        .cost_count = step.costs.count,
    };
}

pub fn strengthenGoldPer1000Exp(rarity: u8) ?u32 {
    if (rarity == 0) return null;
    return generated.strengthen_gold_per_1000_exp;
}

pub const material_ids = blk: {
    const capacity = generated.exp_items.len +
        generated.promote_material_sets.len * generated.max_costs;
    var result: [capacity]u32 = undefined;
    var count: usize = 0;

    for (generated.exp_items) |item|
        appendUnique(&result, &count, item.item_id);
    for (generated.promote_material_sets) |set| for (set) |item_id|
        appendUnique(&result, &count, item_id);

    break :blk result[0..count].*;
};

fn appendUnique(items: []u32, count: *usize, id: u32) void {
    if (id == 0)
        return;

    for (items[0..count.*]) |existing| if (existing == id)
        return;

    items[count.*] = id;
    count.* += 1;
}
