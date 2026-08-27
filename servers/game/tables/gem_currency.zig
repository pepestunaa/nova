const raw_currency = @import("tables/GemCurrency");

pub const Currency = struct { paid_item_id: u32, free_item_id: u32, gem_item_id: u32 };
pub const currency: Currency = .{
    .paid_item_id = raw_currency.paid_item_id,
    .free_item_id = raw_currency.free_item_id,
    .gem_item_id = raw_currency.gem_item_id,
};
