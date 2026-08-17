const std = @import("std");
const Allocator = std.mem.Allocator;

const common = @import("common");
const List = @import("../List.zig").List;
const tables = @import("../../tables.zig");

//

pub const max_formation_characters = 3;
pub const max_formation_discs = 6;

pub const MapParam = List(u8);
pub const ClientData = List(u8);

pub const Run = extern struct {
    pub const max_potentials = tables.config.unsignedList(
        usize,
        "PotentialPreselectionMaxCount",
    )[0];
    pub const max_shop_goods = 8;
    pub const max_tower_items = 64;
    pub const max_active_secondary_ids = tables.disc_secondary.max_active_ids;
    pub const max_room_cases = 16;
    pub const max_affinity_changes = 16;

    pub const RoomCaseKind = enum(u8) {
        none,
        battle,
        door,
        select_special_potential,
        select_potential,
        select_event,
        recovery_hp,
        npc_recovery_hp,
        hawker,
        strengthen_machine,
        sync_hp,
    };

    total_damages: [max_formation_characters]u64 = @splat(0),
    /// ID reused if this Ascension becomes a Record.
    build_id: u64 = 0,
    event_rng_state: u64 = 1,
    tower_id: u32 = 0,
    formation_id: u32 = 0,
    floor: u32 = 0,
    pending_floor: u32 = 0,
    /// Keeps the client's chosen layout so `star_tower_info_req` can restore
    /// the same room.
    map_id: u32 = 0,
    map_param_id: u32 = 0,
    map_table_id: u32 = 0,
    client_data_declared_len: u32 = 0,
    client_data_version: u32 = 0,
    char_hp: u32 = 0,
    team_level: u32 = 1,
    team_exp: u32 = 0,
    tower_coins: u32 = 0,
    potential_ids: [max_potentials]u32 = @splat(0),
    offered_potential_ids: [3]u32 = @splat(0),
    offered_potential_character_id: u32 = 0,
    potential_reroll_price: u32 = 0,
    shop_floor: u32 = 0,
    shop_good_sids: [max_shop_goods]u32 = @splat(0),
    shop_good_indices: [max_shop_goods]u32 = @splat(0),
    shop_good_char_positions: [max_shop_goods]u32 = @splat(0),
    shop_good_display_prices: [max_shop_goods]u32 = @splat(0),
    shop_good_prices: [max_shop_goods]u32 = @splat(0),
    shop_good_kinds: [max_shop_goods]u32 = @splat(0),
    shop_good_ids: [max_shop_goods]u32 = @splat(0),
    shop_good_quantities: [max_shop_goods]u32 = @splat(0),
    shop_good_tags: [max_shop_goods]u32 = @splat(0),
    shop_good_discounts: [max_shop_goods]u32 = @splat(0),
    shop_reroll_price: u32 = 0,
    tower_item_ids: [max_tower_items]u32 = @splat(0),
    tower_item_quantities: [max_tower_items]u32 = @splat(0),
    active_secondary_ids: [max_active_secondary_ids]u32 = @splat(0),
    affinity_change_npc_ids: [max_affinity_changes]u32 = @splat(0),
    affinity_change_values: [max_affinity_changes]u32 = @splat(0),
    affinity_change_increases: [max_affinity_changes]u32 = @splat(0),
    affinity_change_reward_ids: [max_affinity_changes]u32 = @splat(0),
    affinity_change_reward_quantities: [max_affinity_changes]i32 = @splat(0),
    event_id: u32 = 0,
    event_npc_id: u32 = 0,
    event_options: [tables.star_tower_event.max_options]u32 = @splat(0),
    room_case_last_id: u32 = 0,
    room_case_ids: [max_room_cases]u32 = @splat(0),
    room_case_effect_ids: [max_room_cases]u32 = @splat(0),
    settlement_time: u32 = 0,
    active: bool = false,
    sweep: bool = false,
    total_damage_count: u8 = 0,
    note_element: u8 = 0,
    potential_levels: [max_potentials]u8 = @splat(0),
    potential_count: u8 = 0,
    offered_potential_levels: [3]u8 = @splat(0),
    offered_potential_count: u8 = 0,
    potential_bonus_count: u8 = 0,
    offered_potential_bonus_pending: [3]bool = @splat(false),
    strengthen_bonus_count: u8 = 0,
    potential_rerolls: u8 = 0,
    potential_selector_is_strengthen: bool = false,
    shop_goods_count: u8 = 0,
    shop_good_purchased: [max_shop_goods]bool = @splat(false),
    shop_rerolls: u8 = 0,
    tower_item_count: u8 = 0,
    active_secondary_count: u8 = 0,
    scratch_coin_count: u8 = 0,
    surprise_note_count: u8 = 0,
    battle_event_count: u8 = 0,
    defeated_boss_count: u8 = 0,
    affinity_change_rewards_are_resources: [max_affinity_changes]bool = @splat(false),
    affinity_change_count: u8 = 0,
    strengthen_times: u8 = 0,
    strengthen_first_free_available: bool = false,
    shop_potential_pending: bool = false,
    event_option_count: u8 = 0,
    event_pending: bool = false,
    room_case_count: u8 = 0,
    room_case_kinds: [max_room_cases]RoomCaseKind = @splat(.none),
    room_case_resolved: [max_room_cases]bool = @splat(false),
    settlement_pending: bool = false,
    final_core_potential_pending: bool = false,

    padding: [1]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }

    pub fn reset(run: *Run) void {
        run.* = .{};
    }
};

