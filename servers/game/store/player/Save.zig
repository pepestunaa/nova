const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const common = @import("common");
const List = @import("../List.zig").List;
const Player = @import("../Player.zig");
const tables = @import("../../tables.zig");

//

const player_save_version = 2;
const max_player_save_bytes = 16 * 1024 * 1024;
const max_opaque_tower_bytes = 1024 * 1024;
const max_player_list_memory_bytes = 64 * 1024 * 1024;

pub const LoadError = error{
    Corrupted,
    InputOutput,
} || Io.Cancelable || Allocator.Error;
pub const SaveError = error{ InputOutput, TooLarge };

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
    mall_purchases_count: u32,
    mall_orders_count: u32,
    monthly_cards_count: u32,

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
            .mall_purchases_count = @intCast(player.mall_purchases.len),
            .mall_orders_count = @intCast(player.mall_orders.len),
            .monthly_cards_count = @intCast(player.monthly_cards.len),
        };
    }
};

fn isLimitedString(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct" => @hasDecl(T, "max_length") and
            @hasDecl(T, "view") and @hasField(T, "bytes"),
        else => false,
    };
}

const EncodeError = Io.Writer.Error || error{TooLarge};
const DecodeError = Io.Reader.Error || error{InvalidFormat};
const DecodeListError = DecodeError || Allocator.Error;

const SaveWriter = struct {
    file: *Io.Writer,
    hasher: *std.hash.Crc32,
    len: usize = 0,

    fn writeAll(writer: *SaveWriter, bytes: []const u8) EncodeError!void {
        const max_body_bytes = max_player_save_bytes -
            @sizeOf(Header) - @sizeOf(u32);
        if (bytes.len > max_body_bytes -| writer.len)
            return error.TooLarge;

        writer.hasher.update(bytes);
        try writer.file.writeAll(bytes);
        writer.len += bytes.len;
    }

    fn writeByte(writer: *SaveWriter, byte: u8) EncodeError!void {
        try writer.writeAll(&.{byte});
    }

    fn writeInt(
        writer: *SaveWriter,
        comptime T: type,
        value: T,
        endian: std.builtin.Endian,
    ) EncodeError!void {
        var bytes: [@sizeOf(T)]u8 = undefined;
        std.mem.writeInt(T, &bytes, value, endian);
        try writer.writeAll(&bytes);
    }
};

fn writeValue(writer: anytype, value: anytype) EncodeError!void {
    const T = @TypeOf(value);
    switch (@typeInfo(T)) {
        .bool => try writer.writeByte(@intFromBool(value)),
        .int => {
            if (T == usize) {
                try writer.writeInt(u64, @intCast(value), .little);
            } else if (T == isize) {
                try writer.writeInt(i64, @intCast(value), .little);
            } else {
                const info = @typeInfo(T).int;
                const WireInt = std.meta.Int(info.signedness, @sizeOf(T) * 8);
                try writer.writeInt(WireInt, @intCast(value), .little);
            }
        },
        .float => {
            if (T == f32) {
                try writeValue(writer, @as(u32, @bitCast(value)));
            } else if (T == f64) {
                try writeValue(writer, @as(u64, @bitCast(value)));
            } else {
                @compileError(
                    "unsupported floating-point type in player save: " ++
                        @typeName(T),
                );
            }
        },
        .@"enum" => |info| try writeValue(
            writer,
            @as(info.tag_type, @intFromEnum(value)),
        ),
        .array => |info| {
            try writer.writeInt(u32, @intCast(info.len), .little);
            for (value) |element| try writeValue(writer, element);
        },
        .@"struct" => |info| {
            if (comptime isLimitedString(T)) {
                const text = value.view();
                try writer.writeInt(u32, @intCast(text.len), .little);
                try writer.writeAll(text);
            } else if (info.backing_integer) |Backing| {
                try writeValue(writer, @as(Backing, @bitCast(value)));
            } else {
                inline for (info.fields) |field| {
                    if (!field.is_comptime)
                        try writeValue(writer, @field(value, field.name));
                }
            }
        },
        .optional => {
            if (value) |payload| {
                try writer.writeByte(1);
                try writeValue(writer, payload);
            } else {
                try writer.writeByte(0);
            }
        },
        else => @compileError("unsupported player save type: " ++ @typeName(T)),
    }
}

