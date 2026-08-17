const generated = @import("generated/assets/gacha");
const acquire_rewards = generated.acquire_rewards;
const a_type_probabilities = generated.a_type_probabilities;

const character = @import("character.zig");
const disc = @import("disc.zig");
const lookup = @import("lookup.zig");
const newbie_config = @import("gacha_newbie.zig");

//

pub const Banner = generated.Banner;
pub const ItemReward = generated.ItemReward;
pub const PackageEntry = generated.PackageEntry;
pub const Reward = generated.Reward;
pub const Storage = generated.Storage;
pub const banner_ids = generated.banner_ids;
pub const banners = generated.banners;

pub const probability_scale = 10_000;

pub const CardKind = enum {
    character,
    disc,
};

pub const Rarity = enum(u8) {
    five_star = 1,
    four_star = 2,
    three_star = 3,
};

pub const CardClass = struct {
    kind: CardKind,
    item_stype: u8,
    rarity: Rarity,
};

pub const Card = struct {
    id: u32,
    class: CardClass,
};

pub const NewbieGachaPool = enum {
    a,
    b_trekker,
    b_disc,
    c,
    guaranteed_b_trekker,
};

const newbie_banner = banner(newbie_config.id) orelse
    @compileError("GachaNewbie does not refer to a Gacha entry");

pub const newbie_gacha = struct {
    pub const a_type_group = newbie_banner.storage.a_type_group;
    pub const a_guarantee_pulls = newbie_banner.a_type_guarantee_pulls;
    pub const b_type_probability = newbie_banner.storage.b_probability;
    pub const b_trekker_probability = probability_scale / 2;
    pub const a_pool = newbie_banner.a_pool;
    pub const b_disc_pool = newbie_banner.b_pool;
    pub const c_pool = newbie_banner.c_pool;
    pub const b_trekker_pool = newbie_banner.b_guarantee_pool;
};

pub fn banner(id: u32) ?*const Banner {
    const row = by_banner_id.find(id) orelse return null;
    return &banners[row];
}

pub fn aTypeProbability(group: u32, pulls_without_a: u32) u32 {
    const row = by_a_type_probability.find(
        (@as(u64, group) << 32) | pulls_without_a,
    ) orelse
        return 0;

    return a_type_probabilities[row];
}

const by_banner_id = lookup.Lookup(u32, &banner_ids);
const by_a_type_probability = lookup.Lookup(u64, &generated.a_type_probability_keys);

pub fn newbieGachaATypeProbabilityAt(pulls_without_a: u8) u32 {
    return aTypeProbability(newbie_gacha.a_type_group, pulls_without_a);
}

pub fn newbieGachaPool(pool: NewbieGachaPool) []const PackageEntry {
    return switch (pool) {
        .a => newbie_gacha.a_pool,
        .b_trekker, .guaranteed_b_trekker => newbie_gacha.b_trekker_pool,
        .b_disc => newbie_gacha.b_disc_pool,
        .c => newbie_gacha.c_pool,
    };
}

pub fn cardClass(id: u32, rarity: Rarity) ?CardClass {
    if (character.grade(id) != null)
        return .{
            .kind = .character,
            .item_stype = 3,
            .rarity = rarity,
        };
    if (disc.contains(id))
        return .{
            .kind = .disc,
            .item_stype = 8,
            .rarity = rarity,
        };

    return null;
}

pub fn classifyCard(card_id: u32) CardClass {
    return maybeClassifyCard(card_id) orelse unreachable;
}

pub fn maybeClassifyCard(card_id: u32) ?CardClass {
    for (&banners) |*entry| {
        if (contains(entry.a_pool, card_id) or contains(entry.a_up_pool, card_id))
            return cardClass(card_id, .five_star);
        if (contains(entry.b_pool, card_id) or
            contains(entry.b_up_pool, card_id) or
            contains(entry.b_guarantee_pool, card_id))
            return cardClass(card_id, .four_star);
        if (contains(entry.c_pool, card_id))
            return cardClass(card_id, .three_star);
    }

    return null;
}

pub fn acquireReward(card: CardClass, acquisition_number: u32) ?Reward {
    for (acquire_rewards) |entry| {
        if (entry.item_stype != card.item_stype or
            entry.item_rarity != @intFromEnum(card.rarity) or
            entry.acquire_times != acquisition_number)
            continue;

        return entry.reward;
    }

    return null;
}

fn contains(entries: []const PackageEntry, id: u32) bool {
    for (entries) |entry| if (entry.goods_id == id)
        return true;

    return false;
}
