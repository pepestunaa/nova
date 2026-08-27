const std = @import("std");
const gameplay = @import("../gameplay.zig");
const config: @import("../Config.zig") = @import("config");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");
const monthly_card = @import("mall_monthly_card.zig");
const mall = @import("mall.zig");

const local_order_prefix = "local-gem:";
const LocalOrder = struct { id: []const u8, sequence: u32 };

fn makeOrderId(scope: *Scope, id: []const u8, sequence: u32) ![]const u8 {
    return std.fmt.allocPrint(scope.arena, "{s}{s}:{d}", .{ local_order_prefix, id, sequence });
}

fn parseOrderId(value: []const u8) ?LocalOrder {
    if (!std.mem.startsWith(u8, value, local_order_prefix))
        return null;
    var fields = std.mem.splitScalar(u8, value[local_order_prefix.len..], ':');
    const id = fields.next() orelse return null;
    const sequence = std.fmt.parseInt(u32, fields.next() orelse return null, 10) catch return null;
    if (id.len == 0 or sequence == 0 or fields.next() != null)
        return null;
    return .{ .id = id, .sequence = sequence };
}

pub fn mall_gem_list_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    var entries: [tables.mall_gem.entries.len]proto.pb.GemInfo = undefined;
    for (tables.mall_gem.entries, 0..) |product, index|
        entries[index] = .{ .Id = product.id, .Maiden = scope.player.mallPurchaseQuantity(.gem, product.key, scope.now) == 0 };
    try scope.respond(proto.pb.MallGemList{ .List = .fromOwnedSlice(&entries) });
}

pub fn gem_convert_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.UI32);
    const receipt = gameplay.mall.gemConvert(scope.mutation(), scope.gpa, request.Value, config.shop) catch |err| switch (err) {
        else => return mall.reject(scope, err),
    };
    try scope.respond(try mall.change(scope, receipt));
}

pub fn mall_gem_order_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.String);
    const order = gameplay.mall.gemOrder(scope.mutation(), scope.gpa, request.Value, scope.now, config.shop) catch |err| switch (err) {
        else => return mall.reject(scope, err),
    };
    const order_id = try makeOrderId(scope, order.id, order.sequence);
    try scope.respond(proto.pb.OrderInfo{ .Id = order_id, .ExtraData = order.id });
    try scope.sink.sendProto(.order_paid_notify, &proto.pb.OrderStateChange{ .OrderId = order_id, .Store = 0 });
}

pub fn mall_order_collect_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.String);
    const order = parseOrderId(request.Value) orelse {
        if (std.mem.startsWith(u8, request.Value, local_order_prefix))
            return scope.respondFailure(proto.pb.CollectResp{ .Status = .Error });
        return monthly_card.order.collect(scope, request.Value);
    };
    const receipt = gameplay.mall.collectGem(scope.mutation(), scope.gpa, order.id, order.sequence, scope.now) catch |err| switch (err) {
        error.InvalidInput => return scope.respondFailure(proto.pb.CollectResp{ .Status = .Error }),
        else => |other| return other,
    };
    try scope.respond(proto.pb.CollectResp{ .Status = .Done, .Items = try mall.change(scope, receipt) });
}
