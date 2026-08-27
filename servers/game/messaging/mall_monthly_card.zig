const proto = @import("proto");
const Scope = @import("../Scope.zig");
const gameplay = @import("../gameplay.zig");
const config: @import("../Config.zig") = @import("config");
const tables = @import("../tables.zig");
const mall = @import("mall.zig");

pub const daily_rewards = struct {
    pub fn send(scope: *Scope, rewards: gameplay.mall.MonthlyDailyRewards, today: i64) !void {
        for (rewards.entries[0..rewards.count]) |entry| {
            try scope.sink.sendProto(.monthly_card_rewards_notify, &proto.pb.MonthlyCardRewards{
                .Id = entry.id,
                .Change = try mall.change(scope, entry.receipt),
                .EndTime = gameplay.mall.cardEndTime(entry.expiry_day),
                .Remaining = gameplay.mall.remainingClaims(entry.expiry_day, today, today),
                .Switch = true,
            });
        }
    }
};

pub fn mall_monthlyCard_list_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    const today = gameplay.mall.cardDay(scope.now);
    var entries: [tables.mall_monthly_card.entries.len]proto.pb.MonthlyCardInfo = undefined;
    for (tables.mall_monthly_card.entries, 0..) |card, index| {
        const state = scope.player.monthlyCard(card.key);
        entries[index] = .{
            .Id = card.id,
            .Remaining = gameplay.mall.remainingClaims(state.expiry_day, state.claimed_day, today),
            .Received = state.expiry_day > today and state.claimed_day == today,
        };
    }
    try scope.respond(proto.pb.MallMonthlyCardList{ .List = .fromOwnedSlice(&entries) });
}

pub fn mall_monthlyCard_order_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.String);
    const today = gameplay.mall.cardDay(scope.now);
    const receipt = gameplay.mall.monthlyCardOrder(scope.mutation(), scope.gpa, request.Value, today, config.shop) catch |err| switch (err) {
        else => return mall.reject(scope, err),
    };
    try scope.respond(proto.pb.OrderInfo{ .Id = receipt.id, .ExtraData = receipt.id });
    try daily_rewards.send(scope, receipt.daily_rewards, today);
    try scope.sink.sendProto(.order_paid_notify, &proto.pb.OrderStateChange{ .OrderId = receipt.id, .Store = 0 });
}

pub const order = struct {
    pub fn collect(scope: *Scope, id: []const u8) !void {
        const receipt = gameplay.mall.collectMonthlyCard(scope.mutation(), id) catch |err| switch (err) {
            error.InvalidInput => return scope.respondFailure(proto.pb.CollectResp{ .Status = .Error }),
            else => |other| return other,
        };
        try scope.respond(proto.pb.CollectResp{
            .Status = .Done,
            .Items = if (receipt.reward_count == 0) null else try mall.change(scope, receipt),
        });
    }
};