fn readValue(
    comptime T: type,
    reader: *Io.Reader,
    value: *T,
) DecodeError!void {
    switch (@typeInfo(T)) {
        .bool => {
            const raw = try reader.takeByte();
            if (raw > 1) return error.InvalidFormat;
            value.* = raw != 0;
        },
        .int => {
            if (T == usize) {
                value.* = std.math.cast(
                    usize,
                    try reader.takeInt(u64, .little),
                ) orelse return error.InvalidFormat;
            } else if (T == isize) {
                value.* = std.math.cast(
                    isize,
                    try reader.takeInt(i64, .little),
                ) orelse return error.InvalidFormat;
            } else {
                const info = @typeInfo(T).int;
                const WireInt = std.meta.Int(info.signedness, @sizeOf(T) * 8);
                value.* = std.math.cast(
                    T,
                    try reader.takeInt(WireInt, .little),
                ) orelse return error.InvalidFormat;
            }
        },
        .float => {
            if (T == f32) {
                value.* = @bitCast(try reader.takeInt(u32, .little));
            } else if (T == f64) {
                value.* = @bitCast(try reader.takeInt(u64, .little));
            } else {
                @compileError(
                    "unsupported floating-point type in player save: " ++
                        @typeName(T),
                );
            }
        },
        .@"enum" => |info| {
            const raw = try readInteger(info.tag_type, reader);
            value.* = std.enums.fromInt(T, raw) orelse
                return error.InvalidFormat;
        },
        .array => |info| {
            const stored_len: usize = @intCast(
                try reader.takeInt(u32, .little),
            );
            const minimum_size = minimumWireSize(info.child);
            if (minimum_size == 0 or
                stored_len > max_player_save_bytes / minimum_size)
            {
                return error.InvalidFormat;
            }
            const copy_len = @min(stored_len, info.len);
            for (0..copy_len) |index|
                try readValue(info.child, reader, &value.*[index]);
            for (copy_len..stored_len) |_| try skipValue(info.child, reader);
        },
        .@"struct" => |info| {
            if (comptime isLimitedString(T)) {
                try readLimitedString(T, reader, value);
                return;
            }

            if (info.backing_integer) |Backing| {
                var backing: Backing = undefined;
                try readValue(Backing, reader, &backing);
                value.* = @bitCast(backing);
                return;
            }

            inline for (info.fields) |field| {
                if (!field.is_comptime)
                    try readValue(
                        field.type,
                        reader,
                        &@field(value.*, field.name),
                    );
            }
        },
        .optional => |info| {
            const present = try reader.takeByte();
            if (present > 1)
                return error.InvalidFormat;
            if (present == 0) {
                value.* = null;
            } else {
                var payload: info.child = undefined;
                try readValue(info.child, reader, &payload);
                value.* = payload;
            }
        },
        else => @compileError("unsupported player save type: " ++ @typeName(T)),
    }
}

fn readInteger(comptime T: type, reader: *Io.Reader) DecodeError!T {
    if (T == usize) {
        return std.math.cast(
            usize,
            try reader.takeInt(u64, .little),
        ) orelse error.InvalidFormat;
    } else if (T == isize) {
        return std.math.cast(
            isize,
            try reader.takeInt(i64, .little),
        ) orelse error.InvalidFormat;
    } else {
        const info = @typeInfo(T).int;
        const WireInt = std.meta.Int(info.signedness, @sizeOf(T) * 8);
        return std.math.cast(
            T,
            try reader.takeInt(WireInt, .little),
        ) orelse error.InvalidFormat;
    }
}

