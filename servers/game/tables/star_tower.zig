const character = @import("character.zig");
const lookup = @import("lookup.zig");

const raw_build_ranks = @import("tables/StarTowerBuildRank");
const raw_floor_exp = @import("tables/StarTowerFloorExp");
const raw_floor_sets = @import("tables/StarTowerFloorSet");
const raw_maps = @import("tables/StarTowerMap");
const raw_note_drop_groups = @import("tables/SubNoteSkillDropGroup");
const raw_stages = @import("tables/StarTowerStage");
const raw_team_exp = @import("tables/StarTowerTeamExp");
const raw_towers = @import("tables/StarTower");

//

pub const Room = struct {
    stage_id: u32,
    stage_group_id: u32,
    stage: u32,
    floor: u32,
    room_type: u32,
    interior_currency_quantity: u32,
};

pub const FirstAward = struct {
    item_id: u32,
    quantity: i32,
};

pub const BattleExperience = struct {
    normal: u32,
    elite: u32,
    boss: u32,
    final_boss: u32,
};

pub const TeamLevel = struct {
    level: u32,
    required_exp: u32,
};

pub const team_levels: [raw_team_exp.len]TeamLevel = blk: {
    var levels: [raw_team_exp.len]TeamLevel = undefined;
    for (raw_team_exp, 0..) |raw, index| levels[index] = .{
        .level = raw.level,
        .required_exp = fieldOr(raw, "need_exp", 0),
    };

    break :blk levels;
};

/// Room values used by the client's `GameEnum.starTowerRoomType`.
pub const RoomType = enum(u32) {
    battle = 0,
    elite_battle = 1,
    boss = 2,
    final_boss = 3,
    danger = 4,
    horror = 5,
    shop = 6,
    event = 7,
    unify_battle = 15,
};

pub fn isBattleRoom(room_type: u32) bool {
    return switch (room_type) {
        @intFromEnum(RoomType.battle),
        @intFromEnum(RoomType.elite_battle),
        @intFromEnum(RoomType.boss),
        @intFromEnum(RoomType.final_boss),
        @intFromEnum(RoomType.danger),
        @intFromEnum(RoomType.horror),
        @intFromEnum(RoomType.unify_battle),
        => true,
        else => false,
    };
}

pub fn isSupportedRoom(room_type: u32) bool {
    return isBattleRoom(room_type) or
        room_type == @intFromEnum(RoomType.shop) or
        room_type == @intFromEnum(RoomType.event);
}

pub fn battleNoteCount(room_type: u32) u32 {
    return switch (room_type) {
        @intFromEnum(RoomType.elite_battle),
        @intFromEnum(RoomType.boss),
        @intFromEnum(RoomType.final_boss),
        => 2,
        else => 1,
    };
}

// Official server does this
pub fn givesRecoveryNpc(room_type: u32) bool {
    return room_type == @intFromEnum(RoomType.elite_battle) or
        room_type == @intFromEnum(RoomType.boss);
}

/// Converts a Trekker or Monolith element into its matching Musical Note.
pub fn elementNote(element: character.Element) u32 {
    return switch (element) {
        .aqua => 90018,
        .ignis => 90019,
        .terra => 90021,
        .ventus => 90020,
        .lux => 90022,
        .umbra => 90023,
    };
}

pub fn firstAwards(tower_id: u32, output: []FirstAward) []FirstAward {
    const row = by_tower_id.find(tower_id) orelse
        return &.{};
    const awards = towers[row].first_awards;
    const count = @min(output.len, awards.len);
    @memcpy(output[0..count], awards[0..count]);

    return output[0..count];
}

pub fn experience(tower_id: u32, stage: u32) ?BattleExperience {
    const row = by_floor_exp.find(pairKey(tower_id, stage)) orelse
        return null;
    return floor_exp[row].value;
}

pub fn contains(tower_id: u32) bool {
    return by_tower_id.contains(tower_id);
}

pub fn difficulty(tower_id: u32) ?u32 {
    const row = by_tower_id.find(tower_id) orelse
        return null;
    return towers[row].difficulty;
}

pub fn buildRating(score: u32) u8 {
    var rating: u8 = 1;
    inline for (raw_build_ranks) |rank| {
        if (score < @as(u32, @intCast(fieldOr(rank, "min_grade", 0))))
            break;
        rating = @intCast(rank.level);
    }

    return rating;
}

pub fn hasElement(tower_id: u32, element: character.Element) bool {
    const row = by_tower_id.find(tower_id) orelse
        return false;
    const tower = &towers[row];

    for (tower.elements[0..tower.element_count]) |tower_element| {
        if (tower_element == @intFromEnum(element))
            return true;
    }

    return false;
}

