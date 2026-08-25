const std = @import("std");

const comptime_utils = @import("comptime.zig");
const lookup = @import("lookup.zig");

const raw_list = @import("tables/AffinityQuest");

const count: usize = raw_list.len;

//

pub const Entry = struct {
    id: u32,
    character_id: u16,
    target: u32,
};

pub const list: [count]Entry = blk: {
    @setEvalBranchQuota(100_000);

    var entries: [count]Entry = undefined;

    for (raw_list, 0..) |raw, index| {
        entries[index] = .{
            .id = raw.id,
            .character_id = std.math.cast(u16, raw.char_id) orelse
                @compileError("affinity quest character ID exceeds u16"),
            .target = comptime_utils.parseUnsigned(u32, raw.param1),
        };
    }

    break :blk entries;
};

const Range = struct {
    character_id: u16,
    start: u32,
    len: u32,
};

const ranges: []const Range = blk: {
    @setEvalBranchQuota(100_000);

    var result: []const Range = &.{};
    for (list, 0..) |entry, index| {
        if (result.len != 0 and result[result.len - 1].character_id == entry.character_id) {
            var last = result[result.len - 1];
            last.len += 1;
            result = result[0 .. result.len - 1] ++ [1]Range{last};

            continue;
        }

        for (result) |existing| {
            if (existing.character_id == entry.character_id)
                @compileError(std.fmt.comptimePrint(
                    "AffinityQuest entries for character {d} are not contiguous",
                    .{entry.character_id},
                ));
        }
        result = result ++ [1]Range{.{
            .character_id = entry.character_id,
            .start = index,
            .len = 1,
        }};
    }
    const final = result[0..result.len].*;

    break :blk &final;
};

pub const max_per_character = blk: {
    var maximum: usize = 0;
    for (ranges) |range| maximum = @max(maximum, range.len);

    break :blk maximum;
};

const by_character = lookup.Lookup(u16, lookup.fieldKeys(u16, ranges, "character_id"));

pub fn forCharacter(character_id: u16) []const Entry {
    const row = by_character.find(character_id) orelse
        return &.{};
    const range = ranges[row];

    return list[range.start..][0..range.len];
}
