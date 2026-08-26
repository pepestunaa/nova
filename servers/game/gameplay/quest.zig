const Allocator = @import("std").mem.Allocator;

const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");
const reset = @import("reset.zig");
const tables = @import("../tables.zig");

//

pub fn initialize(player: *Player, allocator: Allocator, created_at: i64) Allocator.Error!void {
    _ = try refreshDailyWeeklyMissionsPlayer(player, allocator, created_at);

    inline for (tables.quest.initial_tour_guide) |definition|
        try appendDefinition(player, allocator, definition, 0);
    // A new official account receives every Lineup Tutorial objective from
    // both element tracks. `Assists` stores claimed chapters, not active tasks,
    // so it starts empty.
    inline for (tables.quest.assist) |definition|
        try appendDefinition(player, allocator, definition, 0);
    var assist_changes: AssistChanges = .{};
    refreshAssist(player, &assist_changes);

    // Include the active Monolith event objectives.
    inline for (tables.quest.tower_event) |definition|
        try appendDefinition(player, allocator, definition, 0);

    inline for (tables.periodic_quest.list) |definition|
        try player.periodic_quests.append(allocator, .{ .id = definition.id });
}

/// Lineup Tutorial tasks changed while reconciling saved player state. Callers
/// can forward them through `quest_change_notify` after events such as
/// Recruitment rewards.
pub const AssistChanges = struct {
    entries: [tables.quest.assist.len]Player.Quest = undefined,
    len: usize = 0,

    pub fn slice(changes: *const AssistChanges) []const Player.Quest {
        return changes.entries[0..changes.len];
    }
};

/// Recomputes Lineup Tutorial progress that can be derived from saved state.
/// Tasks based on unsupported gameplay events keep their current progress.
pub fn refreshAssist(player: *Player, changes: *AssistChanges) void {
    changes.* = .{};
    for (player.quests.entries[0..player.quests.len]) |*quest| {
        if (quest.quest_type != @intFromEnum(tables.quest.Type.assist))
            continue;
        const progress = assistProgress(player, quest.id) orelse
            continue;
        const clamped = @min(progress, quest.progress_max);
        if (quest.progress_current == clamped)
            continue;

        quest.progress_current = clamped;
        changes.entries[changes.len] = quest.*;
        changes.len += 1;
    }
}

/// Refreshes daily and weekly missions while preserving progress until their
/// next reset.
pub fn refreshDailyWeeklyMissions(mutation: *Mutation, allocator: Allocator, now: i64) !bool {
    const player = mutation.read();
    if (!definitionsNeedRefresh(player, &tables.quest.daily, now) and
        !definitionsNeedRefresh(player, &tables.quest.weekly, now))
        return false;

    return refreshDailyWeeklyMissionsPlayer(
        mutation.modify(.{}),
        allocator,
        now,
    );
}

fn refreshDailyWeeklyMissionsPlayer(player: *Player, allocator: Allocator, now: i64) !bool {
    var changed = try refreshDefinitions(
        player,
        allocator,
        &tables.quest.daily,
        now,
        reset.nextDaily(now),
    );
    changed = try refreshDefinitions(
        player,
        allocator,
        &tables.quest.weekly,
        now,
        reset.nextWeekly(now),
    ) or changed;

    return changed;
}

fn definitionsNeedRefresh(
    player: *const Player,
    comptime definitions: []const tables.quest.Definition,
    now: i64,
) bool {
    for (definitions) |definition| {
        var found = false;
        for (player.quests.slice()) |quest| {
            if (quest.id != definition.id or quest.quest_type != @intFromEnum(definition.type))
                continue;
            found = true;
            if (quest.condition != definition.condition or
                quest.condition_param != definition.condition_param or
                quest.progress_max != definition.progress_max or
                quest.expires_at <= now)
                return true;
            break;
        }
        if (!found)
            return true;
    }

    return false;
}

fn appendDefinition(
    player: *Player,
    allocator: Allocator,
    definition: tables.quest.Definition,
    expires_at: i64,
) Allocator.Error!void {
    try player.quests.append(allocator, .{
        .id = definition.id,
        .expires_at = expires_at,
        .quest_type = @intFromEnum(definition.type),
        .condition = definition.condition,
        .condition_param = definition.condition_param,
        .progress_max = definition.progress_max,
    });
}

const AssistTrack = enum {
    ventus,
    ignis,
};

