pub const Scope = @import("Scope.zig");

const proto = @import("proto");

//

// TODO: Improve errors
const Handler = *const fn (*Scope) anyerror!void;

const namespaces: []const type = &.{
    @import("messaging/achievement.zig"),
    @import("messaging/activity_detail.zig"),
    @import("messaging/client_event_report.zig"),
    @import("messaging/character.zig"),
    @import("messaging/disc.zig"),
    @import("messaging/energy_info.zig"),
    @import("messaging/gacha.zig"),
    @import("messaging/gacha_newbie.zig"),
    @import("messaging/ike.zig"),
    @import("messaging/login.zig"),
    @import("messaging/mall_package.zig"),
    @import("messaging/npc_affinity.zig"),
    @import("messaging/player_data.zig"),
    @import("messaging/player_formation.zig"),
    @import("messaging/player_learn.zig"),
    @import("messaging/player_ping.zig"),
    @import("messaging/player_reg.zig"),
    @import("messaging/potential_preselection.zig"),
    @import("messaging/quest_tower_reward_receive.zig"),
    @import("messaging/star_tower.zig"),
    @import("messaging/star_tower_apply.zig"),
    @import("messaging/star_tower_book.zig"),
    @import("messaging/star_tower_build.zig"),
    @import("messaging/star_tower_give_up.zig"),
    @import("messaging/star_tower_info.zig"),
    @import("messaging/tower_growth.zig"),
};

const max_packet_id = blk: {
    var result: i16 = 0;
    for (@typeInfo(proto.PacketId).@"enum".fields) |field| {
        const id: i16 = @intCast(field.value);
        if (id > result) result = id;
    }

    break :blk @as(usize, @intCast(result));
};

const handlers: []const ?Handler = handlers: {
    var result: [max_packet_id + 1]?Handler = @splat(null);

    for (namespaces) |namespace| for (@typeInfo(namespace).@"struct".decls) |decl| {
        const value = @field(namespace, decl.name);
        if (@typeInfo(@TypeOf(value)) != .@"fn")
            continue;

        const info = @typeInfo(@TypeOf(value)).@"fn";
        if (info.params.len != 1 or info.params[0].type.? != *Scope)
            @compileError("handler '" ++ decl.name ++ "' must take exactly one `*Scope` argument");

        const id = @field(proto.PacketId, decl.name);
        const raw_id = @intFromEnum(id);
        if (raw_id < 0)
            @compileError("handler '" ++ decl.name ++ "' cannot use a negative packet ID");
        if (result[raw_id] != null)
            @compileError("handler for '" ++ @tagName(id) ++ "' defined twice");

        result[raw_id] = &value;
    };

    const final = result;

    break :handlers &final;
};

pub fn dispatch(scope: *Scope) anyerror!void {
    const raw_id = @intFromEnum(scope.source.id);
    if (raw_id < 0 or raw_id >= handlers.len)
        return error.UnhandledMessage;

    return if (handlers[@intCast(raw_id)]) |handler|
        handler(scope)
    else
        error.UnhandledMessage;
}
