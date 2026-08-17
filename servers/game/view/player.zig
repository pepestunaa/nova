const Player = @import("../store/Player.zig");
const proto = @import("proto");
const tables = @import("../tables.zig");

//

const skill_level_count = 5;
const gem_slot_count = 3;
const gem_preset_count = 3;

pub const CharacterBuffers = struct {
    skill_levels: [skill_level_count]u32 = undefined,
    affinity_quests: [tables.affinity_quest.max_per_character]proto.pb.Quest = undefined,
    affinity_progress: [tables.affinity_quest.max_per_character]proto.pb.QuestProgress = undefined,
    gem_slots: [gem_slot_count]proto.pb.CharGemSlot = undefined,
    gem_presets: [gem_preset_count]proto.pb.CharGemPreset = undefined,
    preset_slot_gems: [gem_preset_count][gem_slot_count]i32 = undefined,
};

pub fn character(id: u32, value: *const Player.Character, buffers: *CharacterBuffers) proto.pb.Char {
    buffers.skill_levels = value.skillLevels();
    for (&buffers.gem_slots, tables.character.gemSlots(id) orelse unreachable) |*slot, slot_id|
        slot.* = .{ .Id = slot_id };
    for (&buffers.gem_presets, 0..) |*preset, preset_index| {
        const offset = preset_index * gem_slot_count;
        buffers.preset_slot_gems[preset_index] = value.gem_presets[offset..][0..gem_slot_count].*;
        preset.* = .{ .SlotGem = .fromOwnedSlice(&buffers.preset_slot_gems[preset_index]) };
    }

    const definitions = tables.affinity_quest.forCharacter(@intCast(id));
    for (definitions, 0..) |definition, index| {
        buffers.affinity_progress[index] = .{ .Max = definition.target };
        buffers.affinity_quests[index] = .{
            .Id = definition.id,
            .Type = .Affinity,
            .Progress = .fromOwnedSlice(buffers.affinity_progress[index .. index + 1]),
        };
    }

    return .{
        .Tid = id,
        .Exp = value.exp(),
        .Level = value.level(),
        .SkillLvs = .fromOwnedSlice(&buffers.skill_levels),
        .Skin = value.skin,
        .AffinityLevel = value.affinityLevel(),
        .AffinityExp = value.affinityExp(),
        .Advance = value.advance(),
        .AffinityQuests = .{ .List = .fromOwnedSlice(buffers.affinity_quests[0..definitions.len]) },
        .TalentNodes = &value.talent_nodes,
        .CharGemSlots = .fromOwnedSlice(&buffers.gem_slots),
        .CharGemPresets = .{ .CharGemPresets = .fromOwnedSlice(&buffers.gem_presets) },
        .IsFavorite = value.isFavorite(),
        .CreateTime = value.created_at,
    };
}

pub fn disc(value: *const Player.Disc) proto.pb.Disc {
    return .{
        .Id = value.id,
        .Level = @intFromEnum(value.level),
        .Exp = @intFromEnum(value.exp),
        .Phase = @intFromEnum(value.phase),
        .Star = @intFromEnum(value.star),
        .Read = value.is_story_read,
        .Avg = value.is_avg_story_read,
        .CreateTime = value.created_at,
    };
}
