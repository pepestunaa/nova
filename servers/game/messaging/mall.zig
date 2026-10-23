const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");
const change_info = @import("../view/change_info.zig");

pub fn change(scope: *Scope, receipt: gameplay.mall.Receipt) !proto.pb.ChangeInfo {
    const props = try scope.arena.alloc(proto.pb.Any, receipt.reward_count);
    var count: usize = 0;
    for (receipt.rewards[0..receipt.reward_count]) |reward|
        try change_info.appendReward(scope.arena, props, &count, reward.id, reward.quantity);
    return .{ .Props = .fromOwnedSlice(props[0..count]) };
}

pub fn errorCode(err: anyerror) ?tables.error_code.Code {
    return switch (err) {
        error.PurchasesDisabled => .service_unavailable,
        error.TopupDisabled => .service_unavailable,
        error.PackageNotListed => .mall_package_not_listed,
        error.PackageDelisted => .mall_package_delisted,
        error.PackageStockLimit => .mall_package_stock_limit,
        error.ProductNotFound => .goods_not_found,
        error.ProductNotReady => .product_not_ready,
        error.ProductDelisted => .goods_delisted,
        error.StockLimit => .product_restock_limit,
        error.OrderLimit => .mall_package_order_limit,
        error.InsufficientResources => .cond_check,
        error.NoRewards => .no_rewards_to_receive,
        else => null,
    };
}

pub fn reject(scope: *Scope, err: anyerror) !void {
    if (errorCode(err)) |code|
        return scope.reject(code);
    if (err == error.InvalidInput)
        return scope.reject(.invalid_req);
    return err;
}
