const std = @import("std");
const gameplay = @import("../gameplay.zig");
const config: @import("../Config.zig") = @import("config");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");
const change_info = @import("../view/change_info.zig");
const mall = @import("mall.zig");

const unlimited_stock = std.math.maxInt(i32);

pub fn mall_shop_list_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    var count: usize = 0;
    for (tables.mall_shop.entries) |product| {
        if (!tables.mall_shop.available(product, scope.now))
            continue;
        count += 1;
    }

    const entries = try scope.arena.alloc(proto.pb.ProductInfo, count);
    var index: usize = 0;
    for (tables.mall_shop.entries) |product| {
        if (!tables.mall_shop.available(product, scope.now))
            continue;
        entries[index] = .{
            .Id = try std.fmt.allocPrint(scope.arena, "{d}", .{product.id}),
            .Stock = if (product.stock == 0) unlimited_stock else gameplay.mall.remainingStock(product.stock, scope.player.mallPurchaseQuantity(.mall_shop, product.key, scope.now)),
            .RefreshTime = gameplay.mall.nextReset(product.refresh_type, scope.now),
        };
        index += 1;
    }
    try scope.respond(proto.pb.MallShopProductList{ .List = .fromOwnedSlice(entries) });
}

pub fn daily_mall_reward_receive_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    const reward = gameplay.mall.claimDailyMallReward(scope.mutation(), scope.gpa, scope.now) catch |err| switch (err) {
        else => return mall.reject(scope, err),
    };
    var props: [1]proto.pb.Any = undefined;
    var count: usize = 0;
    try change_info.appendReward(scope.arena, &props, &count, reward.id, reward.quantity);
    try scope.respond(proto.pb.ChangeInfo{ .Props = .fromOwnedSlice(props[0..count]) });
}

pub fn mall_shop_order_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.MallShopOrderReq);
    const product_id = std.fmt.parseInt(u32, request.Id, 10) catch return scope.reject(.invalid_req);
    const receipt = gameplay.mall.mallShopOrder(scope.mutation(), scope.gpa, product_id, request.Qty, scope.now, config.shop) catch |err| switch (err) {
        else => return mall.reject(scope, err),
    };
    var props: [2]proto.pb.Any = undefined;
    var count: usize = 0;
    for (receipt.rewards[0..receipt.reward_count]) |reward|
        try change_info.appendReward(scope.arena, &props, &count, reward.id, reward.quantity);
    try scope.respond(proto.pb.ChangeInfo{ .Props = .fromOwnedSlice(props[0..count]) });
}
