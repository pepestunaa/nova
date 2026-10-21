const std = @import("std");
const Io = std.Io;

const change_info = @import("../view/change_info.zig");
const config: @import("../Config.zig") = @import("config");
const gacha = @import("../gameplay/gacha.zig");
const Player = @import("../store/Player.zig");
const proto = @import("proto");
const reward = @import("../gameplay/reward.zig");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn gacha_information_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);

    var entries: [tables.gacha.banners.len]proto.pb.GachaInfo = undefined;
    for (&tables.gacha.banners, 0..) |*banner, index| {
        const banner_state = findBannerStateConst(scope.player, banner.id);
        const storage_state = findStorageStateConst(scope.player, banner.storage_id);
        entries[index] = infoFor(banner, banner_state, storage_state);
    }

    try scope.respond(proto.pb.GachaInformationResp{
        .Information = .fromOwnedSlice(&entries),
    });
}

pub fn gacha_spin_req(scope: *Scope) !void {
    const log = scope.logger(.gacha_spin_req);
    const request = try scope.source.read(proto.pb.GachaSpinReq);

    const requested_id = request.Id;
    const banner: tables.gacha.Banner = if (tables.gacha.banner(requested_id)) |known| known.* else blk: {
        if (!config.gacha_unknown_banner_fallback)
            return scope.reject(.invalid_req);

        // The client can be newer than the tables and offer banners this
        // server has no data for. Serving the shared pools of the closest
        // banner keeps the pull working instead of rejecting it.
        const fallback = tables.gacha.fallbackBanner(requested_id) orelse
            return scope.reject(.invalid_req);

        log.warn(
            "banner {d} is not in the server tables, serving the shared pools of pity group {d}",
            .{ requested_id, fallback.storage_id },
        );
        break :blk fallback;
    };
    const pull_count: u8 = switch (request.Mode) {
        1 => 1,
        2 => tables.gacha_newbie.cards_per_spin,
        else => return scope.reject(.invalid_req),
    };
    const ticket_quantity = std.math.mul(u32, banner.storage.tickets_per_pull, @intCast(pull_count)) catch
        return scope.reject(.invalid_req);
    const received_first_ten_reward = if (findBannerStateConst(scope.player, banner.id)) |state|
        state.received_first_ten_reward
    else
        false;
    const first_ten_reward = pull_count == tables.gacha_newbie.cards_per_spin and
        !received_first_ten_reward;
    const side_reward_quantity: i32 = if (banner.storage.give_item) |item| blk: {
        const multiplier: u32 = if (first_ten_reward) banner.first_ten_reward_multiplier else 1;
        const multiplier_i32 = std.math.cast(i32, multiplier) orelse
            return scope.reject(.invalid_req);
        const per_pull = std.math.mul(i32, item.quantity, @as(i32, pull_count)) catch
            return scope.reject(.invalid_req);
        break :blk std.math.mul(i32, per_pull, multiplier_i32) catch
            return scope.reject(.invalid_req);
    } else 0;
    var receipt: reward.GachaReceipt = .{};
    reward.consumeRecruitmentCost(
        scope.mutation(),
        scope.gpa,
        &receipt,
        banner.storage.ticket_id,
        ticket_quantity,
        banner.storage.currency_id,
        banner.storage.currency_per_ticket,
    ) catch |err| switch (err) {
        error.InsufficientCurrency => return scope.reject(.invalid_req),
        else => |e| return e,
    };

    const now = scope.timestamp;
    const banner_state = try getOrCreateBannerState(scope, requested_id);
    const storage_state = try getOrCreateStorageState(scope, &banner, now);
    const spin = try gacha.spinBanner(storage_state, &banner, pull_count);
    banner_state.total_pulls +|= pull_count;
    banner_state.daily_pulls +|= pull_count;
    banner_state.a_up_count +|= spin.a_up_count;
    if (pull_count == tables.gacha_newbie.cards_per_spin)
        banner_state.received_first_ten_reward = true;
    try reward.grantCards(scope.mutation(), scope.gpa, spin.slice(), now.toSeconds(), &receipt);
    if (banner.storage.give_item) |item| {
        try reward.grantRecruitmentItem(scope.mutation(), scope.gpa, &receipt, item.id, side_reward_quantity);
    }
    try appendHistory(scope, &banner, now.toSeconds(), &spin);

    var card_messages: [tables.gacha_newbie.cards_per_spin]proto.pb.GachaCard = undefined;
    for (spin.slice(), 0..) |card, index|
        card_messages[index] = .{ .Card = .{ .Tid = card.id, .Qty = 1 } };

    var change: change_info.Gacha = .{};
    try scope.respond(proto.pb.GachaSpinResp{
        .Cards = .fromOwnedSlice(card_messages[0..spin.count]),
        .Change = try change.build(scope.player, &receipt, scope.arena),
        .Time = now.toSeconds(),
        .AMissTimes = storage_state.a_misses,
        .GachaTotalTimes = banner_state.total_pulls,
        .TotalTimes = banner_state.total_pulls,
        .AupGuaranteeTimes = banner_state.a_up_count,
        .AupMissTimes = storage_state.a_up_misses,
        .DaysCount = banner_state.daily_pulls,
    });

    log.info("completed {d} pull(s) on banner {d}", .{ pull_count, banner.id });
    log.debug(
        "result: {d} five-star, {d} four-star, {d} three-star ({d} featured five-star)",
        .{ spin.a_count, spin.b_count, spin.count - spin.a_count - spin.b_count, spin.a_up_count },
    );
}

