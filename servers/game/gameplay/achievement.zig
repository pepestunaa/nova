const std = @import("std");
const Allocator = std.mem.Allocator;

const Mutation = @import("mutation.zig");
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
pub fn refresh(mutation: *Mutation, allocator: Allocator, now: i64, changes: *ChangeSet) !void {
    changes.* = .{};

    try refreshCollection(mutation, allocator, now, changes);
    try refreshProgression(mutation, allocator, now, changes);
}

pub fn refreshCollection(mutation: *Mutation, allocator: Allocator, now: i64, changes: *ChangeSet) !void {
    const player = mutation.read();
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
            try refreshState(mutation, allocator, now, definition, counts[group_index], changes);
        }
    }
}

pub fn refreshProgression(mutation: *Mutation, allocator: Allocator, now: i64, changes: *ChangeSet) !void {
    const player = mutation.read();
    for (tables.achievement.progressions) |definition| {
        const progress = switch (definition.kind) {
            .advance_total => advancementTotal(player),
            .character_level => characterLevelCount(player, definition.minimum_level, null),
            .element_level => characterLevelCount(player, definition.minimum_level, definition.element),
            .skill_level => skillLevelCount(player, definition.minimum_level),
            .disc_tier_total => discTierTotal(player),
            .disc_level => discLevelCount(player, definition.minimum_level),
        };
        const entry = tables.achievement.entry(definition.entry_index);
        try refreshState(mutation, allocator, now, entry, progress, changes);
    }
}

fn discTierTotal(player: *const Player) u32 {
    var total: u32 = 0;
    for (player.discs.slice()) |disc|
        total +|= @intFromEnum(disc.phase);

    return total;
}

fn discLevelCount(player: *const Player, minimum_level: u8) u32 {
    var count: u32 = 0;
    for (player.discs.slice()) |disc| {
        if (@intFromEnum(disc.level) >= minimum_level)
            count += 1;
    }

    return count;
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
    mutation: *Mutation,
    allocator: Allocator,
    now: i64,
    definition: tables.achievement.Entry,
    progress: u32,
    changes: *ChangeSet,
) !void {
    const existing = find(mutation.read(), definition.id);
    const previous_status = if (existing) |state| state.status else .in_progress;
    const status: Player.Achievement.Status = if (previous_status == .reward_received)
        .reward_received
    else if (progress >= definition.target)
        .reward_available
    else
        .in_progress;
    const previous_completed_at = if (existing) |state| state.completed_at else 0;
    const completed_at: i64 = if (status != .in_progress and previous_completed_at == 0)
        now
    else
        previous_completed_at;
    if (existing) |state| {
        if (state.progress == progress and
            state.status == status and
            state.completed_at == completed_at)
            return;
    }

    const player = mutation.modify(.{});
    const state = try getOrCreate(player, allocator, definition.id);
    state.progress = progress;
    state.status = status;
    state.completed_at = completed_at;
    changes.dirty = true;

    if (previous_status != .in_progress)
        return;
    changes.entries[changes.len] = state.*;
    changes.len += 1;
}

fn find(player: *const Player, id: u32) ?*const Player.Achievement {
    for (player.achievements.slice()) |*entry| {
        if (entry.id == id)
            return entry;
    }

    return null;
}

fn getOrCreate(player: *Player, allocator: Allocator, id: u32) !*Player.Achievement {
    for (player.achievements.entries[0..player.achievements.len]) |*entry| {
        if (entry.id == id) return entry;
    }
    try player.achievements.append(allocator, .{ .id = id });

    return &player.achievements.entries[player.achievements.len - 1];
}

//

test "completed and claimed achievements do not notify again" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    const definition = tables.achievement.collectionEntries(
        tables.achievement.collection_groups[0],
    )[0];

    var completion: Mutation = .init(&player);
    var completion_changes: ChangeSet = .{};
    try refreshState(
        &completion,
        testing.allocator,
        100,
        definition,
        definition.target,
        &completion_changes,
    );
    try testing.expectEqual(@as(usize, 1), completion_changes.len);
    try testing.expectEqual(
        Player.Achievement.Status.reward_available,
        completion_changes.slice()[0].status,
    );
    completion.finish();
    completion.committed();

    var further_progress: Mutation = .init(&player);
    var further_changes: ChangeSet = .{};
    try refreshState(
        &further_progress,
        testing.allocator,
        200,
        definition,
        definition.target + 1,
        &further_changes,
    );
    try testing.expectEqual(@as(usize, 0), further_changes.len);
    try testing.expectEqual(@as(i64, 100), find(&player, definition.id).?.completed_at);
    further_progress.finish();
    further_progress.committed();

    player.achievements.entries[0].status = .reward_received;
    var claimed_progress: Mutation = .init(&player);
    var claimed_changes: ChangeSet = .{};
    try refreshState(
        &claimed_progress,
        testing.allocator,
        300,
        definition,
        definition.target + 2,
        &claimed_changes,
    );
    try testing.expectEqual(@as(usize, 0), claimed_changes.len);
    try testing.expectEqual(
        Player.Achievement.Status.reward_received,
        find(&player, definition.id).?.status,
    );
}
