const std = @import("std");

const common = @import("common");

const gacha = @import("../../gameplay/gacha.zig");
const StarTower = @import("StarTower.zig");
const tables = @import("../../tables.zig");

//

pub const max_characters = tables.character.count;
pub const max_friends = tables.config.unsignedList(usize, "FriendMax")[0];
pub const max_formation_characters = StarTower.max_formation_characters;
pub const max_formation_discs = StarTower.max_formation_discs;
pub const max_achievements = tables.achievement.tracked_entry_count;
pub const max_star_tower_builds = tables.config.unsignedList(usize, "StarTowerBuildNumberMax")[0];

const Nickname = common.mem.LimitedString(64);

pub const StarTowerRun = StarTower.Run;
pub const StarTowerBuild = StarTower.Build;

pub const NewbieGacha = gacha.NewbieGachaState;
pub const GachaBanner = gacha.BannerState;
pub const GachaStorage = gacha.StorageState;

/// A Recruit Record entry shared by a `GachaStorage`. Single and 10-pull
/// draws still create a single history entry.
pub const GachaHistory = extern struct {
    storage_id: u32 = 0,
    banner_id: u32 = 0,
    created_at: i64 = 0,
    cards: [gacha.max_pull_count]u32 = @splat(0),
    card_count: u8 = 0,

    padding: [7]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const Basic = extern struct {
    created_at: i64 = 0,
    energy_updated_at: i64 = 0,
    energy_next_at: i64 = 0,
    head_icon: u32 = 101,
    title_prefix: u32 = 1,
    title_suffix: u32 = 2,
    profile_skin_id: u32 = 10301,
    primary_energy: PrimaryEnergy = .regeneration_max,
    level: Level = .min,
    gender: Gender = .female,
    nickname: Nickname = .empty,

    padding: [3]u8 = @splat(0),
    friend_uids: [max_friends]u64 = @splat(0),
    friend_count: u8 = 0,
    friend_stars: [(max_friends + 7) / 8]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }

    pub const PrimaryEnergy = enum(u16) {
        min = 0,
        regeneration_max = tables.config.unsignedList(u16, "EnergyMaxLimit")[0],
        obtain_max = tables.config.unsignedList(u16, "EnergyObtainLimit")[0],
        _,
    };

    pub const Level = enum(u8) {
        min = 1,
        max = tables.tower_growth.max_player_level,
        _,
    };

    pub const Gender = enum(u8) {
        female = 0,
        male = 1,
    };
};