pub fn gacha_histories_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.UI32);
    var count: usize = 0;
    for (scope.player.gacha_histories.slice()) |entry| {
        if (entry.storage_id == request.Value)
            count += 1;
    }

    const entries = try scope.arena.alloc(proto.pb.GachaHistory, count);
    var index: usize = 0;
    for (scope.player.gacha_histories.slice()) |entry| {
        if (entry.storage_id != request.Value)
            continue;
        const ids = try scope.arena.dupe(u32, entry.cards[0..entry.card_count]);
        entries[index] = .{
            .Ids = .fromOwnedSlice(ids),
            .Time = entry.created_at,
            .Gid = entry.banner_id,
        };
        index += 1;
    }
    try scope.respond(proto.pb.GachaHistories{ .List = .fromOwnedSlice(entries) });
}

pub fn gacha_guarantee_reward_receive_req(scope: *Scope) !void {
    const log = scope.logger(.gacha_guarantee_reward_receive_req);
    const request = try scope.source.read(proto.pb.UI32);

    const banner = tables.gacha.banner(request.Value) orelse
        return scope.reject(.invalid_req);
    const current_state = findBannerStateConst(scope.player, banner.id) orelse
        return scope.reject(.invalid_req);
    if (!gacha.canClaimBannerReward(current_state, banner))
        return scope.reject(.invalid_req);
    const configured_reward = banner.claim_reward orelse unreachable;
    const card_class = tables.gacha.cardClass(
        configured_reward.resource_id,
        @enumFromInt(@intFromEnum(tables.character.grade(configured_reward.resource_id) orelse return scope.reject(.invalid_req))),
    ) orelse
        return scope.reject(.invalid_req);

    var receipt: reward.GachaReceipt = .{};
    const cards = [_]tables.gacha.Card{.{
        .id = configured_reward.resource_id,
        .class = card_class,
    }};
    const now = scope.now;
    try reward.grantCards(scope.mutation(), scope.gpa, &cards, now, &receipt);
    const player = scope.mutation().modify(.{});
    const state = findBannerState(player, banner.id).?;
    state.claim_reward_received = true;

    var change: change_info.Gacha = .{};
    try scope.respond(try change.build(scope.player, &receipt, scope.arena));

    log.info("claimed banner {d} guarantee reward", .{banner.id});
}

