const std = @import("std");

const gameplay = @import("../gameplay.zig");
const tower = gameplay.star_tower;

const Player = @import("../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

pub fn star_tower_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    const log = scope.logger(.star_tower_info_req);

    const player = scope.player;
    const run = &player.star_tower_run;
    if (!run.active)
        return scope.reject(.rgl_in_progress);
    const room = tables.star_tower.room(run.tower_id, run.floor) orelse
        return error.InvalidRunFloor;
    const formation = player.getFormation(run.formation_id) orelse
        return error.UnknownFormation;

    const character_count: usize = formation.character_count;
    const characters = try scope.arena.alloc(proto.pb.StarTowerChar, character_count);
    const character_gems = try scope.arena.alloc([3]proto.pb.StarTowerCharGem, character_count);
    const gem_attributes = try scope.arena.alloc([3][4]u32, character_count);
    const gem_overlocks = try scope.arena.alloc([3][4]u32, character_count);
    const skill_levels = try scope.arena.alloc([5]u32, character_count);
    const talent_nodes = try scope.arena.alloc([Player.Character.TalentNodes.wire_max_len]u8, character_count);
    @memset(std.mem.sliceAsBytes(gem_attributes), 0);
    @memset(std.mem.sliceAsBytes(gem_overlocks), 0);
    for (formation.character_ids[0..formation.character_count], 0..) |character_id, index| {
        const character = player.characters.get(character_id) orelse
            return error.UnknownCharacter;
        for (&character_gems[index], tables.character.gemSlots(character_id) orelse
            return error.UnknownCharacter, 0..) |*gem, slot_id, gem_index| gem.* = .{
            .SlotId = slot_id,
            .Attributes = .fromOwnedSlice(&gem_attributes[index][gem_index]),
            .OverlockCount = .fromOwnedSlice(&gem_overlocks[index][gem_index]),
        };
        skill_levels[index] = character.skillLevels();
        characters[index] = .{
            .Id = character_id,
            .Gems = .fromOwnedSlice(&character_gems[index]),
            .Level = character.level(),
            .SkillLvs = .fromOwnedSlice(&skill_levels[index]),
            .AffinityLevel = character.affinityLevel(),
            .Advance = character.advance(),
            .TalentNodes = character.writeTalentNodes(&talent_nodes[index]),
        };
    }

    const disc_count: usize = formation.disc_count;
    const discs = try scope.arena.alloc(proto.pb.StarTowerDisc, disc_count);
    for (formation.disc_ids[0..formation.disc_count], 0..) |disc_id, index| {
        if (disc_id == 0) {
            discs[index] = .{};
        } else if (tower.findDisc(player, disc_id)) |disc| {
            discs[index] = .{
                .Id = disc.id,
                .Level = @intFromEnum(disc.level),
                .Phase = @intFromEnum(disc.phase),
                .Star = @intFromEnum(disc.star),
            };
        } else {
            discs[index] = .{ .Id = disc_id, .Level = 1 };
        }
    }

    const tower_growth_nodes = try scope.arena.alloc(u32, tables.tower_growth.list.len);
    const tower_growth_node_count = tower.collectGrowthNodes(player, tower_growth_nodes);
    const items = try scope.arena.alloc(proto.pb.TowerItemInfo, run.tower_item_count);
    for (run.tower_item_ids[0..run.tower_item_count], 0..) |id, index|
        items[index] = .{ .Tid = id, .Qty = @intCast(run.tower_item_quantities[index]) };
    const owned_potentials = try scope.arena.alloc(proto.pb.PotentialInfo, run.potential_count);
    for (run.potential_ids[0..run.potential_count], 0..) |id, index|
        owned_potentials[index] = .{ .Tid = id, .Level = run.potential_levels[index] };
    var resources = [_]proto.pb.TowerResInfo{.{ .Tid = 11, .Qty = @intCast(run.tower_coins) }};
    const cases = try scope.arena.alloc(proto.pb.StarTowerRoomCase, run.room_case_count);
    const case_count = try resumeCases(scope, player, cases);

    try scope.respond(proto.pb.StarTowerInfo{
        .Meta = .{
            .Id = run.tower_id,
            .CharHp = run.char_hp,
            .TeamLevel = run.team_level,
            .TeamExp = run.team_exp,
            .Chars = .fromOwnedSlice(characters),
            .Discs = .fromOwnedSlice(discs),
            .ActiveSecondaryIds = .fromOwnedSlice(
                @constCast(run.active_secondary_ids[0..run.active_secondary_count]),
            ),
            .NPCInteractions = player.progress.star_tower_npc_interactions,
            .TotalTime = run.settlement_time,
            .DateLen = run.client_data_declared_len,
            .ClientData = player.star_tower_client_data.slice(),
            .TowerGrowthNodes = .fromOwnedSlice(tower_growth_nodes[0..tower_growth_node_count]),
            .TotalDamages = .fromOwnedSlice(@constCast(run.total_damages[0..run.total_damage_count])),
            .BuildId = run.build_id,
            .DataVersion = run.client_data_version,
        },
        .Room = .{
            .Data = .{
                .Floor = room.floor,
                .MapId = run.map_id,
                .ParamId = run.map_param_id,
                .RoomType = room.room_type,
                .MapParam = player.star_tower_map_param.slice(),
                .MapTableId = run.map_table_id,
            },
            .Cases = .fromOwnedSlice(cases[0..case_count]),
        },
        .Bag = .{
            .Potentials = .fromOwnedSlice(owned_potentials),
            .Items = .fromOwnedSlice(items),
            .Res = .fromOwnedSlice(&resources),
        },
    });
    log.info("resumed Ascension {d} at floor {d}", .{ run.tower_id, run.floor });
}

