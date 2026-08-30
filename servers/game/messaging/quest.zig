//! Handles daily and weekly mission reward claims.

const change_info = @import("../view/change_info.zig");
const gameplay = @import("../gameplay.zig");
const reward = @import("../gameplay/reward.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn quest_daily_reward_receive_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.UI32);
    try receiveMission(scope, .daily, request.Value);
}

pub fn quest_weekly_reward_receive_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.UI32);
    try receiveMission(scope, .weekly, request.Value);
}

pub fn quest_daily_active_reward_receive_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try receiveActiveRewards(scope, .daily);
}

pub fn quest_weekly_active_reward_receive_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try receiveActiveRewards(scope, .weekly);
}

fn receiveMission(
    scope: *Scope,
    mission_type: tables.quest.Type,
    id: u32,
) !void {
    var receipt: reward.ResourceReceipt = .{};

    const claimed = gameplay.missions.claim(
        scope.mutation(),
        scope.gpa,
        scope.now,
        mission_type,
        id,
        &receipt,
    ) catch |err| switch (err) {
        error.InvalidMission => return scope.reject(.invalid_req),
        error.MissionExpired => return scope.reject(.quest_closed),
        error.MissionNotComplete => return scope.reject(.quest_not_complete),
        error.MissionAlreadyClaimed => return scope.reject(.recv_reward),
        else => |e| return e,
    };

    var change: change_info.Resources = .{};
    try scope.respond(try change.build(&receipt, scope.arena));

    if (id == 0) {
        switch (mission_type) {
            .daily => scope.logger(.quest_daily_reward_receive_req).info("claimed {d} completed mission(s)", .{claimed}),
            .weekly => scope.logger(.quest_weekly_reward_receive_req).info("claimed {d} completed mission(s)", .{claimed}),
            else => unreachable,
        }
    } else {
        switch (mission_type) {
            .daily => scope.logger(.quest_daily_reward_receive_req).info("claimed mission {d}", .{id}),
            .weekly => scope.logger(.quest_weekly_reward_receive_req).info("claimed mission {d}", .{id}),
            else => unreachable,
        }
    }
}

fn receiveActiveRewards(
    scope: *Scope,
    mission_type: tables.quest.Type,
) !void {
    var result: gameplay.missions.ActiveClaim = .{};
    gameplay.missions.claimActive(
        scope.mutation(),
        scope.gpa,
        mission_type,
        &result,
    ) catch |err| switch (err) {
        error.NoActiveRewards => return scope.reject(.no_rewards_to_receive),
        error.InvalidMission => return scope.reject(.invalid_req),
        else => |e| return e,
    };

    var change: change_info.Resources = .{};
    switch (mission_type) {
        .daily => try scope.respond(proto.pb.QuestDailyActiveRewardReceiveResp{
            .ActiveIds = .fromOwnedSlice(result.ids[0..result.count]),
            .Change = try change.build(&result.rewards, scope.arena),
        }),
        .weekly => try scope.respond(proto.pb.QuestWeeklyActiveRewardReceiveResp{
            .ActiveIds = .fromOwnedSlice(result.ids[0..result.count]),
            .Change = try change.build(&result.rewards, scope.arena),
        }),
        else => unreachable,
    }

    switch (mission_type) {
        .daily => scope.logger(.quest_daily_active_reward_receive_req).info(
            "claimed {d} activity reward(s)",
            .{result.count},
        ),
        .weekly => scope.logger(.quest_weekly_active_reward_receive_req).info(
            "claimed {d} activity reward(s)",
            .{result.count},
        ),
        else => unreachable,
    }
}
