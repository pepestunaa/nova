const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

/// The 1.13.0.143 client asks for the Dorm system when its Dorm guide runs.
/// The Dorm payload schema is not part of the bundled protocol, so the request
/// is answered with its failure packet: the client routes failure packets to
/// its generic error handler instead of the data callback, which would index
/// a missing `mapDromBaseInfo` field.
pub fn player_dorm_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.reject(.api_disabled);
}

pub fn player_dorm_room_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.reject(.api_disabled);
}
