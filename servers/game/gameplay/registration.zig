//! Sets up the gameplay state for a new account.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const common = @import("common");
const gacha = @import("gacha.zig");
const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");
const quest = @import("quest.zig");
const research_project = @import("research_project.zig");
const tables = @import("../tables.zig");

//

pub const Error = error{ NameTooLong, AlreadyRegistered } || Allocator.Error;

const Nickname = common.mem.LimitedString(64);

pub fn register(
    mutation: *Mutation,
    allocator: Allocator,
    new_nickname: []const u8,
    gender: Player.Basic.Gender,
    registered_at: Io.Timestamp,
) Error!void {
    const created_at = registered_at.toSeconds();
    const nickname = Nickname.init(new_nickname) catch
        return error.NameTooLong;
    if (mutation.read().is_registered)
        return error.AlreadyRegistered;

    const player = mutation.modify(.{});
    player.basic = .{
        .created_at = created_at,
        .gender = gender,
        .head_icon = Player.Basic.headIconForGender(gender),
        .nickname = nickname,
        .energy_updated_at = created_at,
        .energy_next_at = 0,
    };

    gacha.initializeNewbieGachaForPlayer(&player.newbie_gacha, registered_at, player.uid orelse 0);

    inline for (starter_characters) |character_id| {
        player.characters.append(character_id, .{
            .skin = comptime starterDefaultSkin(character_id),
            .created_at = created_at,
        }) catch |err| switch (err) {
            error.Full => unreachable,
        };
    }

    inline for (starter_characters) |character_id|
        _ = try player.unlockDefaultSkin(allocator, character_id);

    inline for (starter_characters) |character_id| try player.acquisitions.append(allocator, .{
        .id = character_id,
        .count = 1,
    });

    inline for (starter_handbook_unlocks) |handbook_id|
        try player.handbook.append(allocator, .{ .handbook_id = handbook_id });

    inline for (starter_board) |handbook_id|
        try player.board.append(allocator, .{ .handbook_id = handbook_id });

    // TODO: Remove this
    player.basic.level = .max;

    // TODO: Remove this
    try player.resources.append(allocator, .{ .id = 1, .quantity = 999_999_999 }); // Dorra
    // TODO: Remove this
    try player.resources.append(allocator, .{ .id = 2, .quantity = 999_999 }); // Stellanite Dust

    // TODO: Remove this
    inline for (tables.character_progression.material_ids) |item_id|
        try player.addItem(allocator, item_id, 999_999);

    // TODO: Remove this
    inline for (tables.disc_progression.material_ids) |item_id|
        try player.addItem(allocator, item_id, 999_999);

    // TODO: Remove this
    // Banner tickets and currency
    inline for ([_]u32{ 502, 503, 602, 603 }) |ticket_id|
        try player.addItem(allocator, ticket_id, 999_999);

    inline for (starter_titles) |id|
        try player.titles.append(allocator, .{ .id = id });

    inline for (starter_discs) |id|
        try player.discs.append(allocator, .{
            .id = id,
            .created_at = created_at,
        });

    inline for (starter_discs) |id|
        try player.acquisitions.append(allocator, .{
            .id = id,
            .count = 1,
        });

    inline for (starter_dictionaries) |entry|
        try player.dictionaries.append(allocator, entry);

    try quest.initialize(player, allocator, created_at);
    try research_project.initialize(player, allocator);

    player.is_registered = true;
}

/// Resolves a starter Trekker's base skin at compile time.
fn starterDefaultSkin(comptime character_id: u32) u32 {
    const entry = tables.handbook.defaultSkin(character_id) orelse @compileError(
        std.fmt.comptimePrint("starter character {d} has no default skin", .{character_id}),
    );

    return entry.skin_id;
}

const starter_characters = [_]u32{
    @intFromEnum(tables.character.Id.Iris),
    @intFromEnum(tables.character.Id.Noya),
    @intFromEnum(tables.character.Id.Amber),
};

const starter_board = [_]u32{410301};
const starter_titles = [_]u32{ 1, 2 };
const starter_discs = [_]u32{ 211007, 211008, 211001, 211005 };
const starter_dictionaries = [_]Player.DictionaryEntry{
    .{ .tab_id = 1, .index = 1, .status = 1 },
    .{ .tab_id = 1, .index = 2, .status = 1 },
    .{ .tab_id = 1, .index = 3, .status = 1 },
    .{ .tab_id = 1, .index = 4, .status = 1 },
    .{ .tab_id = 1, .index = 5, .status = 1 },
    .{ .tab_id = 1, .index = 6, .status = 1 },
    .{ .tab_id = 2, .index = 1, .status = 1 },
    .{ .tab_id = 2, .index = 2, .status = 1 },
    .{ .tab_id = 2, .index = 3, .status = 1 },
    .{ .tab_id = 2, .index = 5, .status = 1 },
    .{ .tab_id = 2, .index = 11, .status = 1 },
    .{ .tab_id = 3, .index = 1, .status = 1 },
    .{ .tab_id = 3, .index = 2, .status = 1 },
};

const starter_handbook_unlocks = blk: {
    const type_3_unlock_count = count_blk: {
        var count: usize = 0;
        for (tables.handbook.list) |entry| {
            if (entry.type == 3 and entry.index <= 9) count += 1;
        }

        break :count_blk count;
    };

    var ids: [type_3_unlock_count]u32 = undefined;
    var index: usize = 0;
    for (tables.handbook.list) |entry| {
        if (entry.type != 3 or entry.index > 9)
            continue;
        ids[index] = entry.id;
        index += 1;
    }

    break :blk ids;
};

//

test "registration rejects an already registered player" {
    const testing = std.testing;

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    player.is_registered = true;

    var mutation: Mutation = .init(&player);
    try testing.expectError(
        error.AlreadyRegistered,
        register(&mutation, testing.allocator, "Tyrant", .female, .zero),
    );
    try testing.expect(!mutation.isDirty());
}
