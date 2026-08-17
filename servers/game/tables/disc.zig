const std = @import("std");

const character = @import("character.zig");
const lookup = @import("lookup.zig");
const raw_list = @import("tables/Disc");

//

const by_id = lookup.Lookup(u32, lookup.fieldKeys(u32, raw_list, "id"));

const transform_item_ids: [raw_list.len]u32 = blk: {
    @setEvalBranchQuota(100 * raw_list.len + 1000);

    var result: [raw_list.len]u32 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = entry.transform_item_id;

    break :blk result;
};

const elements: [raw_list.len]u8 = blk: {
    var result: [raw_list.len]u8 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = entry.eet;

    break :blk result;
};

pub fn contains(id: u32) bool {
    return by_id.contains(id);
}

pub fn transformItemId(id: u32) ?u32 {
    const row = by_id.find(id) orelse return null;
    return transform_item_ids[row];
}

pub fn element(id: u32) ?character.Element {
    const row = by_id.find(id) orelse return null;
    return std.enums.fromInt(character.Element, elements[row]);
}