pub fn noteCount(tower_id: u32) usize {
    const row = by_tower_id.find(tower_id) orelse
        return 0;

    return towers[row].notes.len;
}

pub fn note(tower_id: u32, index: usize) ?u32 {
    const row = by_tower_id.find(tower_id) orelse
        return null;
    const notes = towers[row].notes;

    return if (index < notes.len) notes[index] else null;
}

/// Resolves an Ascension floor across all stage groups. Later groups continue
/// after the previous group's last floor instead of restarting at one.
pub fn room(tower_id: u32, global_floor: u32) ?Room {
    if (global_floor == 0)
        return null;

    const tower_row = by_tower_id.find(tower_id) orelse
        return null;
    const tower = &towers[tower_row];

    for (tower.groups[0..tower.group_count]) |group| {
        if (global_floor < group.first_floor or global_floor > group.last_floor)
            continue;

        const local_floor = global_floor - group.first_floor + 1;
        const stage_row = by_stage.find(pairKey(group.id, local_floor)) orelse
            return null;
        const stage = &stages[stage_row];

        return .{
            .stage_id = stage.id,
            .stage_group_id = group.id,
            .stage = stage.stage,
            .floor = global_floor,
            .room_type = stage.room_type,
            .interior_currency_quantity = stage.interior_currency_quantity,
        };
    }

    return null;
}

pub fn hasMap(map_id: u32) bool {
    return by_map_id.contains(map_id);
}

pub fn defaultMap(room_data: Room) ?u32 {
    for (floor_sets) |floor_set| {
        if (floor_set.battle_lvs != room_data.floor)
            continue;
        if (floor_set.room_type != room_data.room_type)
            continue;
        if (!sliceContains(floor_set.stages, room_data.stage))
            continue;
        if (floor_set.floor_ids.len != 0 and
            !sliceContains(floor_set.floor_ids, room_data.stage_group_id))
            continue;
        if (floor_set.map_ids.len == 0)
            continue;

        return floor_set.map_ids[0];
    }

    return null;
}

comptime {
    @setEvalBranchQuota(1_000_000);

    for (stages) |stage| {
        if (!isSupportedRoom(stage.room_type))
            @compileError("StarTowerStage contains an unsupported room type");
    }

    // Settlement currently follows the final battle reward flow. Fail the
    // build if new data ends an Ascension with a shop or event, which needs
    // different packet sequencing.
    for (towers) |tower| {
        const first_room = room(tower.id, 1) orelse
            @compileError("StarTower has no opening stage");
        if (!isBattleRoom(first_room.room_type))
            @compileError("StarTower has a non-battle opening stage");

        const last_floor = tower.groups[tower.group_count - 1].last_floor;
        const terminal_room = room(tower.id, last_floor) orelse
            @compileError("StarTower has no terminal stage");
        if (!isBattleRoom(terminal_room.room_type))
            @compileError("StarTower has a non-battle terminal stage");
    }
}

const max_groups = blk: {
    var longest: usize = 0;
    for (raw_towers) |tower| longest = @max(longest, tower.stage_group_ids.len);

    break :blk longest;
};

const max_elements = blk: {
    var longest: usize = 0;
    for (raw_towers) |tower| longest = @max(longest, tower.eet.len);

    break :blk longest;
};

const Group = struct {
    id: u32,
    first_floor: u32,
    last_floor: u32,
};

const Tower = struct {
    id: u32,
    difficulty: u32,
    elements: [max_elements]u8,
    element_count: u8,
    groups: [max_groups]Group,
    group_count: u8,
    notes: []const u32,
    first_awards: []const FirstAward,
};

const towers: [raw_towers.len]Tower = blk: {
    @setEvalBranchQuota(1_000_000);

    var result: [raw_towers.len]Tower = undefined;
    for (raw_towers, 0..) |raw, index| {
        var groups: [max_groups]Group = undefined;
        var first_floor: u32 = 1;
        for (raw.stage_group_ids, raw.floor_num, 0..) |group_id, floor_count, group_index| {
            const last_floor = first_floor + floor_count - 1;
            groups[group_index] = .{
                .id = group_id,
                .first_floor = first_floor,
                .last_floor = last_floor,
            };
            first_floor = last_floor + 1;
        }

        var elements: [max_elements]u8 = @splat(0);
        for (raw.eet, 0..) |element, element_index| elements[element_index] = element;

        result[index] = .{
            .id = raw.id,
            .difficulty = raw.difficulty,
            .elements = elements,
            .element_count = raw.eet.len,
            .groups = groups,
            .group_count = raw.stage_group_ids.len,
            .notes = notesFor(raw.sub_note_skill_drop_group_id),
            .first_awards = if (@hasField(@TypeOf(raw), "first_award"))
                parseFirstAwards(raw.first_award)
            else
                &.{},
        };
    }

    break :blk result;
};

