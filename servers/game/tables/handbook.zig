const lookup = @import("lookup.zig");

const raw_list = @import("tables/Handbook");

//

pub const Entry = struct {
    id: u32,
    index: usize,
    type: usize,
    character_id: u32,
    skin_id: u32,
    condition: u32,
};

pub const list: [raw_list.len]Entry = blk: {
    var entries: [raw_list.len]Entry = undefined;
    for (raw_list, 0..) |raw, i| entries[i] = .{
        .id = raw.id,
        .index = raw.index,
        .type = raw.type,
        .character_id = if (@hasField(@TypeOf(raw), "char_id")) raw.char_id else 0,
        .skin_id = if (@hasField(@TypeOf(raw), "skin_id")) raw.skin_id else 0,
        .condition = if (@hasField(@TypeOf(raw), "cond")) raw.cond else 0,
    };

    break :blk entries;
};

pub const max_type = blk: {
    var result: usize = 0;
    for (list) |entry| result = @max(result, entry.type);

    break :blk result;
};

pub const type_count = max_type + 1;

pub const max_bitmap_len = blk: {
    var result: usize = 0;
    for (list) |entry| result = @max(result, bitmapLen(entry.index));

    break :blk result;
};

const by_id = lookup.Lookup(u32, lookup.fieldKeys(u32, raw_list, "id"));

pub fn get(id: u32) ?Entry {
    const row = by_id.find(id) orelse return null;
    return list[row];
}

/// Gallery type 1 contains Trekker skins. Condition 10 marks the base skin
/// unlocked with its Trekker.
pub const skin_type = 1;
/// Gallery type 2 contains Runic Discs and uses the Runic Disc ID directly.
pub const disc_type = 2;
const character_unlock_condition = 10;
const advance_skin_unlock_condition = 13;

/// Base-skin rows keyed by Trekker.
const default_skins: []const Entry = blk: {
    var result: []const Entry = &.{};
    for (list) |entry| {
        if (entry.type == skin_type and
            entry.condition == character_unlock_condition)
            result = result ++ [1]Entry{entry};
    }
    const final = result[0..result.len].*;

    break :blk &final;
};

const by_default_skin_character = lookup.Lookup(
    u32,
    lookup.fieldKeys(u32, default_skins, "character_id"),
);

pub fn defaultSkin(character_id: u32) ?Entry {
    const row = by_default_skin_character.find(character_id) orelse return null;
    return default_skins[row];
}

const advance_skins: []const Entry = blk: {
    var result: []const Entry = &.{};
    for (list) |entry| {
        if (entry.type == skin_type and
            entry.condition == advance_skin_unlock_condition)
            result = result ++ [1]Entry{entry};
    }
    const final = result[0..result.len].*;

    break :blk &final;
};

const by_advance_skin_character = lookup.Lookup(
    u32,
    lookup.fieldKeys(u32, advance_skins, "character_id"),
);

pub fn advanceSkin(character_id: u32) ?Entry {
    const row = by_advance_skin_character.find(character_id) orelse return null;
    return advance_skins[row];
}

/// The client stores Gallery flags in big-endian byte order within each
/// 64-bit group, matching `UTILS.IsBitSet` in Lua.
pub fn bitmapByteIndex(index: usize) usize {
    const zero_based = index - 1;
    return (zero_based / 64) * 8 + 7 - (zero_based / 8) % 8;
}

pub fn bitmapLen(index: usize) usize {
    return ((index - 1) / 64 + 1) * 8;
}
