const std = @import("std");
const generated = @import("generated/assets/shop");
const lookup = @import("lookup.zig");

pub const Entry = generated.MallMonthlyCard;
pub const entries = generated.mall_monthly_cards;
pub const Lookup = struct { entry: Entry, key: u64 };
const by_key = lookup.Lookup(u64, lookup.fieldKeys(u64, entries, "key"));

pub fn get(id: []const u8) ?Lookup {
    const row = by_key.find(generated.productKey(id)) orelse return null;
    const entry = entries[row];
    if (!std.mem.eql(u8, entry.id, id)) return null;
    return .{ .entry = entry, .key = entry.key };
}
