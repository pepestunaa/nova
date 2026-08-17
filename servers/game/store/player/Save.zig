const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const common = @import("common");
const List = @import("../List.zig").List;
const Player = @import("../Player.zig");

//

const player_save_version = 1;
const max_save_buffers = 48;
const max_player_save_bytes = 16 * 1024 * 1024;
const max_opaque_tower_bytes = 1024 * 1024;

pub const LoadError = error{ Corrupted, InputOutput } || Io.Cancelable || Allocator.Error;
pub const SaveError = error{InputOutput};

const Header = extern struct {
    version: u32 = player_save_version,
    guides_count: u32,
    board_count: u32,
    handbook_count: u32,
    resources_count: u32,
    items_count: u32,
    titles_count: u32,
    discs_count: u32,
    formations_count: u32,
    acquisitions_count: u32,
    achievements_count: u32,
    dictionaries_count: u32,
    quests_count: u32,
    assists_count: u32,
    tutorials_count: u32,
    stories_count: u32,
    story_choices_count: u32,
    story_evidences_count: u32,
    periodic_quests_count: u32,
    npc_affinities_count: u32,
    tower_book_potentials_count: u32,
    tower_book_potential_rewards_count: u32,
    clears_count: u32,
    star_tower_builds_count: u32,
    star_tower_map_param_bytes: u32,
    star_tower_client_data_bytes: u32,
    gacha_banners_count: u32,
    gacha_storages_count: u32,
    gacha_histories_count: u32,
    checksum: u32 = 0,

    comptime {
        common.mem.assertNoImplicitPadding(@This());
    }

    fn init(player: *const Player) Header {
        return .{
            .guides_count = @intCast(player.guides.len),
            .board_count = @intCast(player.board.len),
            .handbook_count = @intCast(player.handbook.len),
            .resources_count = @intCast(player.resources.len),
            .items_count = @intCast(player.items.len),
            .titles_count = @intCast(player.titles.len),
            .discs_count = @intCast(player.discs.len),
            .formations_count = @intCast(player.formations.len),
            .acquisitions_count = @intCast(player.acquisitions.len),
            .achievements_count = @intCast(player.achievements.len),
            .dictionaries_count = @intCast(player.dictionaries.len),
            .quests_count = @intCast(player.quests.len),
            .assists_count = @intCast(player.assists.len),
            .tutorials_count = @intCast(player.tutorials.len),
            .stories_count = @intCast(player.stories.len),
            .story_choices_count = @intCast(player.story_choices.len),
            .story_evidences_count = @intCast(player.story_evidences.len),
            .periodic_quests_count = @intCast(player.periodic_quests.len),
            .npc_affinities_count = @intCast(player.npc_affinities.len),
            .tower_book_potentials_count = @intCast(player.tower_book_potentials.len),
            .tower_book_potential_rewards_count = @intCast(player.tower_book_potential_rewards.len),
            .clears_count = @intCast(player.clears.len),
            .star_tower_builds_count = @intCast(player.star_tower_builds.len),
            .star_tower_map_param_bytes = @intCast(player.star_tower_map_param.len),
            .star_tower_client_data_bytes = @intCast(player.star_tower_client_data.len),
            .gacha_banners_count = @intCast(player.gacha_banners.len),
            .gacha_storages_count = @intCast(player.gacha_storages.len),
            .gacha_histories_count = @intCast(player.gacha_histories.len),
        };
    }
};

fn appendPlayerBody(buffers: *std.ArrayList([]const u8), player: *const Player) void {
    buffers.appendAssumeCapacity(std.mem.asBytes(&player.basic));
    buffers.appendAssumeCapacity(std.mem.asBytes(&player.progress));
    buffers.appendAssumeCapacity(std.mem.asBytes(&player.tower_growth));
    buffers.appendAssumeCapacity(std.mem.asBytes(&player.research_project));
    buffers.appendAssumeCapacity(std.mem.asBytes(&player.star_tower_run));
    buffers.appendAssumeCapacity(player.star_tower_map_param.slice());
    buffers.appendAssumeCapacity(player.star_tower_client_data.slice());
    buffers.appendAssumeCapacity(std.mem.asBytes(&player.pending_star_tower_build));
    buffers.appendAssumeCapacity(std.mem.asBytes(&player.periodic_campaign));
    buffers.appendAssumeCapacity(std.mem.asBytes(&player.newbie_gacha));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.gacha_banners.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.gacha_storages.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.gacha_histories.slice()));
    buffers.appendAssumeCapacity(std.mem.asBytes(&player.characters.unlocked));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(&player.characters.entries));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.guides.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.board.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.handbook.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.resources.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.items.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.titles.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.discs.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.formations.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.acquisitions.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.achievements.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.dictionaries.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.quests.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.assists.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.tutorials.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.stories.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.story_choices.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.story_evidences.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.periodic_quests.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.npc_affinities.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.tower_book_potentials.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.tower_book_potential_rewards.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.clears.slice()));
    buffers.appendAssumeCapacity(std.mem.sliceAsBytes(player.star_tower_builds.slice()));
}