fn resumeCases(
    scope: *Scope,
    player: *const Player,
    cases: []proto.pb.StarTowerRoomCase,
) !usize {
    const run = &player.star_tower_run;
    const potential_infos = try scope.arena.alloc(proto.pb.PotentialInfo, run.offered_potential_count);
    for (run.offered_potential_ids[0..run.offered_potential_count], 0..) |id, index|
        potential_infos[index] = .{ .Tid = id, .Level = run.offered_potential_levels[index] };
    const goods = try scope.arena.alloc(proto.pb.HawkerGoods, run.shop_goods_count);
    const purchases = try scope.arena.alloc(u32, run.shop_goods_count);
    var purchase_count: usize = 0;
    for (0..run.shop_goods_count) |index| {
        goods[index] = .{
            .Sid = run.shop_good_sids[index],
            .Idx = run.shop_good_indices[index],
            .CharPos = run.shop_good_char_positions[index],
            .Price = @intCast(run.shop_good_display_prices[index]),
            .Discount = @intCast(run.shop_good_discounts[index]),
            .Type = run.shop_good_kinds[index],
            .GoodsId = run.shop_good_ids[index],
            .Tag = run.shop_good_tags[index],
        };
        if (run.shop_good_purchased[index]) {
            purchases[purchase_count] = run.shop_good_sids[index];
            purchase_count += 1;
        }
    }
    const affinity = try scope.arena.alloc(proto.pb.NPCAffinityInfo, 1);
    affinity[0] = .{
        .NPCId = run.event_npc_id,
        .Affinity = player.npcAffinity(run.event_npc_id),
    };
    const next_room = if (run.pending_floor != 0) tables.star_tower.room(run.tower_id, run.pending_floor) else null;

    var count: usize = 0;
    for (0..run.room_case_count) |index| {
        if (run.room_case_resolved[index])
            continue;
        const id = run.room_case_ids[index];
        cases[count] = switch (run.room_case_kinds[index]) {
            .battle => .{ .Id = id, .BattleCase = .{} },
            .sync_hp => .{ .Id = id, .SyncHPCase = .{} },
            .door => .{ .Id = id, .DoorCase = if (run.pending_floor == 0)
                .{ .Floor = 0, .Type = 0 }
            else if (next_room) |next|
                .{ .Floor = next.floor, .Type = next.room_type }
            else
                return error.InvalidRunFloor },
            .select_special_potential => .{ .Id = id, .SelectSpecialPotentialCase = .{
                .Ids = .fromOwnedSlice(@constCast(run.offered_potential_ids[0..run.offered_potential_count])),
                .NewIds = .fromOwnedSlice(@constCast(run.offered_potential_ids[0..run.offered_potential_count])),
                .TeamLevel = run.team_level,
                .CanReRoll = run.potential_rerolls != 0,
                .ReRollPrice = run.potential_reroll_price,
            } },
            .select_potential => .{ .Id = id, .SelectPotentialCase = .{
                .Infos = .fromOwnedSlice(potential_infos[0..run.offered_potential_count]),
                .NewIds = .fromOwnedSlice(@constCast(run.offered_potential_ids[0..run.offered_potential_count])),
                .TeamLevel = run.team_level,
                .CanReRoll = run.potential_rerolls != 0,
                .ReRollPrice = run.potential_reroll_price,
                .Type = if (run.potential_selector_is_strengthen) 2 else if (run.shop_potential_pending) 4 else 1,
            } },
            .select_event => .{ .Id = id, .SelectOptionsEventCase = .{
                .EvtId = run.event_id,
                .Options = .fromOwnedSlice(@constCast(run.event_options[0..run.event_option_count])),
                .NPCId = run.event_npc_id,
                .Infos = .fromOwnedSlice(affinity),
            } },
            .recovery_hp => .{ .Id = id, .RecoveryHPCase = .{ .EffectId = run.room_case_effect_ids[index] } },
            .npc_recovery_hp => .{ .Id = id, .NpcRecoveryHPCase = .{ .EffectId = run.room_case_effect_ids[index] } },
            .hawker => .{ .Id = id, .HawkerCase = .{
                .List = .fromOwnedSlice(goods[0..run.shop_goods_count]),
                .Purchase = .fromOwnedSlice(purchases[0..purchase_count]),
                .CanReRoll = run.shop_rerolls != 0,
                .ReRollPrice = run.shop_reroll_price,
                .ReRollTimes = run.shop_rerolls,
            } },
            .strengthen_machine => .{ .Id = id, .StrengthenMachineCase = .{
                .Times = run.strengthen_times,
                .FirstFree = run.strengthen_first_free_available,
                .Discount = tower.growthModifiers(player, run.tower_id).strengthen_discount,
            } },
            .none => continue,
        };
        count += 1;
    }

    return count;
}
