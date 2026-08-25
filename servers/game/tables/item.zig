const lookup = @import("lookup.zig");

const raw_items = @import("tables/Item");

const count: usize = raw_items.len;

//

const by_id = lookup.Lookup(u32, lookup.fieldKeys(u32, raw_items, "id"));

const resource_flags: [count]bool = blk: {
    @setEvalBranchQuota(100 * count + 1000);

    var result: [count]bool = undefined;
    for (raw_items, 0..) |entry, index| result[index] = entry.type == 1;

    break :blk result;
};

pub fn isResource(id: u32) bool {
    const row = by_id.find(id) orelse return false;
    return resource_flags[row];
}
