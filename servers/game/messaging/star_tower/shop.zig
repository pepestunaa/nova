const std = @import("std");
const Io = std.Io;

const gameplay = @import("../../gameplay.zig");
const tower = gameplay.star_tower;
const Player = @import("../../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../../Scope.zig");
const tables = @import("../../tables.zig");

//

pub fn initialize(player: *const Player, run: *Player.StarTowerRun, floor: u32) void {
    if (run.shop_floor == floor) return;

    const modifiers = tower.growthModifiers(player, run.tower_id);
    run.shop_floor = floor;
    run.shop_goods_count = modifiers.shop_good_count;
    run.shop_good_sids = @splat(0);
    run.shop_good_indices = @splat(0);
    run.shop_good_char_positions = @splat(0);
    run.shop_good_display_prices = @splat(0);
    run.shop_good_prices = @splat(0);
    run.shop_good_kinds = @splat(0);
    run.shop_good_ids = @splat(0);
    run.shop_good_quantities = @splat(0);
    run.shop_good_tags = @splat(0);
    run.shop_good_discounts = @splat(0);
    run.shop_good_purchased = @splat(false);

    // At least half the shop offers Potential selectors, and every expanded
    // shop includes a Musical Note pack. Saved random state keeps its stock
    // unchanged after reconnecting.
    const total: usize = run.shop_goods_count;
    const min_potentials = @max(total / 2, 2);
    const max_potentials = @max(total - 1, min_potentials);
    const potential_count = min_potentials + tower.randomBelow(run, max_potentials - min_potentials + 1);
    const formation = player.getFormation(run.formation_id);

    for (0..potential_count) |index| {
        const character_position: u32 = if (formation != null and formation.?.character_count != 0 and tower.roll(run, 200))
            @intCast(1 + tower.randomBelow(run, formation.?.character_count))
        else
            0;
        setShopGood(run, index, .{
            .index = tables.star_tower_shop.potential_selector.id,
            .char_position = character_position,
            .price = 200,
            .kind = .potential,
            .id = 102,
        });
    }

    for (potential_count..total) |index| {
        const premium = run.tower_coins >= 500 and tower.roll(run, 250);
        const entry = if (premium)
            tables.star_tower_shop.premium_note_pack
        else
            tables.star_tower_shop.standard_note_pack;
        setShopGood(run, index, .{
            .index = entry.id,
            .price = if (premium) 400 else 90,
            .kind = .tower_item,
            .id = tower.randomBattleNote(run),
            .quantity = entry.display_quantity,
        });
    }

    applyShopDiscounts(run, modifiers.shop_discount_tier);
}

fn applyShopDiscounts(run: *Player.StarTowerRun, tier: u8) void {
    const count: usize = switch (tier) {
        1 => 2,
        2 => 3,
        3 => 4,
        else => return,
    };
    const extra_half_price: usize = switch (tier) {
        2 => 1,
        3 => 2,
        else => 0,
    };
    const extra_half_price_chance_per_thousand: u16 = switch (tier) {
        2 => 300,
        3 => 700,
        else => 0,
    };
    var chosen: [Player.StarTowerRun.max_shop_goods]bool = @splat(false);

    for (0..@min(count, @as(usize, run.shop_goods_count))) |_| {
        var index = @as(usize, @intCast(tower.nextRandom(run) % run.shop_goods_count));
        while (chosen[index]) index = (index + 1) % run.shop_goods_count;
        chosen[index] = true;
        // Member Discount I discounts 2 items by 80%. Tiers II and III
        // discount 3 or 4 items by 20%, then have a 30% or 70% chance to
        // raise a random subset to 50%.
        const discounted = if (tier == 1)
            tower.divCeil(run.shop_good_display_prices[index], 5)
        else
            tower.divCeil(run.shop_good_display_prices[index] * 80, 100);
        run.shop_good_prices[index] = discounted;
        run.shop_good_discounts[index] = discounted;
    }

    if (extra_half_price == 0 or !tower.roll(run, extra_half_price_chance_per_thousand))
        return;

    var upgraded: [Player.StarTowerRun.max_shop_goods]bool = @splat(false);

    for (0..@min(extra_half_price, @min(count, @as(usize, run.shop_goods_count)))) |_| {
        var index = @as(usize, @intCast(tower.nextRandom(run) % run.shop_goods_count));
        while (!chosen[index] or upgraded[index]) index = (index + 1) % run.shop_goods_count;
        upgraded[index] = true;
        const discounted = tower.divCeil(run.shop_good_display_prices[index], 2);
        run.shop_good_prices[index] = discounted;
        run.shop_good_discounts[index] = discounted;
    }
}

