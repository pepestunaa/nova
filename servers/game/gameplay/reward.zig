const std = @import("std");
const Allocator = std.mem.Allocator;

const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

//

pub const max_gacha_changes = tables.gacha_newbie.cards_per_spin * 2 + 1;
pub const max_reward_changes = 16;

pub const Error = error{Full} || std.mem.Allocator.Error;
pub const GachaCostError = error{InsufficientCurrency} || Error;

pub const ResourceDelta = struct {
    id: u32,
    quantity: i32,
};

pub const GachaAcquisition = struct {
    id: u32,
    begin: u32,
    count: u32,
};

pub const ItemTemplateDelta = struct {
    id: u32,
    quantity: i32,
};

pub const InventoryItemDelta = struct {
    id: u64,
    template_id: u32,
    quantity: i32,
    expires_at: i64,
};

pub const ResourceDeltaSet = struct {
    entries: [max_gacha_changes]ResourceDelta = undefined,
    len: usize = 0,

    pub fn add(deltas: *ResourceDeltaSet, resource_id: u32, quantity: i32) error{Full}!void {
        for (deltas.entries[0..deltas.len]) |*resource| {
            if (resource.id != resource_id)
                continue;

            resource.quantity +|= quantity;

            return;
        }

        if (deltas.len == deltas.entries.len)
            return error.Full;

        deltas.entries[deltas.len] = .{ .id = resource_id, .quantity = quantity };
        deltas.len += 1;
    }
};

pub const GachaReceipt = struct {
    card_acquisitions: [tables.gacha_newbie.cards_per_spin]GachaAcquisition = undefined,
    card_acquisition_count: usize = 0,
    new_card_ids: [tables.gacha_newbie.cards_per_spin]u32 = undefined,
    new_card_count: usize = 0,
    transform_sources: [tables.gacha_newbie.cards_per_spin]ItemTemplateDelta = undefined,
    transform_source_count: usize = 0,
    transform_destinations: [max_gacha_changes]ItemTemplateDelta = undefined,
    transform_destination_count: usize = 0,
    item_deltas: [max_gacha_changes]InventoryItemDelta = undefined,
    item_delta_count: usize = 0,
    resource_deltas: ResourceDeltaSet = .{},

    pub fn cardAcquisitionIndex(receipt: *const GachaReceipt, card_id: u32) ?usize {
        for (receipt.card_acquisitions[0..receipt.card_acquisition_count], 0..) |entry, index| {
            if (entry.id == card_id)
                return index;
        }

        return null;
    }
};

pub const ResourceReceipt = struct {
    resource_deltas: ResourceDeltaSet = .{},
    item_deltas: [max_reward_changes]InventoryItemDelta = undefined,
    item_delta_count: usize = 0,
};

pub fn grantResource(
    mutation: *Mutation,
    allocator: Allocator,
    receipt: *ResourceReceipt,
    resource_id: u32,
    quantity: i32,
) Error!void {
    if (quantity == 0)
        return;
    const player = mutation.modify(.{});
    try applyResourceDelta(player, allocator, receipt, resource_id, quantity);
}

/// Adds an item reward and records it for the response's ChangeInfo.
pub fn grantItem(
    mutation: *Mutation,
    allocator: Allocator,
    receipt: *ResourceReceipt,
    template_id: u32,
    quantity: i32,
) Error!void {
    if (quantity == 0)
        return;

    const player = mutation.modify(.{});
    try applyRewardItemDelta(player, allocator, receipt, template_id, quantity);
}

/// Spends Recruitment tickets first, then converts enough premium currency to
/// cover the difference. Both changes are returned with the drawn rewards.
pub fn consumeRecruitmentCost(
    mutation: *Mutation,
    allocator: Allocator,
    receipt: *GachaReceipt,
    ticket_id: u32,
    ticket_quantity: u32,
    currency_id: u32,
    currency_per_ticket: u32,
) GachaCostError!void {
    const current = mutation.read();
    const available_tickets: u32 = @intCast(@max(current.itemQuantity(ticket_id), 0));
    const consumed_tickets = @min(available_tickets, ticket_quantity);
    const converted_tickets = ticket_quantity - consumed_tickets;
    const currency_cost: u64 = @as(u64, converted_tickets) * currency_per_ticket;
    if (currency_cost > std.math.maxInt(i32) or
        current.resourceQuantity(currency_id) < @as(i32, @intCast(currency_cost)))
        return error.InsufficientCurrency;

    if (consumed_tickets == 0 and currency_cost == 0)
        return;
    const player = mutation.modify(.{});

    if (consumed_tickets != 0) {
        player.consumeItem(ticket_id, @intCast(consumed_tickets)) catch unreachable;
        try addInventoryItemDelta(receipt, ticket_id, ticket_id, -@as(i32, @intCast(consumed_tickets)), 0);
    }
    if (currency_cost != 0)
        try applyResourceDelta(player, allocator, receipt, currency_id, -@as(i32, @intCast(currency_cost)));
}

