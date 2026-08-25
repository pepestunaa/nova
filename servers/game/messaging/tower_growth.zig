const std = @import("std");
const Io = std.Io;

const gameplay = @import("../gameplay.zig");
const Player = @import("../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

/// Returns an unlock bitmap per Monolith Research group. Empty groups at the
/// end are omitted; the client indexes each word by `Group` and bit by
/// `NodeId`.
pub fn tower_growth_detail_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);

    const details = towerGrowthDetails(scope.player);
    try scope.respond(proto.pb.TowerGrowthDetailResp{
        .Detail = .fromOwnedSlice(@constCast(details)),
    });
}

pub fn tower_growth_node_unlock_req(scope: *Scope) !void {
    const log = scope.logger(.tower_growth_node_unlock_req);

    const request = try scope.source.read(proto.pb.UI32);
    const node = gameplay.tower_growth.unlock(scope.mutation(), request.Value) catch |err| switch (err) {
        error.InvalidNode, error.LockedNode, error.InsufficientItems => {
            log.warn("rejected Monolith Research node {d}: {t}", .{ request.Value, err });
            return scope.reject(switch (err) {
                error.InsufficientItems => .talent_key_nodes_insufficient_quantity,
                error.InvalidNode, error.LockedNode => .talent_not_yet_activated,
            });
        },
    };
    _ = try gameplay.research_project.sync(
        scope.mutation().modify(.{ .quests = true, .research_project = true }),
        scope.gpa,
    );

    var change: ItemChange = undefined;
    try change.init(node.cost_item_id, -node.cost_item_quantity);
    try scope.respond(change.info());

    log.info("unlocked Monolith Research node {d}", .{node.id});
}

/// Quick Research resolves every reachable node on a floor.
pub fn tower_growth_group_node_unlock_req(scope: *Scope) !void {
    const log = scope.logger(.tower_growth_group_node_unlock_req);

    const request = try scope.source.read(proto.pb.UI32);
    const player = scope.player;
    var staged_details = player.tower_growth.details;
    var node_ids: [tables.tower_growth.list.len]u32 = undefined;
    var node_count: usize = 0;
    var cost_item_id: u32 = 0;
    var total_cost: i32 = 0;

    for (tables.tower_growth.list) |node| {
        if (node.group != request.Value)
            continue;
        if (!gameplay.tower_growth.canUnlock(
            &staged_details,
            node.id,
            @intFromEnum(player.basic.level),
        ))
            continue;
        if (cost_item_id == 0) cost_item_id = node.cost_item_id;
        if (cost_item_id != node.cost_item_id)
            return scope.reject(.invalid_req);
        total_cost += node.cost_item_quantity;
        gameplay.tower_growth.setUnlocked(&staged_details, node.id);
        node_ids[node_count] = node.id;
        node_count += 1;
    }
    if (node_count == 0)
        return scope.reject(.tower_growth_group_activated);
    if (player.itemQuantity(cost_item_id) < total_cost)
        return scope.reject(.talent_key_nodes_insufficient_quantity);

    const writable = scope.mutation().modify(.{
        .inventory = true,
        .tower_growth = true,
        .research_project = true,
        .quests = true,
    });
    writable.consumeItem(cost_item_id, total_cost) catch unreachable;
    writable.tower_growth.details = staged_details;
    _ = try gameplay.research_project.sync(writable, scope.gpa);

    var change: ItemChange = undefined;
    try change.init(cost_item_id, -total_cost);
    try scope.respond(proto.pb.TowerGrowthGroupNodeUnlockResp{
        .Nodes = .fromOwnedSlice(node_ids[0..node_count]),
        .ChangeInfo = change.info(),
    });

    log.info("quick-unlocked {d} Monolith Research node(s) in tier {d}", .{
        node_count,
        request.Value,
    });
}

const ItemChange = struct {
    encoded: [32]u8 = undefined,
    props: [1]proto.pb.Any = undefined,

    fn init(change: *ItemChange, item_id: u32, quantity: i32) proto.EncodeError!void {
        var writer = Io.Writer.fixed(&change.encoded);
        const item: proto.pb.Item = .{
            .Id = item_id,
            .Tid = item_id,
            .Qty = quantity,
        };
        try proto.encode(proto.pb.Item, &writer, &item);
        change.props[0] = .{
            .type_url = "type.googleapis.com/proto.Item",
            .value = writer.buffered(),
        };
    }

    fn info(change: *ItemChange) proto.pb.ChangeInfo {
        return .{ .Props = .fromOwnedSlice(&change.props) };
    }
};

fn towerGrowthDetails(player: *const Player) []const u32 {
    var len = player.tower_growth.details.len;
    while (len != 0 and player.tower_growth.details[len - 1] == 0)
        len -= 1;

    return player.tower_growth.details[0..len];
}
