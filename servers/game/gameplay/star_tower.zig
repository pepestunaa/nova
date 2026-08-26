const std = @import("std");

const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");
const tower_growth = @import("tower_growth.zig");

//

pub const generic_recovery_effect_id = 989970;

const strengthen_machine_costs = tables.config.unsignedList(u32, "StrengthenMachineGoldConsume");
var next_run_seed: std.atomic.Value(u64) = .init(1);

pub const SecondaryChange = struct {
    id: u32,
    active: bool,
};

pub const TeamProgress = struct { level: u32, exp: u32 };

/// Returns the NPC Affinity reward for a threshold crossed by a gain.
pub fn crossedNpcAffinityReward(npc_id: u32, before: u32, after: u32) ?tables.star_tower_affinity.Reward {
    for (tables.star_tower_affinity.list) |entry| {
        if (entry.npc_id != npc_id)
            continue;
        if (entry.threshold <= before or entry.threshold > after)
            continue;

        return entry.reward;
    }

    return null;
}

pub fn findDisc(player: *const Player, id: u32) ?*const Player.Disc {
    for (player.discs.slice()) |*disc| {
        if (disc.id == id)
            return disc;
    }

    return null;
}

pub fn collectGrowthNodes(
    player: *const Player,
    output: []u32,
) usize {
    std.debug.assert(output.len >= tables.tower_growth.list.len);
    var len: usize = 0;
    for (tables.tower_growth.list) |node| {
        if (!tower_growth.has(player, node.id))
            continue;
        output[len] = node.id;
        len += 1;
    }

    return len;
}

pub fn growthModifiers(
    player: *const Player,
    tower_id: u32,
) tower_growth.Modifiers {
    return .init(
        &player.tower_growth.details,
        tables.star_tower.difficulty(tower_id) orelse 1,
    );
}

/// Selects and shuffles a Monolith event while advancing the Ascension's saved
/// random state. Static event data stays in `tables`.
pub fn selectEvent(state: *u64) tables.star_tower_event.Event {
    var event = tables.star_tower_event.event(
        eventRandomBelow(state, tables.star_tower_event.count),
        eventRandomBelow(state, 4),
    );
    shuffle(state, event.options[0..event.option_count]);

    return event;
}

/// Chooses among an event option's possible outcomes using the saved
/// Ascension state.
pub fn selectEventOutcome(
    option_id: u32,
    state: *u64,
) ?tables.star_tower_event.Outcome {
    const count = tables.star_tower_event.outcomeCount(option_id);
    if (count == 0)
        return null;

    return tables.star_tower_event.outcome(option_id, eventRandomBelow(state, count));
}

fn shuffle(state: *u64, values: []u32) void {
    var index = values.len;
    while (index > 1) {
        index -= 1;
        const swap_index = eventRandomBelow(state, index + 1);
        const value = values[index];
        values[index] = values[swap_index];
        values[swap_index] = value;
    }
}

fn eventRandomBelow(state: *u64, limit: usize) usize {
    std.debug.assert(limit != 0);
    state.* = nextEventRandom(state.*);
    return @intCast(state.* % limit);
}

/// Events use a separate random stream so a resumed Ascension keeps its choices.
fn nextEventRandom(state: u64) u64 {
    var value = if (state == 0) @as(u64, 0x9e3779b97f4a7c15) else state;
    value ^= value >> 12;
    value ^= value << 25;
    value ^= value >> 27;

    return value *% 0x2545f4914f6cdd1d;
}

