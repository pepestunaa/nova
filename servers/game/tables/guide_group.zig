const raw_list = @import("tables/GuideGroup");

//

pub const all_ids = blk: {
    var ids: [raw_list.len + 1]u32 = undefined;
    ids[0] = 1;

    for (raw_list, 0..) |raw, index| ids[index + 1] = raw.id;

    break :blk ids;
};
