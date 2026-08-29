const std = @import("std");
const Allocator = std.mem.Allocator;

const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");
const reward = @import("reward.zig");
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

/// Mission states changed by a request. The entries are copied before the
/// mutation is finalized so notifications do not borrow mutable player state.
pub const MissionChanges = struct {
    entries: [tables.quest.daily.len + tables.quest.weekly.len]Player.Quest = undefined,
    len: usize = 0,

    pub fn slice(changes: *const MissionChanges) []const Player.Quest {
        return changes.entries[0..changes.len];
    }
};

/// Conditions used by the daily and weekly mission tables. Values are kept in
/// sync with the game's table IDs; unsupported conditions are simply ignored.
pub const Condition = enum(u32) {
    battle_total = 3,
    character_upgrade = 12,
    daily_instance_clear = 26,
    disc_strengthen = 35,
    energy_deplete = 39,
    gift_give = 45,
    login = 51,
    region_boss_clear = 59,
    dating = 74,
    agent_finish = 83,
    skill_trial_clear = 90,
    character_gem_trial_clear = 104,
    daily_shop_reward = 105,
    agent_apply = 106,
    proving_grounds_clear = 123,
    client_report = 200,
    ascension_clear = 508,
    ascension_enter = 538,
    _,
};

pub const ClaimError = error{
    InvalidMission,
    MissionExpired,
    MissionNotComplete,
    MissionAlreadyClaimed,
    NoActiveRewards,
} || reward.Error;

pub const ActiveClaim = struct {
    ids: [@max(tables.quest.daily_active.len, tables.quest.weekly_active.len)]u32 = undefined,
    count: usize = 0,
    rewards: reward.ResourceReceipt = .{},
};

/// Refreshes missions and records one login per reset day. Reconnecting on
/// the same day does not inflate the weekly login mission.
pub fn login(mutation: *Mutation, allocator: Allocator, now: i64) Allocator.Error!void {
    _ = try refreshDailyWeeklyMissions(mutation, allocator, now);

    const day = reset.dayIndex(now);
    if (mutation.read().progress.last_login_day == day)
        return;

    mutation.modify(.{}).progress.last_login_day = day;
    trigger(mutation, .login, 1, 0);
}

/// Applies an action to all active daily and weekly missions that use the
/// supplied condition. Progress is capped at each mission's target and each
/// changed mission is recorded once for the request notification.
pub fn trigger(
    mutation: *Mutation,
    condition: Condition,
    amount: u32,
    parameter_value: u32,
) void {
    if (amount == 0)
        return;

    const player = mutation.read();
    var has_match = false;
    for (player.quests.slice()) |state| {
        if (matches(state, condition, parameter_value)) {
            has_match = true;
            break;
        }
    }
    if (!has_match)
        return;

    const writable = mutation.modify(.{});
    for (writable.quests.mutableSlice()) |*state| {
        const mission_type = missionType(state.quest_type) orelse
            continue;
        if (!matches(state.*, condition, parameter_value))
            continue;

        const progress = @min(state.progress_max, state.progress_current +| amount);
        if (state.progress_current == progress)
            continue;

        state.progress_current = progress;
        mutation.recordMission(mission_type, state.id);
    }
}

/// Copies mission states changed during this request into notification-owned
/// storage. The mutation remains the source of truth for the saved state.
pub fn collectMissionChanges(mutation: *const Mutation, changes: *MissionChanges) void {
    changes.* = .{};

    var changed = mutation.missionIterator();
    while (changed.next()) |raw_index| {
        const mission_type: tables.quest.Type = if (raw_index < tables.quest.daily.len)
            .daily
        else
            .weekly;
        const definitions = missionDefinitions(mission_type);
        const definition = definitions[
            if (mission_type == .daily)
                raw_index
            else
                raw_index - tables.quest.daily.len
        ];
        const state = findMission(mutation.read(), mission_type, definition.id) orelse
            continue;
        std.debug.assert(changes.len < changes.entries.len);
        changes.entries[changes.len] = state.*;
        changes.len += 1;
    }
}