pub fn offerPotentials(
    player: *Player,
    run: *Player.StarTowerRun,
    formation: *const Player.Formation,
    core_only: bool,
    character_override: ?u32,
) u32 {
    const character_id = character_override orelse selectPotentialCharacter(run, formation);
    run.offered_potential_character_id = character_id;
    run.offered_potential_ids = selectPotentialChoices(
        character_id,
        formation.character_ids[0] == character_id,
        run.potential_ids[0..run.potential_count],
        run.potential_levels[0..run.potential_count],
        growthModifiers(player, run.tower_id).potential_level_cap_bonus,
        core_only,
        .{ nextRandom(run), nextRandom(run), nextRandom(run) },
    );
    run.offered_potential_levels = @splat(0);
    run.offered_potential_bonus_pending = @splat(false);
    run.offered_potential_count = 0;
    var butterflies_inside: u32 = 0;
    const modifiers = growthModifiers(player, run.tower_id);
    for (run.offered_potential_ids, 0..) |potential_id, index| {
        if (potential_id == 0)
            continue;
        var level: u8 = 1;
        const can_bonus = modifiers.potential_bonus_chance_per_thousand != 0 and
            (modifiers.potential_bonus_limit == 0 or
                run.potential_bonus_count < modifiers.potential_bonus_limit);
        if (can_bonus and roll(run, modifiers.potential_bonus_chance_per_thousand)) {
            level +|= modifiers.potential_bonus_levels;
            if (modifiers.defer_new_potential_bonus_consumption)
                run.offered_potential_bonus_pending[index] = true
            else {
                run.potential_bonus_count +|= 1;
                butterflies_inside += 1;
            }
        }
        run.offered_potential_levels[index] = level;
        run.offered_potential_count += 1;
    }
    run.potential_rerolls = modifiers.potential_rerolls;
    run.potential_reroll_price = modifiers.potential_reroll_price;
    run.potential_selector_is_strengthen = false;

    return butterflies_inside;
}

pub fn offerPotentialStrengthening(
    player: *const Player,
    run: *Player.StarTowerRun,
) void {
    const modifiers = growthModifiers(player, run.tower_id);
    run.offered_potential_ids = selectPotentialUpgradeChoices(
        run.potential_ids[0..run.potential_count],
        run.potential_levels[0..run.potential_count],
        modifiers.potential_level_cap_bonus,
    );
    run.offered_potential_levels = @splat(0);
    run.offered_potential_count = 0;
    var eligible_count: usize = 0;
    for (run.offered_potential_ids) |potential_id| {
        if (potential_id != 0) eligible_count += 1;
    }
    const can_bonus = modifiers.strengthen_bonus_chance_per_thousand != 0 and
        (modifiers.strengthen_bonus_limit == 0 or
            run.strengthen_bonus_count < modifiers.strengthen_bonus_limit);
    const bonus_triggered = can_bonus and roll(run, modifiers.strengthen_bonus_chance_per_thousand);
    const bonus_index: ?usize = if (bonus_triggered and !modifiers.strengthen_bonus_applies_to_all and eligible_count != 0)
        randomBelow(run, eligible_count)
    else
        null;
    if (bonus_triggered) run.strengthen_bonus_count +|= 1;
    var eligible_index: usize = 0;
    for (run.offered_potential_ids, 0..) |potential_id, index| {
        if (potential_id == 0) continue;
        var level: u8 = 1;
        if (bonus_triggered and (modifiers.strengthen_bonus_applies_to_all or bonus_index.? == eligible_index)) {
            level += 1;
        }
        run.offered_potential_levels[index] = level;
        run.offered_potential_count += 1;
        eligible_index += 1;
    }
    run.potential_rerolls = modifiers.potential_rerolls;
    run.potential_reroll_price = modifiers.potential_reroll_price;
    run.potential_selector_is_strengthen = true;
    run.offered_potential_character_id = 0;
}

pub fn strengthenMachinePrice(times: u8) u32 {
    const index = @min(@as(usize, times), strengthen_machine_costs.len - 1);
    return strengthen_machine_costs[index];
}

pub const build_auto_lock_score = tables.config.unsignedList(
    u32,
    "StarTowerBuildAutoLockScore",
)[0];

pub fn addItem(
    run: *Player.StarTowerRun,
    item_id: u32,
    quantity: u32,
) error{FullTowerInventory}!void {
    for (run.tower_item_ids[0..run.tower_item_count], 0..) |existing_id, index| {
        if (existing_id != item_id)
            continue;
        run.tower_item_quantities[index] +|= quantity;

        return;
    }
    if (run.tower_item_count == run.tower_item_ids.len)
        return error.FullTowerInventory;
    const index = run.tower_item_count;
    run.tower_item_ids[index] = item_id;
    run.tower_item_quantities[index] = quantity;
    run.tower_item_count += 1;
}

