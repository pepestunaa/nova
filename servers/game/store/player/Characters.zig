const std = @import("std");
const StaticBitSet = std.StaticBitSet;

const State = @import("State.zig");
const Character = State.Character;
const max_characters = State.max_characters;
const tables = @import("../../tables.zig");

//

pub const Table = struct {
    unlocked: StaticBitSet(max_characters) = .empty,
    entries: [max_characters]Character = @splat(.{}),

    pub fn clear(table: *Table) void {
        table.unlocked = .empty;
    }

    pub fn append(table: *Table, id: u32, character: Character) error{Full}!void {
        const index = tables.character.Index.fromId(id) orelse
            return error.Full;

        if (table.unlocked.isSet(@intFromEnum(index)))
            return error.Full;

        table.entries[@intFromEnum(index)] = character;
        table.unlocked.set(@intFromEnum(index));
    }

    pub fn count(table: *const Table) usize {
        return table.unlocked.count();
    }

    pub fn get(table: *const Table, id: u32) ?*const Character {
        const index = tables.character.Index.fromId(id) orelse
            return null;

        if (!table.unlocked.isSet(@intFromEnum(index)))
            return null;

        return &table.entries[@intFromEnum(index)];
    }

    pub fn getMut(table: *Table, id: u32) ?*Character {
        const index = tables.character.Index.fromId(id) orelse
            return null;

        if (!table.unlocked.isSet(@intFromEnum(index)))
            return null;

        return &table.entries[@intFromEnum(index)];
    }

    pub fn iterator(table: *const Table) Iterator {
        return .{
            .table = table,
            .inner = table.unlocked.iterator(.{}),
        };
    }

    pub const Iterator = struct {
        table: *const Table,
        inner: StaticBitSet(max_characters).Iterator(.{}),

        pub fn next(it: *Iterator) ?Entry {
            const index = it.inner.next() orelse
                return null;

            return .{
                .index = @enumFromInt(index),
                .value = &it.table.entries[index],
            };
        }
    };

    pub const Entry = struct {
        index: tables.character.Index,
        value: *const Character,

        pub fn id(entry: Entry) u32 {
            return entry.index.id();
        }

        pub fn gemSlots(entry: Entry) [3]u32 {
            return entry.index.gemSlots();
        }
    };
};
