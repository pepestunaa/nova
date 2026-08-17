const std = @import("std");

const items = @import("item.zig");

const raw_groups = @import("tables/NPCAffinityGroup");

//

pub const Reward = struct {
    item_id: u32,
    quantity: i32,
    is_resource: bool,
};

pub const Entry = struct {
    npc_id: u32,
    threshold: u32,
    reward: Reward,
};

pub const list = blk: {
    @setEvalBranchQuota(1_000_000);

    var entries: [entryCount()]Entry = undefined;
    var index: usize = 0;
    for (raw_groups) |raw| {
        if (!@hasField(@TypeOf(raw), "level") or !@hasField(@TypeOf(raw), "reward"))
            continue;
        entries[index] = .{
            .npc_id = raw.affinity_group_id,
            .threshold = raw.affinity_value,
            .reward = parseReward(raw.reward),
        };
        index += 1;
    }

    break :blk entries;
};

fn entryCount() usize {
    var count: usize = 0;
    inline for (raw_groups) |raw| {
        if (@hasField(@TypeOf(raw), "level") and @hasField(@TypeOf(raw), "reward"))
            count += 1;
    }

    return count;
}

fn parseReward(comptime text: []const u8) Reward {
    const prefix = "{\"";
    const separator = "\":";
    if (comptime !std.mem.startsWith(u8, text, prefix) or !std.mem.endsWith(u8, text, "}"))
        @compileError("invalid NPCAffinityGroup reward");

    const separator_index = comptime std.mem.indexOf(
        u8,
        text[prefix.len..],
        separator,
    ).?;
    const key_end = prefix.len + separator_index;
    const value_start = key_end + separator.len;
    const item_id = comptime std.fmt.parseInt(
        u32,
        text[prefix.len..key_end],
        10,
    ) catch unreachable;

    return .{
        .item_id = item_id,
        .quantity = comptime std.fmt.parseInt(
            i32,
            text[value_start .. text.len - 1],
            10,
        ) catch unreachable,
        .is_resource = items.isResource(item_id),
    };
}
