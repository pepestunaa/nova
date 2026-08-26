const Mutation = @This();

const std = @import("std");

const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

//

/// Saved facts that can invalidate derived progression.
pub const Dependency = enum {
    acquisitions,
    characters,
    discs,
    research_project,
    tutorials,
    tower_growth,
};

pub const Invalidated = std.enums.EnumFieldStruct(Dependency, bool, false);
const Dependencies = std.EnumSet(Dependency);
const NewCharacterSet = std.bit_set.IntegerBitSet(tables.character.count);
const HandbookTypeSet = std.bit_set.IntegerBitSet(tables.handbook.type_count);
const ResearchProjectQuestSet = std.bit_set.IntegerBitSet(tables.research_project.list.len);

player: *Player,
invalidated: Dependencies = .empty,
new_characters: NewCharacterSet = .empty,
handbook_types: HandbookTypeSet = .empty,
research_project_quests: ResearchProjectQuestSet = .empty,
dirty: bool = false,
finalized: bool = false,

/// Starts a request-local mutation for `player`.
pub fn init(player: *Player) Mutation {
    return .{ .player = player };
}

/// Returns the current player state without marking the request as changed.
pub fn read(mutation: *const Mutation) *const Player {
    return mutation.player;
}

/// Marks the request dirty, records affected derived data, and returns writable
/// player state. Call it only after validating errors that belong to the
/// client request.
pub fn modify(mutation: *Mutation, invalidated: Invalidated) *Player {
    std.debug.assert(!mutation.finalized);
    mutation.dirty = true;
    mutation.invalidate(invalidated);

    return mutation.player;
}

/// Adds dependencies whose derived views must be rebuilt before the response.
pub fn invalidate(mutation: *Mutation, invalidated: Invalidated) void {
    std.debug.assert(mutation.dirty and !mutation.finalized);
    mutation.invalidated.setUnion(.init(invalidated));
}

/// Reports whether a dependency was invalidated by this request.
pub fn invalidates(mutation: *const Mutation, dependency: Dependency) bool {
    return mutation.invalidated.contains(dependency);
}

/// Reports whether the request changed persistent player state.
pub fn isDirty(mutation: *const Mutation) bool {
    return mutation.dirty;
}

/// Reports whether request processing has reached its finalization point.
pub fn isFinalized(mutation: *const Mutation) bool {
    return mutation.finalized;
}

/// Records a newly acquired character for handbook and progression updates.
pub fn recordNewCharacter(mutation: *Mutation, id: u32) void {
    std.debug.assert(mutation.dirty and !mutation.finalized);
    const index = tables.character.Index.fromId(id) orelse unreachable;
    mutation.new_characters.set(@intFromEnum(index));
}

/// Iterates over the characters recorded by this request.
pub fn newCharacterIterator(mutation: *const Mutation) NewCharacterSet.Iterator(.{}) {
    return mutation.new_characters.iterator(.{});
}

/// Records a handbook category affected by this request.
pub fn recordHandbookType(mutation: *Mutation, handbook_type: usize) void {
    std.debug.assert(mutation.dirty and !mutation.finalized);
    std.debug.assert(handbook_type < tables.handbook.type_count);
    mutation.handbook_types.set(handbook_type);
}

/// Iterates over handbook categories recorded by this request.
pub fn handbookTypeIterator(mutation: *const Mutation) HandbookTypeSet.Iterator(.{}) {
    return mutation.handbook_types.iterator(.{});
}

/// Records a Research Project quest whose progress may have changed.
pub fn recordResearchProjectQuest(mutation: *Mutation, id: u32) void {
    std.debug.assert(mutation.dirty and !mutation.finalized);
    for (tables.research_project.list, 0..) |definition, index| {
        if (definition.id != id)
            continue;
        mutation.invalidate(.{ .research_project = true });
        mutation.research_project_quests.set(index);

        return;
    }

    unreachable;
}

/// Iterates over Research Project quests recorded by this request.
pub fn researchProjectQuestIterator(mutation: *const Mutation) ResearchProjectQuestSet.Iterator(.{}) {
    return mutation.research_project_quests.iterator(.{});
}

/// Closes the mutation before derived progression and notifications run.
pub fn finish(mutation: *Mutation) void {
    std.debug.assert(!mutation.finalized);
    mutation.finalized = true;
}

/// Marks the finalized mutation as persisted successfully.
pub fn committed(mutation: *Mutation) void {
    std.debug.assert(mutation.finalized);
    mutation.dirty = false;
}

/// Reattaches an unused mutation object to another player state.
pub fn rebind(mutation: *Mutation, player: *Player) void {
    std.debug.assert(!mutation.dirty and !mutation.finalized);
    mutation.player = player;
}

//

test "mutation merges dependencies and deduplicates tracked changes" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    var mutation: Mutation = .init(&player);

    try testing.expect(!mutation.isDirty());
    _ = mutation.modify(.{ .acquisitions = true });
    mutation.invalidate(.{ .characters = true });
    mutation.invalidate(.{ .characters = true, .discs = true });

    try testing.expect(mutation.invalidates(.acquisitions));
    try testing.expect(mutation.invalidates(.characters));
    try testing.expect(mutation.invalidates(.discs));
    try testing.expect(!mutation.invalidates(.research_project));

    const character_id = @as(tables.character.Index, @enumFromInt(0)).id();
    mutation.recordNewCharacter(character_id);
    mutation.recordNewCharacter(character_id);
    var characters = mutation.newCharacterIterator();
    try testing.expectEqual(@as(?usize, 0), characters.next());
    try testing.expectEqual(@as(?usize, null), characters.next());

    mutation.recordHandbookType(0);
    mutation.recordHandbookType(0);
    var handbook_types = mutation.handbookTypeIterator();
    try testing.expectEqual(@as(?usize, 0), handbook_types.next());
    try testing.expectEqual(@as(?usize, null), handbook_types.next());

    const research_id = tables.research_project.list[0].id;
    mutation.recordResearchProjectQuest(research_id);
    mutation.recordResearchProjectQuest(research_id);
    try testing.expect(mutation.invalidates(.research_project));
    var research_quests = mutation.researchProjectQuestIterator();
    try testing.expectEqual(@as(?usize, 0), research_quests.next());
    try testing.expectEqual(@as(?usize, null), research_quests.next());

    mutation.finish();
    try testing.expect(mutation.isFinalized());
    mutation.committed();
    try testing.expect(!mutation.isDirty());
}

test "an empty invalidation still enrolls persistent writes" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    var mutation: Mutation = .init(&player);

    _ = mutation.modify(.{});

    try testing.expect(mutation.isDirty());
    inline for (@typeInfo(Dependency).@"enum".fields) |field|
        try testing.expect(!mutation.invalidates(@enumFromInt(field.value)));
}
