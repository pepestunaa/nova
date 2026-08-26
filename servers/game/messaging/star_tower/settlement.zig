//! Handles Ascension settlement, rewards, and Monolith Express.

const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const gameplay = @import("../../gameplay.zig");
const tower = gameplay.star_tower;

const Mutation = @import("../../gameplay/mutation.zig");
const Player = @import("../../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../../Scope.zig");
const star_tower_record = @import("../../gameplay/star_tower/record.zig");
const tables = @import("../../tables.zig");

//

pub const journey_ticket_id = 12;
pub const sweep_ticket_id = 29;
pub const sweep_ticket_undated_id = 30;
pub const max_settlement_changes = 2 + 8 + Player.StarTowerRun.max_affinity_changes;

pub fn send(
    scope: *Scope,
    player: *Player,
    request_id: u32,
) !void {
    const log = scope.logger(.star_tower_interact_req);

    const run = &player.star_tower_run;
    const formation = player.getFormation(run.formation_id) orelse
        return error.UnknownFormation;

    const potentials = try scope.arena.alloc(proto.pb.BuildPotential, run.potential_count);
    const score = tower.buildScore(run);
    for (run.potential_ids[0..run.potential_count], 0..) |potential_id, index| {
        const level = run.potential_levels[index];
        potentials[index] = .{ .PotentialId = potential_id, .Level = level };
    }

    const characters = try scope.arena.alloc(proto.pb.TowerBuildChar, formation.character_count);
    for (formation.character_ids[0..formation.character_count], 0..) |character_id, index| {
        var potential_count: u32 = 0;
        for (run.potential_ids[0..run.potential_count], 0..) |potential_id, potential_index| {
            if (tables.potential.characterId(potential_id) == character_id)
                potential_count +|= run.potential_levels[potential_index];
        }
        characters[index] = .{ .CharId = character_id, .PotentialCnt = potential_count };
    }
    const disc_ids = try scope.arena.alloc(u32, formation.disc_count);
    @memcpy(disc_ids, formation.disc_ids[0..formation.disc_count]);
    const notes = try scope.arena.alloc(proto.pb.ItemTpl, run.tower_item_count);
    for (run.tower_item_ids[0..run.tower_item_count], 0..) |note_id, index|
        notes[index] = .{ .Tid = note_id, .Qty = @intCast(run.tower_item_quantities[index]) };
    const affinity_items = try scope.arena.alloc([1]proto.pb.ItemTpl, run.affinity_change_count);
    const affinity_rewards = try scope.arena.alloc(proto.pb.NPCAffinityLevelReward, run.affinity_change_count);
    const affinity_reward_count = writeAffinityRewards(run, affinity_rewards, affinity_items);

    const completed_tower_id = run.tower_id;
    const completed_difficulty = tables.star_tower.difficulty(completed_tower_id) orelse 0;
    const total_time = run.settlement_time;
    const now = scope.now;
    const ticket_count = try awardRunTickets(player, scope.gpa, run, now);
    const is_first_clear = !player.hasClaimedClearReward(.star_tower, completed_tower_id);
    var first_award_defs: [8]tables.star_tower.FirstAward = undefined;
    const first_award_defs_slice = if (is_first_clear)
        tables.star_tower.firstAwards(completed_tower_id, &first_award_defs)
    else
        &.{};
    var first_award_items: [8]proto.pb.ItemTpl = undefined;
    for (first_award_defs_slice, 0..) |award, index| {
        try player.addResource(scope.gpa, award.item_id, award.quantity);
        first_award_items[index] = .{ .Tid = award.item_id, .Qty = award.quantity };
    }
    var first_awards: [1]proto.pb.FirstAward = undefined;
    const first_award_count: usize = if (first_award_defs_slice.len != 0) blk: {
        first_awards[0] = .{
            .TowerId = completed_tower_id,
            .Items = .fromOwnedSlice(first_award_items[0..first_award_defs_slice.len]),
        };
        break :blk 1;
    } else 0;
    if (is_first_clear) try player.setClearRewardClaimed(scope.gpa, .star_tower, completed_tower_id);
    const build_storage_full =
        player.star_tower_builds.len == Player.max_star_tower_builds;
    _ = star_tower_record.preparePendingBuild(player, formation, score);
    gameplay.research_project.completedAscension(scope.mutation(), completed_difficulty);
    const build_coin = if (build_storage_full) blk: {
        // TODO: Test what the official server does. Until then, dismantle
        // the Record immediately when storage is full.
        const awarded = try star_tower_record.awardDismantleTickets(
            player,
            scope.gpa,
            star_tower_record.dismantleTicketCount(score),
            now,
        );
        player.pending_star_tower_build = .{};

        break :blk awarded;
    } else 0;
    run.active = false;
    run.settlement_pending = false;
    run.final_core_potential_pending = false;
    tower.beginRoomCases(run);

    const settlement_change_capacity = 2 + first_award_defs_slice.len + run.affinity_change_count;
    const encoded_resources = try scope.arena.alloc([32]u8, settlement_change_capacity);
    const settlement_changes = try scope.arena.alloc(proto.pb.Any, settlement_change_capacity);
    var settlement_change_count: usize = 0;
    if (ticket_count != 0) {
        const ticket_resource: proto.pb.Res = .{
            .Tid = journey_ticket_id,
            .Qty = @intCast(ticket_count),
        };
        var ticket_writer = Io.Writer.fixed(&encoded_resources[settlement_change_count]);
        try proto.encode(proto.pb.Res, &ticket_writer, &ticket_resource);
        settlement_changes[settlement_change_count] = .{
            .type_url = "type.googleapis.com/proto.Res",
            .value = ticket_writer.buffered(),
        };
        settlement_change_count += 1;
    }

    if (build_coin != 0) {
        const build_resource: proto.pb.Res = .{
            .Tid = journey_ticket_id,
            .Qty = @intCast(build_coin),
        };
        var build_writer = Io.Writer.fixed(&encoded_resources[settlement_change_count]);
        try proto.encode(proto.pb.Res, &build_writer, &build_resource);
        settlement_changes[settlement_change_count] = .{
            .type_url = "type.googleapis.com/proto.Res",
            .value = build_writer.buffered(),
        };
        settlement_change_count += 1;
    }

    for (first_award_defs_slice) |award| {
        const resource: proto.pb.Res = .{ .Tid = award.item_id, .Qty = award.quantity };
        var writer = Io.Writer.fixed(&encoded_resources[settlement_change_count]);
        try proto.encode(proto.pb.Res, &writer, &resource);
        settlement_changes[settlement_change_count] = .{
            .type_url = "type.googleapis.com/proto.Res",
            .value = writer.buffered(),
        };
        settlement_change_count += 1;
    }
    try appendAffinityRewardChanges(run, encoded_resources, settlement_changes, &settlement_change_count);
    var tower_rewards: [1]proto.pb.ItemTpl = undefined;
    const tower_reward_count: usize = if (ticket_count != 0) blk: {
        tower_rewards[0] = .{
            .Tid = journey_ticket_id,
            .Qty = @intCast(ticket_count),
        };

        break :blk 1;
    } else 0;

    const build_info: proto.pb.StarTowerBuildInfo = if (build_storage_full)
        .{
            .BuildCoin = build_coin,
        }
    else
        .{
            .Brief = .{
                .Id = player.pending_star_tower_build.id,
                .Lock = player.pending_star_tower_build.flags.locked,
                .Score = score,
                .DiscIds = .fromOwnedSlice(disc_ids),
                .Chars = .fromOwnedSlice(characters),
                .StarTowerId = completed_tower_id,
            },
            .Detail = .{
                .Potentials = .fromOwnedSlice(potentials),
                .SubNoteSkills = .fromOwnedSlice(notes),
                .ActiveSecondaryIds = .fromOwnedSlice(
                    player.pending_star_tower_build.active_secondary_ids[0..player.pending_star_tower_build.active_secondary_count],
                ),
            },
        };

    try scope.respond(proto.pb.StarTowerInteractResp{
        .Id = request_id,
        .Change = .{},
        .Data = .{},
        .Settle = .{
            .Change = .{ .Props = .fromOwnedSlice(settlement_changes[0..settlement_change_count]) },
            .Build = build_info,
            .Reward = .fromOwnedSlice(affinity_rewards[0..affinity_reward_count]),
            .NpcInteraction = player.progress.star_tower_npc_interactions,
            .TowerRewards = .fromOwnedSlice(tower_rewards[0..tower_reward_count]),
            .Awards = .fromOwnedSlice(first_awards[0..first_award_count]),
            .TotalTime = total_time,
            .TotalDamages = .fromOwnedSlice(run.total_damages[0..run.total_damage_count]),
        },
    });

    log.info("completed Ascension {d}; awarded {d} run and {d} record Journey Ticket(s)", .{
        completed_tower_id,
        ticket_count,
        build_coin,
    });
}

