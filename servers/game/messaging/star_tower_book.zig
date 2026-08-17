//! Handles Monolith Log collections and rewards.

const std = @import("std");

const change_info = @import("../view/change_info.zig");
const Player = @import("../store/Player.zig");
const proto = @import("proto");
const reward = @import("../gameplay/reward.zig");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

// TODO: Implement Destiny Card details with Cataclysm Survivor.
pub fn tower_book_fate_card_detail_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.respond(proto.pb.TowerBookFateCardDetailResp{});
}

pub fn star_tower_book_potential_brief_list_get_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);

    const player = scope.player;
    const infos = try scope.arena.alloc(
        proto.pb.StarTowerBookCharPotentialBrief,
        player.characters.count(),
    );
    var info_count: usize = 0;

    var character_iterator = player.characters.iterator();
    while (character_iterator.next()) |character| {
        const count = player.towerBookPotentialCount(character.id());
        if (count == 0)
            continue;
        infos[info_count] = .{ .CharId = character.id(), .Count = count };
        info_count += 1;
    }

    try scope.respond(proto.pb.StarTowerBookPotentialBriefListResp{
        .Infos = .fromOwnedSlice(infos[0..info_count]),
    });
}

pub fn star_tower_book_char_potential_get_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.UI32);
    const player = scope.player;
    const character_id = request.Value;
    const potentials = try scope.arena.alloc(
        proto.pb.StarTowerBookPotential,
        player.tower_book_potentials.len,
    );
    var potential_count: usize = 0;
    for (player.tower_book_potentials.slice()) |entry| {
        if (tables.potential.characterId(entry.id) != character_id)
            continue;
        potentials[potential_count] = .{ .Id = entry.id, .Level = entry.level };
        potential_count += 1;
    }

    const received_ids = try scope.arena.alloc(u32, player.tower_book_potential_rewards.len);
    const received_count = appendPotentialRewardClaims(player, character_id, received_ids);

    try scope.respond(proto.pb.StarTowerBookPotentialGetResp{
        .Potentials = .fromOwnedSlice(potentials[0..potential_count]),
        .ReceivedIds = .fromOwnedSlice(received_ids[0..received_count]),
    });
}

pub fn star_tower_book_potential_reward_receive_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_book_potential_reward_receive_req);

    const request = try scope.source.read(proto.pb.UI32);
    const player = scope.playerMut();
    const character_id = request.Value;
    var receipt: reward.AchievementReceipt = .{};
    const received_ids = try scope.arena.alloc(u32, tables.star_tower_book.potential_rewards.len);
    var received_count: usize = 0;

    for (tables.star_tower_book.potential_rewards) |definition| {
        if (character_id != 0 and definition.character_id != character_id)
            continue;
        if (player.hasTowerBookPotentialReward(definition.id))
            continue;
        if (player.towerBookPotentialCount(definition.character_id) < definition.potential_count)
            continue;

        try player.claimTowerBookPotentialReward(scope.gpa, definition.id);
        try reward.applyAchievementReward(
            player,
            scope.gpa,
            &receipt,
            definition.item_id,
            definition.item_quantity,
        );
        received_ids[received_count] = definition.id;
        received_count += 1;
    }

    if (received_count != 0) scope.markDirty();

    var change: change_info.Achievement = .{};
    try scope.respond(proto.pb.StarTowerBookPotentialRewardReceiveResp{
        .Change = try change.build(&receipt, scope.arena),
        .ReceivedIds = .fromOwnedSlice(received_ids[0..received_count]),
    });

    log.info("claimed {d} Monolith Log Potential reward(s)", .{received_count});
}

pub fn star_tower_book_event_reward_receive_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_book_event_reward_receive_req);

    const request = try scope.source.read(proto.pb.UI32);
    const player = scope.playerMut();
    const requested_id = request.Value;
    var receipt: reward.AchievementReceipt = .{};
    const received_ids = try scope.arena.alloc(u32, player.quests.len);
    var received_count: usize = 0;

    for (player.quests.entries[0..player.quests.len]) |*quest| {
        if (quest.quest_type != @intFromEnum(tables.quest.Type.tower_event) or quest.claimed)
            continue;
        if (requested_id != 0 and quest.id != requested_id)
            continue;
        if (quest.progress_current < quest.progress_max)
            continue;
        const definition = tables.star_tower_book.eventReward(quest.id) orelse
            continue;

        quest.claimed = true;
        try reward.applyAchievementReward(
            player,
            scope.gpa,
            &receipt,
            definition.item_id,
            definition.item_quantity,
        );
        received_ids[received_count] = definition.id;
        received_count += 1;
    }

    if (received_count != 0) scope.markDirty();

    var change: change_info.Achievement = .{};
    try scope.respond(proto.pb.StarTowerBookEventRewardReceiveResp{
        .Change = try change.build(&receipt, scope.arena),
        .ReceivedIds = .fromOwnedSlice(received_ids[0..received_count]),
    });

    log.info("claimed {d} Monolith Log event reward(s)", .{received_count});
}

fn appendPotentialRewardClaims(
    player: *const Player,
    character_id: u32,
    output: []u32,
) usize {
    var len: usize = 0;
    for (player.tower_book_potential_rewards.slice()) |claim| {
        const definition = tables.star_tower_book.potentialReward(claim.id) orelse
            continue;
        if (definition.character_id != character_id)
            continue;
        output[len] = claim.id;
        len += 1;
    }

    return len;
}