fn readList(
    comptime Item: type,
    reader: *Io.Reader,
    allocator: Allocator,
    list: *List(Item),
    count: u32,
) (Io.Reader.Error || Allocator.Error)!void {
    const len: usize = @intCast(count);
    try list.ensureTotalCapacity(allocator, len);
    list.len = len;
    try reader.readSliceAll(std.mem.sliceAsBytes(list.mutableSlice()));
}

fn readPlayerBody(
    reader: *Io.Reader,
    allocator: Allocator,
    player: *Player,
    header: *const Header,
) (Io.Reader.Error || Allocator.Error || error{InvalidFormat})!void {
    var state_fields = [_][]u8{
        std.mem.asBytes(&player.basic),
        std.mem.asBytes(&player.progress),
        std.mem.asBytes(&player.tower_growth),
        std.mem.asBytes(&player.research_project),
        std.mem.asBytes(&player.star_tower_run),
    };
    try reader.readVecAll(&state_fields);

    try readList(
        u8,
        reader,
        allocator,
        &player.star_tower_map_param,
        header.star_tower_map_param_bytes,
    );
    try readList(
        u8,
        reader,
        allocator,
        &player.star_tower_client_data,
        header.star_tower_client_data_bytes,
    );

    var other_fields = [_][]u8{
        std.mem.asBytes(&player.pending_star_tower_build),
        std.mem.asBytes(&player.periodic_campaign),
        std.mem.asBytes(&player.newbie_gacha),
    };
    try reader.readVecAll(&other_fields);

    try readList(Player.GachaBanner, reader, allocator, &player.gacha_banners, header.gacha_banners_count);
    try readList(Player.GachaStorage, reader, allocator, &player.gacha_storages, header.gacha_storages_count);
    try readList(Player.GachaHistory, reader, allocator, &player.gacha_histories, header.gacha_histories_count);

    try reader.readSliceAll(std.mem.asBytes(&player.characters.unlocked));
    try reader.readSliceAll(std.mem.sliceAsBytes(&player.characters.entries));

    try readList(Player.Guide, reader, allocator, &player.guides, header.guides_count);
    try readList(Player.BoardEntry, reader, allocator, &player.board, header.board_count);
    try readList(Player.HandbookUnlock, reader, allocator, &player.handbook, header.handbook_count);
    try readList(Player.Resource, reader, allocator, &player.resources, header.resources_count);
    try readList(Player.Item, reader, allocator, &player.items, header.items_count);
    try readList(Player.Title, reader, allocator, &player.titles, header.titles_count);
    try readList(Player.Disc, reader, allocator, &player.discs, header.discs_count);
    try readList(Player.Formation, reader, allocator, &player.formations, header.formations_count);
    try readList(Player.Acquisition, reader, allocator, &player.acquisitions, header.acquisitions_count);
    try readList(Player.Achievement, reader, allocator, &player.achievements, header.achievements_count);
    try readList(Player.DictionaryEntry, reader, allocator, &player.dictionaries, header.dictionaries_count);
    try readList(Player.Quest, reader, allocator, &player.quests, header.quests_count);
    try readList(Player.Assist, reader, allocator, &player.assists, header.assists_count);
    try readList(Player.TutorialLevel, reader, allocator, &player.tutorials, header.tutorials_count);
    try readList(Player.Story, reader, allocator, &player.stories, header.stories_count);
    try readList(Player.StoryChoice, reader, allocator, &player.story_choices, header.story_choices_count);
    try readList(Player.StoryEvidence, reader, allocator, &player.story_evidences, header.story_evidences_count);
    try readList(Player.PeriodicQuest, reader, allocator, &player.periodic_quests, header.periodic_quests_count);
    try readList(Player.NpcAffinity, reader, allocator, &player.npc_affinities, header.npc_affinities_count);
    try readList(Player.TowerBookPotential, reader, allocator, &player.tower_book_potentials, header.tower_book_potentials_count);
    try readList(Player.TowerBookPotentialReward, reader, allocator, &player.tower_book_potential_rewards, header.tower_book_potential_rewards_count);
    try readList(Player.Clear, reader, allocator, &player.clears, header.clears_count);

    try readList(
        Player.StarTowerBuild,
        reader,
        allocator,
        &player.star_tower_builds,
        header.star_tower_builds_count,
    );
}

