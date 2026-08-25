const std = @import("std");

const Player = @import("../store/Player.zig");
const proto = @import("proto");
const tables = @import("../tables.zig");

//

/// Builds a Gallery bitmap in the format cached by the client. `null` means
/// the player has no entries of that type.
pub fn info(
    player: *const Player,
    handbook_type: usize,
    bitmap: []u8,
) ?proto.pb.HandbookInfo {
    std.debug.assert(bitmap.len >= tables.handbook.max_bitmap_len);
    @memset(bitmap, 0);

    var bitmap_len: usize = 0;
    for (player.handbook.slice()) |unlock| {
        const entry = tables.handbook.get(unlock.handbook_id) orelse
            continue;
        if (entry.type != handbook_type) continue;

        const byte_index = tables.handbook.bitmapByteIndex(entry.index);
        const bit: u3 = @intCast((entry.index - 1) % 8);
        bitmap[byte_index] |= @as(u8, 1) << bit;
        bitmap_len = @max(bitmap_len, tables.handbook.bitmapLen(entry.index));
    }

    if (bitmap_len == 0)
        return null;

    return .{
        .Type = @intCast(handbook_type),
        .Data = bitmap[0..bitmap_len],
    };
}
