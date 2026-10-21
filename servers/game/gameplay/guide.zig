const std = @import("std");
const Allocator = std.mem.Allocator;

const config: @import("../Config.zig") = @import("config");
const Mutation = @import("mutation.zig");

//

/// Marks guide groups that the bundled guide table does not know about as
/// complete. The client runs a guide for every group it knows, and a guide
/// for a system the server does not implement asks for data the server cannot
/// answer, which ends in a client-side error.
pub fn ensureExtraGuides(mutation: *Mutation, allocator: Allocator) Allocator.Error!bool {
    if (config.extra_guide_groups.len == 0) return false;

    const player = mutation.read();
    var changed = false;
    for (config.extra_guide_groups) |group_id| {
        var known = false;
        for (player.guides.slice()) |guide| {
            if (guide.group_id != group_id) continue;

            known = true;
            break;
        }
        if (known) continue;

        const writable = mutation.modify(.{});
        try writable.learn(allocator, group_id, -1);
        changed = true;
    }

    return changed;
}
