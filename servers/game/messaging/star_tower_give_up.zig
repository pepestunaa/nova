const std = @import("std");
const Io = std.Io;

const gameplay = @import("../gameplay.zig");
const tower = gameplay.star_tower;

const Player = @import("../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const settlement = @import("star_tower/settlement.zig");
const star_tower_record = @import("../gameplay/star_tower/record.zig");
const tables = @import("../tables.zig");

/// Ends the current Ascension early and offers its Record to save or dismantle.
/// Journey Tickets come from the last defeated boss, and the summary includes
/// NPC Affinity earned during the run.
pub fn star_tower_give_up_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    const log = scope.logger(.star_tower_give_up_req);

    const current = scope.player;
    const current_run = &current.star_tower_run;
    if (!current_run.active) {
        try scope.respondFailureEmpty();
        log.warn("received give-up request without an active Ascension", .{});
        return;
    }

    const formation = current.getFormation(current_run.formation_id) orelse
        return scope.reject(.rgl_cond);
    const player = scope.mutation().modify(.{});
    const run = &player.star_tower_run;
    const now = scope.now;
    const ticket_count = try settlement.awardRunTickets(player, scope.gpa, run, now);

    const potentials = try scope.arena.alloc(proto.pb.BuildPotential, run.potential_count);
    const score = tower.buildScore(run);
    const pending_build = star_tower_record.preparePendingBuild(
        player,
        formation,
        score,
    );
    for (run.potential_ids[0..run.potential_count], 0..) |potential_id, index| {
        const level = run.potential_levels[index];
        potentials[index] = .{
            .PotentialId = potential_id,
            .Level = level,
        };
    }

    const characters = try scope.arena.alloc(proto.pb.TowerBuildChar, formation.character_count);
    for (formation.character_ids[0..formation.character_count], 0..) |character_id, index| {
        var character_potential_count: u32 = 0;
        for (run.potential_ids[0..run.potential_count], 0..) |potential_id, potential_index| {
            if (tables.potential.characterId(potential_id) == character_id)
                character_potential_count +|= run.potential_levels[potential_index];
        }
        characters[index] = .{
            .CharId = character_id,
            .PotentialCnt = character_potential_count,
        };
    }

    const disc_ids = try scope.arena.alloc(u32, formation.disc_count);
    @memcpy(disc_ids, formation.disc_ids[0..formation.disc_count]);
    const notes = try scope.arena.alloc(proto.pb.ItemTpl, run.tower_item_count);
    for (run.tower_item_ids[0..run.tower_item_count], 0..) |note_id, index| {
        notes[index] = .{
            .Tid = note_id,
            .Qty = @intCast(run.tower_item_quantities[index]),
        };
    }
    const active_secondary_ids = try scope.arena.alloc(u32, run.active_secondary_count);
    @memcpy(
        active_secondary_ids,
        run.active_secondary_ids[0..run.active_secondary_count],
    );

    var affinity_items: [Player.StarTowerRun.max_affinity_changes][1]proto.pb.ItemTpl = undefined;
    var affinity_rewards: [Player.StarTowerRun.max_affinity_changes]proto.pb.NPCAffinityLevelReward = undefined;
    const affinity_reward_count = settlement.writeAffinityRewards(run, &affinity_rewards, &affinity_items);

    var encoded_changes: [settlement.max_settlement_changes][32]u8 = undefined;
    var changes: [settlement.max_settlement_changes]proto.pb.Any = undefined;
    var change_count: usize = 0;
    var tower_rewards: [1]proto.pb.ItemTpl = undefined;
    const tower_reward_count: usize = if (ticket_count != 0) blk: {
        const resource: proto.pb.Res = .{
            .Tid = settlement.journey_ticket_id,
            .Qty = @intCast(ticket_count),
        };
        var writer = Io.Writer.fixed(&encoded_changes[change_count]);
        try proto.encode(proto.pb.Res, &writer, &resource);
        changes[change_count] = .{
            .type_url = "type.googleapis.com/proto.Res",
            .value = writer.buffered(),
        };
        change_count += 1;
        tower_rewards[0] = .{
            .Tid = settlement.journey_ticket_id,
            .Qty = @intCast(ticket_count),
        };

        break :blk 1;
    } else 0;
    try settlement.appendAffinityRewardChanges(
        run,
        &encoded_changes,
        &changes,
        &change_count,
    );

    const tower_id = run.tower_id;
    const floor = run.floor;
    const potential_count = run.potential_count;
    const defeated_boss_count = run.defeated_boss_count;
    const total_time = run.settlement_time;
    var total_damages = run.total_damages;
    const total_damage_count = run.total_damage_count;
    const npc_interactions = player.progress.star_tower_npc_interactions;
    player.resetStarTowerRun();

    try scope.respond(proto.pb.StarTowerGiveUpResp{
        .Change = .{ .Props = .fromOwnedSlice(changes[0..change_count]) },
        .Build = .{
            .Brief = .{
                .Id = pending_build.id,
                .Lock = pending_build.flags.locked,
                .Score = score,
                .DiscIds = .fromOwnedSlice(disc_ids),
                .Chars = .fromOwnedSlice(characters),
                .StarTowerId = tower_id,
            },
            .Detail = .{
                .Potentials = .fromOwnedSlice(potentials),
                .SubNoteSkills = .fromOwnedSlice(notes),
                .ActiveSecondaryIds = .fromOwnedSlice(active_secondary_ids),
            },
        },
        .Reward = .fromOwnedSlice(affinity_rewards[0..affinity_reward_count]),
        .NpcInteraction = npc_interactions,
        .TowerRewards = .fromOwnedSlice(tower_rewards[0..tower_reward_count]),
        .Floor = floor,
        .PotentialCnt = potential_count,
        .TotalTime = total_time,
        .TotalDamages = .fromOwnedSlice(total_damages[0..total_damage_count]),
    });

    log.info(
        "gave up Ascension {d} on floor {d} after {d} boss(es); awarded {d} Journey Ticket(s)",
        .{ tower_id, floor, defeated_boss_count, ticket_count },
    );
}
