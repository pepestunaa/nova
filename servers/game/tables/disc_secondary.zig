const generated = @import("generated/assets/disc_secondary");

//

pub const max_groups_per_disc = 2;
pub const max_combat_discs = 3;
pub const max_active_ids = max_combat_discs * max_groups_per_disc;
pub const max_changes = max_active_ids * 2;

pub const Requirement = generated.Requirement;
pub const Skill = generated.Skill;

pub const SupportNotes = struct {
    ids: [generated.max_requirements]u32 = @splat(0),
    quantities: [generated.max_requirements]u32 = @splat(0),
    count: u8 = 0,
};

pub fn supportNotes(disc_id: u32, phase: u32) SupportNotes {
    const disc = findDisc(disc_id) orelse
        return .{};

    if (disc.support_note_group_id == 0)
        return .{};

    for (generated.support_note_definitions) |entry| {
        if (entry.group_id != disc.support_note_group_id or entry.phase != phase)
            continue;

        var result: SupportNotes = .{ .count = entry.requirement_count };
        for (entry.requirements[0..entry.requirement_count], 0..) |requirement, index| {
            result.ids[index] = requirement.note_id;
            result.quantities[index] = requirement.quantity;
        }

        return result;
    }

    return .{};
}

pub const skills = generated.skills;

pub fn groups(disc_id: u32) [max_groups_per_disc]u32 {
    const disc = findDisc(disc_id) orelse
        return @splat(0);

    return disc.groups;
}

fn findDisc(id: u32) ?generated.Disc {
    for (generated.discs) |disc|
        if (disc.id == id)
            return disc;

    return null;
}
