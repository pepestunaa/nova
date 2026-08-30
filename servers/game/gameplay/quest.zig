//! Initializes the quest state that is not part of daily or weekly missions.

const std = @import("std");
const Allocator = std.mem.Allocator;

const lineup_tutorial = @import("lineup_tutorial.zig");
const missions = @import("missions.zig");
const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

//

pub fn initialize(player: *Player, allocator: Allocator, created_at: i64) Allocator.Error!void {
    try missions.initialize(player, allocator, created_at);

    inline for (tables.quest.initial_tour_guide) |definition|
        try appendDefinition(player, allocator, definition, 0);

    inline for (tables.quest.assist) |definition|
        try appendDefinition(player, allocator, definition, 0);
    var lineup_changes: lineup_tutorial.Changes = .{};
    lineup_tutorial.refresh(player, &lineup_changes);

    inline for (tables.quest.tower_event) |definition|
        try appendDefinition(player, allocator, definition, 0);

    inline for (tables.periodic_quest.list) |definition|
        try player.periodic_quests.append(allocator, .{ .id = definition.id });
}

fn appendDefinition(
    player: *Player,
    allocator: Allocator,
    definition: tables.quest.Definition,
    expires_at: i64,
) Allocator.Error!void {
    try player.quests.append(allocator, .{
        .id = definition.id,
        .expires_at = expires_at,
        .quest_type = @intFromEnum(definition.type),
        .condition = definition.condition,
        .condition_param = definition.condition_param,
        .progress_max = definition.progress_max,
    });
}