const ShopGoodKind = enum(u32) {
    potential = 1,
    tower_item = 2,
};

const ShopGoodTemplate = struct {
    index: u32,
    char_position: u32 = 0,
    price: u32,
    kind: ShopGoodKind,
    id: u32,
    quantity: u32 = 1,
    tag: u32 = 1,
};

fn setShopGood(
    run: *Player.StarTowerRun,
    index: usize,
    template: ShopGoodTemplate,
) void {
    run.shop_good_sids[index] = @intCast(index + 1);
    run.shop_good_indices[index] = template.index;
    run.shop_good_char_positions[index] = template.char_position;
    run.shop_good_display_prices[index] = template.price;
    run.shop_good_prices[index] = template.price;
    run.shop_good_kinds[index] = @intFromEnum(template.kind);
    run.shop_good_ids[index] = template.id;
    run.shop_good_quantities[index] = template.quantity;
    run.shop_good_tags[index] = template.tag;
}

pub fn interact(
    scope: *Scope,
    player: *Player,
    request_id: u32,
    hawker: proto.pb.InteractHawkerReq.Decoded,
) !void {
    const log = scope.logger(.star_tower_interact_req);
    const run = &player.star_tower_run;
    const room = tables.star_tower.room(run.tower_id, run.floor) orelse
        return error.InvalidRunFloor;
    const hawker_case_index = tower.roomCaseIndex(run, request_id) orelse
        return error.UnexpectedHawker;
    if (room.room_type != @intFromEnum(tables.star_tower.RoomType.shop) or
        run.room_case_kinds[hawker_case_index] != .hawker or
        run.room_case_resolved[hawker_case_index])
        return error.UnexpectedHawker;

    const sid = hawker.Sid orelse {
        if (hawker.ReRoll == null or !hawker.ReRoll.?)
            return error.InvalidHawkerAction;

        if (run.shop_rerolls == 0 or run.shop_reroll_price > run.tower_coins) {
            try scope.respond(proto.pb.StarTowerInteractResp{ .Id = request_id, .Change = .{}, .Data = .{}, .NilResp = .{} });
            return;
        }

        const reroll_price = run.shop_reroll_price;
        run.shop_rerolls -= 1;
        run.tower_coins -= reroll_price;
        run.shop_floor = 0;
        initialize(player, run, room.floor);
        gameplay.research_project.restockedShop(player);

        scope.markDirty();

        try respondShopReroll(scope, request_id, run, reroll_price);
        log.info("refreshed Ascension shop for {d} currency; {d} refresh(es) remain", .{
            reroll_price,
            run.shop_rerolls,
        });

        return;
    };
    var selected: ?usize = null;
    for (0..run.shop_goods_count) |index| {
        if (run.shop_good_sids[index] == sid) {
            selected = index;
            break;
        }
    }
    const good_index = selected orelse
        return error.UnknownShopGood;
    const price = run.shop_good_prices[good_index];
    const is_discounted = run.shop_good_discounts[good_index] != 0;
    if (run.shop_good_purchased[good_index] or price > run.tower_coins) {
        try scope.respond(proto.pb.StarTowerInteractResp{ .Id = request_id, .Change = .{}, .Data = .{}, .NilResp = .{} });
        return;
    }

    const kind: ShopGoodKind = switch (run.shop_good_kinds[good_index]) {
        @intFromEnum(ShopGoodKind.potential) => .potential,
        @intFromEnum(ShopGoodKind.tower_item) => .tower_item,
        else => return error.UnsupportedShopGood,
    };
    switch (kind) {
        .tower_item => {
            const item_id = run.shop_good_ids[good_index];
            const item_quantity = run.shop_good_quantities[good_index];
            const is_new = tower.itemQuantity(run, item_id) == 0;
            try tower.addItem(run, item_id, item_quantity);
            const formation = player.getFormation(run.formation_id) orelse
                return error.UnknownFormation;
            var secondary_changes: [tables.disc_secondary.max_changes]tower.SecondaryChange = undefined;
            const secondary_change_slice = tower.reconcileActiveSecondaries(run, formation, &secondary_changes);
            if (tables.star_tower_note.contains(item_id))
                gameplay.research_project.collectedMusicalNotes(player, item_quantity);
            gameplay.research_project.activatedHarmonySkills(player, activatedSecondaries(secondary_change_slice));
            run.shop_good_purchased[good_index] = true;
            run.tower_coins -= price;
            run.shop_potential_pending = false;
            gameplay.research_project.purchasedShopGood(player, is_discounted);

            scope.markDirty();

            try respondTowerItemPurchase(scope, request_id, item_id, item_quantity, is_new, price, secondary_change_slice);

            log.info("bought Ascension shop item {d} x{d} for {d} currency", .{
                item_id,
                item_quantity,
                price,
            });
        },
        .potential => {
            const formation = player.getFormation(run.formation_id) orelse
                return error.UnknownFormation;
            // 0 means the selector is not restricted to a Trekker.
            const character_position = run.shop_good_char_positions[good_index];
            const character_override = if (character_position == 0)
                null
            else blk: {
                const formation_index = character_position - 1;
                if (formation_index >= formation.character_count)
                    return error.InvalidShopCharacterPosition;
                break :blk formation.character_ids[formation_index];
            };
            tower.offerPotentials(
                player,
                run,
                formation,
                false,
                character_override,
            );
            if (run.offered_potential_count == 0) return error.NoPotentialChoices;

            run.shop_good_purchased[good_index] = true;
            run.tower_coins -= price;
            run.shop_potential_pending = true;
            gameplay.research_project.purchasedShopGood(player, is_discounted);
            const potential_case_id = try tower.addRoomCase(run, .select_potential, 0);

            scope.markDirty();

            try respondPotentialPurchase(scope, request_id, run, potential_case_id, price);

            if (character_override) |character_id| {
                log.info("bought Ascension shop good {d} for {d} currency (character {d})", .{
                    sid,
                    price,
                    character_id,
                });
            } else {
                log.info("bought Ascension shop good {d} for {d} currency", .{ sid, price });
            }
        },
    }
}

