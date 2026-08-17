const lookup = @import("lookup.zig");

const raw_groups = @import("tables/StarTowerGrowthGroup");
const raw_nodes = @import("tables/StarTowerGrowthNode");

//

const max_prerequisites = blk: {
    var result: usize = 0;
    for (raw_nodes) |node| {
        if (@hasField(@TypeOf(node), "pre_nodes"))
            result = @max(result, @typeInfo(@TypeOf(node.pre_nodes)).@"struct".fields.len);
    }

    break :blk result;
};

/// `TowerGrowthDetailResp.Detail` is indexed by research group ID, and each
/// word uses that group's `NodeId` as its bit index.
pub const detail_words = blk: {
    var result: usize = 0;
    for (raw_groups) |group| result = @max(result, group.id);

    break :blk result;
};
pub const max_world_class = blk: {
    var result: u8 = 0;
    for (raw_groups) |group|
        result = @max(result, @as(u8, @intCast(group.world_class)));

    break :blk result;
};

pub const Group = struct {
    id: u32,
    minimum_level: u32,
    prerequisite_group: u32,
};

pub const Node = struct {
    id: u32,
    group: u32,
    node_id: u32,
    priority: u32,
    cost_item_id: u32,
    cost_item_quantity: i32,
    prerequisites: [max_prerequisites]u32,
    prerequisite_count: u8,
};

pub const groups = blk: {
    var result: [raw_groups.len]Group = undefined;
    for (raw_groups, 0..) |raw, index| result[index] = .{
        .id = raw.id,
        .minimum_level = raw.world_class,
        .prerequisite_group = if (@hasField(@TypeOf(raw), "pre_group")) raw.pre_group else 0,
    };

    break :blk result;
};

pub const list = blk: {
    var result: [raw_nodes.len]Node = undefined;
    for (raw_nodes, 0..) |raw, index| {
        var prerequisites: [max_prerequisites]u32 = @splat(0);
        const prerequisite_count = if (@hasField(@TypeOf(raw), "pre_nodes")) count: {
            for (
                @typeInfo(@TypeOf(raw.pre_nodes)).@"struct".fields,
                0..,
            ) |field, prerequisite_index|
                prerequisites[prerequisite_index] = @field(raw.pre_nodes, field.name);

            break :count @typeInfo(@TypeOf(raw.pre_nodes)).@"struct".fields.len;
        } else 0;
        result[index] = .{
            .id = raw.id,
            .group = raw.group,
            .node_id = raw.node_id,
            .priority = raw.priority,
            .cost_item_id = raw.item_id1,
            .cost_item_quantity = @intCast(raw.item_qty1),
            .prerequisites = prerequisites,
            .prerequisite_count = prerequisite_count,
        };
    }

    break :blk result;
};

const by_node_id = lookup.Lookup(u32, lookup.fieldKeys(u32, &list, "id"));
const by_group_id = lookup.Lookup(u32, lookup.fieldKeys(u32, &groups, "id"));

pub fn get(id: u32) ?Node {
    const row = by_node_id.find(id) orelse return null;
    return list[row];
}

pub fn getGroup(id: u32) ?Group {
    const row = by_group_id.find(id) orelse return null;
    return groups[row];
}