/// Returns the IDs of daily or weekly activity rewards already claimed by the
/// player. The output slice is filled without allocating.
pub fn activeIds(
    player: *const Player,
    mission_type: tables.quest.Type,
    output: []u32,
) []u32 {
    const definitions = activeDefinitions(mission_type);
    std.debug.assert(output.len >= definitions.len);
    const bits = activeRewardBits(player, mission_type);
    var count: usize = 0;
    for (definitions, 0..) |definition, index| {
        if ((bits & (@as(u8, 1) << @intCast(index))) == 0)
            continue;
        output[count] = definition.id;
        count += 1;
    }

    return output[0..count];
}

/// Returns the activity points earned by claimed missions in one track.
pub fn activePoints(player: *const Player, mission_type: tables.quest.Type) u32 {
    var points: u32 = 0;
    for (missionDefinitions(mission_type)) |definition| {
        const state = findMission(player, mission_type, definition.id) orelse
            continue;
        if (state.claimed)
            points +|= definition.active;
    }

    return points;
}

/// Claims one mission, or every completed mission in the selected track when
/// `id` is 0. Rewards are added to the player and recorded for ChangeInfo.
pub fn claim(
    mutation: *Mutation,
    allocator: Allocator,
    now: i64,
    mission_type: tables.quest.Type,
    id: u32,
    receipt: *reward.ResourceReceipt,
) ClaimError!usize {
    receipt.* = .{};
    const definitions = missionDefinitions(mission_type);

    if (id != 0) {
        const definition = definitionFor(mission_type, id) orelse
            return error.InvalidMission;
        const state = findMission(mutation.read(), mission_type, id) orelse
            return error.InvalidMission;
        try validateClaim(state, definition, now);
    } else {
        var claimable = false;

        for (definitions) |definition| {
            const state = findMission(mutation.read(), mission_type, definition.id) orelse
                continue;
            if (isClaimable(state, definition, now)) {
                claimable = true;
                break;
            }
        }

        if (!claimable)
            return error.MissionNotComplete;
    }

    var claimed: usize = 0;
    for (definitions) |definition| {
        if (id != 0 and definition.id != id)
            continue;
        const state = findMission(mutation.read(), mission_type, definition.id) orelse
            continue;
        if (!isClaimable(state, definition, now))
            continue;

        try grantMissionReward(mutation, allocator, receipt, definition);
        const writable = mutation.modify(.{});
        const writable_state = findMissionMut(writable, mission_type, definition.id) orelse unreachable;
        writable_state.claimed = true;
        mutation.recordMission(mission_type, definition.id);
        claimed += 1;
    }

    return claimed;
}

/// Claims all newly unlocked activity rewards for one track.
pub fn claimActive(
    mutation: *Mutation,
    allocator: Allocator,
    mission_type: tables.quest.Type,
    result: *ActiveClaim,
) ClaimError!void {
    result.* = .{};
    const definitions = activeDefinitions(mission_type);
    const bits = activeRewardBits(mutation.read(), mission_type);
    const points = activePoints(mutation.read(), mission_type);

    var claimable = false;
    for (definitions, 0..) |definition, index| {
        if ((bits & (@as(u8, 1) << @intCast(index))) != 0 or
            points < definition.required_active or
            definition.reward_count == 0)
            continue;
        claimable = true;
        break;
    }
    if (!claimable)
        return error.NoActiveRewards;

    for (definitions, 0..) |definition, index| {
        if ((bits & (@as(u8, 1) << @intCast(index))) != 0 or
            points < definition.required_active)
            continue;

        for (definition.rewards[0..definition.reward_count]) |entry| {
            if (entry.id == 0 or entry.quantity <= 0)
                return error.InvalidMission;
            if (tables.item.isResource(entry.id))
                try reward.grantResource(
                    mutation,
                    allocator,
                    &result.rewards,
                    entry.id,
                    entry.quantity,
                )
            else
                try reward.grantItem(
                    mutation,
                    allocator,
                    &result.rewards,
                    entry.id,
                    entry.quantity,
                );
        }

        const writable = mutation.modify(.{});
        setActiveRewardClaimed(writable, mission_type, index);
        std.debug.assert(result.count < result.ids.len);
        result.ids[result.count] = definition.id;
        result.count += 1;
    }
}

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
    const daily_needs_refresh = dailyNeedsRefresh(player, now);
    const weekly_needs_refresh = definitionsNeedRefresh(player, &tables.quest.weekly, now);
    if (!daily_needs_refresh and !weekly_needs_refresh)
        return false;

    const writable = mutation.modify(.{});
    var changed = false;

    if (daily_needs_refresh) {
        const result = try refreshDailyDefinitions(
            writable,
            allocator,
            now,
            reset.nextDaily(now),
        );
        if (result.reset)
            writable.progress.daily_active_reward_bits = 0;
        changed = changed or result.changed;
    }

    if (weekly_needs_refresh) {
        const weekly_changed = try refreshDefinitions(
            writable,
            allocator,
            &tables.quest.weekly,
            now,
            reset.nextWeekly(now),
        );
        if (weekly_changed)
            writable.progress.weekly_active_reward_bits = 0;
        changed = changed or weekly_changed;
    }

    return changed;
}