fn assistProgress(player: *const Player, id: u32) ?u32 {
    const track: AssistTrack = switch (id / 100_000) {
        1 => .ventus,
        2 => .ignis,
        else => return null,
    };
    const chapter = (id % 1000) / 100;
    const objective = id % 100;

    return switch (chapter) {
        1 => switch (objective) {
            1 => passedTutorialCount(player),
            2 => characterLevel(player, trackPrimary(track)),
            3 => ownsCharacter(player, trackSupport(track)),
            4 => characterLevel(player, trackSupport(track)),
            5 => elementalDiscCount(player, trackElement(track), 10, 0),
            else => null,
        },
        2 => switch (objective) {
            1 => passedTutorialCount(player),
            2 => characterAdvance(player, trackPrimary(track)),
            3 => characterAdvance(player, trackSupport(track)),
            4 => elementalDiscCount(player, trackElement(track), 0, 1),
            5 => characterAdvance(player, trackThird(track)),
            6 => characterLevel(player, trackPrimary(track)),
            7 => characterLevel(player, trackSupport(track)),
            8 => characterLevel(player, trackThird(track)),
            else => null,
        },
        3 => switch (objective) {
            2 => passedTutorialCount(player),
            3 => elementalDiscCount(player, trackElement(track), 20, 0),
            4 => characterAdvance(player, trackPrimary(track)),
            5 => characterAdvance(player, trackSupport(track)),
            6 => characterAdvance(player, trackThird(track)),
            7 => elementalDiscCount(player, trackElement(track), 30, 0),
            8 => elementalCharacterCount(player, trackElement(track), 30),
            9 => characterNormalSkillLevel(player, trackPrimary(track)),
            10 => characterMainSkillLevel(player, trackSupport(track)),
            else => null,
        },
        4 => switch (objective) {
            1 => passedTutorialCount(player),
            2 => characterAdvance(player, trackPrimary(track)),
            3 => characterAdvance(player, trackSupport(track)),
            4 => characterAdvance(player, trackThird(track)),
            5 => elementalDiscCount(player, trackElement(track), 40, 0),
            6 => elementalCharacterCount(player, trackElement(track), 40),
            7 => characterNormalSkillLevel(player, trackPrimary(track)),
            8 => characterMainSkillLevel(player, trackSupport(track)),
            else => null,
        },
        5 => switch (objective) {
            1 => passedTutorialCount(player),
            2 => characterAdvance(player, trackPrimary(track)),
            3 => characterAdvance(player, trackSupport(track)),
            4 => characterAdvance(player, trackThird(track)),
            5 => elementalDiscCount(player, trackElement(track), 50, 0),
            6 => elementalCharacterCount(player, trackElement(track), 50),
            7 => characterNormalSkillLevel(player, trackPrimary(track)),
            8 => characterMainSkillLevel(player, trackSupport(track)),
            else => null,
        },
        else => null,
    };
}

fn trackPrimary(track: AssistTrack) u32 {
    return switch (track) {
        .ventus => @intFromEnum(tables.character.Id.Noya),
        .ignis => @intFromEnum(tables.character.Id.Amber),
    };
}

fn trackSupport(track: AssistTrack) u32 {
    return switch (track) {
        .ventus => @intFromEnum(tables.character.Id.Ann),
        .ignis => @intFromEnum(tables.character.Id.Flora),
    };
}

fn trackThird(track: AssistTrack) u32 {
    return switch (track) {
        .ventus => @intFromEnum(tables.character.Id.Canace),
        .ignis => @intFromEnum(tables.character.Id.Kasimira),
    };
}

fn trackElement(track: AssistTrack) tables.character.Element {
    return switch (track) {
        .ventus => .ventus,
        .ignis => .ignis,
    };
}

fn passedTutorialCount(player: *const Player) u32 {
    var count: u32 = 0;
    for (player.tutorials.slice()) |level| {
        if (level.passed)
            count +|= 1;
    }

    return count;
}

fn ownsCharacter(player: *const Player, id: u32) u32 {
    return @intFromBool(player.characters.get(id) != null);
}

fn characterLevel(player: *const Player, id: u32) u32 {
    const character = player.characters.get(id) orelse return 0;

    return character.level();
}

fn characterAdvance(player: *const Player, id: u32) u32 {
    const character = player.characters.get(id) orelse return 0;

    return character.advance();
}

fn characterNormalSkillLevel(player: *const Player, id: u32) u32 {
    const character = player.characters.get(id) orelse return 0;

    return character.skillLevel(.attack);
}

fn characterMainSkillLevel(player: *const Player, id: u32) u32 {
    const character = player.characters.get(id) orelse return 0;

    return character.skillLevel(.main);
}

fn elementalCharacterCount(
    player: *const Player,
    element: tables.character.Element,
    minimum_level: u32,
) u32 {
    var count: u32 = 0;
    var iterator = player.characters.iterator();
    while (iterator.next()) |entry| {
        if (tables.character.element(entry.id()) != element or entry.value.level() < minimum_level)
            continue;
        count +|= 1;
    }

    return count;
}

fn elementalDiscCount(
    player: *const Player,
    element: tables.character.Element,
    minimum_level: u32,
    minimum_phase: u32,
) u32 {
    var count: u32 = 0;
    for (player.discs.slice()) |disc| {
        if (tables.disc.element(disc.id) != element or
            @intFromEnum(disc.level) < minimum_level or
            @intFromEnum(disc.phase) < minimum_phase)
            continue;
        count +|= 1;
    }

    return count;
}

fn refreshDefinitions(
    player: *Player,
    allocator: Allocator,
    comptime definitions: []const tables.quest.Definition,
    now: i64,
    expires_at: i64,
) !bool {
    var changed = false;
    for (definitions) |definition| {
        var found = false;
        for (player.quests.entries[0..player.quests.len]) |*quest| {
            if (quest.id != definition.id or quest.quest_type != @intFromEnum(definition.type))
                continue;
            found = true;

            // Refresh static definitions for existing players too, allowing
            // table corrections without a save migration.
            if (quest.condition != definition.condition or
                quest.condition_param != definition.condition_param or
                quest.progress_max != definition.progress_max)
            {
                quest.condition = definition.condition;
                quest.condition_param = definition.condition_param;
                quest.progress_max = definition.progress_max;
                quest.progress_current = @min(quest.progress_current, quest.progress_max);
                changed = true;
            }

            if (quest.expires_at <= now) {
                quest.expires_at = expires_at;
                quest.progress_current = 0;
                quest.claimed = false;
                changed = true;
            }

            break;
        }

        if (found)
            continue;

        try player.quests.append(allocator, .{
            .id = definition.id,
            .expires_at = expires_at,
            .quest_type = @intFromEnum(definition.type),
            .condition = definition.condition,
            .condition_param = definition.condition_param,
            .progress_max = definition.progress_max,
        });
        changed = true;
    }

    return changed;
}