pub const Progress = extern struct {
    story_build_id: u64 = 0,
    tower_ticket_week: i64 = 0,
    /// Client-reported battle achievements use 1 bit per configured ID. New
    /// official accounts receive this 64-byte bitmap cleared.
    achievement_bits: [64]u8 = @splat(0),
    tour_guide_quest_group: u32 = 0,
    /// Journey Tickets earned this week. The base limit is 2000 and Monolith
    /// Research can raise it.
    tower_ticket: u32 = 0,
    star_tower_npc_interactions: u32 = 0,
    daily_mall_reward_available: bool = true,

    padding: [3]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const TowerGrowth = StarTower.Growth;

pub const Character = extern struct {
    created_at: i64 = 0,
    bits: Bits = .init,
    gem_presets: [3 * 3]i32 = @splat(-1),
    skin: u32 = 0,
    skill_levels: SkillLevels = .init,
    talent_nodes: TalentNodes = .init,
    talent_background: u8 = 0,

    padding: [3]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }

    pub const Bits = packed struct(u64) {
        level: Level = .min,
        advance: Advance = .min,
        affinity_level: AffinityLevel = .min,
        is_favorite: bool = false,
        exp: Exp = .min,
        affinity_exp: AffinityExp = .min,

        _: u10 = 0,

        comptime {
            common.mem.assertNoImplicitPadding(@This());
        }

        pub const init: Bits = .{};
    };

    pub const Level = enum(u7) {
        min = 1,
        max = tables.character.max_level,
        _,
    };

    pub const Advance = enum(u4) {
        min = 0,
        max = tables.character.max_advance,
        _,
    };

    pub const AffinityLevel = enum(u7) {
        min = 0,
        max = tables.character.max_affinity_level,
        _,
    };

    pub const Exp = enum(u18) {
        min = 0,
        max = tables.character.max_exp,
        _,
    };

    pub const AffinityExp = enum(u17) {
        min = 0,
        max = tables.character.max_affinity_exp,
        _,
    };

    pub const SkillLevel = enum(u4) {
        min = 1,
        max = tables.character.max_skill_level,
        _,
    };

    pub const Skill = enum(u3) {
        attack = 1,
        main = 2,
        support = 3,
        ultimate = 4,

        pub fn fromWire(value: u32) ?Skill {
            return switch (value) {
                1 => .attack,
                2 => .main,
                3 => .support,
                4 => .ultimate,
                else => null,
            };
        }
    };

    pub const SkillLevels = packed struct(u16) {
        attack: SkillLevel = .min,
        main: SkillLevel = .min,
        support: SkillLevel = .min,
        ultimate: SkillLevel = .min,

        comptime {
            common.mem.assertNoImplicitPadding(@This());
        }

        pub const init: SkillLevels = .{};

        pub fn toArray(levels: SkillLevels) [5]u32 {
            return .{
                @intFromEnum(levels.attack),
                @intFromEnum(levels.main),
                @intFromEnum(levels.support),
                @intFromEnum(levels.ultimate),
                @intFromEnum(SkillLevel.min),
            };
        }
    };

    pub const TalentNodes = extern struct {
        pub const group_count = tables.character_progression.talent_group_count;
        pub const wire_max_len = 16;

        groups: [group_count]u16 = @splat(0),

        comptime {
            std.debug.assert(group_count == 5);
            common.mem.assertNoImplicitPadding(@This());
            std.debug.assert(@sizeOf(@This()) == group_count * @sizeOf(u16));
        }

        pub const init: TalentNodes = .{};

        pub const Index = enum(u8) {
            _,

            pub fn fromInt(value: u8) Index {
                std.debug.assert(value != 0 and value <= group_count * 16);
                return @enumFromInt(value);
            }
        };

        pub fn writeWire(nodes: *const TalentNodes, buffer: *[wire_max_len]u8) []const u8 {
            @memset(buffer, 0);
            for (nodes.groups, 0..) |group, index| {
                const byte_index: usize = if (index < 4)
                    7 - index * 2
                else
                    15;
                buffer[byte_index] = @truncate(group);
                buffer[byte_index - 1] = @truncate(group >> 8);
            }

            return if (nodes.groups[group_count - 1] == 0)
                buffer[0..8]
            else
                buffer;
        }

        pub fn has(nodes: *const TalentNodes, index: Index) bool {
            const zero_based: usize = @intFromEnum(index) - 1;
            return nodes.groups[zero_based / 16] & (@as(u16, 1) << @intCast(zero_based % 16)) != 0;
        }

        pub fn set(nodes: *TalentNodes, index: Index) bool {
            const zero_based: usize = @intFromEnum(index) - 1;
            const group = &nodes.groups[zero_based / 16];
            const mask = @as(u16, 1) << @intCast(zero_based % 16);
            const was_set = group.* & mask != 0;
            group.* |= mask;

            return !was_set;
        }
    };

    pub fn level(character: *const Character) u32 {
        return @intFromEnum(character.bits.level);
    }

    pub fn exp(character: *const Character) u32 {
        return @intFromEnum(character.bits.exp);
    }

    pub fn affinityLevel(character: *const Character) u32 {
        return @intFromEnum(character.bits.affinity_level);
    }

    pub fn affinityExp(character: *const Character) u32 {
        return @intFromEnum(character.bits.affinity_exp);
    }

    pub fn advance(character: *const Character) u32 {
        return @intFromEnum(character.bits.advance);
    }

    pub fn isFavorite(character: *const Character) bool {
        return character.bits.is_favorite;
    }

    pub fn skillLevels(character: *const Character) [5]u32 {
        return character.skill_levels.toArray();
    }

    pub fn skillLevel(character: *const Character, skill: Skill) u8 {
        return @intFromEnum(switch (skill) {
            .attack => character.skill_levels.attack,
            .main => character.skill_levels.main,
            .support => character.skill_levels.support,
            .ultimate => character.skill_levels.ultimate,
        });
    }

    pub fn setSkillLevel(character: *Character, skill: Skill, new_level: u8) void {
        const value: SkillLevel = @enumFromInt(new_level);
        switch (skill) {
            .attack => character.skill_levels.attack = value,
            .main => character.skill_levels.main = value,
            .support => character.skill_levels.support = value,
            .ultimate => character.skill_levels.ultimate = value,
        }
    }

    pub fn writeTalentNodes(character: *const Character, buffer: *[TalentNodes.wire_max_len]u8) []const u8 {
        return character.talent_nodes.writeWire(buffer);
    }

    pub fn hasTalent(character: *const Character, index: TalentNodes.Index) bool {
        return character.talent_nodes.has(index);
    }

    pub fn setTalent(character: *Character, index: TalentNodes.Index) bool {
        return character.talent_nodes.set(index);
    }
};

