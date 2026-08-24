const std = @import("std");
const Io = std.Io;

const gameplay = @import("../gameplay.zig");
const tower = gameplay.star_tower;

const Player = @import("../store/Player.zig");
const proto = @import("proto");
const research_project_notify = @import("../notify/research_project.zig");
const Scope = @import("../Scope.zig");
const settlement = @import("star_tower/settlement.zig");
const shop = @import("star_tower/shop.zig");
const star_tower_record = @import("../gameplay/star_tower/record.zig");
const tables = @import("../tables.zig");

//

/// Starts a saved Ascension. The client chooses the map layout, while the
/// server owns and validates Monolith and floor progression.
pub fn star_tower_apply_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_apply_req);

    const request = try scope.source.read(proto.pb.StarTowerApplyReq);
    const request_id = request.Id;
    const player = scope.playerMut();
    if (player.star_tower_run.active) {
        return scope.reject(.rgl_in_progress);
    }
    const first_room = tables.star_tower.room(request_id, 1) orelse
        return scope.reject(.rgl_cond);
    const formation = player.getFormation(request.FormationId) orelse
        return scope.reject(.formation_id_need);
    const spent_sweep_ticket: ?u32 = if (request.Sweep) blk: {
        if (!gameplay.tower_growth.has(player, 10301))
            return scope.reject(.rgl_cond);
        break :blk settlement.consumeSweepTicket(player, scope.gpa) catch
            return scope.reject(.rgl_cond);
    } else null;

    const character_count: usize = formation.character_count;
    const characters = try scope.arena.alloc(proto.pb.StarTowerChar, character_count);
    const character_gems = try scope.arena.alloc([3]proto.pb.StarTowerCharGem, character_count);
    const gem_attributes = try scope.arena.alloc([3][4]u32, character_count);
    const gem_overlocks = try scope.arena.alloc([3][4]u32, character_count);
    const skill_levels = try scope.arena.alloc([5]u32, character_count);
    const talent_nodes = try scope.arena.alloc([Player.Character.TalentNodes.wire_max_len]u8, character_count);
    @memset(std.mem.sliceAsBytes(gem_attributes), 0);
    @memset(std.mem.sliceAsBytes(gem_overlocks), 0);
    for (formation.character_ids[0..character_count], 0..) |character_id, index| {
        const character = player.characters.get(character_id) orelse
            return scope.reject(.rgl_cond);
        for (&character_gems[index], tables.character.gemSlots(character_id) orelse
            return scope.reject(.rgl_cond), 0..) |*gem, slot_id, gem_index| gem.* = .{
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
    for (formation.disc_ids[0..disc_count], 0..) |disc_id, index| {
        // 0 marks an empty Runic Disc slot.
        if (disc_id == 0) {
            discs[index] = .{};
            continue;
        }
        const disc = tower.findDisc(player, disc_id) orelse {
            log.warn("formation references unavailable disc {d}", .{disc_id});
            discs[index] = .{ .Id = disc_id, .Level = 1 };

            continue;
        };
        discs[index] = .{
            .Id = disc.id,
            .Level = @intFromEnum(disc.level),
            .Phase = @intFromEnum(disc.phase),
            .Star = @intFromEnum(disc.star),
        };
    }

    const tower_growth_nodes = try scope.arena.alloc(u32, tables.tower_growth.list.len);
    const tower_growth_node_count = tower.collectGrowthNodes(player, tower_growth_nodes);
    const modifiers = tower.growthModifiers(player, request_id);
    const initial_tower_coins = 200 + modifiers.starting_coins;
    const initial_map_id = if (!request.Sweep and request.MapId != 0 and request.MapId != std.math.maxInt(u32))
        request.MapId
    else
        tables.star_tower.defaultMap(first_room) orelse 0;
    const initial_map_table_id = if (!request.Sweep and request.MapTableId != 0 and request.MapTableId != std.math.maxInt(u32))
        request.MapTableId
    else
        initial_map_id;
    const now = Io.Timestamp.now(scope.io, .real).toSeconds();
    player.resetStarTowerRun();
    const run = &player.star_tower_run;
    run.active = true;
    run.build_id = star_tower_record.newBuildId(player, @intCast(now));
    run.sweep = request.Sweep;
    run.tower_id = request_id;
    run.formation_id = formation.number;
    run.floor = 1;
    run.map_id = initial_map_id;
    run.map_param_id = if (request.Sweep) 0 else request.ParamId;
    run.map_table_id = initial_map_table_id;
    try player.setStarTowerMapParam(scope.gpa, request.MapParam);
    run.char_hp = request.CharHp;
    run.tower_coins = initial_tower_coins;
    run.event_rng_state = tower.newRunSeed(
        now,
        player.uid orelse 0,
        request_id,
    );
    run.shop_rerolls = modifiers.shop_rerolls;
    run.shop_reroll_price = modifiers.shop_reroll_price;
    run.strengthen_first_free_available = modifiers.first_strengthen_free;
    run.note_element = if (modifiers.restrict_notes_to_matching_element) blk: {
        const element = tables.character.element(formation.character_ids[0]) orelse
            break :blk 0;
        if (!tables.star_tower.hasElement(request_id, element))
            break :blk 0;

        break :blk @intFromEnum(element);
    } else 0;
    const battle_case_id = try tower.addRoomCase(run, .battle, 0);
    const sync_case_id = try tower.addRoomCase(run, .sync_hp, 0);
    var cases: [2]proto.pb.StarTowerRoomCase = .{
        .{
            .Id = battle_case_id,
            .BattleCase = .{},
        },
        .{
            .Id = sync_case_id,
            .SyncHPCase = .{},
        },
    };
    gameplay.research_project.enteredAscension(player);
    const initial_items = try scope.arena.alloc(
        proto.pb.TowerItemInfo,
        Player.StarTowerRun.max_tower_items,
    );
    var initial_item_count: usize = 0;
    try addInitialTowerItem(initial_items, &initial_item_count, 90017, 3);
    for (0..modifiers.starting_notes) |_| {
        try addInitialTowerItem(
            initial_items,
            &initial_item_count,
            tower.randomBattleNote(run),
            1,
        );
    }
    // The first 3 slots hold combat Runic Discs. Monolith Research unlocks
    // later Support Disc slots, whose promotion Notes begin in the Ascension
    // bag rather than permanent inventory.
    const support_start = @min(formation.disc_count, tables.disc_secondary.max_combat_discs);
    const support_count = @min(
        @as(usize, modifiers.support_disc_capacity),
        formation.disc_count - support_start,
    );
    for (formation.disc_ids[support_start..][0..support_count]) |disc_id| {
        if (disc_id == 0)
            continue;
        const disc = tower.findDisc(player, disc_id) orelse
            continue;
        const support_notes = tables.disc_secondary.supportNotes(
            disc_id,
            @intFromEnum(disc.phase),
        );
        for (support_notes.ids[0..support_notes.count], support_notes.quantities[0..support_notes.count]) |note_id, quantity| {
            try addInitialTowerItem(initial_items, &initial_item_count, note_id, quantity);
        }
    }
    for (initial_items[0..initial_item_count]) |item|
        try tower.addItem(run, item.Tid, @intCast(item.Qty));
    var initial_secondary_changes: [tables.disc_secondary.max_changes]tower.SecondaryChange = undefined;
    const initial_secondary_change_slice = tower.reconcileActiveSecondaries(
        run,
        formation,
        &initial_secondary_changes,
    );
    gameplay.research_project.activatedHarmonySkills(
        player,
        shop.activatedSecondaries(initial_secondary_change_slice),
    );
    var initial_resources: [1]proto.pb.TowerResInfo = .{.{
        .Tid = 11,
        .Qty = @intCast(initial_tower_coins),
    }};
    var encoded_sweep_ticket: [16]u8 = undefined;
    var sweep_changes: [1]proto.pb.Any = undefined;
    const sweep_change_count: usize = if (request.Sweep) blk: {
        const change: proto.pb.Res = .{ .Tid = spent_sweep_ticket.?, .Qty = -1 };
        var writer = Io.Writer.fixed(&encoded_sweep_ticket);
        try proto.encode(proto.pb.Res, &writer, &change);
        sweep_changes[0] = .{
            .type_url = "type.googleapis.com/proto.Res",
            .value = writer.buffered(),
        };

        break :blk 1;
    } else 0;
    try scope.respond(proto.pb.StarTowerApplyResp{
        .Info = .{
            .Meta = .{
                .Id = request_id,
                .CharHp = request.CharHp,
                .TeamLevel = 1,
                .Chars = .fromOwnedSlice(characters),
                .Discs = .fromOwnedSlice(discs),
                .ActiveSecondaryIds = .fromOwnedSlice(
                    run.active_secondary_ids[0..run.active_secondary_count],
                ),
                .NPCInteractions = player.progress.star_tower_npc_interactions,
                .TotalTime = run.settlement_time,
                .TowerGrowthNodes = .fromOwnedSlice(tower_growth_nodes[0..tower_growth_node_count]),
                .BuildId = run.build_id,
            },
            .Room = .{
                .Data = .{
                    .Floor = 1,
                    .MapId = run.map_id,
                    .ParamId = run.map_param_id,
                    .RoomType = first_room.room_type,
                    .MapParam = player.star_tower_map_param.slice(),
                    .MapTableId = run.map_table_id,
                },
                .Cases = .fromOwnedSlice(&cases),
            },
            .Bag = .{
                .Items = .fromOwnedSlice(initial_items[0..initial_item_count]),
                .Res = .fromOwnedSlice(&initial_resources),
            },
        },
        .SweepTicket = @intCast(@max(player.resourceQuantity(settlement.sweep_ticket_id), 0)),
        .SweepTicketUndated = @intCast(@max(player.resourceQuantity(settlement.sweep_ticket_undated_id), 0)),
        .Change = .{ .Props = .fromOwnedSlice(sweep_changes[0..sweep_change_count]) },
    });
    try research_project_notify.send(scope);

    scope.markDirty();

    log.info("started Ascension {d} with formation {d}", .{ request_id, formation.number });
}

/// Merges identical Musical Notes before sending `StarTowerBag.Items`, which
/// the client indexes by item ID and cannot represent as duplicate entries.
fn addInitialTowerItem(
    items: []proto.pb.TowerItemInfo,
    count: *usize,
    item_id: u32,
    quantity: u32,
) error{FullTowerInventory}!void {
    for (items[0..count.*]) |*item| {
        if (item.Tid != item_id)
            continue;
        item.Qty +|= @intCast(quantity);

        return;
    }
    if (count.* == items.len)
        return error.FullTowerInventory;
    items[count.*] = .{ .Tid = item_id, .Qty = @intCast(quantity) };
    count.* += 1;
}
