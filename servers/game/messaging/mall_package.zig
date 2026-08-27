const gameplay = @import("../gameplay.zig");
const config: @import("../Config.zig") = @import("config");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");
const change_info = @import("../view/change_info.zig");
const mall = @import("mall.zig");

pub fn mall_package_list_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    var count: usize = 0;
    for (tables.mall_package.entries) |package| {
        if (!tables.mall_package.visible(package, scope.now, config.shop.show_historical_packages))
            continue;
        count += 1;
    }

    const entries = try scope.arena.alloc(proto.pb.PackageInfo, count);
    var index: usize = 0;
    for (tables.mall_package.entries) |package| {
        if (!tables.mall_package.visible(package, scope.now, config.shop.show_historical_packages))
            continue;
        entries[index] = .{
            .Id = package.id,
            .Stock = if (package.stock == 0) 0 else package.stock -| scope.player.mallPurchaseQuantity(.package, package.key, scope.now),
            .RefreshTime = gameplay.mall.nextReset(package.refresh_type, scope.now),
        };
        index += 1;
    }
    try scope.respond(proto.pb.MallPackageList{ .List = .fromOwnedSlice(entries) });
}

pub fn mall_package_order_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.String);
    const receipt = gameplay.mall.packageOrder(scope.mutation(), scope.gpa, request.Value, scope.now, config.shop) catch |err| switch (err) {
        else => return mall.reject(scope, err),
    };

    var props: [tables.mall_package.max_rewards]proto.pb.Any = undefined;
    var prop_count: usize = 0;
    for (receipt.rewards[0..receipt.reward_count]) |reward|
        try change_info.appendReward(scope.arena, &props, &prop_count, reward.id, reward.quantity);
    try scope.respond(proto.pb.MallPackageOrder{ .Change = .{ .Props = .fromOwnedSlice(props[0..prop_count]) } });
}
