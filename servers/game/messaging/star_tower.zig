const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const gameplay = @import("../gameplay.zig");
const tower = gameplay.star_tower;

const client_reports = @import("star_tower/client_reports.zig");
const event_interaction = @import("star_tower/event.zig");
const Player = @import("../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const settlement = @import("star_tower/settlement.zig");
const shop = @import("star_tower/shop.zig");
const star_tower_record = @import("../gameplay/star_tower/record.zig");
const tables = @import("../tables.zig");

//

pub fn star_tower_interact_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_interact_req);

    const request = try scope.source.read(proto.pb.StarTowerInteractReq);
    const request_id = request.Id;
    const current = scope.player;
    const current_run = &current.star_tower_run;
    if (!current_run.active)
        return error.NoActiveRun;

    if (request.EnterReq != null and
        !(current_run.settlement_pending and current_run.pending_floor == 0))
    {
        const door_case_index = tower.roomCaseIndex(current_run, request_id) orelse
            return scope.reject(.invalid_req);
        if (current_run.room_case_kinds[door_case_index] != .door or
            current_run.room_case_resolved[door_case_index])
            return scope.reject(.invalid_req);
    }

    const player = scope.mutation().modify(.{});
    const run = &player.star_tower_run;

    if (request.EnterReq) |enter| {
        if (run.settlement_pending and run.pending_floor == 0) {
            try settlement.send(scope, player, request_id);
            return;
        }

        const door_case_index = tower.roomCaseIndex(run, request_id).?;
        run.room_case_resolved[door_case_index] = true;

        const floor = run.pending_floor;
        const room = tables.star_tower.room(run.tower_id, floor) orelse
            return error.InvalidRunFloor;

        run.floor = floor;
        run.pending_floor = 0;
        try setRunMap(player, scope.gpa, enter);
        tower.beginRoomCases(run);

        if (tables.star_tower.isBattleRoom(room.room_type)) {
            const note_count = tables.star_tower.battleNoteCount(room.room_type);
            const battle_case_id = try tower.addRoomCase(run, .battle, 0);
            const sync_case_id = try tower.addRoomCase(run, .sync_hp, 0);
            var cases: [2]proto.pb.StarTowerRoomCase = .{
                .{ .Id = battle_case_id, .BattleCase = .{ .SubNoteSkillNum = note_count } },
                .{ .Id = sync_case_id, .SyncHPCase = .{} },
            };

            try scope.respond(proto.pb.StarTowerInteractResp{
                .Id = request_id,
                .Change = .{},
                .Data = .{},
                .EnterResp = .{
                    .Room = .{
                        .Data = roomData(room, enter),
                        .Cases = .fromOwnedSlice(&cases),
                    },
                },
            });
        } else if (room.room_type == @intFromEnum(tables.star_tower.RoomType.event)) {
            const next_room = tables.star_tower.room(run.tower_id, floor + 1) orelse
                return error.UnimplementedFinalRoom;
            const event = if (run.event_pending) blk: {
                break :blk tables.star_tower_event.Event{
                    .id = run.event_id,
                    .npc_id = run.event_npc_id,
                    .options = run.event_options,
                    .option_count = run.event_option_count,
                };
            } else tower.selectEvent(&run.event_rng_state);
            run.pending_floor = next_room.floor;
            run.event_id = event.id;
            run.event_npc_id = event.npc_id;
            run.event_options = event.options;
            run.event_option_count = event.option_count;
            run.event_pending = true;
            const event_case_id = try tower.addRoomCase(run, .select_event, 0);
            const sync_case_id = try tower.addRoomCase(run, .sync_hp, 0);
            const door_case_id = try tower.addRoomCase(run, .door, 0);

            var affinity: [1]proto.pb.NPCAffinityInfo = .{.{
                .NPCId = event.npc_id,
                .Affinity = player.npcAffinity(event.npc_id),
            }};
            var cases: [3]proto.pb.StarTowerRoomCase = .{
                .{
                    .Id = event_case_id,
                    .SelectOptionsEventCase = .{
                        .EvtId = event.id,
                        .Options = .fromOwnedSlice(run.event_options[0..event.option_count]),
                        .NPCId = event.npc_id,
                        .Infos = .fromOwnedSlice(&affinity),
                    },
                },
                .{ .Id = sync_case_id, .SyncHPCase = .{} },
                .{
                    .Id = door_case_id,
                    .DoorCase = .{
                        .Floor = next_room.floor,
                        .Type = next_room.room_type,
                    },
                },
            };

            try scope.respond(proto.pb.StarTowerInteractResp{
                .Id = request_id,
                .Change = .{},
                .Data = .{},
                .EnterResp = .{
                    .Room = .{
                        .Data = roomData(room, enter),
                        .Cases = .fromOwnedSlice(&cases),
                    },
                },
            });

            log.info("opened Ascension event {d} with NPC {d}", .{ event.id, event.npc_id });
        } else {
            const next_room = tables.star_tower.room(run.tower_id, floor + 1) orelse
                return error.UnimplementedFinalRoom;
            run.pending_floor = next_room.floor;

            if (room.room_type == @intFromEnum(tables.star_tower.RoomType.shop)) {
                shop.initialize(player, run, floor);
                const hawker_case_id = try tower.addRoomCase(run, .hawker, 0);
                const sync_case_id = try tower.addRoomCase(run, .sync_hp, 0);
                const door_case_id = try tower.addRoomCase(run, .door, 0);
                const has_strengthen_machine = tower.growthModifiers(player, run.tower_id).enable_shop_strengthen;
                const strengthen_case_id = if (has_strengthen_machine)
                    try tower.addRoomCase(run, .strengthen_machine, 0)
                else
                    0;
                var goods: [Player.StarTowerRun.max_shop_goods]proto.pb.HawkerGoods = undefined;
                var purchases: [Player.StarTowerRun.max_shop_goods]u32 = undefined;
                var goods_count: usize = 0;
                var purchase_count: usize = 0;
                for (0..run.shop_goods_count) |index| {
                    goods[goods_count] = .{
                        .Sid = run.shop_good_sids[index],
                        .Idx = run.shop_good_indices[index],
                        .CharPos = run.shop_good_char_positions[index],
                        .Price = @intCast(run.shop_good_display_prices[index]),
                        .Discount = @intCast(run.shop_good_discounts[index]),
                        .Type = run.shop_good_kinds[index],
                        .GoodsId = run.shop_good_ids[index],
                        .Tag = run.shop_good_tags[index],
                    };
                    goods_count += 1;
                    if (run.shop_good_purchased[index]) {
                        purchases[purchase_count] = run.shop_good_sids[index];
                        purchase_count += 1;
                    }
                }
                var cases: [4]proto.pb.StarTowerRoomCase = .{
                    .{
                        .Id = hawker_case_id,
                        .HawkerCase = .{
                            .List = .fromOwnedSlice(goods[0..goods_count]),
                            .Purchase = .fromOwnedSlice(purchases[0..purchase_count]),
                            .CanReRoll = run.shop_rerolls != 0,
                            .ReRollPrice = run.shop_reroll_price,
                            .ReRollTimes = run.shop_rerolls,
                        },
                    },
                    .{ .Id = sync_case_id, .SyncHPCase = .{} },
                    .{
                        .Id = door_case_id,
                        .DoorCase = .{ .Floor = next_room.floor, .Type = next_room.room_type },
                    },
                    undefined,
                };
                if (has_strengthen_machine) cases[3] = .{
                    .Id = strengthen_case_id,
                    .StrengthenMachineCase = .{
                        .Times = run.strengthen_times,
                        .FirstFree = run.strengthen_first_free_available,
                        .Discount = tower.growthModifiers(player, run.tower_id).strengthen_discount,
                    },
                };

                try scope.respond(proto.pb.StarTowerInteractResp{
                    .Id = request_id,
                    .Change = .{},
                    .Data = .{},
                    .EnterResp = .{
                        .Room = .{
                            .Data = roomData(room, enter),
                            .Cases = .fromOwnedSlice(cases[0..if (has_strengthen_machine) 4 else 3]),
                        },
                    },
                });

                log.info(
                    "opened Ascension shop on floor {d} with {d} good(s)",
                    .{ floor, goods_count },
                );

                return;
            }

            const door_case_id = try tower.addRoomCase(run, .door, 0);
            const sync_case_id = try tower.addRoomCase(run, .sync_hp, 0);

            var cases: [2]proto.pb.StarTowerRoomCase = .{
                .{
                    .Id = door_case_id,
                    .DoorCase = .{
                        .Floor = next_room.floor,
                        .Type = next_room.room_type,
                    },
                },
                .{
                    .Id = sync_case_id,
                    .SyncHPCase = .{},
                },
            };
            try scope.respond(proto.pb.StarTowerInteractResp{
                .Id = request_id,
                .Change = .{},
                .Data = .{},
                .EnterResp = .{
                    .Room = .{
                        .Data = roomData(room, enter),
                        .Cases = .fromOwnedSlice(&cases),
                    },
                },
            });
        }

        log.info("entered Ascension {d}, floor {d}, room type {d}", .{
            run.tower_id,
            room.floor,
            room.room_type,
        });

        return;
    }

    if (request.BattleEndReq) |battle| {
        if (battle.Victory) |victory| {
            const battle_case_index = tower.roomCaseIndex(run, request_id) orelse
                return error.UnexpectedBattle;
            if (run.room_case_kinds[battle_case_index] != .battle or run.room_case_resolved[battle_case_index])
                return error.UnexpectedBattle;
            run.room_case_resolved[battle_case_index] = true;
            const formation = player.getFormation(run.formation_id) orelse
                return error.UnknownFormation;
            const current_room = tables.star_tower.room(run.tower_id, run.floor) orelse
                return error.InvalidRunFloor;
            const next_room = tables.star_tower.room(run.tower_id, run.floor + 1);
            if (current_room.room_type == @intFromEnum(tables.star_tower.RoomType.boss) or
                current_room.room_type == @intFromEnum(tables.star_tower.RoomType.final_boss))
            {
                run.defeated_boss_count +|= 1;
            }

            const modifiers = tower.growthModifiers(player, run.tower_id);
            var coin_reward = current_room.interior_currency_quantity;
            if (modifiers.scratch_coin_chance_per_thousand != 0 and
                run.scratch_coin_count < modifiers.scratch_coin_limit and
                tower.roll(run, modifiers.scratch_coin_chance_per_thousand))
            {
                coin_reward +|= modifiers.scratch_coin_amount;
                run.scratch_coin_count +|= 1;
            }
            run.tower_coins +|= coin_reward;
            run.team_exp +|= tower.battleExperience(run.tower_id, current_room);
            const team_progress = tower.teamProgress(run.team_exp);
            run.team_level = team_progress.level;

            const is_final_room = next_room == null;
            run.pending_floor = if (next_room) |following_room| following_room.floor else 0;
            run.char_hp = victory.HP;
            run.settlement_pending = is_final_room;
            run.final_core_potential_pending = false;
            run.settlement_time = victory.Time;
            try setRunClientData(player, scope.gpa, victory.DateLen, victory.ClientData, victory.DataVersion);
            if (victory.Events) |events|
                try client_reports.record(scope.mutation(), events);
            run.total_damages = @splat(0);
            run.total_damage_count = 0;
            var damages = victory.Damages;
            while (try damages.next()) |damage| {
                if (run.total_damage_count >= run.total_damages.len)
                    break;
                run.total_damages[run.total_damage_count] = damage;
                run.total_damage_count += 1;
            }
            const butterflies_inside = tower.offerPotentials(
                player,
                run,
                formation,
                run.potential_count == 0,
                null,
                .level_up,
            );
            gameplay.research_project.triggeredButterfliesInside(scope.mutation(), butterflies_inside);
            if (run.offered_potential_count == 0)
                return error.NoPotentialChoices;
            const potential_case_id = try tower.addRoomCase(
                run,
                if (run.potential_count == 0) .select_special_potential else .select_potential,
                0,
            );
            const offers_recovery = tables.star_tower.givesRecoveryNpc(current_room.room_type);
            const recovery_case_id = if (offers_recovery)
                try tower.addRoomCase(run, .npc_recovery_hp, tower.generic_recovery_effect_id)
            else
                0;

            var encoded_currency: [16]u8 = undefined;
            var currency_writer = Io.Writer.fixed(&encoded_currency);
            const currency: proto.pb.TowerResInfo = .{
                .Tid = 11,
                .Qty = @intCast(coin_reward),
            };
            try proto.encode(proto.pb.TowerResInfo, &currency_writer, &currency);
            var changes: [9]proto.pb.Any = undefined;
            var change_count: usize = 0;
            changes[change_count] = .{
                .type_url = "type.googleapis.com/proto.TowerResInfo",
                .value = currency_writer.buffered(),
            };
            change_count += 1;
            var note_count = tables.star_tower.battleNoteCount(current_room.room_type);
            if (modifiers.extra_note_chance_per_thousand != 0 and
                tower.roll(run, modifiers.extra_note_chance_per_thousand)) note_count += 1;
            var surprise_note_triggered = false;
            if (modifiers.surprise_note_drops != 0 and
                run.surprise_note_count < modifiers.surprise_note_limit and
                tower.roll(run, modifiers.surprise_note_chance_per_thousand))
            {
                note_count += modifiers.surprise_note_drops;
                run.surprise_note_count +|= 1;
                surprise_note_triggered = true;
            }
            if ((current_room.room_type == @intFromEnum(tables.star_tower.RoomType.elite_battle) or
                current_room.room_type == @intFromEnum(tables.star_tower.RoomType.boss)) and
                modifiers.boss_note_drops != 0 and tower.roll(run, 500))
                note_count += modifiers.boss_note_drops;
            var note_infos: [8]proto.pb.SubNoteSkillInfo = undefined;
            var encoded_notes: [8][16]u8 = undefined;
            for (0..note_count) |index| {
                const note_id = tower.randomBattleNote(run);
                const is_new = tower.itemQuantity(run, note_id) == 0;
                try tower.addItem(run, note_id, 3);
                note_infos[index] = .{ .Tid = note_id, .Qty = 3, .New = is_new };

                var note_writer = Io.Writer.fixed(&encoded_notes[index]);
                const note: proto.pb.TowerItemInfo = .{ .Tid = note_id, .Qty = 3 };
                try proto.encode(proto.pb.TowerItemInfo, &note_writer, &note);
                changes[change_count] = .{
                    .type_url = "type.googleapis.com/proto.TowerItemInfo",
                    .value = note_writer.buffered(),
                };
                change_count += 1;
            }
            gameplay.research_project.collectedMusicalNotes(scope.mutation(), note_count * 3);
            if (surprise_note_triggered)
                gameplay.research_project.triggeredSurpriseNote(scope.mutation());
            gameplay.quest.trigger(scope.mutation(), .battle_total, 1, 0);
            var secondary_changes: [tables.disc_secondary.max_changes]tower.SecondaryChange = undefined;
            const secondary_change_slice = tower.reconcileActiveSecondaries(
                run,
                formation,
                &secondary_changes,
            );
            gameplay.research_project.activatedHarmonySkills(scope.mutation(), shop.activatedSecondaries(secondary_change_slice));
            var secondaries: [tables.disc_secondary.max_changes]proto.pb.ActiveSecondaryChange = undefined;
            for (secondary_change_slice, 0..) |secondary, index| secondaries[index] = .{
                .SecondaryId = secondary.id,
                .Active = secondary.active,
            };
            var potential_infos: [3]proto.pb.PotentialInfo = undefined;
            for (run.offered_potential_ids[0..run.offered_potential_count], 0..) |potential_id, index|
                potential_infos[index] = .{ .Tid = potential_id, .Level = run.offered_potential_levels[index] };
            var cases: [2]proto.pb.StarTowerRoomCase = undefined;
            cases[0] = .{
                .Id = potential_case_id,
                .SelectSpecialPotentialCase = if (run.potential_count == 0) .{
                    .Ids = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
                    .NewIds = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
                    .TeamLevel = run.team_level,
                } else null,
                .SelectPotentialCase = if (run.potential_count != 0) .{
                    .Infos = .fromOwnedSlice(potential_infos[0..run.offered_potential_count]),
                    .NewIds = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
                    .TeamLevel = run.team_level,
                    .Type = @intFromEnum(Player.StarTowerRun.PotentialSelectorType.level_up),
                } else null,
            };
            if (offers_recovery) cases[1] = .{
                .Id = recovery_case_id,
                .NpcRecoveryHPCase = .{ .EffectId = tower.generic_recovery_effect_id },
            };

            try scope.respond(proto.pb.StarTowerInteractResp{
                .Id = request_id,
                .Cases = .fromOwnedSlice(cases[0..if (offers_recovery) 2 else 1]),
                .Change = .{ .Props = .fromOwnedSlice(changes[0..change_count]) },
                .Data = .{
                    .Infos = .fromOwnedSlice(note_infos[0..note_count]),
                    .Secondaries = .fromOwnedSlice(secondaries[0..secondary_change_slice.len]),
                },
                .BattleEndResp = .{ .Victory = .{
                    .Exp = team_progress.exp,
                    .Lv = run.team_level,
                    .BattleTime = victory.Time,
                } },
            });

            log.info("completed Ascension floor {d}; offered {d} potential(s){s}", .{
                run.floor,
                run.offered_potential_count,
                if (offers_recovery) " and recovery NPC" else "",
            });
            return;
        }

        try scope.respond(proto.pb.StarTowerInteractResp{
            .Id = request_id,
            .Change = .{},
            .Data = .{},
            .BattleEndResp = .{
                .Defeat = .{ .Lv = run.team_level },
            },
        });

        log.info("accepted Ascension battle defeat on floor {d}", .{run.floor});

        return;
    }

    if (request.HawkerReq) |hawker| {
        try shop.interact(scope, player, request_id, hawker);
        return;
    }

    if (request.RecoveryHPReq) |recovery| {
        const case_index = tower.roomCaseIndex(run, request_id) orelse
            return error.UnexpectedRecovery;
        const case_kind = run.room_case_kinds[case_index];
        if (run.room_case_resolved[case_index])
            return error.UnexpectedRecovery;
        if (case_kind == .npc_recovery_hp) {
            run.room_case_resolved[case_index] = true;
            run.char_hp = recovery.Hp;

            try scope.respond(proto.pb.StarTowerInteractResp{ .Id = request_id, .Change = .{}, .Data = .{}, .NilResp = .{} });

            return;
        }
        if (case_kind != .recovery_hp and case_kind != .sync_hp)
            return error.UnexpectedRecovery;

        run.room_case_resolved[case_index] = true;
        run.char_hp = recovery.Hp;
        const next_sync_case_id = try tower.addRoomCase(run, .sync_hp, 0);

        var cases: [1]proto.pb.StarTowerRoomCase = .{.{
            .Id = next_sync_case_id,
            .SyncHPCase = .{},
        }};
        try scope.respond(proto.pb.StarTowerInteractResp{
            .Id = request_id,
            .Cases = .fromOwnedSlice(&cases),
            .Change = .{},
            .Data = .{},
            .NilResp = .{},
        });

        return;
    }

    if (request.SelectReq) |select| {
        const selected_case_index = tower.roomCaseIndex(run, request_id) orelse
            return error.UnexpectedSelect;
        const selected_case_kind = run.room_case_kinds[selected_case_index];
        if (selected_case_kind == .strengthen_machine) {
            if (run.room_case_resolved[selected_case_index])
                return error.UnexpectedSelect;
            const modifiers = tower.growthModifiers(player, run.tower_id);
            const price = if (run.strengthen_first_free_available)
                0
            else
                tower.strengthenMachinePrice(run.strengthen_times) -| modifiers.strengthen_discount;
            if (price > run.tower_coins) {
                try scope.respond(proto.pb.StarTowerInteractResp{
                    .Id = request_id,
                    .Change = .{},
                    .Data = .{},
                    .StrengthenMachineResp = .{
                        .BuySucceed = false,
                    },
                });

                return;
            }
            run.room_case_resolved[selected_case_index] = true;
            run.tower_coins -= price;
            if (run.strengthen_first_free_available)
                run.strengthen_first_free_available = false
            else
                run.strengthen_times +|= 1;
            const strengthen_bonus_count = run.strengthen_bonus_count;
            tower.offerPotentialStrengthening(player, run);
            gameplay.research_project.usedEnhancementMachine(scope.mutation());
            if (run.strengthen_bonus_count != strengthen_bonus_count)
                gameplay.research_project.triggeredPotentialBoost(scope.mutation());
            if (run.offered_potential_count == 0) {
                try scope.respond(proto.pb.StarTowerInteractResp{
                    .Id = request_id,
                    .Change = .{},
                    .Data = .{},
                    .StrengthenMachineResp = .{
                        .BuySucceed = false,
                    },
                });

                return;
            }
            const potential_case_id = try tower.addRoomCase(run, .select_potential, 0);

            var infos: [3]proto.pb.PotentialInfo = undefined;
            for (run.offered_potential_ids[0..run.offered_potential_count], 0..) |potential_id, index|
                infos[index] = .{ .Tid = potential_id, .Level = run.offered_potential_levels[index] };
            var encoded_currency: [16]u8 = undefined;
            var currency_writer = Io.Writer.fixed(&encoded_currency);
            const currency: proto.pb.TowerResInfo = .{ .Tid = 11, .Qty = -@as(i32, @intCast(price)) };
            try proto.encode(proto.pb.TowerResInfo, &currency_writer, &currency);
            var changes: [1]proto.pb.Any = undefined;
            var change_count: usize = 0;
            if (price != 0) {
                changes[0] = .{
                    .type_url = "type.googleapis.com/proto.TowerResInfo",
                    .value = currency_writer.buffered(),
                };
                change_count = 1;
            }
            var cases = [_]proto.pb.StarTowerRoomCase{.{
                .Id = potential_case_id,
                .SelectPotentialCase = .{
                    .Infos = .fromOwnedSlice(infos[0..run.offered_potential_count]),
                    .NewIds = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
                    .CanReRoll = run.potential_rerolls != 0,
                    .ReRollPrice = run.potential_reroll_price,
                    .Type = @intFromEnum(Player.StarTowerRun.PotentialSelectorType.strengthen),
                },
            }};

            try scope.respond(proto.pb.StarTowerInteractResp{
                .Id = request_id,
                .Cases = .fromOwnedSlice(&cases),
                .Change = .{ .Props = .fromOwnedSlice(changes[0..change_count]) },
                .Data = .{},
                .StrengthenMachineResp = .{ .BuySucceed = true },
            });

            log.info("opened Potential strengthening selector for {d} currency", .{price});

            return;
        }
        if (selected_case_kind == .select_special_potential or selected_case_kind == .select_potential) {
            if (run.room_case_resolved[selected_case_index])
                return error.UnexpectedSelect;
            if (select.ReRoll) |should_reroll| if (should_reroll) {
                if (run.potential_rerolls == 0 or run.potential_reroll_price > run.tower_coins)
                    return error.UnavailablePotentialReroll;
                const formation = player.getFormation(run.formation_id) orelse
                    return error.UnknownFormation;
                const reroll_price = run.potential_reroll_price;
                run.room_case_resolved[selected_case_index] = true;
                run.potential_rerolls -= 1;
                const rerolls_remaining = run.potential_rerolls;
                run.tower_coins -= reroll_price;
                if (run.potential_selector == .strengthen) {
                    const strengthen_bonus_count = run.strengthen_bonus_count;
                    tower.offerPotentialStrengthening(player, run);
                    if (run.strengthen_bonus_count != strengthen_bonus_count)
                        gameplay.research_project.triggeredPotentialBoost(scope.mutation());
                } else {
                    const butterflies_inside = tower.offerPotentials(
                        player,
                        run,
                        formation,
                        selected_case_kind == .select_special_potential,
                        run.offered_potential_character_id,
                        run.potential_selector,
                    );
                    gameplay.research_project.triggeredButterfliesInside(scope.mutation(), butterflies_inside);
                    gameplay.research_project.refreshedPotentials(scope.mutation());
                }
                run.potential_rerolls = rerolls_remaining;
                if (run.offered_potential_count == 0)
                    return error.NoPotentialChoices;
                const reroll_case_id = try tower.addRoomCase(run, selected_case_kind, 0);

                var infos: [3]proto.pb.PotentialInfo = undefined;
                for (run.offered_potential_ids[0..run.offered_potential_count], 0..) |potential_id, info_index|
                    infos[info_index] = .{ .Tid = potential_id, .Level = run.offered_potential_levels[info_index] };
                var encoded_currency: [16]u8 = undefined;
                var currency_writer = Io.Writer.fixed(&encoded_currency);
                const currency: proto.pb.TowerResInfo = .{ .Tid = 11, .Qty = -@as(i32, @intCast(reroll_price)) };
                try proto.encode(proto.pb.TowerResInfo, &currency_writer, &currency);
                var changes = [_]proto.pb.Any{.{
                    .type_url = "type.googleapis.com/proto.TowerResInfo",
                    .value = currency_writer.buffered(),
                }};
                var cases = [_]proto.pb.StarTowerRoomCase{.{
                    .Id = reroll_case_id,
                    .SelectSpecialPotentialCase = if (selected_case_kind == .select_special_potential) .{
                        .Ids = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
                        .NewIds = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
                    } else null,
                    .SelectPotentialCase = if (selected_case_kind == .select_potential) .{
                        .Infos = .fromOwnedSlice(infos[0..run.offered_potential_count]),
                        .NewIds = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
                        .Type = @intFromEnum(run.potential_selector),
                    } else null,
                }};

                try scope.respond(proto.pb.StarTowerInteractResp{
                    .Id = request_id,
                    .Cases = .fromOwnedSlice(&cases),
                    .Change = .{ .Props = .fromOwnedSlice(&changes) },
                    .Data = .{},
                    .NilResp = .{},
                });

                log.info("rerolled Ascension potential choices for {d} currency", .{reroll_price});

                return;
            };
            run.room_case_resolved[selected_case_index] = true;
            const formation = player.getFormation(run.formation_id) orelse
                return error.UnknownFormation;
            const index = select.Index orelse
                return error.InvalidSelect;
            if (index >= run.offered_potential_count)
                return error.InvalidSelect;
            const potential_id = run.offered_potential_ids[index];
            const potential_level = run.offered_potential_levels[index];
            if (run.offered_potential_bonus_pending[index]) {
                run.potential_bonus_count +|= 1;
                gameplay.research_project.triggeredButterfliesInside(scope.mutation(), 1);
            }
            const selector_type = run.potential_selector;
            if (selector_type == .strengthen) {
                const owned_index = tower.potentialIndex(run, potential_id) orelse
                    return error.UnknownPotential;
                const cap = tower.potentialLevelCap(
                    potential_id,
                    tower.growthModifiers(player, run.tower_id).potential_level_cap_bonus,
                );
                run.potential_levels[owned_index] = @min(cap, run.potential_levels[owned_index] + potential_level);
            } else {
                if (tower.potentialIndex(run, potential_id)) |owned_index| {
                    const cap = tower.potentialLevelCap(
                        potential_id,
                        tower.growthModifiers(player, run.tower_id).potential_level_cap_bonus,
                    );
                    run.potential_levels[owned_index] = @min(cap, run.potential_levels[owned_index] + potential_level);
                } else {
                    if (run.potential_count >= run.potential_ids.len)
                        return error.TooManyPotentials;
                    run.potential_ids[run.potential_count] = potential_id;
                    run.potential_levels[run.potential_count] = potential_level;
                    run.potential_count += 1;
                }
            }
            const current_potential_level = run.potential_levels[tower.potentialIndex(run, potential_id).?];
            const tower_book_changed = try player.recordTowerBookPotential(
                scope.gpa,
                potential_id,
                current_potential_level,
            );
            run.offered_potential_count = 0;
            run.offered_potential_character_id = 0;

            var awarded: [1]proto.pb.ItemTpl = .{.{ .Tid = potential_id, .Qty = 1 }};
            var encoded_potential: [32]u8 = undefined;
            var potential_writer = Io.Writer.fixed(&encoded_potential);
            const potential: proto.pb.PotentialInfo = .{ .Tid = potential_id, .Level = potential_level };
            try proto.encode(proto.pb.PotentialInfo, &potential_writer, &potential);
            var changes: [1]proto.pb.Any = .{.{
                .type_url = "type.googleapis.com/proto.PotentialInfo",
                .value = potential_writer.buffered(),
            }};

            run.potential_selector = .level_up;

            if (selector_type == .shop) {
                try scope.respond(proto.pb.StarTowerInteractResp{
                    .Id = request_id,
                    .Change = .{ .Props = .fromOwnedSlice(&changes) },
                    .Data = .{},
                    .SelectResp = .{ .Resp = .{ .Items = .fromOwnedSlice(&awarded) } },
                });
                try settlement.sendTowerBookPotentialChange(
                    scope,
                    potential_id,
                    current_potential_level,
                    tower_book_changed,
                );

                log.info("selected shop potential {d}", .{potential_id});
                return;
            }

            if (run.settlement_pending and !run.final_core_potential_pending) {
                run.final_core_potential_pending = true;
                const butterflies_inside = tower.offerPotentials(
                    player,
                    run,
                    formation,
                    true,
                    null,
                    .level_up,
                );
                gameplay.research_project.triggeredButterfliesInside(scope.mutation(), butterflies_inside);
                if (run.offered_potential_count == 0)
                    return error.NoPotentialChoices;
                const core_case_id = try tower.addRoomCase(run, .select_special_potential, 0);
                var cases: [1]proto.pb.StarTowerRoomCase = .{.{
                    .Id = core_case_id,
                    .SelectSpecialPotentialCase = .{
                        .Ids = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
                        .NewIds = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
                        .TeamLevel = run.team_level,
                        .CanReRoll = run.potential_rerolls != 0,
                        .ReRollPrice = run.potential_reroll_price,
                    },
                }};

                try scope.respond(proto.pb.StarTowerInteractResp{
                    .Id = request_id,
                    .Cases = .fromOwnedSlice(&cases),
                    .Change = .{
                        .Props = .fromOwnedSlice(&changes),
                    },
                    .Data = .{},
                    .SelectResp = .{
                        .Resp = .{
                            .Items = .fromOwnedSlice(&awarded),
                        },
                    },
                });
                try settlement.sendTowerBookPotentialChange(
                    scope,
                    potential_id,
                    current_potential_level,
                    tower_book_changed,
                );

                log.info(
                    "selected final-room potential {d}; offering core potential",
                    .{potential_id},
                );

                return;
            }

            const current_room = tables.star_tower.room(run.tower_id, run.floor) orelse
                return error.InvalidRunFloor;
            const modifiers = tower.growthModifiers(player, run.tower_id);
            const opens_battle_event = !run.settlement_pending and
                current_room.room_type == @intFromEnum(tables.star_tower.RoomType.battle) and
                modifiers.battle_event_chance_per_thousand != 0 and
                run.battle_event_count < modifiers.battle_event_limit and
                tower.roll(run, modifiers.battle_event_chance_per_thousand);
            const battle_event_case_id = if (opens_battle_event) blk: {
                const event = tower.selectEvent(&run.event_rng_state);
                run.event_id = event.id;
                run.event_npc_id = event.npc_id;
                run.event_options = event.options;
                run.event_option_count = event.option_count;
                run.event_pending = true;
                run.battle_event_count +|= 1;

                break :blk try tower.addRoomCase(run, .select_event, 0);
            } else 0;

            // Event and shop rooms create their exit on entry. Combat rooms
            // create it after the Potential choice. Keep an existing exit
            // because the client may resolve it after selection or HP sync.
            const has_door = tower.activeRoomCaseIndex(run, .door) != null or opens_battle_event;
            const door = if (run.settlement_pending)
                proto.pb.DoorCaseData{ .Floor = 0, .Type = 0 }
            else blk: {
                const next_room = tables.star_tower.room(run.tower_id, run.pending_floor) orelse
                    return error.InvalidRunFloor;
                break :blk proto.pb.DoorCaseData{ .Floor = next_room.floor, .Type = next_room.room_type };
            };
            const door_case_id = if (!has_door) try tower.addRoomCase(run, .door, 0) else 0;
            const has_end_strengthen = run.settlement_pending and
                tower.growthModifiers(player, run.tower_id).enable_end_strengthen;
            const strengthen_case_id = if (has_end_strengthen)
                try tower.addRoomCase(run, .strengthen_machine, 0)
            else
                0;

            var cases: [2]proto.pb.StarTowerRoomCase = undefined;
            var next_case_count: usize = 0;
            if (opens_battle_event) {
                var affinity: [1]proto.pb.NPCAffinityInfo = .{.{
                    .NPCId = run.event_npc_id,
                    .Affinity = player.npcAffinity(run.event_npc_id),
                }};
                cases[next_case_count] = .{ .Id = battle_event_case_id, .SelectOptionsEventCase = .{
                    .EvtId = run.event_id,
                    .Options = .fromOwnedSlice(run.event_options[0..run.event_option_count]),
                    .NPCId = run.event_npc_id,
                    .Infos = .fromOwnedSlice(&affinity),
                } };
                next_case_count += 1;
            } else if (!has_door) {
                cases[next_case_count] = .{ .Id = door_case_id, .DoorCase = door };
                next_case_count += 1;
            }
            if (has_end_strengthen) {
                cases[next_case_count] = .{
                    .Id = strengthen_case_id,
                    .StrengthenMachineCase = .{
                        .Times = run.strengthen_times,
                        .FirstFree = run.strengthen_first_free_available,
                        .Discount = tower.growthModifiers(player, run.tower_id).strengthen_discount,
                    },
                };
                next_case_count += 1;
            }
            try scope.respond(proto.pb.StarTowerInteractResp{
                .Id = request_id,
                .Cases = .fromOwnedSlice(cases[0..next_case_count]),
                .Change = .{
                    .Props = .fromOwnedSlice(&changes),
                },
                .Data = .{},
                .SelectResp = .{
                    .Resp = .{
                        .Items = .fromOwnedSlice(&awarded),
                        .OptionsResult = false,
                    },
                },
            });
            try settlement.sendTowerBookPotentialChange(
                scope,
                potential_id,
                current_potential_level,
                tower_book_changed,
            );

            log.info("selected Ascension potential {d}", .{potential_id});

            return;
        }

        if (selected_case_kind != .select_event or
            run.room_case_resolved[selected_case_index] or
            !run.event_pending)
            return error.UnexpectedSelect;
        const index = select.Index orelse
            return error.InvalidSelect;
        if (index >= run.event_option_count)
            return error.InvalidSelect;
        const option_id = run.event_options[index];
        try event_interaction.resolve(scope, player, request_id, option_id);

        return;
    }

    if (tower.roomCaseIndex(run, request_id)) |case_index| if (run.room_case_kinds[case_index] == .npc_recovery_hp and !run.room_case_resolved[case_index]) {
        run.room_case_resolved[case_index] = true;

        try scope.respond(
            proto.pb.StarTowerInteractResp{
                .Id = request_id,
                .Change = .{},
                .Data = .{},
                .NilResp = .{},
            },
        );

        return;
    };

    return error.UnknownRoomCase;
}

fn roomData(room: tables.star_tower.Room, enter: proto.pb.InteractEnterReq.Decoded) proto.pb.StarTowerRoomData {
    return .{
        .Floor = room.floor,
        .MapId = enter.MapId,
        .ParamId = enter.ParamId,
        .RoomType = room.room_type,
        .MapParam = enter.MapParam,
        .MapTableId = enter.MapTableId,
    };
}

fn setRunMap(
    player: *Player,
    allocator: Allocator,
    enter: proto.pb.InteractEnterReq.Decoded,
) !void {
    const run = &player.star_tower_run;
    run.map_id = enter.MapId;
    run.map_param_id = enter.ParamId;
    run.map_table_id = enter.MapTableId;
    try player.setStarTowerMapParam(allocator, enter.MapParam);
    try player.setStarTowerClientData(
        allocator,
        enter.DateLen,
        enter.ClientData,
        enter.DataVersion,
    );
}

fn setRunClientData(
    player: *Player,
    allocator: Allocator,
    data_len: u32,
    client_data: []const u8,
    data_version: u32,
) !void {
    try player.setStarTowerClientData(allocator, data_len, client_data, data_version);
}
