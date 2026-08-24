const achievement = @import("../gameplay/achievement.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn send(scope: *Scope, changes: *const achievement.ChangeSet) !void {
    for (changes.slice()) |state| {
        const definition = tables.achievement.get(state.id) orelse
            continue;
        var progress: [1]proto.pb.QuestProgress = .{.{
            .Cur = state.progress,
            .Max = definition.target,
        }};
        const message: proto.pb.Achievement = .{
            .Id = state.id,
            .Status = @intFromEnum(state.status),
            .Completed = state.completed_at,
            .Progress = .fromOwnedSlice(&progress),
        };
        try scope.sink.sendProto(.achievement_change_notify, &message);
    }
}
