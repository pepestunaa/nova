const std = @import("std");
const Io = std.Io;

const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn player_ping_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Ping);
    try scope.respond(proto.pb.Pong{
        .ServerTs = Io.Timestamp.now(scope.io, .real).toSeconds(),
    });
}
