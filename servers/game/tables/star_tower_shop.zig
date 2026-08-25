const lookup = @import("lookup.zig");

const raw_goods = @import("tables/StarTowerShopGoods");

const goods_count: usize = raw_goods.len;

//

pub const Entry = struct {
    id: u32,
    group_id: u32,
    display_item_id: u32,
    display_quantity: u32,
};

pub const list = blk: {
    var entries: [goods_count]Entry = undefined;
    for (raw_goods, 0..) |raw, index| entries[index] = .{
        .id = raw.id,
        .group_id = raw.goods_group_id,
        .display_item_id = raw.show_item,
        .display_quantity = if (@hasField(@TypeOf(raw), "show_item_num")) raw.show_item_num else 1,
    };

    break :blk entries;
};

const by_id = lookup.Lookup(u32, lookup.fieldKeys(u32, &list, "id"));

pub fn get(id: u32) ?Entry {
    const row = by_id.find(id) orelse
        return null;
    return list[row];
}

pub const potential_selector = get(1) orelse @compileError("missing StarTowerShopGoods potential selector");
pub const standard_note_pack = get(3) orelse @compileError("missing StarTowerShopGoods standard note pack");
pub const premium_note_pack = get(8) orelse @compileError("missing StarTowerShopGoods premium note pack");
