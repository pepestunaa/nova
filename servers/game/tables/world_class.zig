const raw_list = @import("tables/WorldClass");

//

pub const count: usize = raw_list.len;

pub const max_level: u8 = blk: {
    var result: u8 = 0;
    for (raw_list) |entry|
        result = @max(result, @as(u8, @intCast(entry.id)));

    break :blk result;
};
