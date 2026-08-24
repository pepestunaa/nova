const Allocator = @import("std").mem.Allocator;

const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

//

pub const ChangeSet = struct {
    entries: [tables.achievement.tracked_entry_count]Player.Achievement = undefined,
    len: usize = 0,
    dirty: bool = false,

    pub fn slice(changes: *const ChangeSet) []const Player.Achievement {
        return changes.entries[0..changes.len];
    }
};

/// Rebuilds every supported achievement from persistent state.
/// This keeps the result correct after a restart and lets character changes
/// satisfy milestones that were added after the player first leveled up.
pub fn refresh(player: *Player, allocator: Allocator, now: i64, changes: *ChangeSet) !void {
    changes.* = .{};

    try refreshCollection(player, allocator, now, changes);
    try refreshCharacterProgression(player, allocator, now, changes);
}

fn refreshCollection(player: *Player, allocator: Allocator, now: i64, changes: *ChangeSet) !void {
    var counts: [@typeInfo(tables.achievement.CollectionKind).@"enum".fields.len]u32 = @splat(0);
    for (player.acquisitions.slice()) |acquisition| {
        const card = tables.gacha.maybeClassifyCard(acquisition.id) orelse
            continue;
        switch (card.kind) {
            .disc => {
                counts[@intFromEnum(tables.achievement.CollectionKind.all_discs)] +|= acquisition.count;
                if (card.rarity == .five_star)
                    counts[@intFromEnum(tables.achievement.CollectionKind.five_star_discs)] +|= acquisition.count;
            },
            .character => {
                counts[@intFromEnum(tables.achievement.CollectionKind.all_trekkers)] +|= acquisition.count;
                if (card.rarity == .five_star)
                    counts[@intFromEnum(tables.achievement.CollectionKind.five_star_trekkers)] +|= acquisition.count;
            },
        }
    }

    for (tables.achievement.collection_groups, 0..) |group, group_index| {
        for (tables.achievement.collectionEntries(group)) |definition| {
            try refreshState(player, allocator, now, definition, counts[group_index], changes);
        }
    }
}

fn refreshCharacterProgression(player: *Player, allocator: Allocator, now: i64, changes: *ChangeSet) !void {
    for (tables.achievement.character_progressions) |definition| {
        const progress = switch (definition.kind) {
            .advance_total => advancementTotal(player),
            .character_level => characterLevelCount(player, definition.minimum_level, null),
            .element_level => characterLevelCount(player, definition.minimum_level, definition.element),
            .skill_level => skillLevelCount(player, definition.minimum_level),
        };
        const entry = tables.achievement.entry(definition.entry_index);
        try refreshState(player, allocator, now, entry, progress, changes);
    }
}

fn advancementTotal(player: *const Player) u32 {
    var total: u32 = 0;
    var characters = player.characters.iterator();
    while (characters.next()) |entry|
        total +|= entry.value.advance();

    return total;
}

fn characterLevelCount(player: *const Player, minimum_level: u8, element_filter: ?u8) u32 {
    var count: u32 = 0;
    var characters = player.characters.iterator();
    while (characters.next()) |entry| {
        if (entry.value.level() < minimum_level)
            continue;
        if (element_filter) |element| {
            const character_element = tables.character.element(entry.id()) orelse unreachable;
            if (@intFromEnum(character_element) != element)
                continue;
        }
        count += 1;
    }

    return count;
}

fn skillLevelCount(player: *const Player, minimum_level: u8) u32 {
    var count: u32 = 0;
    var characters = player.characters.iterator();
    while (characters.next()) |entry| {
        const levels = entry.value.skillLevels();
        for (levels[0..4]) |level| {
            if (level >= minimum_level)
                count += 1;
        }
    }

    return count;
}

fn refreshState(
    player: *Player,
    allocator: Allocator,
    now: i64,
    definition: tables.achievement.Entry,
    progress: u32,
    changes: *ChangeSet,
) !void {
    const state = try getOrCreate(player, allocator, definition.id);
    const previous_status = state.status;
    const status: Player.Achievement.Status = if (previous_status == .reward_received)
        .reward_received
    else if (progress >= definition.target)
        .reward_available
    else
        .in_progress;
    const completed_at: i64 = if (status != .in_progress and state.completed_at == 0)
        now
    else
        state.completed_at;
    if (state.progress == progress and
        state.status == status and
        state.completed_at == completed_at)
        return;

    state.progress = progress;
    state.status = status;
    state.completed_at = completed_at;
    changes.dirty = true;

    if (previous_status != .in_progress)
        return;
    changes.entries[changes.len] = state.*;
    changes.len += 1;
}

fn getOrCreate(player: *Player, allocator: Allocator, id: u32) !*Player.Achievement {
    for (player.achievements.entries[0..player.achievements.len]) |*entry| {
        if (entry.id == id) return entry;
    }
    try player.achievements.append(allocator, .{ .id = id });

    return &player.achievements.entries[player.achievements.len - 1];
}