fn readLimitedString(
    comptime T: type,
    reader: *Io.Reader,
    value: *T,
) DecodeError!void {
    const stored_len = try reader.takeInt(u32, .little);
    if (stored_len > max_player_save_bytes)
        return error.InvalidFormat;

    value.* = .{};
    const copy_len = @min(@as(usize, stored_len), T.max_length);
    try reader.readSliceAll(value.bytes[0..copy_len]);
    try skipBytes(reader, @as(usize, stored_len) - copy_len);

    var valid_len = copy_len;
    if (copy_len < @as(usize, stored_len)) {
        while (valid_len != 0 and
            !std.unicode.utf8ValidateSlice(value.bytes[0..valid_len]))
        {
            valid_len -= 1;
        }
    }
    value.bytes[valid_len] = 0;
}

fn skipValue(comptime T: type, reader: *Io.Reader) DecodeError!void {
    switch (@typeInfo(T)) {
        .bool => {
            var value: bool = false;
            try readValue(bool, reader, &value);
        },
        .int => {
            _ = try readInteger(T, reader);
        },
        .float => {
            if (T == f32) {
                _ = try reader.takeInt(u32, .little);
            } else if (T == f64) {
                _ = try reader.takeInt(u64, .little);
            } else {
                @compileError(
                    "unsupported floating-point type in player save: " ++
                        @typeName(T),
                );
            }
        },
        .@"enum" => |info| {
            _ = try readInteger(info.tag_type, reader);
        },
        .array => |info| {
            const stored_len: usize = @intCast(
                try reader.takeInt(u32, .little),
            );
            const minimum_size = minimumWireSize(info.child);
            if (minimum_size == 0 or
                stored_len > max_player_save_bytes / minimum_size)
            {
                return error.InvalidFormat;
            }
            for (0..stored_len) |_| try skipValue(info.child, reader);
        },
        .@"struct" => |info| {
            if (comptime isLimitedString(T)) {
                const stored_len = try reader.takeInt(u32, .little);
                if (stored_len > max_player_save_bytes)
                    return error.InvalidFormat;
                try skipBytes(reader, @intCast(stored_len));
                return;
            }

            if (info.backing_integer) |Backing| {
                _ = try readInteger(Backing, reader);
                return;
            }

            inline for (info.fields) |field| {
                if (!field.is_comptime) try skipValue(field.type, reader);
            }
        },
        .optional => |info| {
            const present = try reader.takeByte();
            if (present > 1) return error.InvalidFormat;
            if (present != 0) try skipValue(info.child, reader);
        },
        else => @compileError("unsupported player save type: " ++ @typeName(T)),
    }
}

fn skipBytes(reader: *Io.Reader, count: usize) Io.Reader.Error!void {
    var buffer: [1024]u8 = undefined;
    var remaining = count;
    while (remaining != 0) {
        const chunk_len = @min(remaining, buffer.len);
        try reader.readSliceAll(buffer[0..chunk_len]);
        remaining -= chunk_len;
    }
}

fn minimumWireSize(comptime T: type) usize {
    return switch (@typeInfo(T)) {
        .bool => 1,
        .int => if (T == usize or T == isize) 8 else @sizeOf(T),
        .float => @sizeOf(T),
        .@"enum" => |info| minimumWireSize(info.tag_type),
        .array => @sizeOf(u32),
        .@"struct" => |info| blk: {
            if (comptime isLimitedString(T)) break :blk @sizeOf(u32);
            if (info.backing_integer) |Backing|
                break :blk minimumWireSize(Backing);
            var size: usize = 0;
            inline for (info.fields) |field| {
                if (!field.is_comptime)
                    size += minimumWireSize(field.type);
            }
            break :blk size;
        },
        .optional => 1,
        else => @compileError("unsupported player save type: " ++ @typeName(T)),
    };
}

fn writeList(writer: anytype, list: anytype) EncodeError!void {
    for (list.slice()) |entry| try writeValue(writer, entry);
}