comptime {
    var nodes: Character.TalentNodes = .init;
    var buffer: [Character.TalentNodes.wire_max_len]u8 = undefined;

    std.debug.assert(nodes.set(.fromInt(1)));
    std.debug.assert(nodes.set(.fromInt(64)));
    const first_chunk = nodes.writeWire(&buffer);
    std.debug.assert(first_chunk.len == 8);
    std.debug.assert(first_chunk[7] == 1);
    std.debug.assert(first_chunk[0] == 0x80);

    std.debug.assert(nodes.set(.fromInt(65)));
    std.debug.assert(nodes.set(.fromInt(80)));
    const both_chunks = nodes.writeWire(&buffer);
    std.debug.assert(both_chunks.len == 16);
    std.debug.assert(both_chunks[15] == 1);
    std.debug.assert(both_chunks[14] == 0x80);
}

pub const Guide = extern struct {
    group_id: u32 = 0,
    step_id: i32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const BoardEntry = extern struct {
    handbook_id: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const HandbookUnlock = extern struct {
    handbook_id: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const Resource = extern struct {
    id: u32 = 0,
    quantity: i32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const Item = extern struct {
    id: u64 = 0,
    template_id: u32 = 0,
    quantity: i32 = 0,
    expires_at: i64 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const Title = extern struct {
    id: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const Disc = extern struct {
    id: u32 = 0,
    exp: Exp = .min,
    created_at: i64 = 0,
    level: Level = .min,
    phase: Phase = .min,
    star: Star = .min,
    is_story_read: bool = false,
    is_avg_story_read: bool = false,

    padding: [2]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }

    pub const Level = enum(u16) {
        min = 1,
        max = tables.disc_progression.max_level,
        _,
    };

    pub const Exp = enum(u32) {
        min = 0,
        max = tables.disc_progression.max_exp,
        _,
    };

    pub const Phase = enum(u8) {
        min = 0,
        max = tables.disc_progression.max_phase,
        _,
    };

    pub const Star = enum(u8) {
        min = 0,
        max = tables.disc_progression.max_star,
        _,
    };
};

pub const Formation = extern struct {
    preselection_id: u64 = 0,
    number: u32 = 0,
    character_ids: [max_formation_characters]u32 = @splat(0),
    disc_ids: [max_formation_discs]u32 = @splat(0),
    character_count: u8 = 0,
    disc_count: u8 = 0,

    padding: [6]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

/// Lifetime copies received for a collectible. Duplicate rewards depend on
/// this total rather than current ownership.
pub const Acquisition = extern struct {
    id: u32 = 0,
    count: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const Achievement = extern struct {
    completed_at: i64 = 0,
    id: u32 = 0,
    progress: u32 = 0,
    status: Status = .in_progress,

    padding: [7]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }

    pub const Status = enum(u8) {
        in_progress = 0,
        reward_available = 1,
        reward_received = 2,
    };
};

pub const DictionaryEntry = extern struct {
    tab_id: u32 = 0,
    index: u32 = 0,
    status: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const Quest = extern struct {
    expires_at: i64 = 0,
    id: u32 = 0,
    condition: u32 = 0,
    condition_param: u32 = 0,
    progress_current: u32 = 0,
    progress_max: u32 = 0,
    quest_type: u8 = 0,
    claimed: bool = false,

    padding: [2]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

/// Current Lineup Tutorial chapter for an elemental track.
pub const Assist = extern struct {
    attribute_id: u32 = 0,
    group_id: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const TutorialLevel = extern struct {
    level_id: u32 = 0,
    passed: bool = false,
    reward_received: bool = false,

    padding: [2]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const Story = extern struct {
    index: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const StoryChoice = extern struct {
    story_index: u32 = 0,
    group: u32 = 0,
    value: u32 = 0,
    personality: bool = false,

    padding: [3]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const StoryEvidence = extern struct {
    id: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const PeriodicCampaign = extern struct {
    final_reward_claimed: bool = false,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

pub const PeriodicQuest = extern struct {
    id: u32 = 0,
    status: Status = .uncompleted,

    padding: [3]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }

    pub const Status = enum(u8) {
        uncompleted = 0,
        completed = 1,
        reward_received = 2,
    };
};

/// Affinity earned from Monolith event NPCs. The Employee Handbook only needs
/// the NPC ID and current Affinity; story rewards can be tracked separately
/// when those interactions are implemented.
pub const NpcAffinity = extern struct {
    npc_id: u32 = 0,
    affinity: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

/// A Potential discovered in the Monolith Log.
pub const TowerBookPotential = extern struct {
    id: u32 = 0,
    level: u8 = 0,

    padding: [3]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

/// A claimed Monolith Log Potential reward.
pub const TowerBookPotentialReward = extern struct {
    id: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }
};

/// Tracks a first clear and whether its reward was claimed.
pub const Clear = extern struct {
    id: u32 = 0,
    kind: Kind = .star_tower,
    reward_claimed: bool = false,

    padding: [2]u8 = @splat(0),

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }

    pub const Kind = enum(u8) {
        star_tower,
        story_stage,
        dungeon,
        activity,
    };
};