pub fn activatedSecondaries(changes: []const tower.SecondaryChange) u32 {
    var count: u32 = 0;
    for (changes) |change| {
        if (change.active) count += 1;
    }

    return count;
}

fn respondTowerItemPurchase(
    scope: *Scope,
    request_id: u32,
    item_id: u32,
    item_quantity: u32,
    is_new: bool,
    price: u32,
    secondary_changes: []const tower.SecondaryChange,
) !void {
    var encoded_currency: [16]u8 = undefined;
    var currency_writer = Io.Writer.fixed(&encoded_currency);
    const currency: proto.pb.TowerResInfo = .{
        .Tid = 11,
        .Qty = -@as(i32, @intCast(price)),
    };
    try proto.encode(proto.pb.TowerResInfo, &currency_writer, &currency);
    var encoded_item: [16]u8 = undefined;
    var item_writer = Io.Writer.fixed(&encoded_item);
    const item: proto.pb.TowerItemInfo = .{
        .Tid = item_id,
        .Qty = @intCast(item_quantity),
    };
    try proto.encode(proto.pb.TowerItemInfo, &item_writer, &item);
    var changes: [2]proto.pb.Any = .{
        .{
            .type_url = "type.googleapis.com/proto.TowerResInfo",
            .value = currency_writer.buffered(),
        },
        .{
            .type_url = "type.googleapis.com/proto.TowerItemInfo",
            .value = item_writer.buffered(),
        },
    };
    var items: [1]proto.pb.SubNoteSkillInfo = .{.{
        .Tid = item.Tid,
        .Qty = item.Qty,
        .New = is_new,
    }};
    var secondaries: [tables.disc_secondary.max_changes]proto.pb.ActiveSecondaryChange = undefined;
    for (secondary_changes, 0..) |secondary, index| secondaries[index] = .{
        .SecondaryId = secondary.id,
        .Active = secondary.active,
    };
    try scope.respond(proto.pb.StarTowerInteractResp{
        .Id = request_id,
        .Change = .{ .Props = .fromOwnedSlice(&changes) },
        .Data = .{
            .Infos = .fromOwnedSlice(&items),
            .Secondaries = .fromOwnedSlice(secondaries[0..secondary_changes.len]),
        },
        .NilResp = .{},
    });
}

