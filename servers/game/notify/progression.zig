const std = @import("std");

const achievement = @import("achievement.zig");
const gameplay_progression = @import("../gameplay/progression.zig");
const handbook = @import("handbook.zig");
const quest = @import("quest.zig");
const research_project = @import("research_project.zig");
const Scope = @import("../Scope.zig");

//

/// Appends live progression notifications after the handler's primary
/// response and in the same order used by the existing handlers.
pub fn send(scope: *Scope, changes: *const gameplay_progression.Changes) !void {
    const mutation = scope.mutation();
    std.debug.assert(mutation.isFinalized());

    try quest.sendLineupTutorial(scope, &changes.lineup_tutorial);
    try quest.sendMissionChanges(scope, &changes.missions);
    try quest.sendNewTrekkerAffinityQuests(scope, mutation);
    try achievement.send(scope, &changes.achievements);
    try research_project.send(scope, &changes.research_project);
    try handbook.send(scope);
}
