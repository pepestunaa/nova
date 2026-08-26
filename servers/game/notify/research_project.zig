const proto = @import("proto");
const research_project = @import("../gameplay/research_project.zig");
const Scope = @import("../Scope.zig");

pub fn send(scope: *Scope, changes: *const research_project.ChangeSet) !void {
    for (changes.slice()) |quest| {
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
