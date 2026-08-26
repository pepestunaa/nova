const std = @import("std");

const Scope = @import("../Scope.zig");
const Player = @import("../store/Player.zig");
const State = @import("../store/player/State.zig");
const proto = @import("proto");

const max_friends = State.max_friends;

pub fn friend_list_get_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.respond(proto.pb.FriendListGetResp{
        .Friends = .empty,
    });
}

pub fn friend_uid_search_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.FriendUIdSearchReq);
    try scope.respond(proto.pb.FriendUIdSearchResp{});
}

pub fn friend_name_search_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.FriendNameSearchReq);
    try scope.respond(proto.pb.FriendNameSearchResp{
        .Friends = .empty,
    });
}

pub fn friend_recommendation_get_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.respond(proto.pb.FriendRecommendationGetResp{
        .Friends = .empty,
    });
}

pub fn friend_add_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.FriendAddReq);
    try scope.reject(.invalid_req);
}

pub fn friend_delete_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.FriendDeleteReq);
    const index = friendIndex(scope.player, request.UId) orelse
        return scope.reject(.invalid_req);

    const player = scope.mutation().modify(.{});
    const last_index = player.basic.friend_count - 1;
    var current = index;
    while (current < last_index) : (current += 1) {
        player.basic.friend_uids[current] = player.basic.friend_uids[current + 1];
        setFriendStar(player, current, isFriendStar(player, current + 1));
    }
    player.basic.friend_uids[last_index] = 0;
    setFriendStar(player, last_index, false);
    player.basic.friend_count -= 1;
    try scope.respondEmpty();
}

pub fn friend_star_set_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.FriendStarSetReq);
    var uids: [max_friends]u64 = undefined;
    var uid_count: usize = 0;
    var iterator = request.UIds;
    while (iterator.next() catch return error.MalformedMessage) |uid| {
        if (uid_count == uids.len)
            return scope.reject(.invalid_req);
        uids[uid_count] = uid;
        uid_count += 1;
    }

    if (uid_count == 0)
        return scope.reject(.invalid_req);

    for (uids[0..uid_count]) |uid| {
        if (friendIndex(scope.player, uid) == null)
            return scope.reject(.invalid_req);
    }

    var changed = false;
    for (uids[0..uid_count]) |uid| {
        const index = friendIndex(scope.player, uid).?;
        changed = changed or isFriendStar(scope.player, index) != request.Star;
    }
    if (!changed)
        return scope.respondEmpty();

    const player = scope.mutation().modify(.{});
    for (uids[0..uid_count]) |uid| {
        setFriendStar(player, friendIndex(player, uid).?, request.Star);
    }
    try scope.respondEmpty();
}

pub fn friend_send_energy_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.FriendSendEnergyReq);
    const accepted = try scope.arena.alloc(u64, max_friends);
    var accepted_count: usize = 0;
    var iterator = request.UIds;
    while (iterator.next() catch return error.MalformedMessage) |uid| {
        if (accepted_count == accepted.len or friendIndex(scope.player, uid) == null)
            return scope.reject(.invalid_req);
        accepted[accepted_count] = uid;
        accepted_count += 1;
    }

    if (accepted_count == 0) {
        for (scope.player.basic.friend_uids[0..scope.player.basic.friend_count]) |uid| {
            accepted[accepted_count] = uid;
            accepted_count += 1;
        }
    }

    try scope.respond(proto.pb.FriendSendEnergyResp{
        .UIds = .fromOwnedSlice(accepted[0..accepted_count]),
    });
}

fn friendIndex(player: *const Player, uid: u64) ?usize {
    return std.mem.indexOfScalar(u64, player.basic.friend_uids[0..player.basic.friend_count], uid);
}

fn isFriendStar(player: *const Player, index: usize) bool {
    const mask: u8 = @as(u8, 1) << @intCast(index & 7);
    return player.basic.friend_stars[index >> 3] & mask != 0;
}

fn setFriendStar(player: *Player, index: usize, value: bool) void {
    const mask: u8 = @as(u8, 1) << @intCast(index & 7);
    if (value) {
        player.basic.friend_stars[index >> 3] |= mask;
    } else {
        player.basic.friend_stars[index >> 3] &= ~mask;
    }
}
