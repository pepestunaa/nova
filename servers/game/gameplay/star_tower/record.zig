const std = @import("std");
const Allocator = std.mem.Allocator;

const Player = @import("../../store/Player.zig");
const tables = @import("../../tables.zig");
const tower = @import("../star_tower.zig");
const tower_growth = @import("../tower_growth.zig");

//

/// Turns the active Ascension into the pending Record that the player can save
/// or dismantle. Finishing and giving up both use this path.
pub fn preparePendingBuild(
    player: *Player,
    formation: *const Player.Formation,
    score: u32,
) *const Player.StarTowerBuild {
    const run = &player.star_tower_run;
    const build = &player.pending_star_tower_build;
    build.* = .{
        .flags = .{
            .valid = true,
            .locked = score >= tower.build_auto_lock_score,
        },
        .id = run.build_id,
        .tower_id = run.tower_id,
        .score = score,
        .character_count = formation.character_count,
        .disc_count = formation.disc_count,
        .potential_count = run.potential_count,
        .tower_item_count = run.tower_item_count,
        .active_secondary_count = run.active_secondary_count,
    };
    @memcpy(build.character_ids[0..formation.character_count], formation.character_ids[0..formation.character_count]);
    @memcpy(build.disc_ids[0..formation.disc_count], formation.disc_ids[0..formation.disc_count]);
    @memcpy(build.potential_ids[0..run.potential_count], run.potential_ids[0..run.potential_count]);
    @memcpy(build.potential_levels[0..run.potential_count], run.potential_levels[0..run.potential_count]);
    @memcpy(build.tower_item_ids[0..run.tower_item_count], run.tower_item_ids[0..run.tower_item_count]);
    @memcpy(build.tower_item_quantities[0..run.tower_item_count], run.tower_item_quantities[0..run.tower_item_count]);
    @memcpy(build.active_secondary_ids[0..run.active_secondary_count], run.active_secondary_ids[0..run.active_secondary_count]);

    return build;
}

pub fn dismantleTicketCount(score: u32) u32 {
    return std.math.clamp(
        score / build_transform_parameters[0],
        build_transform_parameters[1],
        build_transform_parameters[2],
    );
}

pub fn awardDismantleTickets(
    player: *Player,
    allocator: Allocator,
    requested: u32,
    now: i64,
) !u32 {
    const week = @divFloor(now, seconds_per_week);
    if (player.progress.tower_ticket_week != week) {
        player.progress.tower_ticket_week = week;
        player.progress.tower_ticket = 0;
    }
    const modifiers = tower_growth.Modifiers.init(&player.tower_growth.details, 1);
    const awarded = @min(
        requested,
        modifiers.journey_ticket_weekly_limit -| player.progress.tower_ticket,
    );
    if (awarded != 0) try player.addResource(allocator, journey_ticket_id, @intCast(awarded));
    player.progress.tower_ticket +|= awarded;
    return awarded;
}

pub const journey_ticket_id =
    tables.config.unsignedList(u32, "StarTowerBuildDeleteReturnItemId")[0];

/// Allocates the ID reused by the Record if this Ascension is saved.
pub fn newBuildId(player: *const Player, timestamp: u64) u64 {
    var result = timestamp;
    for (player.star_tower_builds.slice()) |build| {
        if (build.id >= result) result = build.id +| 1;
    }
    if (player.pending_star_tower_build.flags.valid and
        player.pending_star_tower_build.id >= result)
    {
        result = player.pending_star_tower_build.id +| 1;
    }
    return result;
}

const build_transform_parameters =
    tables.config.unsignedList(u32, "StarTowerBuildTransformParas");
const seconds_per_week = 7 * 24 * 60 * 60;

comptime {
    std.debug.assert(build_transform_parameters.len == 3);
    std.debug.assert(build_transform_parameters[0] != 0);
}
