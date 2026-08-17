const lookup = @import("lookup.zig");

const raw_items = @import("tables/Item");

//

const by_id = lookup.Lookup(u32, lookup.fieldKeys(u32, raw_items, "id"));

const resource_flags: [raw_items.len]bool = blk: {
    @setEvalBranchQuota(100 * raw_items.len + 1000);

    var result: [raw_items.len]bool = undefined;
    for (raw_items, 0..) |entry, index| result[index] = entry.type == 1;

    break :blk result;
};

pub fn isResource(id: u32) bool {
    const row = by_id.find(id) orelse return false;
    return resource_flags[row];
}
