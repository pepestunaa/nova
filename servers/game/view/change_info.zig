//! Builds protobuf `ChangeInfo` messages for inventory changes.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const character_progression = @import("../gameplay/character_progression.zig");
const Player = @import("../store/Player.zig");
const player_view = @import("player.zig");
const proto = @import("proto");
const reward = @import("../gameplay/reward.zig");
const tables = @import("../tables.zig");

//

const Error = Allocator.Error || proto.EncodeError || error{Full};

pub const Gacha = struct {
    builder: Builder = .{},
    acquisitions: [tables.gacha_newbie.cards_per_spin]proto.pb.AcqInfo = undefined,
    transform_src: [tables.gacha_newbie.cards_per_spin]proto.pb.ItemTpl = undefined,
    transform_dst: [reward.max_gacha_changes]proto.pb.ItemTpl = undefined,
    item_messages: [reward.max_gacha_changes]proto.pb.Item = undefined,
    resource_messages: [reward.max_gacha_changes]proto.pb.Res = undefined,
    character_buffers: [tables.gacha_newbie.cards_per_spin]player_view.CharacterBuffers = undefined,

    pub fn build(
        formatter: *Gacha,
        player: *const Player,
        receipt: *const reward.GachaReceipt,
        arena: Allocator,
    ) Error!proto.pb.ChangeInfo {
        formatter.builder.len = 0;
        for (receipt.card_acquisitions[0..receipt.card_acquisition_count], 0..) |entry, index|
            formatter.acquisitions[index] = .{
                .Tid = entry.id,
                .Begin = entry.begin,
                .Count = entry.count,
            };

        for (receipt.transform_sources[0..receipt.transform_source_count], 0..) |entry, index|
            formatter.transform_src[index] = .{
                .Tid = entry.id,
                .Qty = entry.quantity,
            };
        for (receipt.transform_destinations[0..receipt.transform_destination_count], 0..) |entry, index|
            formatter.transform_dst[index] = .{
                .Tid = entry.id,
                .Qty = entry.quantity,
            };
        if (receipt.transform_source_count != 0) {
            const transform: proto.pb.Transform = .{
                .Src = .fromOwnedSlice(formatter.transform_src[0..receipt.transform_source_count]),
                .Dst = .fromOwnedSlice(formatter.transform_dst[0..receipt.transform_destination_count]),
            };
            try formatter.builder.append(arena, proto.pb.Transform, &transform);
        }

        const acquire: proto.pb.Acquire = .{
            .List = .fromOwnedSlice(formatter.acquisitions[0..receipt.card_acquisition_count]),
        };
        try formatter.builder.append(arena, proto.pb.Acquire, &acquire);

        for (
            receipt.new_card_ids[0..receipt.new_card_count],
            0..,
        ) |card_id, index| switch (tables.gacha.classifyCard(card_id).kind) {
            .character => {
                const character = player.characters.get(card_id) orelse unreachable;
                const message = player_view.character(
                    card_id,
                    character,
                    &formatter.character_buffers[index],
                );
                try formatter.builder.append(arena, proto.pb.Char, &message);
            },
            .disc => {
                const disc = findDisc(player, card_id) orelse unreachable;
                const message = player_view.disc(disc);
                try formatter.builder.append(arena, proto.pb.Disc, &message);
            },
        };

        for (receipt.item_deltas[0..receipt.item_delta_count], 0..) |entry, index| {
            formatter.item_messages[index] = .{
                .Id = entry.id,
                .Tid = entry.template_id,
                .Qty = entry.quantity,
                .Expire = entry.expires_at,
            };
            try formatter.builder.append(arena, proto.pb.Item, &formatter.item_messages[index]);
        }

        for (
            receipt.resource_deltas.entries[0..receipt.resource_deltas.len],
            0..,
        ) |entry, index| {
            formatter.resource_messages[index] = .{ .Tid = entry.id, .Qty = entry.quantity };
            try formatter.builder.append(arena, proto.pb.Res, &formatter.resource_messages[index]);
        }

        return formatter.builder.finish();
    }
};

