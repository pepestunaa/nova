const advances = @import("tables/CharacterAdvance");
const affinities = @import("tables/AffinityLevel");
const skill_upgrades = @import("tables/CharacterSkillUpgrade");
const skills = @import("tables/Skill");
const upgrades = @import("tables/CharacterUpgrade");

//

pub const max_level = maxOptionalField(upgrades, "level");
pub const max_exp = maxOptionalField(upgrades, "exp");
pub const max_advance = maxOptionalField(advances, "advance_lvl");
pub const max_skill_upgrade_rank = maxOptionalField(skill_upgrades, "advance_num");
pub const max_skill_level = maxOptionalField(skills, "max_level");
pub const max_affinity_level = maxOptionalField(affinities, "affinity_level");
pub const max_affinity_exp = maxOptionalField(affinities, "need_exp");

fn maxOptionalField(comptime list: anytype, comptime name: []const u8) u32 {
    @setEvalBranchQuota(1_000_000);

    var maximum: u32 = 0;
    inline for (list) |entry| {
        if (@hasField(@TypeOf(entry), name))
            maximum = @max(maximum, @field(entry, name));
    }

    return maximum;
}