fn refreshDailyWeeklyMissionsPlayer(player: *Player, allocator: Allocator, now: i64) !bool {
    const daily_result = try refreshDailyDefinitions(
        player,
        allocator,
        now,
        reset.nextDaily(now),
    );
    if (daily_result.reset)
        player.progress.daily_active_reward_bits = 0;

    const weekly_changed = try refreshDefinitions(
        player,
        allocator,
        &tables.quest.weekly,
        now,
        reset.nextWeekly(now),
    );
    if (weekly_changed)
        player.progress.weekly_active_reward_bits = 0;

    return daily_result.changed or weekly_changed;
}

const DailyRefresh = struct {
    changed: bool,
    reset: bool,
};

fn dailyNeedsRefresh(player: *const Player, now: i64) bool {
    var selected: [tables.quest.daily.len]bool = undefined;
    selectDaily(player.uid orelse 0, reset.dayIndex(now), &selected);

    for (selected, 0..) |is_selected, index| {
        if (!is_selected)
            continue;

        const definition = tables.quest.daily[index];
        const quest = findMission(player, .daily, definition.id) orelse
            return true;

        if (quest.condition != definition.condition or
            quest.condition_param != definition.condition_param or
            quest.progress_max != definition.progress_max or
            quest.expires_at <= now)
            return true;
    }

    return false;
}

fn refreshDailyDefinitions(
    player: *Player,
    allocator: Allocator,
    now: i64,
    expires_at: i64,
) Allocator.Error!DailyRefresh {
    var selected: [tables.quest.daily.len]bool = undefined;
    selectDaily(player.uid orelse 0, reset.dayIndex(now), &selected);

    var changed = false;
    var reset_cycle = false;
    var index: usize = 0;

    while (index < player.quests.len) {
        const quest = &player.quests.entries[index];
        if (quest.quest_type != @intFromEnum(tables.quest.Type.daily)) {
            index += 1;
            continue;
        }

        const definition_index = dailyDefinitionIndex(quest.id) orelse {
            index += 1;
            continue;
        };

        if (!selected[definition_index]) {
            _ = player.quests.swapRemove(index);
            changed = true;
            continue;
        }

        const definition = tables.quest.daily[definition_index];
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

        if (quest.expires_at != expires_at) {
            const expired = quest.expires_at <= now;
            quest.expires_at = expires_at;
            quest.progress_current = 0;
            quest.claimed = false;
            changed = true;
            if (expired)
                reset_cycle = true;
        }

        index += 1;
    }

    for (selected, 0..) |is_selected, definition_index| {
        if (!is_selected)
            continue;

        if (findMission(player, .daily, tables.quest.daily[definition_index].id) != null)
            continue;

        try appendDefinition(
            player,
            allocator,
            tables.quest.daily[definition_index],
            expires_at,
        );
        changed = true;
    }

    return .{
        .changed = changed,
        .reset = reset_cycle,
    };
}

fn dailyDefinitionIndex(id: u32) ?usize {
    for (tables.quest.daily, 0..) |definition, index| {
        if (definition.id == id)
            return index;
    }

    return null;
}