pub fn reconcileActiveSecondaries(
    run: *Player.StarTowerRun,
    formation: *const Player.Formation,
    changes: *[tables.disc_secondary.max_changes]SecondaryChange,
) []const SecondaryChange {
    var desired: [tables.disc_secondary.max_active_ids]u32 = @splat(0);
    var desired_count: usize = 0;
    for (formation.disc_ids[0..@min(formation.disc_count, tables.disc_secondary.max_combat_discs)]) |disc_id| {
        for (tables.disc_secondary.groups(disc_id)) |group_id| {
            const skill = highestSatisfiedSecondary(
                group_id,
                run.tower_item_ids[0..run.tower_item_count],
                run.tower_item_quantities[0..run.tower_item_count],
            ) orelse
                continue;
            if (containsSecondary(desired[0..desired_count], skill.id))
                continue;
            desired[desired_count] = skill.id;
            desired_count += 1;
        }
    }

    const previous_count = @min(@as(usize, run.active_secondary_count), run.active_secondary_ids.len);
    var change_count: usize = 0;
    for (run.active_secondary_ids[0..previous_count]) |id| {
        if (containsSecondary(desired[0..desired_count], id))
            continue;
        changes[change_count] = .{ .id = id, .active = false };
        change_count += 1;
    }
    for (desired[0..desired_count]) |id| {
        if (containsSecondary(run.active_secondary_ids[0..previous_count], id))
            continue;
        changes[change_count] = .{ .id = id, .active = true };
        change_count += 1;
    }

    run.active_secondary_ids = @splat(0);
    @memcpy(run.active_secondary_ids[0..desired_count], desired[0..desired_count]);
    run.active_secondary_count = @intCast(desired_count);
    return changes[0..change_count];
}

pub fn buildScore(run: *const Player.StarTowerRun) u32 {
    var score: u32 = secondaryScore(run.active_secondary_ids[0..run.active_secondary_count]);
    for (run.tower_item_ids[0..run.tower_item_count], 0..) |item_id, index|
        score +|= noteScore(item_id, run.tower_item_quantities[index]);
    for (run.potential_ids[0..run.potential_count], 0..) |potential_id, index|
        score +|= tables.potential.score(potential_id, run.potential_levels[index]);

    return score;
}

fn noteScore(id: u32, quantity: u32) u32 {
    if (quantity == 0)
        return 0;
    for (tables.star_tower_note.list) |entry| {
        if (entry.id != id)
            continue;
        const index = @min(@as(usize, quantity - 1), entry.score_count - 1);

        return entry.scores[index];
    }

    return 0;
}

fn highestSatisfiedSecondary(
    group_id: u32,
    note_ids: []const u32,
    note_quantities: []const u32,
) ?tables.disc_secondary.Skill {
    if (group_id == 0)
        return null;
    var result: ?tables.disc_secondary.Skill = null;
    for (tables.disc_secondary.skills) |skill| {
        if (skill.group_id != group_id or skill.requirement_count == 0)
            continue;
        if (!secondaryRequirementsSatisfied(skill, note_ids, note_quantities))
            continue;
        if (result == null or skill.level > result.?.level) result = skill;
    }

    return result;
}

fn secondaryRequirementsSatisfied(
    skill: tables.disc_secondary.Skill,
    note_ids: []const u32,
    note_quantities: []const u32,
) bool {
    for (skill.requirements[0..skill.requirement_count]) |requirement| {
        var quantity: u32 = 0;
        for (note_ids, note_quantities) |note_id, owned_quantity| {
            if (note_id != requirement.note_id)
                continue;
            quantity = owned_quantity;

            break;
        }
        if (quantity < requirement.quantity)
            return false;
    }

    return true;
}

fn secondaryScore(ids: []const u32) u32 {
    var total: u32 = 0;
    for (ids) |id| for (tables.disc_secondary.skills) |skill| {
        if (skill.id != id)
            continue;
        total +|= skill.score;

        break;
    };
    return total;
}

fn containsSecondary(ids: []const u32, expected: u32) bool {
    for (ids) |id| if (id == expected)
        return true;
    return false;
}