pub const Achievement = struct {
    builder: Builder = .{},

    pub fn build(
        formatter: *Achievement,
        receipt: *const reward.AchievementReceipt,
        arena: Allocator,
    ) Error!proto.pb.ChangeInfo {
        formatter.builder.len = 0;
        const resources = try arena.alloc(proto.pb.Res, receipt.resource_deltas.len);
        for (
            receipt.resource_deltas.entries[0..receipt.resource_deltas.len],
            0..,
        ) |entry, index| {
            resources[index] = .{ .Tid = entry.id, .Qty = entry.quantity };
            try formatter.builder.append(arena, proto.pb.Res, &resources[index]);
        }

        return formatter.builder.finish();
    }
};

pub const ResearchProject = struct {
    builder: Builder = .{},
    resources: [2]proto.pb.Res = undefined,
    items: [2]proto.pb.Item = undefined,

    pub fn build(
        formatter: *ResearchProject,
        receipt: *const @import("../gameplay/research_project.zig").RewardReceipt,
        arena: Allocator,
    ) Error!proto.pb.ChangeInfo {
        formatter.builder.len = 0;
        for (receipt.resources[0..receipt.resource_count], 0..) |entry, index| {
            formatter.resources[index] = .{ .Tid = entry.id, .Qty = entry.quantity };
            try formatter.builder.append(arena, proto.pb.Res, &formatter.resources[index]);
        }
        for (receipt.items[0..receipt.item_count], 0..) |entry, index| {
            formatter.items[index] = .{ .Id = entry.id, .Tid = entry.id, .Qty = entry.quantity };
            try formatter.builder.append(arena, proto.pb.Item, &formatter.items[index]);
        }

        return formatter.builder.finish();
    }
};

pub const CharacterProgression = struct {
    builder: Builder = .{},
    items: [character_progression.max_item_changes]proto.pb.Item = undefined,
    gold: proto.pb.Res = .{},

    pub fn build(
        formatter: *CharacterProgression,
        receipt: *const character_progression.Receipt,
        arena: Allocator,
    ) Error!proto.pb.ChangeInfo {
        formatter.builder.len = 0;
        for (receipt.items[0..receipt.item_count], 0..) |entry, index| {
            formatter.items[index] = .{
                .Id = entry.id,
                .Tid = entry.id,
                .Qty = entry.quantity,
            };
            try formatter.builder.append(arena, proto.pb.Item, &formatter.items[index]);
        }
        if (receipt.gold != 0) {
            formatter.gold = .{
                .Tid = tables.character_progression.gold_id,
                .Qty = receipt.gold,
            };
            try formatter.builder.append(arena, proto.pb.Res, &formatter.gold);
        }

        return formatter.builder.finish();
    }
};

pub const Talent = struct {
    builder: Builder = .{},
    item: proto.pb.Item = .{},

    pub fn build(
        formatter: *Talent,
        receipt: *const character_progression.TalentReceipt,
        arena: Allocator,
    ) Error!proto.pb.ChangeInfo {
        formatter.builder.len = 0;
        if (receipt.cost.quantity != 0) {
            formatter.item = .{
                .Id = receipt.cost.id,
                .Tid = receipt.cost.id,
                .Qty = receipt.cost.quantity,
            };
            try formatter.builder.append(arena, proto.pb.Item, &formatter.item);
        }

        return formatter.builder.finish();
    }
};

const Builder = struct {
    // TODO: Allow custom?
    const max_props = 32;
    props: [max_props]proto.pb.Any = undefined,
    len: usize = 0,

    fn append(
        builder: *Builder,
        arena: Allocator,
        comptime Message: type,
        message: *const Message,
    ) Error!void {
        if (builder.len == builder.props.len)
            return error.Full;

        const encoded = try arena.alloc(u8, proto.encodingLength(Message, message));
        var writer = Io.Writer.fixed(encoded);
        try proto.encode(Message, &writer, message);
        builder.props[builder.len] = .{
            .type_url = comptime "type.googleapis.com/proto." ++ Message.message_name,
            .value = writer.buffered(),
        };
        builder.len += 1;
    }

    fn finish(builder: *Builder) proto.pb.ChangeInfo {
        return .{
            .Props = .fromOwnedSlice(builder.props[0..builder.len]),
        };
    }
};

fn findDisc(player: *const Player, id: u32) ?*const Player.Disc {
    for (player.discs.slice()) |*disc| if (disc.id == id)
        return disc;

    return null;
}