/// Picks the rotating daily missions. The official selector is unknown; this
/// keeps the observed per-player, per-day behavior stable without storing more
/// state in the player save.
fn selectDaily(uid: u64, day: i64, selected: *[tables.quest.daily.len]bool) void {
    @memset(selected, false);

    var candidates: [tables.quest.daily_rotating.len]usize = undefined;
    var candidate_count: usize = 0;
    for (tables.quest.daily, 0..) |definition, index| {
        if (definition.daily_fixed) {
            selected[index] = true;
        } else {
            candidates[candidate_count] = index;
            candidate_count += 1;
        }
    }

    std.debug.assert(candidate_count == candidates.len);

    var state = uid ^ @as(u64, @bitCast(day));
    var remaining = candidate_count;
    var selected_count: usize = 0;
    while (selected_count < tables.quest.daily_rotation_count) : (selected_count += 1) {
        const candidate = @as(usize, @intCast(nextDailyRandom(&state) % remaining));
        selected[candidates[candidate]] = true;
        remaining -= 1;
        candidates[candidate] = candidates[remaining];
    }
}

fn nextDailyRandom(state: *u64) u64 {
    state.* +%= 0x9e3779b97f4a7c15;
    var value = state.*;
    value = (value ^ (value >> 30)) *% 0xbf58476d1ce4e5b9;
    value = (value ^ (value >> 27)) *% 0x94d049bb133111eb;
    return value ^ (value >> 31);
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

fn missionDefinitions(mission_type: tables.quest.Type) []const tables.quest.Definition {
    return switch (mission_type) {
        .daily => tables.quest.daily[0..],
        .weekly => tables.quest.weekly[0..],
        else => unreachable,
    };
}

fn activeDefinitions(mission_type: tables.quest.Type) []const tables.quest.ActiveReward {
    return switch (mission_type) {
        .daily => tables.quest.daily_active[0..],
        .weekly => tables.quest.weekly_active[0..],
        else => unreachable,
    };
}

fn missionType(raw_type: u8) ?tables.quest.Type {
    if (raw_type == @intFromEnum(tables.quest.Type.daily))
        return .daily;
    if (raw_type == @intFromEnum(tables.quest.Type.weekly))
        return .weekly;
    return null;
}

fn matches(
    state: Player.Quest,
    condition: Condition,
    parameter_value: u32,
) bool {
    return missionType(state.quest_type) != null and
        !state.claimed and
        state.progress_current < state.progress_max and
        state.condition == @intFromEnum(condition) and
        (state.condition_param == 0 or state.condition_param == parameter_value);
}

fn findMission(
    player: *const Player,
    mission_type: tables.quest.Type,
    id: u32,
) ?*const Player.Quest {
    const raw_type = @intFromEnum(mission_type);
    for (player.quests.slice()) |*state| {
        if (state.quest_type == raw_type and state.id == id)
            return state;
    }

    return null;
}

fn findMissionMut(
    player: *Player,
    mission_type: tables.quest.Type,
    id: u32,
) ?*Player.Quest {
    const raw_type = @intFromEnum(mission_type);
    for (player.quests.mutableSlice()) |*state| {
        if (state.quest_type == raw_type and state.id == id)
            return state;
    }

    return null;
}

fn definitionFor(
    mission_type: tables.quest.Type,
    id: u32,
) ?tables.quest.Definition {
    for (missionDefinitions(mission_type)) |definition| {
        if (definition.id == id)
            return definition;
    }

    return null;
}

fn isClaimable(
    state: *const Player.Quest,
    definition: tables.quest.Definition,
    now: i64,
) bool {
    return !isExpired(state, now) and
        !state.claimed and
        state.progress_current >= state.progress_max and
        definition.reward_id != 0 and
        definition.reward_quantity > 0;
}

fn isExpired(state: *const Player.Quest, now: i64) bool {
    return state.expires_at != 0 and state.expires_at <= now;
}

fn validateClaim(
    state: *const Player.Quest,
    definition: tables.quest.Definition,
    now: i64,
) ClaimError!void {
    if (isExpired(state, now))
        return error.MissionExpired;
    if (state.claimed)
        return error.MissionAlreadyClaimed;
    if (state.progress_current < state.progress_max)
        return error.MissionNotComplete;
    if (definition.reward_id == 0 or definition.reward_quantity <= 0)
        return error.InvalidMission;
}

fn grantMissionReward(
    mutation: *Mutation,
    allocator: Allocator,
    receipt: *reward.ResourceReceipt,
    definition: tables.quest.Definition,
) reward.Error!void {
    if (tables.item.isResource(definition.reward_id))
        return reward.grantResource(
            mutation,
            allocator,
            receipt,
            definition.reward_id,
            definition.reward_quantity,
        );

    return reward.grantItem(
        mutation,
        allocator,
        receipt,
        definition.reward_id,
        definition.reward_quantity,
    );
}

fn activeRewardBits(player: *const Player, mission_type: tables.quest.Type) u8 {
    return switch (mission_type) {
        .daily => player.progress.daily_active_reward_bits,
        .weekly => player.progress.weekly_active_reward_bits,
        else => unreachable,
    };
}

fn setActiveRewardClaimed(
    player: *Player,
    mission_type: tables.quest.Type,
    index: usize,
) void {
    std.debug.assert(index < @bitSizeOf(u8));
    const mask: u8 = @as(u8, 1) << @intCast(index);
    switch (mission_type) {
        .daily => player.progress.daily_active_reward_bits |= mask,
        .weekly => player.progress.weekly_active_reward_bits |= mask,
        else => unreachable,
    }
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

//

test "daily and weekly missions track supported actions" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try initialize(&player, testing.allocator, 100);

    var mutation: Mutation = .init(&player);
    trigger(&mutation, .battle_total, 11, 0);

    try testing.expectEqual(@as(u32, 5), findMission(&player, .daily, 1003).?.progress_current);
    try testing.expectEqual(@as(u32, 10), findMission(&player, .weekly, 1005).?.progress_current);
    try testing.expectEqual(@as(u32, 11), findMission(&player, .weekly, 1006).?.progress_current);
    try testing.expectEqual(@as(u32, 11), findMission(&player, .weekly, 1007).?.progress_current);

    var changes: MissionChanges = .{};
    collectMissionChanges(&mutation, &changes);
    try testing.expectEqual(@as(usize, 4), changes.len);

    trigger(&mutation, .battle_total, 100, 0);
    try testing.expectEqual(@as(u32, 10), findMission(&player, .weekly, 1005).?.progress_current);
    try testing.expectEqual(@as(u32, 20), findMission(&player, .weekly, 1006).?.progress_current);
    try testing.expectEqual(@as(u32, 40), findMission(&player, .weekly, 1007).?.progress_current);
}

test "daily missions keep fixed entries and a stable rotating pair" {
    const testing = std.testing;

    const now: i64 = 100;

    var first = Player.init(1);
    defer first.deinit(testing.allocator);
    try initialize(&first, testing.allocator, now);

    var second = Player.init(1);
    defer second.deinit(testing.allocator);
    try initialize(&second, testing.allocator, now);

    var daily_count: usize = 0;
    var fixed_count: usize = 0;
    var rotating_ids: [tables.quest.daily_rotation_count]u32 = undefined;
    var rotating_count: usize = 0;
    for (first.quests.slice()) |state| {
        if (state.quest_type != @intFromEnum(tables.quest.Type.daily))
            continue;

        daily_count += 1;
        const definition = definitionFor(.daily, state.id).?;
        if (definition.daily_fixed) {
            fixed_count += 1;
        } else {
            rotating_ids[rotating_count] = state.id;
            rotating_count += 1;
        }
    }

    try testing.expectEqual(tables.quest.daily_refresh_count, daily_count);
    try testing.expectEqual(tables.quest.daily_fixed.len, fixed_count);
    try testing.expectEqual(tables.quest.daily_rotation_count, rotating_count);

    for (rotating_ids[0..rotating_count]) |id|
        try testing.expect(findMission(&second, .daily, id) != null);
}

test "daily refresh rotates missions at the reset" {
    const testing = std.testing;

    const created_at: i64 = 100;
    const reset_at = reset.nextDaily(created_at);

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try initialize(&player, testing.allocator, created_at);

    findMissionMut(&player, .daily, 1001).?.progress_current = 1;
    player.progress.daily_active_reward_bits = 1;

    var mutation: Mutation = .init(&player);
    try testing.expect(try refreshDailyWeeklyMissions(&mutation, testing.allocator, reset_at));

    var daily_count: usize = 0;
    for (player.quests.slice()) |state| {
        if (state.quest_type == @intFromEnum(tables.quest.Type.daily))
            daily_count += 1;
    }
    try testing.expectEqual(tables.quest.daily_refresh_count, daily_count);
    try testing.expectEqual(@as(u32, 0), findMission(&player, .daily, 1001).?.progress_current);
    try testing.expectEqual(@as(u8, 0), player.progress.daily_active_reward_bits);

    var selected: [tables.quest.daily.len]bool = undefined;
    selectDaily(player.uid orelse 0, reset.dayIndex(reset_at), &selected);
    for (tables.quest.daily, 0..) |definition, index| {
        const state = findMission(&player, .daily, definition.id);
        try testing.expectEqual(selected[index], state != null);
    }
}

test "login mission progress is counted once per reset day" {
    const testing = std.testing;

    const now: i64 = 100;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try initialize(&player, testing.allocator, now);

    var mutation: Mutation = .init(&player);
    try login(&mutation, testing.allocator, now);

    try testing.expectEqual(reset.dayIndex(now), player.progress.last_login_day);
    try testing.expectEqual(@as(u32, 1), findMission(&player, .daily, 1001).?.progress_current);
    try testing.expectEqual(@as(u32, 1), findMission(&player, .weekly, 1001).?.progress_current);
    try testing.expectEqual(@as(u32, 1), findMission(&player, .weekly, 1002).?.progress_current);

    var next_request: Mutation = .init(&player);
    try login(&next_request, testing.allocator, now);
    try testing.expectEqual(@as(u32, 1), findMission(&player, .daily, 1001).?.progress_current);
    try testing.expectEqual(@as(u32, 1), findMission(&player, .weekly, 1001).?.progress_current);
    try testing.expect(!next_request.isDirty());
}

test "mission claims grant rewards and reject a second claim" {
    const testing = std.testing;

    const now: i64 = 100;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try initialize(&player, testing.allocator, now);

    var mutation: Mutation = .init(&player);
    const writable = mutation.modify(.{});
    const state = findMissionMut(writable, .daily, 1001).?;
    state.progress_current = state.progress_max;

    var receipt: reward.ResourceReceipt = .{};
    try testing.expectEqual(
        @as(usize, 1),
        try claim(&mutation, testing.allocator, now, .daily, 1001, &receipt),
    );
    try testing.expectEqual(@as(i32, 10_000), player.resourceQuantity(1));
    try testing.expect(findMission(&player, .daily, 1001).?.claimed);
    try testing.expectEqual(@as(i32, 10_000), receipt.resource_deltas.entries[0].quantity);

    var second_mutation: Mutation = .init(&player);
    var second_receipt: reward.ResourceReceipt = .{};
    try testing.expectError(
        error.MissionAlreadyClaimed,
        claim(&second_mutation, testing.allocator, now, .daily, 1001, &second_receipt),
    );
}

test "activity rewards are claimed once when enough missions are complete" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try initialize(&player, testing.allocator, 100);

    var mutation: Mutation = .init(&player);
    const writable = mutation.modify(.{});
    findMissionMut(writable, .daily, 1001).?.claimed = true;
    findMissionMut(writable, .daily, 1002).?.claimed = true;

    var result: ActiveClaim = .{};
    try claimActive(&mutation, testing.allocator, .daily, &result);
    try testing.expectEqual(@as(usize, 1), result.count);
    try testing.expectEqual(@as(u32, 1), result.ids[0]);
    try testing.expectEqual(@as(usize, 2), result.rewards.item_delta_count);
    try testing.expectEqual(@as(u32, 1), player.progress.daily_active_reward_bits & 1);

    var second_mutation: Mutation = .init(&player);
    var second_result: ActiveClaim = .{};
    try testing.expectError(
        error.NoActiveRewards,
        claimActive(&second_mutation, testing.allocator, .daily, &second_result),
    );
}

test "daily refresh clears activity rewards at the reset" {
    const testing = std.testing;

    const created_at: i64 = 100;
    const reset_at = reset.nextDaily(created_at);

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    try initialize(&player, testing.allocator, created_at);
    player.progress.daily_active_reward_bits = 1;
    findMissionMut(&player, .daily, 1001).?.progress_current = 1;

    var mutation: Mutation = .init(&player);
    try testing.expect(try refreshDailyWeeklyMissions(&mutation, testing.allocator, reset_at));
    try testing.expectEqual(@as(u8, 0), player.progress.daily_active_reward_bits);
    try testing.expectEqual(@as(u32, 0), findMission(&player, .daily, 1001).?.progress_current);
}