fn writeCharacters(writer: anytype, player: *const Player) EncodeError!void {
    try writer.writeInt(u32, @intCast(player.characters.count()), .little);
    var iterator = player.characters.iterator();
    while (iterator.next()) |entry| {
        try writeValue(writer, entry.id());
        try writeValue(writer, entry.value.*);
    }
}

fn writePlayerBody(writer: anytype, player: *const Player) EncodeError!void {
    try writeValue(writer, player.basic);
    try writeValue(writer, player.progress);
    try writeValue(writer, player.tower_growth);
    try writeValue(writer, player.research_project);
    try writeValue(writer, player.star_tower_run);
    try writeList(writer, &player.star_tower_map_param);
    try writeList(writer, &player.star_tower_client_data);
    try writeValue(writer, player.pending_star_tower_build);
    try writeValue(writer, player.periodic_campaign);
    try writeValue(writer, player.newbie_gacha);
    try writeList(writer, &player.gacha_banners);
    try writeList(writer, &player.gacha_storages);
    try writeList(writer, &player.gacha_histories);
    try writeList(writer, &player.mall_purchases);
    try writeList(writer, &player.mall_orders);
    try writeList(writer, &player.monthly_cards);
    try writeCharacters(writer, player);
    try writeList(writer, &player.guides);
    try writeList(writer, &player.board);
    try writeList(writer, &player.handbook);
    try writeList(writer, &player.resources);
    try writeList(writer, &player.items);
    try writeList(writer, &player.titles);
    try writeList(writer, &player.discs);
    try writeList(writer, &player.formations);
    try writeList(writer, &player.acquisitions);
    try writeList(writer, &player.achievements);
    try writeList(writer, &player.dictionaries);
    try writeList(writer, &player.quests);
    try writeList(writer, &player.assists);
    try writeList(writer, &player.tutorials);
    try writeList(writer, &player.stories);
    try writeList(writer, &player.story_choices);
    try writeList(writer, &player.story_evidences);
    try writeList(writer, &player.periodic_quests);
    try writeList(writer, &player.npc_affinities);
    try writeList(writer, &player.tower_book_potentials);
    try writeList(writer, &player.tower_book_potential_rewards);
    try writeList(writer, &player.clears);
    try writeList(writer, &player.star_tower_builds);
}

fn readList(
    comptime Item: type,
    reader: *Io.Reader,
    allocator: Allocator,
    list: *List(Item),
    count: u32,
    max_count: usize,
    allocated_bytes: *usize,
) DecodeListError!void {
    const source_len: usize = @intCast(count);
    const minimum_size = minimumWireSize(Item);
    if (minimum_size == 0 or source_len > max_player_save_bytes / minimum_size)
        return error.InvalidFormat;

    const len = @min(source_len, max_count);
    for (0..source_len - len) |_| try skipValue(Item, reader);

    const requested_bytes = std.math.mul(usize, len, @sizeOf(Item)) catch
        return error.InvalidFormat;
    if (requested_bytes > max_player_list_memory_bytes -| allocated_bytes.*)
        return error.InvalidFormat;

    try list.ensureTotalCapacity(allocator, len);
    const capacity_bytes = std.math.mul(
        usize,
        list.entries.len,
        @sizeOf(Item),
    ) catch
        return error.InvalidFormat;
    if (capacity_bytes > max_player_list_memory_bytes -| allocated_bytes.*)
        return error.InvalidFormat;
    allocated_bytes.* += capacity_bytes;
    list.len = len;

    for (0..len) |index| {
        if (Item == u8) {
            list.entries[index] = 0;
        } else {
            list.entries[index] = .{};
        }
        try readValue(Item, reader, &list.entries[index]);
    }
}