fn respondShopReroll(
    scope: *Scope,
    request_id: u32,
    run: *const Player.StarTowerRun,
    price: u32,
) !void {
    var goods: [Player.StarTowerRun.max_shop_goods]proto.pb.HawkerGoods = undefined;
    for (0..run.shop_goods_count) |index| goods[index] = .{
        .Sid = run.shop_good_sids[index],
        .Idx = run.shop_good_indices[index],
        .CharPos = run.shop_good_char_positions[index],
        .Price = @intCast(run.shop_good_display_prices[index]),
        .Discount = @intCast(run.shop_good_discounts[index]),
        .Type = run.shop_good_kinds[index],
        .GoodsId = run.shop_good_ids[index],
        .Tag = run.shop_good_tags[index],
    };
    var encoded_currency: [16]u8 = undefined;
    var currency_writer = Io.Writer.fixed(&encoded_currency);
    const currency: proto.pb.TowerResInfo = .{ .Tid = 11, .Qty = -@as(i32, @intCast(price)) };
    try proto.encode(proto.pb.TowerResInfo, &currency_writer, &currency);
    var changes = [_]proto.pb.Any{.{
        .type_url = "type.googleapis.com/proto.TowerResInfo",
        .value = currency_writer.buffered(),
    }};
    try scope.respond(proto.pb.StarTowerInteractResp{
        .Id = request_id,
        .Change = .{ .Props = .fromOwnedSlice(&changes) },
        .Data = .{},
        .SelectResp = .{
            .HawkerCase = .{
                .List = .fromOwnedSlice(goods[0..run.shop_goods_count]),
                .CanReRoll = run.shop_rerolls != 0,
                .ReRollPrice = run.shop_reroll_price,
                .ReRollTimes = run.shop_rerolls,
            },
        },
    });
}

fn respondPotentialPurchase(
    scope: *Scope,
    request_id: u32,
    run: *Player.StarTowerRun,
    potential_case_id: u32,
    price: u32,
) !void {
    var potential_infos: [3]proto.pb.PotentialInfo = undefined;
    for (run.offered_potential_ids[0..run.offered_potential_count], 0..) |potential_id, index|
        potential_infos[index] = .{ .Tid = potential_id, .Level = run.offered_potential_levels[index] };
    var encoded_currency: [16]u8 = undefined;
    var currency_writer = Io.Writer.fixed(&encoded_currency);
    const currency: proto.pb.TowerResInfo = .{
        .Tid = 11,
        .Qty = -@as(i32, @intCast(price)),
    };
    try proto.encode(proto.pb.TowerResInfo, &currency_writer, &currency);
    var changes: [1]proto.pb.Any = .{.{
        .type_url = "type.googleapis.com/proto.TowerResInfo",
        .value = currency_writer.buffered(),
    }};
    var cases: [1]proto.pb.StarTowerRoomCase = .{.{
        .Id = potential_case_id,
        .SelectPotentialCase = .{
            .Infos = .fromOwnedSlice(potential_infos[0..run.offered_potential_count]),
            .NewIds = .fromOwnedSlice(run.offered_potential_ids[0..run.offered_potential_count]),
            .CanReRoll = run.potential_rerolls != 0,
            .ReRollPrice = run.potential_reroll_price,
            .Type = 4,
        },
    }};
    try scope.respond(proto.pb.StarTowerInteractResp{
        .Id = request_id,
        .Cases = .fromOwnedSlice(&cases),
        .Change = .{ .Props = .fromOwnedSlice(&changes) },
        .Data = .{},
        .NilResp = .{},
    });
}