pub fn addRunNpcAffinity(
    mutation: *Mutation,
    allocator: Allocator,
    run: *Player.StarTowerRun,
    npc_id: u32,
    increase: u32,
) !u32 {
    if (run.affinity_change_count >= Player.StarTowerRun.max_affinity_changes)
        return error.TooManyAffinityChanges;

    const player = mutation.modify(.{ .research_project = true });
    const before = player.npcAffinity(npc_id);
    const after = try player.addNpcAffinity(allocator, npc_id, increase);
    const reward = tower.crossedNpcAffinityReward(npc_id, before, after);
    if (reward) |item| {
        if (item.is_resource)
            try player.addResource(allocator, item.item_id, item.quantity)
        else
            try player.addItem(allocator, item.item_id, item.quantity);
    }

    const index = run.affinity_change_count;
    run.affinity_change_npc_ids[index] = npc_id;
    run.affinity_change_values[index] = after;
    run.affinity_change_increases[index] = increase;
    run.affinity_change_reward_ids[index] = if (reward) |item| item.item_id else 0;
    run.affinity_change_reward_quantities[index] = if (reward) |item| item.quantity else 0;
    run.affinity_change_rewards_are_resources[index] = if (reward) |item| item.is_resource else false;
    run.affinity_change_count += 1;
    player.progress.star_tower_npc_interactions +|= 1;

    for (player.quests.entries[0..player.quests.len]) |*quest| {
        if (quest.quest_type != @intFromEnum(tables.quest.Type.tower_event) or
            quest.condition != tables.quest.tower_event_npc_interaction_condition or
            quest.condition_param != npc_id or
            quest.claimed)
            continue;
        quest.progress_current = @min(quest.progress_max, quest.progress_current +| 1);
    }

    return after;
}

