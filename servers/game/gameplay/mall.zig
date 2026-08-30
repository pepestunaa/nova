const std = @import("std");

const Config = @import("../Config.zig");
const missions = @import("missions.zig");
const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");
const reset = @import("reset.zig");
const tables = @import("../tables.zig");

//

pub const Reward = struct {
    id: u32,
    quantity: i32,
};

const max_gem_conversion_rewards = 3;
pub const max_rewards = @max(tables.mall_package.max_rewards, max_gem_conversion_rewards);

pub const Receipt = struct {
    rewards: [max_rewards]Reward = undefined,
    reward_count: usize = 0,

    fn append(receipt: *Receipt, id: u32, quantity: i32) !void {
        if (quantity == 0)
            return;
        for (receipt.rewards[0..receipt.reward_count], 0..) |*reward, index| {
            if (reward.id != id)
                continue;
            const merged = std.math.add(i32, reward.quantity, quantity) catch
                return error.Overflow;
            if (merged != 0) {
                reward.quantity = merged;
                return;
            }
            receipt.reward_count -= 1;
            if (index != receipt.reward_count)
                reward.* = receipt.rewards[receipt.reward_count];
            return;
        }
        if (receipt.reward_count == receipt.rewards.len)
            return error.Full;
        receipt.rewards[receipt.reward_count] = .{ .id = id, .quantity = quantity };
        receipt.reward_count += 1;
    }
};

pub const MonthlyDailyReward = struct {
    id: u32,
    expiry_day: i64,
    receipt: Receipt,
};

pub const MonthlyDailyRewards = struct {
    entries: [tables.mall_monthly_card.entries.len]MonthlyDailyReward = undefined,
    count: usize = 0,
};

pub const MonthlyOrder = struct {
    id: []const u8,
    daily_rewards: MonthlyDailyRewards = .{},
};
pub const GemOrder = struct { id: []const u8, sequence: u32 };

pub fn cardDay(now: i64) i64 {
    return reset.dayIndex(now);
}

pub fn remainingDays(expiry_day: i64, today: i64) u32 {
    const days = std.math.sub(i64, expiry_day, today) catch return std.math.maxInt(u32);
    return std.math.cast(u32, @max(days, 0)) orelse std.math.maxInt(u32);
}

pub fn remainingClaims(expiry_day: i64, claimed_day: i64, today: i64) u32 {
    return remainingDays(expiry_day, today) -| @intFromBool(claimed_day == today);
}

pub fn cardEndTime(expiry_day: i64) i64 {
    const seconds = std.math.mul(i64, expiry_day, reset.seconds_per_day) catch return std.math.maxInt(i64);
    return std.math.sub(i64, seconds, reset.seconds_per_day - reset.daily_reset_seconds) catch std.math.minInt(i64);
}

pub fn remainingStock(stock: i32, purchased: u32) i32 {
    const bought = std.math.cast(i32, purchased) orelse return 0;
    return stock -| bought;
}

pub fn nextReset(refresh_type: tables.MallRefreshType, now: i64) i64 {
    return switch (refresh_type) {
        .none => 0,
        .day => reset.nextDaily(now),
        .week => reset.nextWeekly(now),
        .month => reset.nextMonthly(now),
    };
}

pub fn packageOrder(mutation: *Mutation, allocator: std.mem.Allocator, id: []const u8, now: i64, shop: Config.Shop) !Receipt {
    if (!shop.enable)
        return error.PurchasesDisabled;
    const package = tables.mall_package.get(id) orelse return error.PackageNotListed;
    if (package.entry.starts_at != 0 and now < package.entry.starts_at)
        return error.PackageNotListed;
    if (package.entry.ends_at != 0 and now >= package.entry.ends_at)
        return error.PackageDelisted;
    if (package.entry.stock != 0 and mutation.read().mallPurchaseQuantity(.package, package.key, now) >= package.entry.stock)
        return error.PackageStockLimit;

    const player = mutation.modify(.{});
    var receipt: Receipt = .{};
    var handbook_changed = false;
    for (package.entry.rewards[0..package.entry.reward_count]) |reward| {
        if (tables.handbook.skin(reward.id)) |skin| {
            handbook_changed = (try player.unlockHandbook(allocator, skin.id)) or handbook_changed;
        } else if (tables.item.isResource(reward.id)) {
            try player.addResource(allocator, reward.id, reward.quantity);
            try receipt.append(reward.id, reward.quantity);
        } else {
            try player.addItem(allocator, reward.id, reward.quantity);
            try receipt.append(reward.id, reward.quantity);
        }
    }
    try player.recordMallPurchase(allocator, .package, package.key, 1, nextReset(package.entry.refresh_type, now), now);
    if (handbook_changed)
        mutation.recordHandbookType(tables.handbook.skin_type);
    return receipt;
}

