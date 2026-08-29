const std = @import("std");

const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");
const tables = @import("../tables.zig");

//

pub fn setHeadIcon(mutation: *Mutation, icon_id: u32) error{IconNotOwned}!void {
    const player = mutation.read();
    if (!ownsHeadIcon(player, icon_id))
        return error.IconNotOwned;
    if (icon_id == player.basic.head_icon)
        return;

    mutation.modify(.{}).basic.head_icon = icon_id;
}

fn ownsHeadIcon(player: *const Player, icon_id: u32) bool {
    if (icon_id == Player.Basic.headIconForGender(player.basic.gender))
        return true;

    // TODO: Implement type-4 PlayerHead ownership when their acquisition route is added.
    return ownsSkin(player, icon_id);
}

pub fn setProfileSkin(mutation: *Mutation, skin_id: u32) error{SkinNotOwned}!void {
    const player = mutation.read();
    const character_id = tables.handbook.skinCharacterId(skin_id) orelse
        return error.SkinNotOwned;
    if (player.characters.get(character_id) == null or !ownsSkin(player, skin_id))
        return error.SkinNotOwned;
    if (skin_id == player.basic.profile_skin_id)
        return;

    mutation.modify(.{}).basic.profile_skin_id = skin_id;
}

fn ownsSkin(player: *const Player, skin_id: u32) bool {
    for (player.handbook.slice()) |unlock| {
        const entry = tables.handbook.get(unlock.handbook_id) orelse continue;
        if (entry.type == tables.handbook.skin_type and entry.skin_id == skin_id)
            return true;
    }

    return false;
}

pub fn setNickname(mutation: *Mutation, value: []const u8) error{InvalidNickname}!void {
    if (value.len == 0)
        return error.InvalidNickname;

    const player = mutation.read();
    if (std.mem.eql(u8, player.nickname(), value))
        return;

    var nickname = player.basic.nickname;
    nickname.set(value) catch return error.InvalidNickname;
    mutation.modify(.{}).basic.nickname = nickname;
}

pub fn setTitle(mutation: *Mutation, prefix: u32, suffix: u32) error{TitleNotOwned}!void {
    const player = mutation.read();
    if (!ownsTitle(player, prefix) or !ownsTitle(player, suffix))
        return error.TitleNotOwned;
    if (player.basic.title_prefix == prefix and player.basic.title_suffix == suffix)
        return;

    const basic = &mutation.modify(.{}).basic;
    basic.title_prefix = prefix;
    basic.title_suffix = suffix;
}

pub fn setSignature(mutation: *Mutation, value: []const u8) error{ SignatureTooLong, InvalidSignature, ForbiddenSignature }!void {
    const character_count = std.unicode.utf8CountCodepoints(value) catch
        return error.InvalidSignature;
    if (character_count > Player.Basic.signature_max_characters)
        return error.SignatureTooLong;
    if (std.mem.indexOfAny(u8, value, "<>/'") != null)
        return error.ForbiddenSignature;

    const player = mutation.read();
    if (std.mem.eql(u8, player.basic.signature.view(), value))
        return;

    var signature = player.basic.signature;
    signature.set(value) catch return error.SignatureTooLong;
    mutation.modify(.{}).basic.signature = signature;
}

fn ownsTitle(player: *const Player, id: u32) bool {
    for (player.titles.slice()) |title|
        if (title.id == id)
            return true;
    return false;
}

pub fn setHonors(mutation: *Mutation, ids: [Player.Basic.honor_slot_count]u32) error{InvalidHonor}!void {
    for (ids) |id|
        if (id != 0)
            return error.InvalidHonor;

    const player = mutation.read();
    if (std.mem.eql(u32, &player.basic.honor_ids, &ids))
        return;

    mutation.modify(.{}).basic.honor_ids = ids;
}

pub fn setProfileCharacters(mutation: *Mutation, ids: [Player.Basic.profile_char_slot_count]u32) error{InvalidCharacter}!void {
    const player = mutation.read();
    for (ids, 0..) |id, index| {
        if (id == 0)
            continue;
        if (player.characters.get(id) == null)
            return error.InvalidCharacter;
        for (ids[0..index]) |other| {
            if (id == other)
                return error.InvalidCharacter;
        }
    }

    if (std.mem.eql(u32, &player.basic.profile_char_ids, &ids))
        return;

    mutation.modify(.{}).basic.profile_char_ids = ids;
}