/// Updates the Monolith Log when an Ascension discovers or upgrades a
/// Potential, even if its screen is already open.
pub fn sendTowerBookPotentialChange(
    scope: *Scope,
    potential_id: u32,
    level: u8,
    changed: bool,
) !void {
    if (!changed) return;

    const character_id = tables.potential.characterId(potential_id) orelse
        return;
    var potentials: [1]proto.pb.StarTowerBookPotential = .{.{
        .Id = potential_id,
        .Level = level,
    }};
    var characters: [1]proto.pb.StarTowerBookCharPotential = .{.{
        .CharId = character_id,
        .Potentials = .fromOwnedSlice(&potentials),
    }};
    const change: proto.pb.StarTowerBookPotentialChange = .{
        .CharPotentials = .fromOwnedSlice(&characters),
    };
    try scope.sink.sendProto(.star_tower_book_potential_notify, &change);
}

pub fn sendTowerBookEventQuestChanges(
    scope: *Scope,
    player: *const Player,
    npc_id: u32,
) !void {
    for (player.quests.slice()) |quest| {
        if (quest.quest_type != @intFromEnum(tables.quest.Type.tower_event) or
            quest.condition != tables.quest.tower_event_npc_interaction_condition or
            quest.condition_param != npc_id)
            continue;
        var progress: [1]proto.pb.QuestProgress = .{.{
            .Cur = quest.progress_current,
            .Max = quest.progress_max,
        }};
        const change: proto.pb.Quest = .{
            .Id = quest.id,
            .Status = if (quest.claimed) 2 else if (quest.progress_current >= quest.progress_max) 1 else 0,
            .Type = .TowerEvent,
            .Progress = .fromOwnedSlice(&progress),
        };
        try scope.sink.sendProto(.quest_change_notify, &change);
    }
}

