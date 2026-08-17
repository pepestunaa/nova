const Allocator = @import("std").mem.Allocator;

const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

//

pub const ChangeSet = struct {
    entries: [tables.achievement.collection_entry_count]Player.Achievement = undefined,
    len: usize = 0,
    dirty: bool = false,

    pub fn slice(changes: *const ChangeSet) []const Player.Achievement {
        return changes.entries[0..changes.len];
    }
};

/// Rebuilds the collection achievements from the player's lifetime
/// acquisitions, so the result remains correct after a restart.
pub fn refreshCollection(player: *Player, allocator: Allocator, now: i64, changes: *ChangeSet) !void {
    changes.* = .{};

    var counts: [@typeInfo(tables.achievement.CollectionKind).@"enum".fields.len]u32 = @splat(0);
    for (player.acquisitions.slice()) |acquisition| {
        const card = tables.gacha.maybeClassifyCard(acquisition.id) orelse
            continue;
        switch (card.kind) {
            .disc => {
                counts[@intFromEnum(tables.achievement.CollectionKind.all_discs)] +|= acquisition.count;
                if (card.rarity == .five_star)
                    counts[@intFromEnum(tables.achievement.CollectionKind.five_star_discs)] +|= acquisition.count;
            },
            .character => {
                counts[@intFromEnum(tables.achievement.CollectionKind.all_trekkers)] +|= acquisition.count;
                if (card.rarity == .five_star)
                    counts[@intFromEnum(tables.achievement.CollectionKind.five_star_trekkers)] +|= acquisition.count;
            },
        }
    }

    for (tables.achievement.collection_groups, 0..) |group, group_index| {
        for (group.entries) |definition| {
            const state = try getOrCreate(player, allocator, definition.id);
            const previous_status = state.status;
            const status: Player.Achievement.Status = if (previous_status == .reward_received)
                .reward_received
            else if (counts[group_index] >= definition.target)
                .reward_available
            else
                .in_progress;
            const completed_at: i64 = if (status != .in_progress and state.completed_at == 0)
                now
            else
                state.completed_at;
            if (state.progress == counts[group_index] and state.status == status and state.completed_at == completed_at)
                continue;

            state.progress = counts[group_index];
            state.status = status;
            state.completed_at = completed_at;
            changes.dirty = true;

            // Any non-in-progress update opens a new completion banner. Keep
            // saving later progress, but notify only on the first completion.
            if (previous_status != .in_progress)
                continue;
            changes.entries[changes.len] = state.*;
            changes.len += 1;
        }
    }
}

fn getOrCreate(player: *Player, allocator: Allocator, id: u32) !*Player.Achievement {
    for (player.achievements.entries[0..player.achievements.len]) |*entry| {
        if (entry.id == id) return entry;
    }
    try player.achievements.append(allocator, .{ .id = id });

    return &player.achievements.entries[player.achievements.len - 1];
}
