const std = @import("std");
const change_info = @import("../view/change_info.zig");
const Player = @import("../store/Player.zig");
const progression = @import("../gameplay/disc_progression.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn disc_strengthen_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.DiscStrengthenReq);
    var items: [progression.max_item_changes]progression.ItemAmount = undefined;
    var item_count: usize = 0;
    var requested_items = request.Items;
    while (try requested_items.next()) |item| {
        if (item.Tid == 0 or item.Qty == 0)
            return scope.reject(.invalid_req);
        const quantity = std.math.cast(i32, item.Qty) orelse
            return scope.reject(.invalid_req);

        for (items[0..item_count]) |*existing| {
            if (existing.id != item.Tid)
                continue;
            existing.quantity = std.math.add(i32, existing.quantity, quantity) catch
                return scope.reject(.invalid_req);
            break;
        } else {
            if (item_count == items.len)
                return scope.reject(.invalid_req);
            items[item_count] = .{ .id = item.Tid, .quantity = quantity };
            item_count += 1;
        }
    }

    var receipt: progression.Receipt = .{};
    progression.strengthen(scope.mutation(), request.Id, items[0..item_count], &receipt) catch |err| switch (err) {
        error.LevelCapReached => return scope.reject(.disc_strengthen_max),
        error.InsufficientResources => return scope.reject(.cond_check),
        error.InvalidDisc => return scope.reject(.disc_no_data),
        error.InvalidItems => return scope.reject(.invalid_req),
        else => |other| return other,
    };

    const disc = discById(scope.player, request.Id) orelse unreachable;
    var change: change_info.Progression = .{};
    try scope.respond(proto.pb.DiscStrengthenResp{
        .Level = @intFromEnum(disc.level),
        .Exp = @intFromEnum(disc.exp),
        .Change = try change.build(&receipt, scope.arena),
    });
}

pub fn disc_promote_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.DiscPromoteReq);
    var receipt: progression.Receipt = .{};
    progression.promote(scope.mutation(), request.Id, &receipt) catch |err| switch (err) {
        error.LevelNotReached => return scope.reject(.disc_level_not_reached),
        error.MaximumPhaseReached => return scope.reject(.disc_phase_max),
        error.PlayerLevelNotMet, error.InsufficientResources => return scope.reject(.cond_check),
        error.InvalidDisc => return scope.reject(.disc_no_data),
        else => |other| return other,
    };

    const disc = discById(scope.player, request.Id) orelse unreachable;
    var change: change_info.Progression = .{};
    try scope.respond(proto.pb.DiscPromoteResp{
        .Phase = @intFromEnum(disc.phase),
        .Change = try change.build(&receipt, scope.arena),
    });
}

pub fn disc_limit_break_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.DiscLimitBreakReq);
    var receipt: progression.Receipt = .{};
    progression.limitBreak(scope.mutation(), request.Id, request.Qty, &receipt) catch |err| switch (err) {
        error.MaximumStarReached => return scope.reject(.disc_star_max),
        error.InsufficientResources => return scope.reject(.cond_check),
        error.InvalidDisc => return scope.reject(.disc_no_data),
        else => |other| return other,
    };

    const disc = discById(scope.player, request.Id) orelse unreachable;
    var change: change_info.Progression = .{};
    try scope.respond(proto.pb.DiscLimitBreakResp{
        .Star = @intFromEnum(disc.star),
        .Change = try change.build(&receipt, scope.arena),
    });
}

fn discById(player: *const Player, id: u32) ?*const Player.Disc {
    for (player.discs.slice()) |*disc| {
        if (disc.id == id)
            return disc;
    }

    return null;
}
