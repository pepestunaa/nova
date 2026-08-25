const raw_activities = @import("tables/Activity");
const raw_groups = @import("tables/PeriodicQuestGroup");
const raw_quests = @import("tables/PeriodicQuest");

const group_count: usize = raw_groups.len;
const quest_count: usize = raw_quests.len;

//

pub const activity_id: u32 = blk: {
    if (quest_count == 0)
        @compileError("PeriodicQuest contains no definitions");

    const id = raw_quests[0].belong;
    for (raw_quests) |quest| {
        if (quest.belong != id)
            @compileError("PeriodicQuest definitions belong to multiple activities");
    }
    for (raw_groups) |group| {
        if (group.value.belong != id)
            @compileError("PeriodicQuestGroup definitions belong to multiple activities");
    }

    var found = false;
    for (raw_activities) |activity| {
        if (activity.id != id)
            continue;

        found = true;

        break;
    }
    if (!found)
        @compileError("PeriodicQuest activity is missing from Activity");

    break :blk id;
};

pub const Definition = struct {
    id: u32,
    group_id: u8,
};

pub const Group = struct {
    id: u8,
    unlock_day: u8,
};

pub const list: [quest_count]Definition = blk: {
    var definitions: [quest_count]Definition = undefined;
    for (raw_quests, 0..) |raw, index| {
        if (raw.belong != activity_id)
            @compileError("PeriodicQuest contains an unexpected activity");

        definitions[index] = .{
            .id = raw.id,
            .group_id = @intCast(raw.groupid),
        };
    }

    break :blk definitions;
};

pub const groups: [group_count]Group = blk: {
    var result: [group_count]Group = undefined;
    for (raw_groups, 0..) |raw, index| {
        if (raw.value.belong != activity_id)
            @compileError("PeriodicQuestGroup contains an unexpected activity");

        result[index] = .{
            .id = @intCast(raw.value.group_id),
            .unlock_day = if (@hasField(@TypeOf(raw.value), "unlock_time"))
                @intCast(raw.value.unlock_time)
            else
                0,
        };
    }

    break :blk result;
};