pub fn grantCards(
    mutation: *Mutation,
    allocator: Allocator,
    cards: []const tables.gacha.Card,
    now: i64,
    receipt: *GachaReceipt,
) Error!void {
    if (cards.len == 0)
        return;
    const player = mutation.modify(.{ .acquisitions = true });

    for (cards) |card| {
        const card_id = card.id;
        const acquisition = try getOrCreatePlayerAcquisition(player, allocator, card_id);
        const first_for_card = acquisition.count == 0;
        const receipt_index = receipt.cardAcquisitionIndex(card_id) orelse blk: {
            receipt.card_acquisitions[receipt.card_acquisition_count] = .{
                .id = card_id,
                .begin = acquisition.count,
                .count = 0,
            };
            const index = receipt.card_acquisition_count;
            receipt.card_acquisition_count += 1;

            break :blk index;
        };

        acquisition.count +|= 1;
        receipt.card_acquisitions[receipt_index].count += 1;

        const card_class = card.class;
        if (first_for_card) {
            switch (card_class.kind) {
                .character => {
                    const handbook_changed = try unlockCharacter(player, allocator, card_id, now);
                    mutation.invalidate(.{ .characters = true });
                    if (handbook_changed)
                        mutation.recordHandbookType(tables.handbook.skin_type);
                    mutation.recordNewCharacter(card_id);
                },
                .disc => {
                    const handbook_changed = try unlockDisc(player, allocator, card_id, now);
                    mutation.invalidate(.{ .discs = true });
                    if (handbook_changed)
                        mutation.recordHandbookType(tables.handbook.disc_type);
                },
            }
            receipt.new_card_ids[receipt.new_card_count] = card_id;
            receipt.new_card_count += 1;
        } else {
            try addItemTemplateDelta(&receipt.transform_sources, &receipt.transform_source_count, card_id, 1);
            const conversion_item_id: u32 = switch (card_class.kind) {
                .character => tables.character.fragmentsId(card_id) orelse return error.Full,
                .disc => tables.disc.transformItemId(card_id) orelse return error.Full,
            };
            const conversion_quantity: i32 = switch (card_class.kind) {
                .character => tables.character.transformQuantity(card_id) orelse return error.Full,
                .disc => 1,
            };
            try addItemTemplateDelta(
                &receipt.transform_destinations,
                &receipt.transform_destination_count,
                conversion_item_id,
                conversion_quantity,
            );
            try applyInventoryItemDelta(player, allocator, receipt, conversion_item_id, conversion_quantity);

            if (tables.gacha.acquireReward(card_class, acquisition.count)) |reward|
                try applyResourceDelta(player, allocator, receipt, reward.resource_id, reward.quantity);
        }
    }
}

/// Adds an item awarded alongside a normal Recruitment draw.
pub fn grantRecruitmentItem(
    mutation: *Mutation,
    allocator: Allocator,
    receipt: *GachaReceipt,
    item_id: u32,
    quantity: i32,
) Error!void {
    if (quantity == 0)
        return;

    const player = mutation.modify(.{});
    try applyInventoryItemDelta(player, allocator, receipt, item_id, quantity);
}

fn getOrCreatePlayerAcquisition(player: *Player, allocator: Allocator, card_id: u32) Error!*Player.Acquisition {
    for (player.acquisitions.entries[0..player.acquisitions.len]) |*entry| {
        if (entry.id == card_id)
            return entry;
    }
    try player.acquisitions.append(allocator, .{ .id = card_id });

    return &player.acquisitions.entries[player.acquisitions.len - 1];
}

