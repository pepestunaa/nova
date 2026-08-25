const Mutation = @This();

const std = @import("std");

const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

//

/// Player-state domains that can affect derived progression.
pub const Domain = enum {
    acquisitions,
    characters,
    discs,
    handbook,
    inventory,
    achievements,
    gacha,
    formations,
    social,
    quests,
    research_project,
    tutorials,
    ascension,
    tower_growth,
    player_progression,
};

pub const Affected = std.enums.EnumFieldStruct(Domain, bool, false);
const Domains = std.EnumSet(Domain);
const NewCharacterSet = std.bit_set.IntegerBitSet(tables.character.count);
const HandbookTypeSet = std.bit_set.IntegerBitSet(tables.handbook.type_count);

player: *Player,
domains: Domains = .empty,
new_characters: NewCharacterSet = .empty,
handbook_types: HandbookTypeSet = .empty,
dirty: bool = false,
finalized: bool = false,

pub fn init(player: *Player) Mutation {
    return .{ .player = player };
}

pub fn read(mutation: *const Mutation) *const Player {
    return mutation.player;
}

/// Enrolls the request in rollback and returns writable state. Gameplay
/// operations call this only after every expected client error is validated.
pub fn modify(mutation: *Mutation, affected: Affected) *Player {
    std.debug.assert(!mutation.finalized);
    mutation.dirty = true;
    mutation.affect(affected);

    return mutation.player;
}

pub fn affect(mutation: *Mutation, affected: Affected) void {
    std.debug.assert(mutation.dirty and !mutation.finalized);
    mutation.domains.setUnion(.init(affected));
}

pub fn affects(mutation: *const Mutation, domain: Domain) bool {
    return mutation.domains.contains(domain);
}

pub fn isDirty(mutation: *const Mutation) bool {
    return mutation.dirty;
}

pub fn isFinalized(mutation: *const Mutation) bool {
    return mutation.finalized;
}

pub fn recordNewCharacter(mutation: *Mutation, id: u32) void {
    std.debug.assert(mutation.dirty and !mutation.finalized);
    const index = tables.character.Index.fromId(id) orelse unreachable;
    mutation.new_characters.set(@intFromEnum(index));
}

pub fn newCharacterIterator(mutation: *const Mutation) NewCharacterSet.Iterator(.{}) {
    return mutation.new_characters.iterator(.{});
}

pub fn recordHandbookType(mutation: *Mutation, handbook_type: usize) void {
    std.debug.assert(mutation.dirty and !mutation.finalized);
    std.debug.assert(handbook_type < tables.handbook.type_count);
    mutation.affect(.{ .handbook = true });
    mutation.handbook_types.set(handbook_type);
}

pub fn handbookTypeIterator(mutation: *const Mutation) HandbookTypeSet.Iterator(.{}) {
    return mutation.handbook_types.iterator(.{});
}

pub fn finish(mutation: *Mutation) void {
    std.debug.assert(!mutation.finalized);
    mutation.finalized = true;
}

pub fn committed(mutation: *Mutation) void {
    std.debug.assert(mutation.finalized);
    mutation.dirty = false;
}

pub fn rebind(mutation: *Mutation, player: *Player) void {
    std.debug.assert(!mutation.dirty and !mutation.finalized);
    mutation.player = player;
}
