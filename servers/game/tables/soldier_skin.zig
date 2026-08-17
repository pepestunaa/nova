const std = @import("std");

const raw_list = @import("tables/SoldierSkin");

//

pub const Entry = struct {
    id: u32,
    character_id: u16,
};

pub const list: [character_skin_count]Entry = blk: {
    @setEvalBranchQuota(100_000);

    var entries: [character_skin_count]Entry = undefined;
    var index: usize = 0;
    for (raw_list) |raw| {
        if (!@hasField(@TypeOf(raw), "character_id"))
            continue;
        entries[index] = .{
            .id = raw.id,
            .character_id = std.math.cast(u16, raw.character_id) orelse
                @compileError("soldier skin character ID exceeds u16"),
        };
        index += 1;
    }

    break :blk entries;
};

pub fn getCharacterId(skin_id: u32) ?u16 {
    for (list) |entry| if (entry.id == skin_id)
        return entry.character_id;

    return null;
}

const character_skin_count = blk: {
    var count: usize = 0;
    for (raw_list) |raw| {
        if (@hasField(@TypeOf(raw), "character_id")) count += 1;
    }

    break :blk count;
};
