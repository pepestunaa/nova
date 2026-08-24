const std = @import("std");
const Io = std.Io;

const achievement = @import("../gameplay/achievement.zig");
const achievement_notify = @import("../notify/achievement.zig");
const change_info = @import("../view/change_info.zig");
const Player = @import("../store/Player.zig");
const player_data = @import("player_data.zig");
const progression = @import("../gameplay/character_progression.zig");
const proto = @import("proto");
const quest_notify = @import("../notify/quest.zig");
const Scope = @import("../Scope.zig");

//

pub fn char_upgrade_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.CharUpgradeReq);

    var items: [progression.max_item_changes]progression.ItemAmount = undefined;
    var item_count: usize = 0;
    var requested_items = request.Items;
    while (try requested_items.next()) |item| {
        if (item.Tid == 0 or item.Qty <= 0)
            return scope.reject(.invalid_req);

        var merged = false;
        for (items[0..item_count]) |*existing| {
            if (existing.id != item.Tid)
                continue;
            existing.quantity = std.math.add(i32, existing.quantity, item.Qty) catch
                return scope.reject(.invalid_req);
            merged = true;

            break;
        }

        if (merged)
            continue;

        if (item_count == items.len)
            return scope.reject(.invalid_req);

        items[item_count] = .{ .id = item.Tid, .quantity = item.Qty };
        item_count += 1;
    }

    var receipt: progression.Receipt = .{};
    progression.upgrade(scope.playerMut(), request.CharId, items[0..item_count], &receipt) catch |err| switch (err) {
        error.LevelCapReached, error.MaximumReached => return scope.reject(.char_max_level),
        error.InsufficientResources => return scope.reject(.cond_check),
        error.InvalidCharacter, error.InvalidItems => return scope.reject(.invalid_req),
        else => |other| return other,
    };

    const character = scope.player.characters.get(request.CharId) orelse unreachable;

    var achievement_changes: achievement.ChangeSet = .{};
    try achievement.refresh(
        scope.playerMut(),
        scope.gpa,
        Io.Timestamp.now(scope.io, .real).toSeconds(),
        &achievement_changes,
    );

    var change: change_info.CharacterProgression = .{};
    try scope.respond(proto.pb.CharUpgradeResp{
        .Level = character.level(),
        .Exp = character.exp(),
        .Change = try change.build(&receipt, scope.arena),
    });

    try quest_notify.refreshLineupTutorial(scope);
    try achievement_notify.send(scope, &achievement_changes);
}

pub fn char_advance_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.UI32);

    var receipt: progression.Receipt = .{};
    progression.advance(scope.playerMut(), scope.gpa, request.Value, &receipt) catch |err| switch (err) {
        error.ConditionsNotMet => return scope.reject(.char_cond_max_advance),
        error.PlayerLevelNotMet => return scope.reject(.char_world_class_cond_not_met),
        error.MaximumReached => return scope.reject(.char_max_advance),
        error.InsufficientResources => return scope.reject(.cond_check),
        error.InvalidCharacter => return scope.reject(.invalid_req),
        else => |other| return other,
    };

    var achievement_changes: achievement.ChangeSet = .{};
    try achievement.refresh(
        scope.playerMut(),
        scope.gpa,
        Io.Timestamp.now(scope.io, .real).toSeconds(),
        &achievement_changes,
    );

    var change: change_info.CharacterProgression = .{};
    try scope.respond(try change.build(&receipt, scope.arena));

    try quest_notify.refreshLineupTutorial(scope);
    try achievement_notify.send(scope, &achievement_changes);

    if (receipt.unlocked_advance_skin)
        try player_data.response.sendHandbookChanges(scope);
}

pub fn char_skill_upgrade_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.CharSkillUpgradeReq);

    const skill = Player.Character.Skill.fromWire(request.Index) orelse
        return scope.reject(.invalid_req);
    var receipt: progression.Receipt = .{};
    progression.upgradeSkill(scope.playerMut(), request.CharId, skill, &receipt) catch |err| switch (err) {
        error.MaximumReached => return scope.reject(.char_skill_max_level),
        error.ConditionsNotMet => return scope.reject(.char_skill_cond_not_met),
        error.InsufficientResources => return scope.reject(.cond_check),
        error.InvalidCharacter => return scope.reject(.invalid_req),
        else => |other| return other,
    };

    var achievement_changes: achievement.ChangeSet = .{};
    try achievement.refresh(
        scope.playerMut(),
        scope.gpa,
        Io.Timestamp.now(scope.io, .real).toSeconds(),
        &achievement_changes,
    );

    var change: change_info.CharacterProgression = .{};
    try scope.respond(try change.build(&receipt, scope.arena));

    try quest_notify.refreshLineupTutorial(scope);
    try achievement_notify.send(scope, &achievement_changes);
}

pub fn char_skin_set_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.CharSkinSetReq);
    progression.setSkin(
        scope.playerMut(),
        request.CharId,
        request.SkinId,
    ) catch |err| switch (err) {
        error.ConditionsNotMet => return scope.reject(.cond_check),
        error.InvalidCharacter => return scope.reject(.invalid_req),
        else => |other| return other,
    };
    try scope.respond(proto.pb.Nil{});
}

pub fn talent_group_unlock_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.UI32);

    var receipt: progression.TalentReceipt = .{};
    progression.unlockTalentGroup(
        scope.playerMut(),
        request.Value,
        &receipt,
    ) catch |err| switch (err) {
        error.TalentGroupLocked => return scope.reject(.talent_group_not_yet_open),
        error.TalentGroupComplete => return scope.reject(.talent_activation_limit),
        error.InsufficientResources => return scope.reject(.talent_ordinary_nodes_insufficient_quantity),
        error.InvalidCharacter, error.InvalidTalent => return scope.reject(.invalid_req),
        else => |other| return other,
    };

    var change: change_info.Talent = .{};
    try scope.respond(proto.pb.TalentGroupUnlockResp{
        .Change = try change.build(&receipt, scope.arena),
        .Nodes = .fromOwnedSlice(receipt.slice()),
    });
}

pub fn talent_unlock_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.UI32);

    var receipt: progression.TalentReceipt = .{};
    progression.unlockTalent(scope.playerMut(), request.Value, &receipt) catch |err| switch (err) {
        error.TalentAlreadyUnlocked => return scope.reject(.talent_alreay_activeated),
        error.TalentGroupLocked => return scope.reject(.talent_group_not_yet_open),
        error.TalentGroupComplete => return scope.reject(.talent_activation_limit),
        error.InsufficientResources => return scope.reject(.talent_ordinary_nodes_insufficient_quantity),
        error.InvalidCharacter, error.InvalidTalent => return scope.reject(.invalid_req),
        else => |other| return other,
    };

    var change: change_info.Talent = .{};
    try scope.respond(proto.pb.TalentUnlockResp{
        .Change = try change.build(&receipt, scope.arena),
        .TalentId = receipt.key_talent_id,
    });
}

pub fn talent_background_set_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.TalentBackgroundSetReq);

    progression.setTalentBackground(scope.playerMut(), request.CharId, request.GroupId) catch |err| switch (err) {
        error.TalentGroupLocked => return scope.reject(.talent_group_not_yet_open),
        error.InvalidCharacter, error.InvalidTalent => return scope.reject(.invalid_req),
        else => |other| return other,
    };
    try scope.respond(proto.pb.Nil{});
}
