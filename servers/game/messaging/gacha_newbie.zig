const change_info = @import("../view/change_info.zig");
const gacha_rules = @import("../gameplay/gacha.zig");
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

    if (request.Value != tables.gacha_newbie.id)
        return scope.reject(.invalid_req);
    var checked = scope.player.newbie_gacha;
    _ = gacha_rules.spinNewbieGacha(&checked) catch
        return scope.reject(.invalid_req);
    const player = scope.mutation().modify(.{ .gacha = true });
    var cards = gacha_rules.spinNewbieGacha(&player.newbie_gacha) catch unreachable;

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
    var checked = scope.player.newbie_gacha;
    gacha_rules.saveNewbieGachaResult(&checked, request.Idx) catch
        return scope.reject(.invalid_req);
    const player = scope.mutation().modify(.{ .gacha = true });
    gacha_rules.saveNewbieGachaResult(&player.newbie_gacha, request.Idx) catch unreachable;

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
    const now = scope.now;
    var drawn_cards: [tables.gacha_newbie.cards_per_spin]tables.gacha.Card = undefined;
    for (&drawn_cards, cards) |*drawn, card_id|
        drawn.* = .{ .id = card_id, .class = tables.gacha.classifyCard(card_id) };
    var receipt: reward.GachaReceipt = .{};
    try reward.grantCards(scope.mutation(), scope.gpa, &drawn_cards, now, &receipt);
    const player = scope.mutation().modify(.{ .gacha = true });
    gacha_rules.markNewbieGachaReceived(&player.newbie_gacha);

    var change: change_info.Gacha = .{};
    try scope.respond(try change.build(scope.player, &receipt, scope.arena));

    log.info("selected newbie gacha result {d}", .{request.Idx});
}
