const std = @import("std");

const raw_assist = @import("tables/AssistQuest");
const raw_daily = @import("tables/DailyQuest");
const raw_daily_active = @import("tables/DailyQuestActive");
const raw_tour_guide = @import("tables/TourGuideQuest");
const raw_tower_event = @import("tables/StarTowerBookEventReward");
const raw_weekly = @import("tables/WeeklyQuest");
const raw_weekly_active = @import("tables/WeeklyQuestActive");

const assist_count: usize = raw_assist.len;
const daily_count: usize = raw_daily.len;
const daily_active_count: usize = raw_daily_active.len;
const tower_event_count: usize = raw_tower_event.len;
const weekly_count: usize = raw_weekly.len;
const weekly_active_count: usize = raw_weekly_active.len;

//

pub const Type = enum(u8) {
    tour_guide = 1,
    daily = 2,
    vampire_survivor_normal = 8,
    vampire_survivor_season = 9,
    tower = 10,
    tower_event = 12,
    weekly = 13,
    assist = 14,
};

/// Completion condition used when the player interacts with a Monolith event
/// NPC.
pub const tower_event_npc_interaction_condition = 94;

pub const Definition = struct {
    id: u32,
    type: Type,
    condition: u32,
    condition_param: u32,
    progress_max: u32,
    active: u32,
    reward_id: u32,
    reward_quantity: i32,
};

pub const Reward = struct {
    id: u32,
    quantity: i32,
};

pub const ActiveReward = struct {
    id: u32,
    required_active: u32,
    rewards: [2]Reward,
    reward_count: u8,
};

pub const daily = buildConditional(raw_daily, daily_count, .daily);
pub const weekly = buildConditional(raw_weekly, weekly_count, .weekly);
pub const daily_active = buildActive(raw_daily_active, daily_active_count);
pub const weekly_active = buildActive(raw_weekly_active, weekly_active_count);

comptime {
    if (daily_active.len > @bitSizeOf(u8) or weekly_active.len > @bitSizeOf(u8))
        @compileError("daily/weekly activity reward count no longer fits in Progress' u8 bitsets");
}

pub const tower_event = buildTowerEvent(raw_tower_event, tower_event_count);
/// New official accounts receive all 5 chapters of the Ventus and Ignis
/// Lineup Tutorial tracks. `AssistQuest` defines their rewards and text, but
/// not their targets; the Lua client displays the `Cur` and `Max` values sent
/// through PlayerData and `quest_change_notify`.
///
/// These targets were captured from an official `player_data_succeed_ack`. If
/// the table changes, capture a new account and update each `Progress[0].Max`.
/// Compile-time checks reject new tracks or layouts instead of guessing.
pub const assist = buildAssist(raw_assist, assist_count);

/// The first Tour Guide group given to a new account.
pub const initial_tour_guide = blk: {
    var count: usize = 0;
    for (raw_tour_guide) |raw| {
        if (raw.order == 1000) count += 1;
    }

    var definitions: [count]Definition = undefined;
    var index: usize = 0;
    for (raw_tour_guide) |raw| {
        if (raw.order != 1000)
            continue;
        definitions[index] = .{
            .id = raw.id,
            .type = .tour_guide,
            .condition = 0,
            .condition_param = 0,
            .progress_max = 1,
            .active = 0,
            .reward_id = 0,
            .reward_quantity = 0,
        };
        index += 1;
    }

    break :blk definitions;
};

fn buildConditional(
    comptime raw_list: anytype,
    comptime raw_count: usize,
    comptime quest_type: Type,
) [raw_count]Definition {
    var definitions: [raw_count]Definition = undefined;
    for (raw_list, 0..) |raw, index| definitions[index] = .{
        .id = raw.id,
        .type = quest_type,
        .condition = raw.complete_cond,
        .condition_param = parameter(raw.complete_cond_params, 1),
        .progress_max = parameter(raw.complete_cond_params, 0),
        .active = raw.active,
        .reward_id = raw.item_tid,
        .reward_quantity = raw.item_qty,
    };

    return definitions;
}

