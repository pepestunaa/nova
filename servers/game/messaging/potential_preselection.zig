const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

// TODO: Implement Potential Presets.
pub fn potential_preselection_list_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.respond(proto.pb.PotentialPreselectionList{});
}
