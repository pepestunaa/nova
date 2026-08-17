const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

pub fn send(scope: *Scope) !void {
    for (scope.player.quests.slice()) |quest| {
        if (quest.quest_type != @intFromEnum(tables.quest.Type.tower))
            continue;
        var progress: [1]proto.pb.QuestProgress = .{.{
            .Cur = quest.progress_current,
            .Max = quest.progress_max,
        }};
        const change: proto.pb.Quest = .{
            .Id = quest.id,
            .Status = if (quest.claimed) 2 else if (quest.progress_current >= quest.progress_max) 1 else 0,
            .Type = .Tower,
            .Progress = .fromOwnedSlice(&progress),
        };
        try scope.sink.sendProto(.quest_change_notify, &change);
    }
}