pub fn itemQuantity(run: *const Player.StarTowerRun, item_id: u32) u32 {
    for (run.tower_item_ids[0..run.tower_item_count], 0..) |existing_id, index| {
        if (existing_id == item_id)
            return run.tower_item_quantities[index];
    }

    return 0;
}

pub fn potentialIndex(run: *const Player.StarTowerRun, potential_id: u32) ?usize {
    for (run.potential_ids[0..run.potential_count], 0..) |owned_id, index|
        if (owned_id == potential_id)
            return index;

    return null;
}

pub fn itemTotal(run: *const Player.StarTowerRun) u32 {
    var total: u32 = 0;
    for (run.tower_item_quantities[0..run.tower_item_count]) |quantity| total +|= quantity;

    return total;
}

pub fn consumeItems(run: *Player.StarTowerRun, quantity: u32) void {
    var remaining = quantity;
    for (run.tower_item_quantities[0..run.tower_item_count]) |*owned_quantity| {
        const consumed = @min(owned_quantity.*, remaining);
        owned_quantity.* -= consumed;
        remaining -= consumed;
        if (remaining == 0)
            return;
    }

    unreachable;
}

pub fn newRunSeed(now: i64, uid: u64, tower_id: u32) u64 {
    const nonce = next_run_seed.fetchAdd(1, .monotonic);
    return (@as(u64, @bitCast(now)) ^ uid ^ (@as(u64, tower_id) << 32) ^ nonce) | 1;
}

pub fn randomBattleNote(run: *Player.StarTowerRun) u32 {
    if (std.enums.fromInt(tables.character.Element, run.note_element)) |element|
        return tables.star_tower.elementNote(element);
    const random = nextRandom(run);
    const count = tables.star_tower.noteCount(run.tower_id);
    if (count == 0)
        return 90011;

    return tables.star_tower.note(run.tower_id, @intCast(random % count)) orelse 90011;
}

pub fn battleExperience(tower_id: u32, room: tables.star_tower.Room) u32 {
    const experience = tables.star_tower.experience(tower_id, room.stage) orelse
        return 0;

    return switch (room.room_type) {
        @intFromEnum(tables.star_tower.RoomType.elite_battle) => experience.elite,
        @intFromEnum(tables.star_tower.RoomType.boss) => experience.boss,
        @intFromEnum(tables.star_tower.RoomType.final_boss) => experience.final_boss,
        else => experience.normal,
    };
}

/// Converts squad experience into the level and progress shown by the client.
pub fn teamProgress(total_exp: u32) TeamProgress {
    var remaining = total_exp;
    var level: u32 = 1;
    for (tables.star_tower.team_levels) |entry| {
        if (entry.level == 1)
            continue;
        if (remaining < entry.required_exp)
            break;
        remaining -= entry.required_exp;
        level = entry.level;
    }

    return .{ .level = level, .exp = remaining };
}

pub fn randomBelow(run: *Player.StarTowerRun, limit: usize) usize {
    std.debug.assert(limit != 0);
    return @intCast(nextRandom(run) % limit);
}

pub fn roll(run: *Player.StarTowerRun, chance_per_thousand: u16) bool {
    return nextRandom(run) % 1000 < chance_per_thousand;
}

pub fn divCeil(value: u32, divisor: u32) u32 {
    return value / divisor + @intFromBool(value % divisor != 0);
}

pub fn nextRandom(run: *Player.StarTowerRun) u64 {
    var state = run.event_rng_state;
    state ^= state << 13;
    state ^= state >> 7;
    state ^= state << 17;
    run.event_rng_state = state;

    return state;
}

pub fn beginRoomCases(run: *Player.StarTowerRun) void {
    run.room_case_last_id = 0;
    run.room_case_count = 0;
    run.room_case_ids = @splat(0);
    run.room_case_kinds = @splat(.none);
    run.room_case_effect_ids = @splat(0);
    run.room_case_resolved = @splat(false);
}

pub fn addRoomCase(
    run: *Player.StarTowerRun,
    kind: Player.StarTowerRun.RoomCaseKind,
    effect_id: u32,
) error{TooManyRoomCases}!u32 {
    if (run.room_case_count == run.room_case_ids.len)
        return error.TooManyRoomCases;

    run.room_case_last_id +|= 1;
    const index = run.room_case_count;
    run.room_case_ids[index] = run.room_case_last_id;
    run.room_case_kinds[index] = kind;
    run.room_case_effect_ids[index] = effect_id;
    run.room_case_resolved[index] = false;
    run.room_case_count += 1;

    return run.room_case_last_id;
}