fn readCharacters(reader: *Io.Reader, player: *Player) DecodeError!void {
    const count = try reader.takeInt(u32, .little);
    const minimum_size = @sizeOf(u32) + minimumWireSize(Player.Character);
    if (@as(usize, count) > max_player_save_bytes / minimum_size)
        return error.InvalidFormat;

    for (0..count) |_| {
        const id = try readInteger(u32, reader);
        var character: Player.Character = .{};
        try readValue(Player.Character, reader, &character);

        const index = tables.character.Index.fromId(id) orelse
            continue;
        const bit_index = @intFromEnum(index);
        if (player.characters.unlocked.isSet(bit_index))
            return error.InvalidFormat;
        player.characters.append(id, character) catch
            return error.InvalidFormat;
    }
}

fn readPlayerBody(
    reader: *Io.Reader,
    allocator: Allocator,
    player: *Player,
    header: *const Header,
) DecodeListError!void {
    try readValue(
        Player.Basic,
        reader,
        &player.basic,
    );
    try readValue(
        Player.Progress,
        reader,
        &player.progress,
    );
    try readValue(
        Player.TowerGrowth,
        reader,
        &player.tower_growth,
    );
    try readValue(
        Player.ResearchProject,
        reader,
        &player.research_project,
    );
    try readValue(
        Player.StarTowerRun,
        reader,
        &player.star_tower_run,
    );

    var allocated_bytes: usize = 0;
    try readList(
        u8,
        reader,
        allocator,
        &player.star_tower_map_param,
        header.star_tower_map_param_bytes,
        max_opaque_tower_bytes,
        &allocated_bytes,
    );
    try readList(
        u8,
        reader,
        allocator,
        &player.star_tower_client_data,
        header.star_tower_client_data_bytes,
        max_opaque_tower_bytes,
        &allocated_bytes,
    );

    try readValue(
        Player.StarTowerBuild,
        reader,
        &player.pending_star_tower_build,
    );
    try readValue(
        Player.PeriodicCampaign,
        reader,
        &player.periodic_campaign,
    );
    try readValue(
        Player.NewbieGacha,
        reader,
        &player.newbie_gacha,
    );

    try readList(
        Player.GachaBanner,
        reader,
        allocator,
        &player.gacha_banners,
        header.gacha_banners_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.GachaStorage,
        reader,
        allocator,
        &player.gacha_storages,
        header.gacha_storages_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.GachaHistory,
        reader,
        allocator,
        &player.gacha_histories,
        header.gacha_histories_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.MallPurchase,
        reader,
        allocator,
        &player.mall_purchases,
        header.mall_purchases_count,
        Player.max_mall_purchases,
        &allocated_bytes,
    );
    try readList(
        Player.MallOrder,
        reader,
        allocator,
        &player.mall_orders,
        header.mall_orders_count,
        Player.max_mall_orders,
        &allocated_bytes,
    );
    try readList(
        Player.MonthlyCard,
        reader,
        allocator,
        &player.monthly_cards,
        header.monthly_cards_count,
        Player.max_monthly_cards,
        &allocated_bytes,
    );

    try readCharacters(reader, player);

    try readList(
        Player.Guide,
        reader,
        allocator,
        &player.guides,
        header.guides_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.BoardEntry,
        reader,
        allocator,
        &player.board,
        header.board_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.HandbookUnlock,
        reader,
        allocator,
        &player.handbook,
        header.handbook_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Resource,
        reader,
        allocator,
        &player.resources,
        header.resources_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Item,
        reader,
        allocator,
        &player.items,
        header.items_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Title,
        reader,
        allocator,
        &player.titles,
        header.titles_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Disc,
        reader,
        allocator,
        &player.discs,
        header.discs_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Formation,
        reader,
        allocator,
        &player.formations,
        header.formations_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Acquisition,
        reader,
        allocator,
        &player.acquisitions,
        header.acquisitions_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Achievement,
        reader,
        allocator,
        &player.achievements,
        header.achievements_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.DictionaryEntry,
        reader,
        allocator,
        &player.dictionaries,
        header.dictionaries_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Quest,
        reader,
        allocator,
        &player.quests,
        header.quests_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Assist,
        reader,
        allocator,
        &player.assists,
        header.assists_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.TutorialLevel,
        reader,
        allocator,
        &player.tutorials,
        header.tutorials_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Story,
        reader,
        allocator,
        &player.stories,
        header.stories_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.StoryChoice,
        reader,
        allocator,
        &player.story_choices,
        header.story_choices_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.StoryEvidence,
        reader,
        allocator,
        &player.story_evidences,
        header.story_evidences_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.PeriodicQuest,
        reader,
        allocator,
        &player.periodic_quests,
        header.periodic_quests_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.NpcAffinity,
        reader,
        allocator,
        &player.npc_affinities,
        header.npc_affinities_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.TowerBookPotential,
        reader,
        allocator,
        &player.tower_book_potentials,
        header.tower_book_potentials_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.TowerBookPotentialReward,
        reader,
        allocator,
        &player.tower_book_potential_rewards,
        header.tower_book_potential_rewards_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.Clear,
        reader,
        allocator,
        &player.clears,
        header.clears_count,
        std.math.maxInt(usize),
        &allocated_bytes,
    );
    try readList(
        Player.StarTowerBuild,
        reader,
        allocator,
        &player.star_tower_builds,
        header.star_tower_builds_count,
        Player.max_star_tower_builds,
        &allocated_bytes,
    );
}