fn unlockCharacter(player: *Player, allocator: Allocator, id: u32, now: i64) Error!bool {
    if (player.characters.get(id) != null)
        return false;
    const skin = tables.handbook.defaultSkin(id) orelse return error.Full;
    const character: Player.Character = .{
        .skin = skin.skin_id,
        .created_at = now,
    };
    player.characters.append(id, character) catch
        return error.Full;
    const handbook_changed = player.unlockDefaultSkin(allocator, id) catch
        return error.Full;

    return handbook_changed;
}

fn unlockDisc(player: *Player, allocator: Allocator, id: u32, now: i64) Error!bool {
    for (player.discs.slice()) |disc| if (disc.id == id)
        return false;
    const disc: Player.Disc = .{ .id = id, .created_at = now };
    player.discs.append(allocator, disc) catch
        return error.Full;

    return player.unlockHandbook(allocator, id) catch
        return error.Full;
}

fn applyResourceDelta(player: *Player, allocator: Allocator, receipt: anytype, resource_id: u32, quantity: i32) Error!void {
    if (quantity == 0)
        return;
    try player.addResource(allocator, resource_id, quantity);
    try receipt.resource_deltas.add(resource_id, quantity);
}

fn applyRewardItemDelta(
    player: *Player,
    allocator: Allocator,
    receipt: *ResourceReceipt,
    template_id: u32,
    quantity: i32,
) Error!void {
    for (player.items.entries[0..player.items.len]) |*item| {
        if (item.template_id != template_id)
            continue;
        item.quantity +|= quantity;
        try addRewardItemDelta(receipt, item.id, template_id, quantity, item.expires_at);

        return;
    }

    const item: Player.Item = .{
        .id = template_id,
        .template_id = template_id,
        .quantity = quantity,
    };
    player.items.append(allocator, item) catch
        return error.Full;
    try addRewardItemDelta(receipt, item.id, item.template_id, quantity, item.expires_at);
}

fn addRewardItemDelta(
    receipt: *ResourceReceipt,
    id: u64,
    template_id: u32,
    quantity: i32,
    expires_at: i64,
) error{Full}!void {
    for (receipt.item_deltas[0..receipt.item_delta_count]) |*item| {
        if (item.template_id != template_id or item.expires_at != expires_at)
            continue;
        item.quantity +|= quantity;

        return;
    }
    if (receipt.item_delta_count == receipt.item_deltas.len)
        return error.Full;
    receipt.item_deltas[receipt.item_delta_count] = .{
        .id = id,
        .template_id = template_id,
        .quantity = quantity,
        .expires_at = expires_at,
    };
    receipt.item_delta_count += 1;
}

fn addItemTemplateDelta(
    entries: anytype,
    len: *usize,
    id: u32,
    quantity: i32,
) error{Full}!void {
    for (entries[0..len.*]) |*entry| {
        if (entry.id != id)
            continue;
        entry.quantity +|= quantity;

        return;
    }
    if (len.* == entries.len)
        return error.Full;
    entries[len.*] = .{ .id = id, .quantity = quantity };
    len.* += 1;
}

fn applyInventoryItemDelta(player: *Player, allocator: Allocator, receipt: *GachaReceipt, template_id: u32, quantity: i32) Error!void {
    for (player.items.entries[0..player.items.len]) |*item| {
        if (item.template_id != template_id)
            continue;
        item.quantity +|= quantity;
        return addInventoryItemDelta(receipt, item.id, template_id, quantity, item.expires_at);
    }

    const item: Player.Item = .{
        .id = template_id,
        .template_id = template_id,
        .quantity = quantity,
    };
    player.items.append(allocator, item) catch
        return error.Full;
    try addInventoryItemDelta(receipt, item.id, item.template_id, quantity, item.expires_at);
}

fn addInventoryItemDelta(
    receipt: *GachaReceipt,
    id: u64,
    template_id: u32,
    quantity: i32,
    expires_at: i64,
) error{Full}!void {
    for (receipt.item_deltas[0..receipt.item_delta_count]) |*item| {
        if (item.template_id != template_id or item.expires_at != expires_at)
            continue;
        item.quantity +|= quantity;

        return;
    }
    if (receipt.item_delta_count == receipt.item_deltas.len) return error.Full;
    receipt.item_deltas[receipt.item_delta_count] = .{
        .id = id,
        .template_id = template_id,
        .quantity = quantity,
        .expires_at = expires_at,
    };
    receipt.item_delta_count += 1;
}
