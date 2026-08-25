const Allocator = @import("std").mem.Allocator;

const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

//

pub fn ensureDefaultSkins(mutation: *Mutation, allocator: Allocator) Allocator.Error!bool {
    const player = mutation.read();
    var changed = false;
    var characters = player.characters.iterator();
    while (characters.next()) |character| {
        const entry = tables.handbook.defaultSkin(character.id()) orelse
            continue;
        if (hasEntry(player, entry.id))
            continue;

        const writable = mutation.modify(.{});
        _ = try writable.unlockHandbook(allocator, entry.id);
        mutation.recordHandbookType(tables.handbook.skin_type);
        changed = true;
    }

    return changed;
}

fn hasEntry(player: *const Player, id: u32) bool {
    for (player.handbook.slice()) |entry| {
        if (entry.handbook_id == id)
            return true;
    }

    return false;
}
