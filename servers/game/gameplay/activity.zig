const tables = @import("../tables.zig");

//

/// Returns the activities currently visible to the player. Permanent ones
/// begin when the account is created.
pub fn active(now: i64, player_created_at: i64, output: []tables.activity.Entry) []const tables.activity.Entry {
    var count: usize = 0;
    for (tables.activity.list) |entry| {
        if (entry.end_at >= 0 and entry.end_at <= now)
            continue;
        if (!entry.permanent and entry.start_at > now)
            continue;

        output[count] = entry;
        if (entry.permanent) output[count].start_at = player_created_at;
        count += 1;
    }

    return output[0..count];
}

/// The permanent beginner campaign keeps its unread marker in
/// `PlayerInfo.State.Activities`, not the activity-detail response.
pub fn showsNew(entry: tables.activity.Entry) bool {
    return entry.type == 1;
}