fn validateHeader(header: *const Header) error{InvalidFormat}!void {
    if (header.mall_purchases_count > Player.max_mall_purchases or
        header.mall_orders_count > Player.max_mall_orders or
        header.monthly_cards_count > Player.max_monthly_cards or
        header.star_tower_map_param_bytes > max_opaque_tower_bytes or
        header.star_tower_client_data_bytes > max_opaque_tower_bytes)
        return error.InvalidFormat;
}

fn clampCount(count: anytype, lengths: anytype) @TypeOf(count) {
    var limit: usize = std.math.maxInt(usize);
    inline for (lengths) |len| limit = @min(limit, len);
    return @intCast(@min(@as(usize, count), limit));
}

fn normalizeRun(run: *Player.StarTowerRun) void {
    run.total_damage_count = clampCount(
        run.total_damage_count,
        .{run.total_damages.len},
    );
    run.potential_count = clampCount(
        run.potential_count,
        .{ run.potential_ids.len, run.potential_levels.len },
    );
    run.offered_potential_count = clampCount(
        run.offered_potential_count,
        .{ run.offered_potential_ids.len, run.offered_potential_levels.len },
    );
    run.shop_goods_count = clampCount(
        run.shop_goods_count,
        .{run.shop_good_sids.len},
    );
    run.tower_item_count = clampCount(
        run.tower_item_count,
        .{ run.tower_item_ids.len, run.tower_item_quantities.len },
    );
    run.active_secondary_count = clampCount(
        run.active_secondary_count,
        .{run.active_secondary_ids.len},
    );
    run.affinity_change_count = clampCount(
        run.affinity_change_count,
        .{
            run.affinity_change_npc_ids.len,
            run.affinity_change_values.len,
            run.affinity_change_increases.len,
            run.affinity_change_reward_ids.len,
            run.affinity_change_reward_quantities.len,
            run.affinity_change_rewards_are_resources.len,
        },
    );
    run.event_option_count = clampCount(
        run.event_option_count,
        .{run.event_options.len},
    );
    run.room_case_count = clampCount(
        run.room_case_count,
        .{
            run.room_case_ids.len,
            run.room_case_effect_ids.len,
            run.room_case_kinds.len,
            run.room_case_resolved.len,
        },
    );
}

fn normalizeBuild(build: *Player.StarTowerBuild) void {
    build.character_count = clampCount(
        build.character_count,
        .{build.character_ids.len},
    );
    build.disc_count = clampCount(
        build.disc_count,
        .{build.disc_ids.len},
    );
    build.potential_count = clampCount(
        build.potential_count,
        .{ build.potential_ids.len, build.potential_levels.len },
    );
    build.tower_item_count = clampCount(
        build.tower_item_count,
        .{ build.tower_item_ids.len, build.tower_item_quantities.len },
    );
    build.active_secondary_count = clampCount(
        build.active_secondary_count,
        .{build.active_secondary_ids.len},
    );
}

