const std = @import("std");

const generated = @import("generated/assets/character_progression");

const affinities = @import("tables/AffinityLevel");
const lookup = @import("lookup.zig");

//

pub const Cost = struct {
    item_id: u32,
    quantity: i32,
};

pub const Advance = struct {
    gold: i32,
    costs: [generated.max_costs]Cost,
    cost_count: u8,
};

pub const SkillUpgrade = struct {
    required_advance: u8,
    gold: i32,
    costs: [generated.max_costs]Cost,
    cost_count: u8,
};

pub const Character = struct {
    id: u32,
    grade: u8,
    advance_materials: u8,
    skill_materials: u8,
    fragments_id: u32,
    default_skin_id: u32,
    advance_skin_id: u32,
    advance_skin_unlock_level: u8,
};

pub const Talent = struct {
    id: u32,
    index: u8,
    group_id: u32,
    kind: u8,
    sort: u8,
};

pub const TalentGroup = struct {
    id: u32,
    character_id: u32,
    previous_group: u32,
    node_limit: u8,
    background: u8,
    key_talent_id: u32,
};

pub const gold_id = 1;
pub const level_gold_per_1000_exp = @import("config.zig").unsignedList(
    u32,
    "CharUpgradeGoldPerExp",
)[0];

pub const max_level = generated.max_level;
pub const max_exp = generated.max_exp;
pub const max_advance = generated.max_advance;
pub const max_skill_upgrade_rank = generated.max_skill_upgrade_rank;
pub const max_skill_level = generated.max_skill_level;
pub const max_affinity_level = maximumOptional(affinities, "affinity_level");
pub const max_affinity_exp = maximumOptional(affinities, "need_exp");
pub const max_item_changes = @max(generated.max_costs, generated.exp_item_count);
pub const max_talent_changes = generated.max_talents_per_group;
pub const talent_group_count = generated.talent_group_count;
pub const max_talent_index = generated.max_talent_index;

comptime {
    std.debug.assert(talent_group_count == 5);
    std.debug.assert(max_talent_index <= talent_group_count * 16);
}

const by_character = lookup.Lookup(u32, lookup.fieldKeys(u32, &generated.characters, "id"));
const by_exp_item = lookup.Lookup(u32, lookup.fieldKeys(u32, &generated.exp_items, "item_id"));
const by_grade = lookup.Lookup(u8, lookup.fieldKeys(u8, &generated.grades, "id"));

pub fn character(id: u32) ?Character {
    const row = by_character.find(id) orelse
        return null;

    return .{
        .id = generated.characters[row].id,
        .grade = generated.characters[row].grade,
        .advance_materials = generated.characters[row].advance_materials,
        .skill_materials = generated.characters[row].skill_materials,
        .fragments_id = id * 10,
        .default_skin_id = id * 100 + 1,
        .advance_skin_id = id * 100 + 2,
        .advance_skin_unlock_level = 3,
    };
}

pub fn levelCost(target_level: u8) ?u32 {
    if (target_level < 2 or target_level > max_level)
        return null;
    return generated.level_costs[target_level - 2].exp;
}

pub fn levelCap(advance_level: u8) ?u8 {
    if (advance_level >= generated.level_caps.len)
        return null;
    return generated.level_caps[advance_level].level;
}

pub fn advanceRequiredPlayerLevel(advance_level: u8) ?u8 {
    if (advance_level >= generated.level_caps.len)
        return null;
    return generated.level_caps[advance_level].player_level;
}

pub fn expItem(item_id: u32) ?u32 {
    const row = by_exp_item.find(item_id) orelse return null;
    return generated.exp_items[row].exp;
}

pub fn advance(material_set: u8, target_level: u8) ?Advance {
    if (material_set >= generated.advance_shape.len)
        return null;
    if (target_level == 0 or target_level > generated.advance_shape[material_set].len)
        return null;
    const step = generated.advance_shape[material_set][target_level - 1];
    var costs: [generated.max_costs]Cost = undefined;
    resolveCosts(step.costs, &generated.advance_materials[material_set], &costs);

    return .{
        .gold = step.gold,
        .costs = costs,
        .cost_count = step.costs.count,
    };
}

