const std = @import("std");
const Io = std.Io;

const gameplay = @import("../../gameplay.zig");
const tower = gameplay.star_tower;

const Player = @import("../../store/Player.zig");
const proto = @import("proto");
const research_project_notify = @import("../../notify/research_project.zig");
const Scope = @import("../../Scope.zig");
const settlement = @import("settlement.zig");
const shop = @import("shop.zig");
const tables = @import("../../tables.zig");

//

pub fn resolve(
    scope: *Scope,
    player: *Player,
    request_id: u32,
    option_id: u32,
) !void {
    const log = scope.logger(.star_tower_interact_req);

    const run = &player.star_tower_run;
    const rng_before = run.event_rng_state;
    const outcome = tower.selectEventOutcome(option_id, &run.event_rng_state) orelse
        return error.UnknownEventOption;
    const coin_cost: u32 = if (outcome.coin_delta < 0) @intCast(-outcome.coin_delta) else 0;
    if (coin_cost != 0) {
        const cost = coin_cost;
        if (cost > run.tower_coins) {
            try scope.respond(proto.pb.StarTowerInteractResp{
                .Id = request_id,
                .Change = .{},
                .Data = .{},
                .SelectResp = .{ .Resp = .{ .OptionsResult = false } },
            });
            run.event_rng_state = rng_before;

            return;
        }
    }

    if (outcome.note_cost > tower.itemTotal(run)) {
        try scope.respond(proto.pb.StarTowerInteractResp{
            .Id = request_id,
            .Change = .{},
            .Data = .{},
            .SelectResp = .{ .Resp = .{ .OptionsResult = false } },
        });
        run.event_rng_state = rng_before;

        return;
    }

    if (coin_cost != 0)
        run.tower_coins -= coin_cost
    else
        run.tower_coins +|= @intCast(outcome.coin_delta);
    tower.consumeItems(run, outcome.note_cost);

    var items: [1]proto.pb.ItemTpl = undefined;
    var item_count: usize = 0;
    var encoded_currency: [16]u8 = undefined;
    var currency_writer = Io.Writer.fixed(&encoded_currency);
    var changes: [1]proto.pb.Any = undefined;
    var change_count: usize = 0;
    if (outcome.coin_delta != 0) {
        items[item_count] = .{ .Tid = 11, .Qty = outcome.coin_delta };
        item_count += 1;
        const currency: proto.pb.TowerResInfo = .{ .Tid = 11, .Qty = outcome.coin_delta };
        try proto.encode(proto.pb.TowerResInfo, &currency_writer, &currency);
        changes[change_count] = .{
            .type_url = "type.googleapis.com/proto.TowerResInfo",
            .value = currency_writer.buffered(),
        };
        change_count += 1;
    }

    var notes: [1]proto.pb.SubNoteSkillInfo = undefined;
    var note_count: usize = 0;
    const note_id = if (outcome.random_note)
        tower.randomBattleNote(run)
    else
        outcome.note_id;
    if (note_id != 0) {
        const is_new = tower.itemQuantity(run, note_id) == 0;
        try tower.addItem(run, note_id, outcome.note_quantity);
        gameplay.research_project.collectedMusicalNotes(player, outcome.note_quantity);
        notes[note_count] = .{
            .Tid = note_id,
            .Qty = @intCast(outcome.note_quantity),
            .New = is_new,
        };
        note_count += 1;
    }
    const formation = player.getFormation(run.formation_id) orelse
        return error.UnknownFormation;
    var secondary_changes: [tables.disc_secondary.max_changes]tower.SecondaryChange = undefined;
    const secondary_change_slice = tower.reconcileActiveSecondaries(run, formation, &secondary_changes);
    gameplay.research_project.activatedHarmonySkills(player, shop.activatedSecondaries(secondary_change_slice));
    var secondaries: [tables.disc_secondary.max_changes]proto.pb.ActiveSecondaryChange = undefined;
    for (secondary_change_slice, 0..) |secondary, index| secondaries[index] = .{
        .SecondaryId = secondary.id,
        .Active = secondary.active,
    };

    run.room_case_resolved[tower.roomCaseIndex(run, request_id).?] = true;
    var cases: [3]proto.pb.StarTowerRoomCase = undefined;
    var case_count: usize = 0;

    if (outcome.potential_kind != 0) {
        const character_override: ?u32 = if (outcome.potential_character_position != 0 and
            outcome.potential_character_position <= formation.character_count)
            formation.character_ids[outcome.potential_character_position - 1]
        else
            null;
        tower.offerPotentials(
            player,
            run,
            formation,
            false,
            character_override,
        );
        if (run.offered_potential_count == 0)
            return error.NoPotentialChoices;

        var potentials: [3]proto.pb.PotentialInfo = undefined;
        for (run.offered_potential_ids[0..run.offered_potential_count], 0..) |potential_id, index|
            potentials[index] = .{ .Tid = potential_id, .Level = run.offered_potential_levels[index] };
        const potential_case_id = try tower.addRoomCase(run, .select_potential, 0);
        cases[case_count] = .{ .Id = potential_case_id, .SelectPotentialCase = .{
            .Infos = .fromOwnedSlice(potentials[0..run.offered_potential_count]),
            .NewIds = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
            .CanReRoll = run.potential_rerolls != 0,
            .ReRollPrice = run.potential_reroll_price,
            .Type = 5,
        } };
        case_count += 1;
    }

    if (outcome.recovery_effect_id != 0) {
        const recovery_case_id = try tower.addRoomCase(run, .recovery_hp, outcome.recovery_effect_id);
        cases[case_count] = .{ .Id = recovery_case_id, .RecoveryHPCase = .{
            .EffectId = outcome.recovery_effect_id,
        } };
        case_count += 1;
    }

    if (case_count == 0 and tower.activeRoomCaseIndex(run, .door) == null) {
        const next_room = tables.star_tower.room(run.tower_id, run.pending_floor) orelse
            return error.InvalidRunFloor;
        const door_case_id = try tower.addRoomCase(run, .door, 0);
        cases[case_count] = .{ .Id = door_case_id, .DoorCase = .{
            .Floor = next_room.floor,
            .Type = next_room.room_type,
        } };
        case_count += 1;
    }

    run.event_pending = false;
    var affinity: [1]proto.pb.NPCAffinityChange = undefined;
    const affinity_count: usize = if (run.event_npc_id != 0) blk: {
        const affinity_increase: u32 = 100;
        const affinity_value = try settlement.addRunNpcAffinity(
            player,
            scope.gpa,
            run,
            run.event_npc_id,
            affinity_increase,
        );
        affinity[0] = .{
            .NPCId = run.event_npc_id,
            .Affinity = affinity_value,
            .Increase = affinity_increase,
        };

        break :blk 1;
    } else 0;

    scope.markDirty();

    try scope.respond(proto.pb.StarTowerInteractResp{
        .Id = request_id,
        .Cases = .fromOwnedSlice(cases[0..case_count]),
        .Change = .{
            .Props = .fromOwnedSlice(changes[0..change_count]),
        },
        .Data = .{
            .Infos = .fromOwnedSlice(notes[0..note_count]),
            .Secondaries = .fromOwnedSlice(secondaries[0..secondary_change_slice.len]),
        },
        .SelectResp = .{
            .Resp = .{
                .Items = .fromOwnedSlice(items[0..item_count]),
                .OptionsResult = true,
                .SubNoteSkills = .fromOwnedSlice(notes[0..note_count]),
                .OptionsParamId = outcome.message_id,
                .AffinityChange = .fromOwnedSlice(affinity[0..affinity_count]),
            },
        },
    });
    try settlement.sendTowerBookEventQuestChanges(scope, player, run.event_npc_id);
    try research_project_notify.send(scope);
    log.info(
        "completed Ascension event {d}, option {d}: currency {d}, note {d} x{d}, potential kind {d}, character slot {d}",
        .{ run.event_id, option_id, outcome.coin_delta, note_id, outcome.note_quantity, outcome.potential_kind, outcome.potential_character_position },
    );
}