pub fn grantMonthlyDaily(mutation: *Mutation, allocator: std.mem.Allocator, today: i64) !MonthlyDailyRewards {
    var eligible: [tables.mall_monthly_card.entries.len]tables.mall_monthly_card.Entry = undefined;
    var count: usize = 0;
    for (tables.mall_monthly_card.entries) |card| {
        const state = mutation.read().monthlyCard(card.key);
        if (state.expiry_day > today and state.claimed_day != today) {
            eligible[count] = card;
            count += 1;
        }
    }
    if (count == 0)
        return .{};

    const player = mutation.modify(.{});
    var result: MonthlyDailyRewards = .{};
    for (eligible[0..count]) |card| {
        var state = player.monthlyCard(card.key);
        var receipt: Receipt = .{};
        for (card.daily_rewards) |reward| {
            if (tables.item.isResource(reward.id))
                try player.addResource(allocator, reward.id, reward.quantity)
            else
                try player.addItem(allocator, reward.id, reward.quantity);
            try receipt.append(reward.id, reward.quantity);
        }
        state.claimed_day = today;
        try player.setMonthlyCard(allocator, state);
        result.entries[result.count] = .{
            .id = card.monthly_card_id,
            .expiry_day = state.expiry_day,
            .receipt = receipt,
        };
        result.count += 1;
    }
    return result;
}

pub fn monthlyCardOrder(mutation: *Mutation, allocator: std.mem.Allocator, id: []const u8, today: i64, shop: Config.Shop) !MonthlyOrder {
    if (!shop.enable)
        return error.PurchasesDisabled;
    const card = tables.mall_monthly_card.get(id) orelse return error.ProductNotFound;
    const current = mutation.read();
    if (current.pendingMallOrder(.monthly_card, card.key) != null)
        return .{ .id = card.entry.id };
    var state = current.monthlyCard(card.key);
    const new_period = state.expiry_day <= today;
    if (remainingDays(state.expiry_day, today) > card.entry.max_days -| card.entry.duration_days)
        return error.OrderLimit;
    const base_day = @max(state.expiry_day, today);
    state.expiry_day = std.math.add(i64, base_day, card.entry.duration_days) catch return error.InvalidInput;
    if (new_period)
        state.claimed_day = -1;

    const player = mutation.modify(.{});
    try player.addResource(allocator, card.entry.base_resource_id, card.entry.base_quantity);
    try player.setMonthlyCard(allocator, state);
    try player.setPendingMallOrder(allocator, .monthly_card, card.key, 1);
    return .{
        .id = card.entry.id,
        .daily_rewards = if (new_period) try grantMonthlyDaily(mutation, allocator, today) else .{},
    };
}

pub fn collectMonthlyCard(mutation: *Mutation, id: []const u8) !Receipt {
    const card = tables.mall_monthly_card.get(id) orelse return error.InvalidInput;
    const sequence = mutation.read().mallOrderSequence(.monthly_card, card.key) orelse return error.InvalidInput;
    if (sequence == 0)
        return .{};
    var receipt: Receipt = .{};
    try receipt.append(card.entry.base_resource_id, card.entry.base_quantity);
    mutation.modify(.{}).clearPendingMallOrder(.monthly_card, card.key);
    return receipt;
}

pub fn gemConvert(mutation: *Mutation, allocator: std.mem.Allocator, requested: u32, shop: Config.Shop) !Receipt {
    if (!shop.enable)
        return error.PurchasesDisabled;
    const quantity = std.math.cast(i32, requested) orelse return error.InvalidInput;
    if (quantity <= 0)
        return error.InvalidInput;
    const currency = tables.gem_currency.currency;
    const current = mutation.read();
    const free_stone = @max(current.resourceQuantity(currency.free_item_id), 0);
    const paid_stone = @max(current.resourceQuantity(currency.paid_item_id), 0);
    if (@as(i64, free_stone) + @as(i64, paid_stone) < quantity)
        return error.InsufficientResources;

    const consume_paid = @min(quantity, paid_stone);
    const consume_free = quantity - consume_paid;
    const player = mutation.modify(.{});
    try player.addResource(allocator, currency.free_item_id, -consume_free);
    try player.addResource(allocator, currency.paid_item_id, -consume_paid);
    try player.addResource(allocator, currency.gem_item_id, quantity);

    var receipt: Receipt = .{};
    try receipt.append(currency.gem_item_id, quantity);
    try receipt.append(currency.paid_item_id, -consume_paid);
    try receipt.append(currency.free_item_id, -consume_free);
    return receipt;
}

