const raw_list = @import("tables/GuideGroup");

const count: usize = raw_list.len;

//

pub const all_ids = blk: {
    var ids: [count + 1]u32 = undefined;
    ids[0] = 1;

    for (raw_list, 0..) |raw, index| ids[index + 1] = raw.id;

    break :blk ids;
};