fn normalizeDynamicCounts(player: *Player) void {
    player.basic.friend_count = clampCount(
        player.basic.friend_count,
        .{player.basic.friend_uids.len},
    );
    player.newbie_gacha.saved_count = clampCount(
        player.newbie_gacha.saved_count,
        .{player.newbie_gacha.saved.len},
    );
    normalizeRun(&player.star_tower_run);
    normalizeBuild(&player.pending_star_tower_build);
    for (player.star_tower_builds.mutableSlice()) |*build|
        normalizeBuild(build);
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
    if (file_size < @sizeOf(Header) + @sizeOf(u32) or
        file_size > max_player_save_bytes)
        return error.Corrupted;

    var read_buffer: [4096]u8 = undefined;
    var file_reader = file.reader(io, &read_buffer);

    var header: Header = undefined;
    file_reader.interface.readSliceAll(std.mem.asBytes(&header)) catch
        return error.Corrupted;
    if (header.version != player_save_version) {
        std.log.warn(
            "player {d} save format {d} is unsupported; delete " ++
                "store/player/{d}.bin to reset it",
            .{ uid, header.version, uid },
        );
        return error.Corrupted;
    }
    validateHeader(&header) catch return error.Corrupted;

    const body_size = file_size - @sizeOf(Header) - @sizeOf(u32);
    var body_reader_buffer: [4096]u8 = undefined;
    var body_reader = file_reader.interface.limited(
        .limited(body_size),
        &body_reader_buffer,
    );

    var hash_buffer: [4096]u8 = undefined;
    var hashed = body_reader.interface.hashed(
        std.hash.Crc32.init(),
        &hash_buffer,
    );
    hashed.hasher.update(std.mem.asBytes(&header));

    var player = Player.init(uid);
    errdefer player.deinit(allocator);
    readPlayerBody(
        &hashed.reader,
        allocator,
        &player,
        &header,
    ) catch |err| switch (err) {
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
    const body_trailing_len = hashed.reader.readSliceShort(&trailing) catch
        return error.Corrupted;
    if (body_trailing_len != 0) {
        std.log.warn("player {d} save body has trailing data", .{uid});
        return error.Corrupted;
    }

    const found_checksum = hashed.hasher.final();
    const expected_checksum = file_reader.interface.takeInt(u32, .little) catch
        return error.Corrupted;

    const trailing_len = file_reader.interface.readSliceShort(&trailing) catch
        return error.Corrupted;
    if (trailing_len != 0) {
        std.log.warn("player {d} save has trailing data", .{uid});
        return error.Corrupted;
    }

    if (found_checksum != expected_checksum) {
        std.log.warn(
            "player {d} save checksum mismatch: expected {x:0>8}, " ++
                "found {x:0>8}",
            .{ uid, expected_checksum, found_checksum },
        );

        return error.Corrupted;
    }

    normalizeDynamicCounts(&player);
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

    const header = Header.init(player);

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

    var write_buffer: [4096]u8 = undefined;
    var file_writer = atomic_file.file.writer(io, &write_buffer);
    file_writer.interface.writeAll(std.mem.asBytes(&header)) catch
        return error.InputOutput;
    var checksum = std.hash.Crc32.init();
    checksum.update(std.mem.asBytes(&header));
    var body_writer: SaveWriter = .{
        .file = &file_writer.interface,
        .hasher = &checksum,
    };
    writePlayerBody(&body_writer, player) catch |err| switch (err) {
        error.TooLarge => return error.TooLarge,
        else => return error.InputOutput,
    };
    file_writer.interface.writeInt(u32, checksum.final(), .little) catch
        return error.InputOutput;

    file_writer.interface.flush() catch
        return error.InputOutput;
    atomic_file.replace(io) catch
        return error.InputOutput;
}