fn getOrCreateBannerState(
    scope: *Scope,
    id: u32,
) !*Player.GachaBanner {
    const player = scope.mutation().modify(.{});
    if (findBannerState(player, id)) |state|
        return state;

    var state: Player.GachaBanner = undefined;
    gacha.initializeBanner(&state, id);
    try player.gacha_banners.append(scope.gpa, state);

    return &player.gacha_banners.entries[player.gacha_banners.len - 1];
}

fn appendHistory(
    scope: *Scope,
    banner: *const tables.gacha.Banner,
    created_at: i64,
    spin: *const gacha.NormalSpin,
) !void {
    const player = scope.mutation().modify(.{});
    var matching_count: usize = 0;
    var oldest_index: ?usize = null;
    for (player.gacha_histories.slice(), 0..) |entry, index| {
        if (entry.storage_id != banner.storage_id)
            continue;
        matching_count += 1;
        if (oldest_index == null)
            oldest_index = index;
    }
    if (matching_count >= gacha.history_limit_per_storage) {
        const index = oldest_index orelse unreachable;
        const histories = &player.gacha_histories;
        std.mem.copyForwards(
            Player.GachaHistory,
            histories.entries[index .. histories.len - 1],
            histories.entries[index + 1 .. histories.len],
        );
        histories.len -= 1;
    }

    var history: Player.GachaHistory = .{
        .storage_id = banner.storage_id,
        .banner_id = banner.id,
        .created_at = created_at,
        .card_count = spin.count,
    };
    for (spin.slice(), 0..) |card, index|
        history.cards[index] = card.id;
    try player.gacha_histories.append(scope.gpa, history);
}

fn getOrCreateStorageState(
    scope: *Scope,
    banner: *const tables.gacha.Banner,
    now: Io.Timestamp,
) !*Player.GachaStorage {
    const player = scope.mutation().modify(.{});
    if (findStorageState(player, banner.storage_id)) |state|
        return state;

    var state: Player.GachaStorage = undefined;
    gacha.initializeStorageForPlayer(&state, banner.storage_id, now, player.uid orelse 0);
    try player.gacha_storages.append(scope.gpa, state);

    return &player.gacha_storages.entries[player.gacha_storages.len - 1];
}

fn findBannerState(player: *Player, id: u32) ?*Player.GachaBanner {
    for (player.gacha_banners.entries[0..player.gacha_banners.len]) |*state| if (state.id == id)
        return state;
    return null;
}

fn findBannerStateConst(player: *const Player, id: u32) ?*const Player.GachaBanner {
    for (player.gacha_banners.entries[0..player.gacha_banners.len]) |*state| if (state.id == id)
        return state;
    return null;
}

fn findStorageState(player: *Player, id: u32) ?*Player.GachaStorage {
    for (player.gacha_storages.entries[0..player.gacha_storages.len]) |*state| if (state.id == id)
        return state;
    return null;
}

fn findStorageStateConst(player: *const Player, id: u32) ?*const Player.GachaStorage {
    for (player.gacha_storages.entries[0..player.gacha_storages.len]) |*state| if (state.id == id)
        return state;
    return null;
}

fn infoFor(
    banner: *const tables.gacha.Banner,
    banner_state: ?*const Player.GachaBanner,
    storage_state: ?*const Player.GachaStorage,
) proto.pb.GachaInfo {
    const banner_value = banner_state orelse
        return .{ .Id = banner.id };

    return .{
        .Id = banner.id,
        .DaysCount = banner_value.daily_pulls,
        .AupMissTimes = if (storage_state) |value| value.a_up_misses else 0,
        .AMissTimes = if (storage_state) |value| value.a_misses else 0,
        .ReveFirstTenReward = banner_value.received_first_ten_reward,
        .RecvGuaranteeReward = banner_value.claim_reward_received,
        .GachaTotalTimes = banner_value.total_pulls,
        .TotalTimes = banner_value.total_pulls,
        .AupGuaranteeTimes = banner_value.a_up_count,
    };
}