/// Monolith Research unlocks, stored as a node bitmap per group.
pub const Growth = extern struct {
    details: [tables.tower_growth.detail_words]u32 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const ResearchProject = extern struct {
    ascensions: u32 = 0,
    shop_purchases: u32 = 0,
    discounted_shop_purchases: u32 = 0,
    musical_notes: u32 = 0,
    enhancement_machine_uses: u32 = 0,
    harmony_skills: u32 = 0,
    surprise_notes: u32 = 0,
    butterflies_inside: u32 = 0,
    potential_boosts: u32 = 0,
    potential_refreshes: u32 = 0,
    shop_restocks: u32 = 0,
    /// Indexed by difficulty -1. A clear counts toward every
    /// "Difficulty N or above" task at or below that difficulty.
    clears_by_difficulty: [8]u32 = @splat(0),
    highest_record_rating: u8 = 0,

    padding: [3]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

/// A completed Record is independent of the live Ascension, so it remains
/// available after settlement clears the active state.
pub const Build = extern struct {
    pub const max_potentials = Run.max_potentials;
    pub const max_tower_items = Run.max_tower_items;
    pub const max_active_secondary_ids = Run.max_active_secondary_ids;

    id: u64 = 0,
    character_ids: [max_formation_characters]u32 = @splat(0),
    disc_ids: [max_formation_discs]u32 = @splat(0),
    potential_ids: [max_potentials]u32 = @splat(0),
    tower_item_ids: [max_tower_items]u32 = @splat(0),
    tower_item_quantities: [max_tower_items]u32 = @splat(0),
    active_secondary_ids: [max_active_secondary_ids]u32 = @splat(0),
    tower_id: u32 = 0,
    score: u32 = 0,
    name: Name = .empty,
    potential_levels: [max_potentials]u8 = @splat(0),
    character_count: u8 = 0,
    disc_count: u8 = 0,
    potential_count: u8 = 0,
    tower_item_count: u8 = 0,
    active_secondary_count: u8 = 0,
    flags: Flags = .{},

    padding: [3]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }

    pub const Name = common.mem.LimitedString(64);

    pub const Flags = packed struct(u8) {
        valid: bool = false,
        locked: bool = false,
        preferred: bool = false,

        _: u5 = 0,
    };
};
