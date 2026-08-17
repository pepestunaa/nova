const std = @import("std");
const Io = std.Io;

const achievement = @import("../gameplay/achievement.zig");
const change_info = @import("../view/change_info.zig");
const gacha_rules = @import("../gameplay/gacha.zig");
const quest_notify = @import("../notify/quest.zig");
const Player = @import("../store/Player.zig");
const player_data = @import("player_data.zig");
const proto = @import("proto");
const reward = @import("../gameplay/reward.zig");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn gacha_newbie_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    const gacha = &scope.player.newbie_gacha;
    var saved: [tables.gacha_newbie.max_saved_results]proto.pb.UI32s = undefined;
    for (gacha.saved[0..gacha.saved_count], 0..) |*cards, index| {
        saved[index] = .{ .Values = .fromOwnedSlice(@constCast(cards)) };
    }

    const temp: ?proto.pb.UI32s = if (gacha_rules.hasNewbieGachaPendingResult(gacha))
        .{
            .Values = .fromOwnedSlice(@constCast(&gacha.pending)),
        }
    else
        null;
    var infos: [1]proto.pb.GachaNewbieInfo = .{.{
        .Id = tables.gacha_newbie.id,
        .Receive = gacha.received,
        .Times = gacha.spins,
        .Cards = .fromOwnedSlice(saved[0..gacha.saved_count]),
        .Temp = temp,
    }};
    try scope.respond(proto.pb.GachaNewbieInfoResp{
        .List = .fromOwnedSlice(&infos),
    });
}

pub fn gacha_newbie_spin_req(scope: *Scope) !void {
    const log = scope.logger(.gacha_newbie_spin_req);

    const request = try scope.source.read(proto.pb.UI32);
    if (request.Value != tables.gacha_newbie.id) return scope.reject(.invalid_req);
    const player = scope.playerMut();
    var cards = gacha_rules.spinNewbieGacha(&player.newbie_gacha) catch
        return scope.reject(.invalid_req);

    scope.markDirty();

    try scope.respond(proto.pb.GachaNewbieSpinResp{ .Cards = .fromOwnedSlice(&cards) });

    log.info("generated newbie gacha pull {d}/{d}", .{
        scope.player.newbie_gacha.spins,
        tables.gacha_newbie.max_spins,
    });
}

pub fn gacha_newbie_save_req(scope: *Scope) !void {
    const log = scope.logger(.gacha_newbie_save_req);

    const request = try scope.source.read(proto.pb.GachaNewbieSaveReq);
    if (request.Id != tables.gacha_newbie.id)
        return scope.reject(.invalid_req);
    const player = scope.playerMut();
    gacha_rules.saveNewbieGachaResult(&player.newbie_gacha, request.Idx) catch
        return scope.reject(.invalid_req);

    scope.markDirty();

    try scope.respond(proto.pb.Nil{});

    log.info("saved newbie gacha pull in slot {d}", .{request.Idx});
}

pub fn gacha_newbie_obtain_req(scope: *Scope) !void {
    const log = scope.logger(.gacha_newbie_obtain_req);

    const request = try scope.source.read(proto.pb.GachaNewbieObtainReq);
    if (request.Id != tables.gacha_newbie.id)
        return scope.reject(.invalid_req);
    const cards = gacha_rules.selectedNewbieGachaResult(&scope.player.newbie_gacha, request.Idx) catch
        return scope.reject(.invalid_req);
    const player = scope.playerMut();
    const now = Io.Timestamp.now(scope.io, .real).toSeconds();
    var drawn_cards: [tables.gacha_newbie.cards_per_spin]tables.gacha.Card = undefined;
    for (&drawn_cards, cards) |*drawn, card_id|
        drawn.* = .{ .id = card_id, .class = tables.gacha.classifyCard(card_id) };
    var receipt: reward.GachaReceipt = .{};
    try reward.applyGachaCards(player, scope.gpa, &drawn_cards, now, &receipt);
    var achievement_changes: achievement.ChangeSet = .{};
    try achievement.refreshCollection(player, scope.gpa, now, &achievement_changes);
    gacha_rules.markNewbieGachaReceived(&player.newbie_gacha);

    scope.markDirty();

    var change: change_info.Gacha = .{};
    try scope.respond(try change.build(scope.player, &receipt, scope.arena));

    try quest_notify.refreshLineupTutorial(scope);
    try quest_notify.sendNewTrekkerAffinityQuests(scope, &receipt);
    try sendAchievementChanges(scope, &achievement_changes);
    if (receipt.handbook_changed)
        try player_data.response.sendHandbookChanges(scope);

    log.info("selected newbie gacha result {d}", .{request.Idx});
}

fn sendAchievementChanges(scope: *Scope, changes: *const achievement.ChangeSet) !void {
    for (changes.slice()) |state| {
        const definition = tables.achievement.get(state.id) orelse
            continue;
        var progress: [1]proto.pb.QuestProgress = .{.{
            .Cur = state.progress,
            .Max = definition.target,
        }};
        const achievement_change: proto.pb.Achievement = .{
            .Id = state.id,
            .Status = @intFromEnum(state.status),
            .Completed = state.completed_at,
            .Progress = .fromOwnedSlice(&progress),
        };
        try scope.sink.sendProto(.achievement_change_notify, &achievement_change);
    }
}