pub fn skillUpgrade(material_set: u8, target_level: u8) ?SkillUpgrade {
    if (material_set >= generated.skill_shape.len)
        return null;
    if (target_level == 0 or target_level > generated.skill_shape[material_set].len)
        return null;
    const step = generated.skill_shape[material_set][target_level - 1];
    var costs: [generated.max_costs]Cost = undefined;
    resolveCosts(step.costs, &generated.skill_materials[material_set], &costs);

    return .{
        .required_advance = step.required_advance,
        .gold = step.gold,
        .costs = costs,
        .cost_count = step.costs.count,
    };
}

pub fn fragmentsPerTalentNode(grade: u8) ?i32 {
    const row = by_grade.find(grade) orelse return null;
    return generated.grades[row].fragments_per_node;
}

pub fn talent(id: u32) ?Talent {
    const group = talentGroup(id / 100) orelse
        return null;
    const index: u8 = @intCast(id % 100);
    const group_number: u8 = @intCast(group.id % 100);
    const base = (group_number - 1) * 16;
    if (index >= base + 1 and index <= base + 10)
        return .{ .id = id, .index = index, .group_id = group.id, .kind = 2, .sort = index - base };
    if (index == base + 16)
        return .{ .id = id, .index = index, .group_id = group.id, .kind = 1, .sort = 1 };

    return null;
}

pub fn talentGroup(id: u32) ?TalentGroup {
    const character_id = id / 100;
    const group_number: u8 = @intCast(id % 100);
    if (group_number == 0 or group_number > talent_group_count or character(character_id) == null)
        return null;
    const previous_group = if (group_number == 1) 0 else id - 1;
    const base = (group_number - 1) * 16;

    return .{
        .id = id,
        .character_id = character_id,
        .previous_group = previous_group,
        .node_limit = 10,
        .background = group_number,
        .key_talent_id = id * 100 + base + 16,
    };
}

pub fn talents(group: *const TalentGroup) [generated.max_talents_per_group]Talent {
    var result: [generated.max_talents_per_group]Talent = undefined;
    const group_number: u8 = @intCast(group.id % 100);
    const base = (group_number - 1) * 16;
    for (1..11) |sort| {
        const index: u8 = base + @as(u8, @intCast(sort));
        result[sort - 1] = .{
            .id = group.id * 100 + index,
            .index = index,
            .group_id = group.id,
            .kind = 2,
            .sort = @intCast(sort),
        };
    }
    result[10] = .{
        .id = group.key_talent_id,
        .index = base + 16,
        .group_id = group.id,
        .kind = 1,
        .sort = 1,
    };

    return result;
}

pub const material_ids = blk: {
    @setEvalBranchQuota(1_000_000);

    const capacity = generated.exp_items.len +
        generated.advance_materials.len * generated.advance_materials[0].len +
        generated.skill_materials.len * generated.skill_materials[0].len;
    var result: [capacity]u32 = undefined;
    var count: usize = 0;

    for (generated.exp_items) |entry|
        appendUnique(&result, &count, entry.item_id);
    for (generated.advance_materials) |materials| for (materials) |item_id|
        appendUnique(&result, &count, item_id);
    for (generated.skill_materials) |materials| for (materials) |item_id|
        appendUnique(&result, &count, item_id);

    const final = result[0..count].*;

    break :blk final;
};

fn resolveCosts(template: generated.Costs, materials: []const u32, result: *[generated.max_costs]Cost) void {
    for (template.entries[0..template.count], 0..) |cost, index| result[index] = .{
        .item_id = materials[cost.material],
        .quantity = cost.quantity,
    };
}

fn appendUnique(result: []u32, count: *usize, id: u32) void {
    if (id == 0)
        return;
    for (result[0..count.*]) |existing| if (existing == id)
        return;
    result[count.*] = id;
    count.* += 1;
}

fn maximumOptional(comptime rows: anytype, comptime field: []const u8) u32 {
    var result: u32 = 0;

    inline for (rows) |row| {
        if (@hasField(@TypeOf(row), field))
            result = @max(result, @field(row, field));
    }

    return result;
}

test "advance reaches every step of a material set" {
    try std.testing.expect(advance(2, 5) != null);
    try std.testing.expect(advance(2, 9) != null);
    try std.testing.expect(advance(2, 10) == null);
    try std.testing.expect(advance(generated.advance_shape.len, 1) == null);
}

test "skill upgrade rejects a target past the last step" {
    try std.testing.expect(skillUpgrade(28, 10) != null);
    try std.testing.expect(skillUpgrade(28, 11) == null);
    try std.testing.expect(skillUpgrade(generated.skill_shape.len, 1) == null);
}
