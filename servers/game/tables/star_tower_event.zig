const raw_events = @import("tables/StarTowerEvent");
const raw_options = @import("tables/EventOptions");
const raw_results = @import("tables/EventResult");

//

pub const max_options = 9;

pub const Event = struct {
    id: u32,
    npc_id: u32,
    options: [max_options]u32,
    option_count: u8,
};

const Definition = struct {
    id: u32,
    npc_ids: [4]u32,
    options: [max_options]u32,
    option_count: u8,
};

const definitions = blk: {
    @setEvalBranchQuota(100_000);

    var list: [raw_events.len]Definition = undefined;
    for (raw_events, 0..) |raw_event, index| {
        var candidates: [max_options]u32 = undefined;
        var candidate_count: usize = 0;
        for (raw_options) |option| {
            if (option.id / 100 != raw_event.id)
                continue;
            candidates[candidate_count] = option.id;
            candidate_count += 1;
        }

        var options: [max_options]u32 = @splat(0);
        const option_count = @min(candidate_count, options.len);
        @memcpy(options[0..option_count], candidates[0..option_count]);

        list[index] = .{
            .id = raw_event.id,
            .npc_ids = raw_event.related_np_cs,
            .options = options,
            .option_count = @intCast(option_count),
        };
    }

    break :blk list;
};

pub const Outcome = struct {
    option_id: u32,
    coin_delta: i32 = 0,
    potential_kind: u32 = 0,
    potential_character_position: u32 = 0,
    note_id: u32 = 0,
    note_quantity: u32 = 0,
    random_note: bool = false,
    note_cost: u32 = 0,
    message_id: u32 = 0,
    recovery_effect_id: u32 = 0,
};

const outcomes = blk: {
    @setEvalBranchQuota(100_000);

    var list: [raw_results.len]Outcome = undefined;
    for (raw_results, 0..) |result, index| {
        var entry: Outcome = .{ .option_id = result.id / 100 };
        applyEffect(&entry, result.effect1, parameters(result, "parameter1"));
        if (@hasField(@TypeOf(result), "effect2"))
            applyEffect(&entry, result.effect2, parameters(result, "parameter2"));
        if (@hasField(@TypeOf(result), "effect3"))
            applyEffect(&entry, result.effect3, parameters(result, "parameter3"));
        list[index] = entry;
    }

    break :blk list;
};

comptime {
    @setEvalBranchQuota(100_000);

    // Event results change server-owned Ascension state. Fail the build if new
    // data introduces an effect the server would otherwise ignore.
    for (raw_results) |result| {
        validateEffect(result.effect1);
        if (@hasField(@TypeOf(result), "effect2")) validateEffect(result.effect2);
        if (@hasField(@TypeOf(result), "effect3")) validateEffect(result.effect3);
    }
}

pub const count = definitions.len;

pub fn event(index: usize, npc_index: usize) Event {
    const definition = definitions[index];

    return .{
        .id = definition.id,
        .npc_id = definition.npc_ids[npc_index],
        .options = definition.options,
        .option_count = definition.option_count,
    };
}

pub fn outcomeCount(option_id: u32) usize {
    var matching_count: usize = 0;
    for (outcomes) |result| {
        if (result.option_id == option_id) matching_count += 1;
    }

    return matching_count;
}

pub fn outcome(option_id: u32, index: usize) ?Outcome {
    var matching_index: usize = 0;
    for (outcomes) |result| {
        if (result.option_id != option_id)
            continue;
        if (matching_index == index)
            return result;
        matching_index += 1;
    }

    return null;
}

fn applyEffect(entry: *Outcome, effect: u32, params: [2]u32) void {
    switch (effect) {
        1 => entry.coin_delta += @intCast(params[0]),
        5, 6 => entry.coin_delta -= @intCast(params[0]),
        3 => {
            entry.potential_kind = params[0];
            entry.potential_character_position = params[1];
        },
        17 => {
            entry.random_note = true;
            entry.note_quantity = params[0];
        },
        18 => {
            entry.note_id = params[0];
            entry.note_quantity = params[1];
        },
        19 => entry.note_cost += params[0],
        16 => entry.message_id = params[0],
        14 => entry.recovery_effect_id = params[0],
        else => {},
    }
}

fn validateEffect(effect: u32) void {
    switch (effect) {
        1, 3, 5, 6, 14, 16, 17, 18, 19 => {},
        else => @compileError("EventResult contains an unsupported Ascension event effect"),
    }
}

fn parameters(comptime result: anytype, comptime field_name: []const u8) [2]u32 {
    if (!@hasField(@TypeOf(result), field_name))
        return .{ 0, 0 };

    var result_params: [2]u32 = .{ 0, 0 };
    for (@field(result, field_name), 0..) |value, index| {
        if (index == result_params.len)
            break;
        result_params[index] = value;
    }

    return result_params;
}
