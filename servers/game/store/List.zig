//! Stores a player-owned list without reserving its maximum size up front.
//! `entries` holds the allocated capacity and `len` marks the portion in use.

const std = @import("std");
const Allocator = std.mem.Allocator;

//

pub fn List(comptime Entry: type) type {
    return struct {
        entries: []Entry = &.{},
        len: usize = 0,

        pub fn deinit(list: *@This(), allocator: Allocator) void {
            if (list.entries.len != 0)
                allocator.free(list.entries);
            list.entries = &.{};
            list.len = 0;
        }

        pub fn clear(list: *@This()) void {
            list.len = 0;
        }

        pub fn append(list: *@This(), allocator: Allocator, entry: Entry) Allocator.Error!void {
            try list.ensureTotalCapacity(allocator, list.len + 1);
            list.entries[list.len] = entry;
            list.len += 1;
        }

        pub fn swapRemove(list: *@This(), index: usize) Entry {
            std.debug.assert(index < list.len);

            const entry = list.entries[index];
            list.len -= 1;
            if (index != list.len)
                list.entries[index] = list.entries[list.len];

            return entry;
        }

        pub fn ensureTotalCapacity(list: *@This(), allocator: Allocator, count: usize) Allocator.Error!void {
            if (count <= list.entries.len)
                return;

            var capacity: usize = if (list.entries.len == 0) 8 else list.entries.len;
            while (capacity < count)
                capacity += capacity / 2;

            list.entries = if (list.entries.len == 0)
                try allocator.alloc(Entry, capacity)
            else
                try allocator.realloc(list.entries, capacity);
        }

        pub fn slice(list: *const @This()) []const Entry {
            return list.entries[0..list.len];
        }

        pub fn mutableSlice(list: *@This()) []Entry {
            return list.entries[0..list.len];
        }
    };
}
