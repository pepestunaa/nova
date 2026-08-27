const generated = @import("generated/assets/shop");
const lookup = @import("lookup.zig");

pub const RefreshType = generated.RefreshType;
pub const Entry = generated.MallShop;
pub const entries = generated.mall_shop;
pub const Lookup = struct { entry: Entry, key: u64 };
const by_id = lookup.Lookup(u32, lookup.fieldKeys(u32, entries, "id"));

pub fn get(id: u32) ?Lookup {
    const row = by_id.find(id) orelse return null;
    const entry = entries[row];
    return .{ .entry = entry, .key = entry.key };
}

pub fn available(entry: Entry, now: i64) bool {
    return (entry.starts_at == 0 or now >= entry.starts_at) and (entry.ends_at == 0 or now < entry.ends_at);
}