fn buildActive(
    comptime raw_list: anytype,
    comptime raw_count: usize,
) [raw_count]ActiveReward {
    var definitions: [raw_count]ActiveReward = undefined;
    for (raw_list, 0..) |raw, index| {
        var rewards: [2]Reward = @splat(.{ .id = 0, .quantity = 0 });
        var reward_count: u8 = 0;
        if (raw.item_tid1 != 0) {
            rewards[reward_count] = .{ .id = raw.item_tid1, .quantity = raw.number1 };
            reward_count += 1;
        }
        if (comptime @hasField(@TypeOf(raw), "item_tid2")) {
            if (raw.item_tid2 != 0) {
                rewards[reward_count] = .{ .id = raw.item_tid2, .quantity = raw.number2 };
                reward_count += 1;
            }
        }
        definitions[index] = .{
            .id = raw.id,
            .required_active = raw.active,
            .rewards = rewards,
            .reward_count = reward_count,
        };
    }

    return definitions;
}

fn buildTowerEvent(
    comptime raw_list: anytype,
    comptime raw_count: usize,
) [raw_count]Definition {
    @setEvalBranchQuota(100_000);

    var definitions: [raw_count]Definition = undefined;
    for (raw_list, 0..) |raw, index| definitions[index] = .{
        .id = raw.id,
        .type = .tower_event,
        .condition = raw.complete_cond,
        .condition_param = parameter(raw.complete_cond_params, 0),
        .progress_max = parameter(raw.complete_cond_params, 1),
        .active = 0,
        .reward_id = 0,
        .reward_quantity = 0,
    };

    return definitions;
}

fn buildAssist(
    comptime raw_list: anytype,
    comptime raw_count: usize,
) [raw_count]Definition {
    const track_count = 2;
    const quests_per_track = 39;
    var track_quest_counts: [track_count]usize = @splat(0);
    var definitions: [raw_count]Definition = undefined;
    for (raw_list, 0..) |raw, index| {
        const track = raw.id / 100_000;
        if (track < 1 or track > track_count)
            @compileError(std.fmt.comptimePrint(
                "unsupported Lineup Tutorial track in AssistQuest ID {d}; capture the official initial PlayerData before adding it",
                .{raw.id},
            ));
        track_quest_counts[track - 1] += 1;
        definitions[index] = .{
            .id = raw.id,
            .type = .assist,
            .condition = 0,
            .condition_param = 0,
            .progress_max = assistTarget(raw.id),
            .active = 0,
            .reward_id = 0,
            .reward_quantity = 0,
        };
    }
    for (track_quest_counts, 1..) |count, track| {
        if (count != quests_per_track)
            @compileError(std.fmt.comptimePrint(
                "Lineup Tutorial track {d} has {d} AssistQuest entries, expected {d}; recapture the official initial PlayerData",
                .{ track, count, quests_per_track },
            ));
    }

    return definitions;
}

/// Captured `Progress[0].Max` values for every Lineup Tutorial task. Both
/// element tracks share a layout: `100xxx` and `200xxx` select the track, the
/// middle digits select the chapter, and the final 2 select the task.
fn assistTarget(comptime id: u32) u32 {
    const track = id / 100_000;
    if (track < 1 or track > 2)
        @compileError(std.fmt.comptimePrint("unsupported Lineup Tutorial track in AssistQuest ID {d}", .{id}));
    const chapter = (id % 1000) / 100;
    const objective = (id % 100) - 1;
    const targets = switch (chapter) {
        1 => &.{ 1, 10, 1, 10, 1 },
        2 => &.{ 2, 1, 1, 1, 1, 20, 20, 20 },
        3 => &.{ 1, 4, 3, 1, 1, 1, 3, 3, 1, 1 },
        4 => &.{ 6, 1, 1, 1, 3, 3, 1, 1 },
        5 => &.{ 8, 1, 1, 1, 3, 3, 1, 1 },
        else => @compileError(std.fmt.comptimePrint("unknown AssistQuest chapter in ID {d}", .{id})),
    };
    if (objective >= targets.len)
        @compileError(std.fmt.comptimePrint("unknown AssistQuest objective ID {d}", .{id}));

    return targets[objective];
}

/// Reads a value from a compact parameter list such as `[3,1005]`.
fn parameter(comptime text: []const u8, comptime wanted_index: usize) u32 {
    var value: u32 = 0;
    var index: usize = 0;
    var found: usize = 0;
    var reading = false;

    while (index < text.len) : (index += 1) {
        const byte = text[index];
        if (byte >= '0' and byte <= '9') {
            value = value * 10 + byte - '0';
            reading = true;

            continue;
        }

        if (!reading)
            continue;

        if (found == wanted_index)
            return value;

        found += 1;
        value = 0;
        reading = false;
    }

    if (reading and found == wanted_index)
        return value;

    return 0;
}
