const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

/// Acknowledges client events. Achievement reports are accepted
/// only when attached to a validated Ascension victory, where the server has
/// enough context to associate them with a completed battle.
pub fn client_event_report_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Events);
    try scope.respond(proto.pb.Nil{});
}