const by_tower_id = lookup.Lookup(u32, lookup.fieldKeys(u32, raw_towers, "id"));

const Stage = struct {
    id: u32,
    stage: u32,
    room_type: u32,
    interior_currency_quantity: u32,
};

const stages: [raw_stages.len]Stage = blk: {
    @setEvalBranchQuota(1_000_000);

    var result: [raw_stages.len]Stage = undefined;
    for (raw_stages, 0..) |raw, index| result[index] = .{
        .id = raw.id,
        .stage = raw.stage,
        .room_type = fieldOr(raw, "room_type", 0),
        .interior_currency_quantity = fieldOr(raw, "interior_currency_quantity", 0),
    };

    break :blk result;
};

const by_stage = lookup.Lookup(u64, blk: {
    @setEvalBranchQuota(1_000_000);

    var keys: [raw_stages.len]u64 = undefined;
    for (raw_stages, 0..) |raw, index| keys[index] = pairKey(raw.group_id, raw.floor);
    const result = keys;

    break :blk &result;
});

const FloorExp = struct {
    value: BattleExperience,
};

const floor_exp: [raw_floor_exp.len]FloorExp = blk: {
    var result: [raw_floor_exp.len]FloorExp = undefined;
    for (raw_floor_exp, 0..) |raw, index| result[index] = .{ .value = .{
        .normal = raw.normal_exp,
        .elite = raw.elite_exp,
        .boss = raw.boss_exp,
        .final_boss = raw.final_boss_exp,
    } };

    break :blk result;
};

const by_floor_exp = lookup.Lookup(u64, blk: {
    var keys: [raw_floor_exp.len]u64 = undefined;
    for (raw_floor_exp, 0..) |raw, index| keys[index] = pairKey(raw.star_tower_id, raw.stage);
    const result = keys;

    break :blk &result;
});

const by_map_id = lookup.Lookup(u32, lookup.fieldKeys(u32, raw_maps, "id"));

const FloorSet = struct {
    battle_lvs: u32,
    room_type: u32,
    stages: []const u32,
    floor_ids: []const u32,
    map_ids: []const u32,
};

const floor_sets: [raw_floor_sets.len]FloorSet = blk: {
    @setEvalBranchQuota(1_000_000);

    var result: [raw_floor_sets.len]FloorSet = undefined;
    for (raw_floor_sets, 0..) |raw, index| result[index] = .{
        .battle_lvs = raw.battle_lvs,
        .room_type = fieldOr(raw, "room_type", 0),
        .stages = constSlice(u32, raw.stage),
        .floor_ids = if (@hasField(@TypeOf(raw), "floor_id"))
            constSlice(u32, raw.floor_id)
        else
            &.{},
        .map_ids = constSlice(u32, raw.map_id),
    };

    break :blk result;
};

fn pairKey(high: u32, low: u32) u64 {
    return (@as(u64, high) << 32) | low;
}

fn sliceContains(values: []const u32, expected: u32) bool {
    for (values) |value| {
        if (value == expected)
            return true;
    }

    return false;
}

fn constSlice(comptime Value: type, comptime values: anytype) []const Value {
    var result: [values.len]Value = undefined;
    for (values, 0..) |value, index| result[index] = value;
    const final = result;

    return &final;
}

fn notesFor(comptime drop_group_id: u32) []const u32 {
    if (drop_group_id == 0)
        return &.{};

    var result: []const u32 = &.{};
    for (raw_note_drop_groups) |entry| {
        if (entry.group_id == drop_group_id)
            result = result ++ [1]u32{entry.sub_note_skill_id};
    }

    return result;
}

fn parseFirstAwards(comptime text: []const u8) []const FirstAward {
    var numbers: [32]u32 = undefined;
    var number_count: usize = 0;
    var value: u32 = 0;
    var in_number = false;
    for (text) |byte| {
        if (byte >= '0' and byte <= '9') {
            value = value * 10 + (byte - '0');
            in_number = true;

            continue;
        }

        if (!in_number)
            continue;

        if (number_count == numbers.len)
            break;

        numbers[number_count] = value;
        number_count += 1;
        value = 0;
        in_number = false;
    }
    if (in_number and number_count != numbers.len) {
        numbers[number_count] = value;
        number_count += 1;
    }

    var result: []const FirstAward = &.{};
    for (0..number_count / 2) |index| result = result ++ [1]FirstAward{.{
        .item_id = numbers[index * 2],
        .quantity = numbers[index * 2 + 1],
    }};

    return result;
}

fn fieldOr(comptime entry: anytype, comptime name: []const u8, default: u32) u32 {
    if (@hasField(@TypeOf(entry), name))
        return @field(entry, name);

    return default;
}
