const std = @import("std");
const generated = @import("generated/assets/shop");
const lookup = @import("lookup.zig");

pub const Reward = generated.Reward;
pub const RefreshType = generated.RefreshType;
pub const Entry = generated.MallPackage;
pub const entries = generated.mall_packages;
pub const max_rewards = generated.max_package_rewards;

// TODO: Enforce MallPackage list/order conditions after their type and parameter semantics are recovered.
pub const Lookup = struct { entry: Entry, key: u64 };
const by_key = lookup.Lookup(u64, lookup.fieldKeys(u64, entries, "key"));

pub fn get(id: []const u8) ?Lookup {
    const row = by_key.find(generated.productKey(id)) orelse return null;
    const entry = entries[row];
    if (!std.mem.eql(u8, entry.id, id)) return null;
    return .{ .entry = entry, .key = entry.key };
}

pub fn visible(entry: Entry, now: i64, show_expired: bool) bool {
    if (entry.starts_at != 0 and now < entry.starts_at)
        return false;
    return show_expired or entry.ends_at == 0 or now < entry.ends_at;
}

pub fn available(entry: Entry, now: i64) bool {
    return visible(entry, now, false);
}
