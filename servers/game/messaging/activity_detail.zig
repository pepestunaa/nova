const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn activity_dust_dawn_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.respondEmpty();
}

pub fn activity_detail_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    var quests: [tables.periodic_quest.list.len]proto.pb.ActivityQuest = undefined;
    for (tables.periodic_quest.list, 0..) |definition, index| quests[index] = .{
        .Id = definition.id,
        .Status = @intFromEnum(scope.player.periodicQuestStatus(definition.id)),
        .ActivityId = tables.periodic_quest.activity_id,
    };

    var activities: [1]proto.pb.ActivityMsg = .{.{
        .Id = tables.periodic_quest.activity_id,
        .Periodic = .{
            .ActivityId = tables.periodic_quest.activity_id,
            .FinalStatus = scope.player.periodic_campaign.final_reward_claimed,
            .Quests = .fromOwnedSlice(&quests),
        },
    }};
    try scope.respond(proto.pb.ActivityResp{ .List = .fromOwnedSlice(&activities) });
}
