const std = @import("std");

/// Collects a field from every table row at compile time.
pub fn fieldKeys(comptime Key: type, comptime rows: anytype, comptime field: []const u8) []const Key {
    comptime {
        @setEvalBranchQuota(100 * rows.len + 1000);

        var keys: [rows.len]Key = undefined;
        for (rows, 0..) |row, index| keys[index] = @field(row, field);
        const result = keys;

        return &result;
    }
}

/// Maps each key to its row. Duplicate keys fail compilation.
pub fn Lookup(comptime Key: type, comptime keys: []const Key) type {
    return struct {
        /// Returns the row containing `key`, or null if it is absent.
        pub fn find(key: Key) ?usize {
            return switch (comptime strategy()) {
                .direct => {
                    const offset = @as(i128, key) - @as(i128, minimum);
                    if (offset < 0 or offset >= direct_slots.len) return null;
                    const row = direct_slots[@intCast(offset)];

                    return if (row == absent) null else row;
                },
                // An ordered table needs no side index because each key's
                // value is already its row.
                .ascending => std.sort.binarySearch(Key, keys, key, orderKey),
                .sorted => {
                    const position = std.sort.binarySearch(
                        Pair,
                        sorted_pairs,
                        key,
                        Pair.order,
                    ) orelse
                        return null;

                    return sorted_pairs[position].row;
                },
            };
        }

        pub fn contains(key: Key) bool {
            return find(key) != null;
        }

        const Row = u32;
        const absent = std.math.maxInt(Row);

        fn orderKey(key: Key, candidate: Key) std.math.Order {
            return std.math.order(key, candidate);
        }

        const is_ascending = blk: {
            @setEvalBranchQuota(1000 * keys.len + 10_000);

            for (keys[0..keys.len -| 1], keys[1..]) |current, next| {
                if (current >= next)
                    break :blk false;
            }

            break :blk true;
        };

        const Pair = struct {
            key: Key,
            row: Row,

            fn order(key: Key, pair: Pair) std.math.Order {
                return std.math.order(key, pair.key);
            }

            fn lessThan(_: void, lhs: Pair, rhs: Pair) bool {
                return lhs.key < rhs.key;
            }
        };

        /// Used only when the table needs a sorted side index.
        const sorted_pairs: []const Pair = pairs: {
            if (strategy() != .sorted)
                break :pairs &.{};

            @setEvalBranchQuota(1000 * keys.len + 10_000);

            var pairs: [keys.len]Pair = undefined;
            for (keys, 0..) |key, row| pairs[row] = .{ .key = key, .row = @intCast(row) };
            std.mem.sort(Pair, &pairs, {}, Pair.lessThan);
            for (pairs[0..pairs.len -| 1], pairs[1..]) |current, next| {
                if (current.key == next.key) @compileError(std.fmt.comptimePrint(
                    "duplicate table key {d} at rows {d} and {d}",
                    .{ current.key, current.row, next.row },
                ));
            }
            const result = pairs;

            break :pairs &result;
        };

        const bounds = blk: {
            @setEvalBranchQuota(1000 * keys.len + 10_000);
            if (keys.len == 0) break :blk [2]Key{ 0, 0 };

            var low = keys[0];
            var high = keys[0];
            for (keys[1..]) |key| {
                low = @min(low, key);
                high = @max(high, key);
            }

            break :blk [2]Key{ low, high };
        };

        const minimum: Key = bounds[0];
        const maximum: Key = bounds[1];

        const span: u128 = if (keys.len == 0)
            0
        else
            @intCast(@as(i128, maximum) - @as(i128, minimum) + 1);

        /// A direct table reserves 1 `Row` for every value in the key range,
        /// so use it only when that range stays close to the row count. Ordered
        /// tables index themselves; the rest use a sorted side index.
        fn strategy() enum { direct, ascending, sorted } {
            if (keys.len == 0)
                return .sorted;
            if (span <= @max(64, @as(u128, keys.len) * 2))
                return .direct;
            return if (is_ascending) .ascending else .sorted;
        }

        const direct_slots: []const Row = slots: {
            if (strategy() != .direct) break :slots &.{};
            @setEvalBranchQuota(1000 * keys.len + 10_000);

            var slots: [@as(usize, @intCast(span))]Row = @splat(absent);
            for (keys, 0..) |key, row| {
                const slot: usize = @intCast(@as(i128, key) - @as(i128, minimum));
                if (slots[slot] != absent) @compileError(std.fmt.comptimePrint(
                    "duplicate table key {d} at rows {d} and {d}",
                    .{ key, slots[slot], row },
                ));
                slots[slot] = @intCast(row);
            }
            const result = slots;

            break :slots &result;
        };
    };
}
