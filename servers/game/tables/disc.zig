const std = @import("std");

const character = @import("character.zig");
const lookup = @import("lookup.zig");
const raw_list = @import("tables/Disc");
const raw_items = @import("tables/Item");

const count: usize = raw_list.len;

//

const by_id = lookup.Lookup(u32, lookup.fieldKeys(u32, raw_list, "id"));

pub const Definition = struct {
    strengthen_group: u32,
    promote_group: u32,
    transform_item_id: u32,
    rarity: u8,
};

const transform_item_ids: [count]u32 = blk: {
    @setEvalBranchQuota(100 * count + 1000);

    var result: [count]u32 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = entry.transform_item_id;

    break :blk result;
};

const strengthen_groups: [count]u32 = blk: {
    var result: [count]u32 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = entry.strengthen_group_id;
    break :blk result;
};

const promote_groups: [count]u32 = blk: {
    var result: [count]u32 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = entry.promote_group_id;
    break :blk result;
};

const rarities: [count]u8 = blk: {
    @setEvalBranchQuota(1_000_000);

    var result: [count]u8 = undefined;
    for (raw_list, 0..) |disc, disc_index| {
        for (raw_items) |item| {
            if (item.id != disc.id)
                continue;

            result[disc_index] = item.rarity;

            break;
        } else @compileError(std.fmt.comptimePrint("missing Item entry for Disc {d}", .{disc.id}));
    }

    break :blk result;
};

const elements: [count]u8 = blk: {
    var result: [count]u8 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = entry.eet;

    break :blk result;
};

pub fn contains(id: u32) bool {
    return by_id.contains(id);
}

pub fn transformItemId(id: u32) ?u32 {
    return (definition(id) orelse return null).transform_item_id;
}

pub fn definition(id: u32) ?Definition {
    const row = by_id.find(id) orelse return null;
    return .{
        .strengthen_group = strengthen_groups[row],
        .promote_group = promote_groups[row],
        .transform_item_id = transform_item_ids[row],
        .rarity = rarities[row],
    };
}

pub fn element(id: u32) ?character.Element {
    const row = by_id.find(id) orelse return null;
    return std.enums.fromInt(character.Element, elements[row]);
}
