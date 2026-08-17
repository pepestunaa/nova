const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

/// Receives progress events observed by the client. The official server uses
/// them for systems such as missions and achievements, but none of the state
/// implemented here depends on them *yet*.
pub fn client_event_report_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Events);
    try scope.respond(proto.pb.Nil{});
}