pub fn gemOrder(mutation: *Mutation, allocator: std.mem.Allocator, id: []const u8, now: i64, shop: Config.Shop) !GemOrder {
    if (!shop.enable)
        return error.PurchasesDisabled;
    const product = tables.mall_gem.get(id) orelse return error.ProductNotFound;
    const current = mutation.read();
    const sequence = current.pendingMallOrder(.gem, product.key) orelse blk: {
        const next = std.math.add(u32, current.mallPurchaseQuantity(.gem, product.key, now), 1) catch return error.InvalidInput;
        const player = mutation.modify(.{});
        try player.setPendingMallOrder(allocator, .gem, product.key, next);
        break :blk next;
    };
    return .{ .id = product.entry.id, .sequence = sequence };
}

pub fn collectGem(mutation: *Mutation, allocator: std.mem.Allocator, id: []const u8, sequence: u32, now: i64) !Receipt {
    const product = tables.mall_gem.get(id) orelse return error.InvalidInput;
    if (sequence == 0)
        return error.InvalidInput;
    const order_sequence = mutation.read().mallOrderSequence(.gem, product.key) orelse return error.InvalidInput;
    const purchased = mutation.read().mallPurchaseQuantity(.gem, product.key, now);
    if (order_sequence == 0) {
        if (sequence == purchased and purchased != 0)
            return .{};
        return error.InvalidInput;
    }
    if (order_sequence != sequence)
        return error.InvalidInput;
    const expected = std.math.add(u32, purchased, 1) catch return error.InvalidInput;
    if (sequence != expected)
        return error.InvalidInput;

    const first_purchase = purchased == 0;
    const bonus = if (first_purchase) product.entry.maiden_bonus_quantity else product.entry.experienced_bonus_quantity;
    const bonus_item_id = if (first_purchase) product.entry.maiden_bonus_item_id else product.entry.experienced_bonus_item_id;
    const player = mutation.modify(.{});
    try player.addResource(allocator, product.entry.base_item_id, product.entry.base_quantity);
    try player.addResource(allocator, bonus_item_id, bonus);
    try player.recordMallPurchase(allocator, .gem, product.key, 1, 0, now);
    player.clearPendingMallOrder(.gem, product.key);

    var receipt: Receipt = .{};
    try receipt.append(product.entry.base_item_id, product.entry.base_quantity);
    try receipt.append(bonus_item_id, bonus);
    return receipt;
}

pub fn mallShopOrder(mutation: *Mutation, allocator: std.mem.Allocator, id: u32, requested_quantity: u32, now: i64, shop: Config.Shop) !Receipt {
    if (!shop.enable)
        return error.PurchasesDisabled;
    const product = tables.mall_shop.get(id) orelse return error.ProductNotFound;
    if (product.entry.starts_at != 0 and now < product.entry.starts_at)
        return error.ProductNotReady;
    if (product.entry.ends_at != 0 and now >= product.entry.ends_at)
        return error.ProductDelisted;
    const quantity = std.math.cast(i32, requested_quantity) orelse return error.InvalidInput;
    if (quantity <= 0)
        return error.InvalidInput;
    const current = mutation.read();
    const purchased = current.mallPurchaseQuantity(.mall_shop, product.key, now);
    if (product.entry.stock != 0 and quantity > remainingStock(product.entry.stock, purchased))
        return error.StockLimit;
    const total_price = std.math.mul(i32, product.entry.price, quantity) catch return error.InvalidInput;
    const item_quantity = std.math.mul(i32, product.entry.item_quantity, quantity) catch return error.InvalidInput;
    if (current.resourceQuantity(product.entry.currency_id) < total_price)
        return error.InsufficientResources;

    const player = mutation.modify(.{});
    try player.addResource(allocator, product.entry.currency_id, -total_price);
    if (tables.item.isResource(product.entry.item_id))
        try player.addResource(allocator, product.entry.item_id, item_quantity)
    else
        try player.addItem(allocator, product.entry.item_id, item_quantity);
    try player.recordMallPurchase(allocator, .mall_shop, product.key, @intCast(quantity), nextReset(product.entry.refresh_type, now), now);

    var receipt: Receipt = .{};
    try receipt.append(product.entry.currency_id, -total_price);
    try receipt.append(product.entry.item_id, item_quantity);
    return receipt;
}

pub fn claimDailyMallReward(mutation: *Mutation, allocator: std.mem.Allocator, now: i64) !Reward {
    const day = cardDay(now);
    if (mutation.read().progress.daily_mall_reward_day == day)
        return error.NoRewards;
    const reward = tables.daily_mall_reward.reward;
    const player = mutation.modify(.{});
    player.progress.daily_mall_reward_day = day;
    try player.addResource(allocator, reward.resource_id, reward.quantity);
    missions.trigger(mutation, .daily_shop_reward, 1, 0);
    return .{ .id = reward.resource_id, .quantity = reward.quantity };
}

pub fn dailyMallRewardAvailable(player: *const Player, now: i64) bool {
    return player.progress.daily_mall_reward_day != cardDay(now);
}