pub fn writeAffinityRewards(
    run: *const Player.StarTowerRun,
    output: []proto.pb.NPCAffinityLevelReward,
    reward_items: [][1]proto.pb.ItemTpl,
) usize {
    std.debug.assert(output.len >= run.affinity_change_count);
    std.debug.assert(reward_items.len >= run.affinity_change_count);

    for (0..run.affinity_change_count) |index| {
        const has_reward = run.affinity_change_reward_ids[index] != 0;
        if (has_reward) {
            reward_items[index][0] = .{
                .Tid = run.affinity_change_reward_ids[index],
                .Qty = run.affinity_change_reward_quantities[index],
            };
        }
        output[index] = .{
            .Change = .{
                .NPCId = run.affinity_change_npc_ids[index],
                .Affinity = run.affinity_change_values[index],
                .Increase = run.affinity_change_increases[index],
            },
            .Items = .fromOwnedSlice(reward_items[index][0..if (has_reward) 1 else 0]),
        };
    }

    return run.affinity_change_count;
}

pub fn appendAffinityRewardChanges(
    run: *const Player.StarTowerRun,
    encoded: [][32]u8,
    changes: []proto.pb.Any,
    change_count: *usize,
) proto.EncodeError!void {
    for (0..run.affinity_change_count) |index| {
        const reward_id = run.affinity_change_reward_ids[index];
        if (reward_id == 0) continue;
        std.debug.assert(change_count.* < changes.len);

        var writer = Io.Writer.fixed(&encoded[change_count.*]);
        if (run.affinity_change_rewards_are_resources[index]) {
            const resource: proto.pb.Res = .{
                .Tid = reward_id,
                .Qty = run.affinity_change_reward_quantities[index],
            };
            try proto.encode(proto.pb.Res, &writer, &resource);
            changes[change_count.*] = .{
                .type_url = "type.googleapis.com/proto.Res",
                .value = writer.buffered(),
            };
        } else {
            const item: proto.pb.Item = .{
                .Tid = reward_id,
                .Qty = run.affinity_change_reward_quantities[index],
            };
            try proto.encode(proto.pb.Item, &writer, &item);
            changes[change_count.*] = .{
                .type_url = "type.googleapis.com/proto.Item",
                .value = writer.buffered(),
            };
        }
        change_count.* += 1;
    }
}

pub fn awardRunTickets(
    player: *Player,
    allocator: Allocator,
    run: *const Player.StarTowerRun,
    now: i64,
) !u32 {
    const week = @divFloor(now, seconds_per_week);
    if (player.progress.tower_ticket_week != week) {
        player.progress.tower_ticket_week = week;
        player.progress.tower_ticket = 0;
    }

    const base = give_up_ticket_tiers[
        @min(
            run.defeated_boss_count,
            give_up_ticket_tiers.len - 1,
        )
    ];
    const modifiers = tower.growthModifiers(player, run.tower_id);
    const scaled: u32 = @intCast(
        (@as(u64, base) * modifiers.journey_ticket_multiplier_per_thousand + 500) / 1000,
    );
    const awarded = @min(
        scaled,
        modifiers.journey_ticket_weekly_limit -| player.progress.tower_ticket,
    );
    try player.addResource(allocator, journey_ticket_id, @intCast(awarded));
    player.progress.tower_ticket +|= awarded;

    return awarded;
}

const give_up_ticket_tiers = [_]u32{ 0, 35, 105, 215 };
const seconds_per_week = 7 * 24 * 60 * 60;

pub fn consumeSweepTicket(player: *Player, allocator: Allocator) !u32 {
    if (player.resourceQuantity(sweep_ticket_id) > 0) {
        try player.addResource(allocator, sweep_ticket_id, -1);
        return sweep_ticket_id;
    }

    if (player.resourceQuantity(sweep_ticket_undated_id) > 0) {
        try player.addResource(allocator, sweep_ticket_undated_id, -1);
        return sweep_ticket_undated_id;
    }

    return error.InsufficientSweepTickets;
}