pub fn roomCaseIndex(run: *const Player.StarTowerRun, id: u32) ?usize {
    for (run.room_case_ids[0..run.room_case_count], 0..) |case_id, index| {
        if (case_id == id)
            return index;
    }

    return null;
}

pub fn activeRoomCaseIndex(
    run: *const Player.StarTowerRun,
    kind: Player.StarTowerRun.RoomCaseKind,
) ?usize {
    for (run.room_case_kinds[0..run.room_case_count], 0..) |case_kind, index| {
        if (case_kind == kind and !run.room_case_resolved[index])
            return index;
    }

    return null;
}

fn selectPotentialCharacter(
    run: *Player.StarTowerRun,
    formation: *const Player.Formation,
) u32 {
    const count: usize = formation.character_count;
    std.debug.assert(count != 0);
    return formation.character_ids[@intCast(nextRandom(run) % count)];
}

fn selectPotentialChoices(
    character_id: u32,
    master: bool,
    owned_ids: []const u32,
    owned_levels: []const u8,
    extra_level_cap: u8,
    core_only: bool,
    random_values: [3]u64,
) [3]u32 {
    var candidates: [32]u32 = undefined;
    var candidate_count: usize = 0;
    const pool = tables.potential.pool(character_id, master) orelse
        return @splat(0);

    appendEligiblePotentials(
        &candidates,
        &candidate_count,
        pool.specific,
        owned_ids,
        owned_levels,
        extra_level_cap,
    );
    if (!core_only) {
        appendEligiblePotentials(
            &candidates,
            &candidate_count,
            pool.normal,
            owned_ids,
            owned_levels,
            extra_level_cap,
        );
        appendEligiblePotentials(
            &candidates,
            &candidate_count,
            pool.common,
            owned_ids,
            owned_levels,
            extra_level_cap,
        );
    }

    var result: [3]u32 = @splat(0);
    for (&result, random_values) |*selected, random_value| {
        if (candidate_count == 0)
            break;
        const index: usize = @intCast(random_value % candidate_count);
        selected.* = candidates[index];
        candidate_count -= 1;
        candidates[index] = candidates[candidate_count];
    }

    return result;
}

fn selectPotentialUpgradeChoices(
    owned_ids: []const u32,
    owned_levels: []const u8,
    extra_level_cap: u8,
) [3]u32 {
    var result: [3]u32 = @splat(0);
    var result_count: usize = 0;
    for (owned_ids, owned_levels) |id, level| {
        if (result_count == result.len or containsPotential(result[0..result_count], id))
            continue;
        if (level >= potentialLevelCap(id, extra_level_cap))
            continue;
        result[result_count] = id;
        result_count += 1;
    }

    return result;
}

fn appendEligiblePotentials(
    candidates: *[32]u32,
    candidate_count: *usize,
    potential_ids: []const u32,
    owned_ids: []const u32,
    owned_levels: []const u8,
    extra_level_cap: u8,
) void {
    for (potential_ids) |id| {
        if (candidate_count.* == candidates.len or containsPotential(candidates[0..candidate_count.*], id))
            continue;
        if (ownedPotentialLevel(owned_ids, owned_levels, id) >= potentialLevelCap(id, extra_level_cap))
            continue;
        candidates[candidate_count.*] = id;
        candidate_count.* += 1;
    }
}

fn ownedPotentialLevel(owned_ids: []const u32, owned_levels: []const u8, id: u32) u32 {
    for (owned_ids, owned_levels) |owned_id, level|
        if (owned_id == id)
            return level;

    return 0;
}

pub fn potentialLevelCap(id: u32, extra_level_cap: u8) u32 {
    return tables.potential.maxLevel(id) + if (tables.potential.allowsExtraLevelCap(id)) extra_level_cap else 0;
}

fn containsPotential(ids: []const u32, expected: u32) bool {
    for (ids) |id| if (id == expected) return true;
    return false;
}