fn expectedFileSize(header: *const Header) error{InvalidFormat}!usize {
    if (header.star_tower_builds_count > Player.max_star_tower_builds or
        header.star_tower_map_param_bytes > max_opaque_tower_bytes or
        header.star_tower_client_data_bytes > max_opaque_tower_bytes)
        return error.InvalidFormat;

    var total: usize = @sizeOf(Header);
    const fixed_sizes = [_]usize{
        @sizeOf(Player.Basic),
        @sizeOf(Player.Progress),
        @sizeOf(Player.TowerGrowth),
        @sizeOf(Player.ResearchProject),
        @sizeOf(Player.StarTowerRun),
        @sizeOf(Player.StarTowerBuild),
        @sizeOf(Player.PeriodicCampaign),
        @sizeOf(Player.NewbieGacha),
        @sizeOf(@TypeOf(@as(Player.CharacterTable, undefined).unlocked)),
        @sizeOf([Player.max_characters]Player.Character),
    };
    for (fixed_sizes) |size|
        total = std.math.add(usize, total, size) catch return error.InvalidFormat;

    const sections = [_]struct { count: u32, size: usize }{
        .{ .count = header.star_tower_map_param_bytes, .size = @sizeOf(u8) },
        .{ .count = header.star_tower_client_data_bytes, .size = @sizeOf(u8) },
        .{ .count = header.gacha_banners_count, .size = @sizeOf(Player.GachaBanner) },
        .{ .count = header.gacha_storages_count, .size = @sizeOf(Player.GachaStorage) },
        .{ .count = header.gacha_histories_count, .size = @sizeOf(Player.GachaHistory) },
        .{ .count = header.guides_count, .size = @sizeOf(Player.Guide) },
        .{ .count = header.board_count, .size = @sizeOf(Player.BoardEntry) },
        .{ .count = header.handbook_count, .size = @sizeOf(Player.HandbookUnlock) },
        .{ .count = header.resources_count, .size = @sizeOf(Player.Resource) },
        .{ .count = header.items_count, .size = @sizeOf(Player.Item) },
        .{ .count = header.titles_count, .size = @sizeOf(Player.Title) },
        .{ .count = header.discs_count, .size = @sizeOf(Player.Disc) },
        .{ .count = header.formations_count, .size = @sizeOf(Player.Formation) },
        .{ .count = header.acquisitions_count, .size = @sizeOf(Player.Acquisition) },
        .{ .count = header.achievements_count, .size = @sizeOf(Player.Achievement) },
        .{ .count = header.dictionaries_count, .size = @sizeOf(Player.DictionaryEntry) },
        .{ .count = header.quests_count, .size = @sizeOf(Player.Quest) },
        .{ .count = header.assists_count, .size = @sizeOf(Player.Assist) },
        .{ .count = header.tutorials_count, .size = @sizeOf(Player.TutorialLevel) },
        .{ .count = header.stories_count, .size = @sizeOf(Player.Story) },
        .{ .count = header.story_choices_count, .size = @sizeOf(Player.StoryChoice) },
        .{ .count = header.story_evidences_count, .size = @sizeOf(Player.StoryEvidence) },
        .{ .count = header.periodic_quests_count, .size = @sizeOf(Player.PeriodicQuest) },
        .{ .count = header.npc_affinities_count, .size = @sizeOf(Player.NpcAffinity) },
        .{ .count = header.tower_book_potentials_count, .size = @sizeOf(Player.TowerBookPotential) },
        .{ .count = header.tower_book_potential_rewards_count, .size = @sizeOf(Player.TowerBookPotentialReward) },
        .{ .count = header.clears_count, .size = @sizeOf(Player.Clear) },
        .{ .count = header.star_tower_builds_count, .size = @sizeOf(Player.StarTowerBuild) },
    };
    for (sections) |section| {
        const bytes = std.math.mul(
            usize,
            @intCast(section.count),
            section.size,
        ) catch
            return error.InvalidFormat;
        total = std.math.add(usize, total, bytes) catch
            return error.InvalidFormat;
        if (total > max_player_save_bytes)
            return error.InvalidFormat;
    }

    return total;
}

