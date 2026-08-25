const raw_potential_rewards = @import("tables/StarTowerBookPotentialReward");
const raw_event_rewards = @import("tables/StarTowerBookEventReward");

const event_reward_count: usize = raw_event_rewards.len;
const potential_reward_count: usize = raw_potential_rewards.len;

//

pub const PotentialReward = struct {
    id: u32,
    character_id: u32,
    potential_count: u32,
    item_id: u32,
    item_quantity: i32,
};

pub const potential_rewards = blk: {
    @setEvalBranchQuota(100_000);

    var list: [potential_reward_count]PotentialReward = undefined;
    for (raw_potential_rewards, 0..) |raw, index| list[index] = .{
        .id = raw.id,
        .character_id = raw.char_id,
        .potential_count = parameter(raw.params, 1),
        .item_id = raw.item_id,
        .item_quantity = raw.item_qty,
    };

    break :blk list;
};

pub const EventReward = struct {
    id: u32,
    npc_id: u32,
    item_id: u32,
    item_quantity: i32,
};

pub const event_rewards = blk: {
    var list: [event_reward_count]EventReward = undefined;
    for (raw_event_rewards, 0..) |raw, index| list[index] = .{
        .id = raw.id,
        .npc_id = raw.npc_id,
        .item_id = raw.item_id,
        .item_quantity = raw.item_qty,
    };

    break :blk list;
};

pub fn potentialReward(id: u32) ?PotentialReward {
    for (potential_rewards) |entry| if (entry.id == id)
        return entry;

    return null;
}

pub fn eventReward(id: u32) ?EventReward {
    for (event_rewards) |entry| if (entry.id == id)
        return entry;

    return null;
}

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

    return if (reading and found == wanted_index) value else 0;
}
