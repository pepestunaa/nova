const lookup = @import("lookup.zig");

const raw_character_potentials = @import("tables/CharPotential");
const raw_list = @import("tables/Potential");

//

pub const count = entries.len;

const Entry = struct {
    id: u32,
    character_id: u32,
    branch_type: u8,
    max_level: u8,
    scores: [9]u32,
};

const CharacterEntry = struct {
    id: u32,
    master_specific: []const u32,
    assist_specific: []const u32,
    common: []const u32,
    master_normal: []const u32,
    assist_normal: []const u32,
};

pub const Pool = struct {
    specific: []const u32,
    normal: []const u32,
    common: []const u32,
};

const entries = blk: {
    @setEvalBranchQuota(1_000_000);

    var list: [raw_list.len]Entry = undefined;
    for (raw_list, 0..) |raw, index| {
        var scores: [9]u32 = @splat(0);
        for (raw.build_score, 0..) |build_score, score_index|
            scores[score_index] = build_score;
        list[index] = .{
            .id = raw.id,
            .character_id = raw.char_id,
            .branch_type = raw.branch_type,
            .max_level = raw.max_level,
            .scores = scores,
        };
    }

    break :blk list;
};

const character_entries = blk: {
    var list: [raw_character_potentials.len]CharacterEntry = undefined;
    for (raw_character_potentials, 0..) |raw, index| list[index] = .{
        .id = raw.id,
        .master_specific = &raw.master_specific_potential_ids,
        .assist_specific = &raw.assist_specific_potential_ids,
        .common = &raw.common_potential_ids,
        .master_normal = &raw.master_normal_potential_ids,
        .assist_normal = &raw.assist_normal_potential_ids,
    };

    break :blk list;
};

const by_id = lookup.Lookup(u32, lookup.fieldKeys(u32, &entries, "id"));
const by_character_id = lookup.Lookup(u32, lookup.fieldKeys(u32, &character_entries, "id"));

/// Returns the Potential pools for a Trekker and squad role.
pub fn pool(character_id: u32, master: bool) ?Pool {
    const row = by_character_id.find(character_id) orelse
        return null;
    const character = character_entries[row];

    return .{
        .specific = if (master) character.master_specific else character.assist_specific,
        .normal = if (master) character.master_normal else character.assist_normal,
        .common = character.common,
    };
}

pub fn characterId(id: u32) ?u32 {
    const row = by_id.find(id) orelse return null;
    return entries[row].character_id;
}

pub fn score(id: u32, level: u32) u32 {
    const row = by_id.find(id) orelse
        return 0;
    const entry = &entries[row];
    const index = @min(@as(usize, level -| 1), entry.scores.len - 1);

    return entry.scores[index];
}

pub fn maxLevel(id: u32) u32 {
    const row = by_id.find(id) orelse return 1;
    return entries[row].max_level;
}

pub fn allowsExtraLevelCap(id: u32) bool {
    const row = by_id.find(id) orelse return false;
    return entries[row].branch_type == 3;
}
