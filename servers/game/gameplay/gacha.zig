//! Handles Recruitment draws, banner rules, pity, and saved Beginner Limited
//! Banner results.

const std = @import("std");
const Io = std.Io;

const common = @import("common");
const tables = @import("../tables.zig");

//

const probability_scale = 10_000;
const default_seed = 0x9e3779b97f4a7c15;

pub const max_pull_count = 10;
pub const history_limit_per_storage = 120;

var next_newbie_gacha_seed: std.atomic.Value(u64) = .init(1);

/// State owned by a Recruitment entry: its total draws and single 120-draw
/// reward. Entries with the same `StorageId` share pity separately.
pub const BannerState = extern struct {
    id: u32 = 0,
    total_pulls: u32 = 0,
    daily_pulls: u32 = 0,
    a_up_count: u32 = 0,
    claim_reward_received: bool = false,
    received_first_ten_reward: bool = false,

    padding: [2]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

/// Pity and random state shared by Recruitment entries using a
/// `GachaStorage`.
pub const StorageState = extern struct {
    rng_state: u64 = default_seed,
    id: u32 = 0,
    a_misses: u32 = 0,
    a_up_misses: u32 = 0,
    b_misses: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const NormalSpin = struct {
    cards: [max_pull_count]tables.gacha.Card = undefined,
    count: u8 = 0,
    a_count: u8 = 0,
    b_count: u8 = 0,
    a_up_count: u8 = 0,

    pub fn slice(spin: *const NormalSpin) []const tables.gacha.Card {
        return spin.cards[0..spin.count];
    }
};

pub const NewbieGachaState = extern struct {
    rng_state: u64 = default_seed,
    pending: [tables.gacha_newbie.cards_per_spin]u32 = @splat(0),
    saved: [tables.gacha_newbie.max_saved_results][tables.gacha_newbie.cards_per_spin]u32 =
        @splat(@splat(0)),
    spins: u8 = 0,
    saved_count: u8 = 0,
    received: bool = false,
    pulls_without_a: u8 = 0,

    padding: [4]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const Error = error{
    NewbieGachaUnavailable,
    InvalidPullCount,
    InvalidBanner,
};

pub fn initializeNewbieGacha(state: *NewbieGachaState, seed: u64) void {
    state.* = .{ .rng_state = if (seed == 0) default_seed else seed };
}

pub fn initializeNewbieGachaForPlayer(
    state: *NewbieGachaState,
    registered_at: Io.Timestamp,
    uid: u64,
) void {
    const timestamp: u64 = @truncate(@as(u96, @bitCast(registered_at.nanoseconds)));
    const nonce = next_newbie_gacha_seed.fetchAdd(1, .monotonic);
    initializeNewbieGacha(state, mixSeed(timestamp ^ uid ^ nonce));
}

pub fn initializeBanner(state: *BannerState, id: u32) void {
    state.* = .{ .id = id };
}

pub fn initializeStorageForPlayer(
    state: *StorageState,
    id: u32,
    registered_at: Io.Timestamp,
    uid: u64,
) void {
    const timestamp: u64 = @truncate(@as(u96, @bitCast(registered_at.nanoseconds)));
    const nonce = next_newbie_gacha_seed.fetchAdd(1, .monotonic);
    state.* = .{
        .id = id,
        .rng_state = mixSeed(timestamp ^ uid ^ id ^ nonce),
    };
}

pub fn spinBanner(
    storage_state: *StorageState,
    banner: *const tables.gacha.Banner,
    count: u8,
) Error!NormalSpin {
    if (count != 1 and count != max_pull_count)
        return error.InvalidPullCount;
    if (storage_state.id != banner.storage_id)
        return error.InvalidBanner;

    var spin: NormalSpin = .{};
    for (spin.cards[0..count]) |*card| {
        var a_up = false;
        card.* = try drawBannerCard(storage_state, banner, &a_up);
        switch (card.class.rarity) {
            .five_star => spin.a_count += 1,
            .four_star => spin.b_count += 1,
            .three_star => {},
        }
        spin.a_up_count += @intFromBool(a_up);
    }
    spin.count = count;
    return spin;
}

pub fn canClaimBannerReward(state: *const BannerState, banner: *const tables.gacha.Banner) bool {
    return banner.claim_reward != null and
        !state.claim_reward_received and
        state.total_pulls >= banner.claim_reward_pulls;
}

pub fn spinNewbieGacha(state: *NewbieGachaState) Error![tables.gacha_newbie.cards_per_spin]u32 {
    if (state.received or state.spins >= tables.gacha_newbie.max_spins)
        return error.NewbieGachaUnavailable;

    const guaranteed_index = nextRandom(&state.rng_state) % tables.gacha_newbie.cards_per_spin;
    for (&state.pending, 0..) |*card, index| {
        const pool: tables.gacha.NewbieGachaPool = if (index == guaranteed_index)
            .guaranteed_b_trekker
        else
            nextNewbieGachaPool(state);
        card.* = drawNewbieGachaCard(pool, nextRandom(&state.rng_state));
    }
    state.spins += 1;

    return state.pending;
}

pub fn saveNewbieGachaResult(state: *NewbieGachaState, requested_slot: u32) Error!u32 {
    if (!hasNewbieGachaPendingResult(state) or state.received)
        return error.NewbieGachaUnavailable;

    const index: usize = if (requested_slot == 0) blk: {
        if (state.saved_count == tables.gacha_newbie.max_saved_results)
            return error.NewbieGachaUnavailable;
        const next = state.saved_count;
        state.saved_count += 1;

        break :blk next;
    } else std.math.cast(usize, requested_slot - 1) orelse
        return error.NewbieGachaUnavailable;
    if (index >= state.saved_count)
        return error.NewbieGachaUnavailable;

    state.saved[index] = state.pending;
    @memset(&state.pending, 0);

    return @intCast(index + 1);
}

//

test "newbie gacha append slots advance independently of request sentinel" {
    var state: NewbieGachaState = .{};

    state.pending[0] = 101;
    try std.testing.expectEqual(@as(u32, 1), try saveNewbieGachaResult(&state, 0));
    try std.testing.expectEqual(@as(u8, 1), state.saved_count);
    try std.testing.expectEqual(@as(u32, 101), state.saved[0][0]);

    state.pending[0] = 202;
    try std.testing.expectEqual(@as(u32, 2), try saveNewbieGachaResult(&state, 0));
    try std.testing.expectEqual(@as(u8, 2), state.saved_count);
    try std.testing.expectEqual(@as(u32, 202), state.saved[1][0]);
}

pub fn selectedNewbieGachaResult(state: *const NewbieGachaState, slot: u32) Error![tables.gacha_newbie.cards_per_spin]u32 {
    if (slot == 0)
        return error.NewbieGachaUnavailable;
    const index = std.math.cast(usize, slot - 1) orelse
        return error.NewbieGachaUnavailable;
    if (state.received or index >= state.saved_count)
        return error.NewbieGachaUnavailable;

    return state.saved[index];
}

pub fn markNewbieGachaReceived(state: *NewbieGachaState) void {
    state.received = true;
}

pub fn hasNewbieGachaPendingResult(state: *const NewbieGachaState) bool {
    for (state.pending) |card| if (card != 0)
        return true;

    return false;
}

fn nextNewbieGachaPool(state: *NewbieGachaState) tables.gacha.NewbieGachaPool {
    const a_probability = newbieGachaATypeProbability(state.pulls_without_a);
    const pool: tables.gacha.NewbieGachaPool = if (nextRandom(&state.rng_state) % probability_scale < a_probability)
        .a
    else if (nextRandom(&state.rng_state) % probability_scale < tables.gacha.newbie_gacha.b_type_probability)
        if (nextRandom(&state.rng_state) % probability_scale < tables.gacha.newbie_gacha.b_trekker_probability)
            .b_trekker
        else
            .b_disc
    else
        .c;

    switch (pool) {
        .a => {
            state.pulls_without_a = 0;
        },
        .b_trekker, .b_disc, .c => {
            state.pulls_without_a +|= 1;
        },
        .guaranteed_b_trekker => unreachable,
    }

    return pool;
}

fn newbieGachaATypeProbability(pulls_without_a: u8) u32 {
    if (pulls_without_a >= tables.gacha.newbie_gacha.a_guarantee_pulls - 1)
        return probability_scale;

    return tables.gacha.newbieGachaATypeProbabilityAt(pulls_without_a);
}

fn drawNewbieGachaCard(pool: tables.gacha.NewbieGachaPool, random: u32) u32 {
    const entries = tables.gacha.newbieGachaPool(pool);
    var total_weight: u32 = 0;
    for (entries) |entry| total_weight += entry.weight;

    var selection = random % total_weight;
    for (entries) |entry| {
        if (selection < entry.weight)
            return entry.goods_id;
        selection -= entry.weight;
    }

    unreachable;
}

fn drawBannerCard(
    state: *StorageState,
    banner: *const tables.gacha.Banner,
    a_up: *bool,
) Error!tables.gacha.Card {
    const storage = banner.storage;
    const a_guaranteed = banner.a_type_guarantee_pulls != 0 and
        state.a_misses + 1 >= banner.a_type_guarantee_pulls;
    const a_probability = tables.gacha.aTypeProbability(storage.a_type_group, state.a_misses);
    const roll = nextRandom(&state.rng_state) % probability_scale;

    const rarity: tables.gacha.Rarity = if (a_guaranteed or roll < a_probability) .five_star else if (state.b_misses >= 9 or
        roll < a_probability + storage.b_probability) .four_star else .three_star;
    const pool = switch (rarity) {
        .five_star => blk: {
            const selection = selectAPool(state, banner);
            a_up.* = selection.up;
            break :blk selection.entries;
        },
        .four_star => selectBPool(state, banner),
        .three_star => banner.c_pool,
    };
    const entry = choose(pool, nextRandom(&state.rng_state)) orelse
        return error.InvalidBanner;
    const class = tables.gacha.cardClass(entry.goods_id, rarity) orelse
        return error.InvalidBanner;

    switch (rarity) {
        .five_star => {
            state.a_misses = 0;
            state.b_misses = 0;
        },
        .four_star => {
            state.a_misses +|= 1;
            state.b_misses = 0;
        },
        .three_star => {
            state.a_misses +|= 1;
            state.b_misses +|= 1;
        },
    }

    // `AupMissTimes` counts draws without a featured *5 reward. Every other
    // result advances it, and a featured *5 resets it.
    if (banner.a_up_pool.len != 0) {
        if (a_up.*)
            state.a_up_misses = 0
        else
            state.a_up_misses +|= 1;
    }

    return .{ .id = entry.goods_id, .class = class };
}

fn selectAPool(state: *StorageState, banner: *const tables.gacha.Banner) PoolSelection {
    const storage = banner.storage;
    const force_featured = storage.a_up_guarantee_pulls != 0 and
        state.a_up_misses + 1 >= storage.a_up_guarantee_pulls;
    const featured = banner.a_up_pool.len != 0 and (force_featured or
        nextRandom(&state.rng_state) % probability_scale < storage.a_up_probability);
    if (featured)
        return .{ .entries = banner.a_up_pool, .up = true };

    return .{ .entries = if (banner.a_pool.len != 0) banner.a_pool else banner.a_up_pool };
}

fn selectBPool(state: *StorageState, banner: *const tables.gacha.Banner) []const tables.gacha.PackageEntry {
    const forced = state.b_misses >= 9;
    if (forced and banner.b_guarantee_pool.len != 0)
        return banner.b_guarantee_pool;

    const roll = nextRandom(&state.rng_state) % probability_scale;
    if (banner.b_up_pool.len != 0 and roll < banner.storage.b_up_probability)
        return banner.b_up_pool;
    if (banner.b_guarantee_pool.len != 0 and
        roll < banner.storage.b_up_probability + banner.storage.b_guarantee_probability)
        return banner.b_guarantee_pool;
    if (banner.b_pool.len == 0)
        return if (banner.b_up_pool.len != 0) banner.b_up_pool else banner.b_guarantee_pool;

    return banner.b_pool;
}

const PoolSelection = struct {
    entries: []const tables.gacha.PackageEntry,
    up: bool = false,
};

fn choose(entries: []const tables.gacha.PackageEntry, random: u32) ?tables.gacha.PackageEntry {
    if (entries.len == 0) return null;
    var total_weight: u32 = 0;
    for (entries) |entry| total_weight +|= entry.weight;
    if (total_weight == 0) return null;

    var selection = random % total_weight;
    for (entries) |entry| {
        if (selection < entry.weight)
            return entry;
        selection -= entry.weight;
    }
    unreachable;
}

fn nextRandom(rng_state: *u64) u32 {
    var value = rng_state.*;
    value ^= value >> 12;
    value ^= value << 25;
    value ^= value >> 27;
    rng_state.* = value;

    return @truncate((value *% 0x2545f4914f6cdd1d) >> 32);
}

fn mixSeed(input: u64) u64 {
    var value = input +% 0x9e3779b97f4a7c15;
    value = (value ^ (value >> 30)) *% 0xbf58476d1ce4e5b9;
    value = (value ^ (value >> 27)) *% 0x94d049bb133111eb;

    return value ^ (value >> 31);
}