pub fn load(allocator: Allocator, io: Io, uid: u64) LoadError!?Player {
    var path_buffer: [Io.Dir.max_path_bytes]u8 = undefined;
    const path = std.fmt.bufPrint(
        &path_buffer,
        "store/player/{d}.bin",
        .{uid},
    ) catch
        return error.Corrupted;
    const file = Io.Dir.openFile(
        .cwd(),
        io,
        path,
        .{},
    ) catch |err|
        return switch (err) {
            error.FileNotFound => null,
            error.Canceled => |e| e,
            else => error.InputOutput,
        };
    defer file.close(io);

    const file_size_u64 = file.length(io) catch
        return error.InputOutput;
    const file_size = std.math.cast(usize, file_size_u64) orelse
        return error.Corrupted;
    if (file_size < @sizeOf(Header) or file_size > max_player_save_bytes)
        return error.Corrupted;

    var read_buffer: [4096]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);

    var header: Header = undefined;
    file_reader.interface.readSliceAll(std.mem.asBytes(&header)) catch
        return error.Corrupted;
    if (header.version != player_save_version)
        return error.Corrupted;
    const expected_size = expectedFileSize(&header) catch
        return error.Corrupted;
    if (expected_size != file_size)
        return error.Corrupted;

    var hash_buffer: [4096]u8 = undefined;
    var hashed = file_reader.interface.hashed(
        std.hash.Crc32.init(),
        &hash_buffer,
    );
    hashed.hasher.update(std.mem.asBytes(&header)[0..@offsetOf(Header, "checksum")]);

    var player = Player.init(uid);
    errdefer player.deinit(allocator);
    readPlayerBody(&hashed.reader, allocator, &player, &header) catch |err| switch (err) {
        error.OutOfMemory => |e| return e,
        else => |e| {
            std.log.warn(
                "failed to read player {d} save body: {t}",
                .{ uid, e },
            );

            return error.Corrupted;
        },
    };

    var trailing: [1]u8 = undefined;
    const trailing_len = hashed.reader.readSliceShort(&trailing) catch
        return error.Corrupted;
    if (trailing_len != 0) {
        std.log.warn("player {d} save has trailing data", .{uid});
        return error.Corrupted;
    }

    const checksum = hashed.hasher.final();
    if (checksum != header.checksum) {
        std.log.warn(
            "player {d} save checksum mismatch: expected {x:0>8}, found {x:0>8}",
            .{ uid, checksum, header.checksum },
        );

        return error.Corrupted;
    }

    player.is_registered = true;

    return player;
}

pub fn save(io: Io, player: *const Player) SaveError!void {
    const uid = player.uid orelse
        return error.InputOutput;
    if (!player.is_registered)
        return error.InputOutput;

    const old_cancel_protection = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(old_cancel_protection);

    var path_buffer: [Io.Dir.max_path_bytes]u8 = undefined;
    const path = std.fmt.bufPrint(
        &path_buffer,
        "store/player/{d}.bin",
        .{uid},
    ) catch
        return error.InputOutput;
    var atomic_file = Io.Dir.cwd().createFileAtomic(io, path, .{
        .make_path = true,
        .replace = true,
    }) catch
        return error.InputOutput;
    defer atomic_file.deinit(io);

    var header = Header.init(player);
    var buffers_storage: [max_save_buffers][]const u8 = undefined;
    var buffers: std.ArrayList([]const u8) = .initBuffer(&buffers_storage);
    buffers.appendAssumeCapacity(std.mem.asBytes(&header));
    appendPlayerBody(&buffers, player);

    var checksum = std.hash.Crc32.init();
    checksum.update(std.mem.asBytes(&header)[0..@offsetOf(Header, "checksum")]);
    for (buffers.items[1..]) |buffer| checksum.update(buffer);
    header.checksum = checksum.final();

    var write_buffer: [4096]u8 = undefined;
    var file_writer = atomic_file.file.writer(io, &write_buffer);
    file_writer.interface.writeVecAll(buffers.items) catch
        return error.InputOutput;

    file_writer.interface.flush() catch
        return error.InputOutput;
    atomic_file.replace(io) catch
        return error.InputOutput;
}
