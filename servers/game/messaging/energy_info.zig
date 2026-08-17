const std = @import("std");
const Io = std.Io;

const gameplay = @import("../gameplay.zig");
const Player = @import("../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn energy_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    const now = Io.Timestamp.now(scope.io, .real).toSeconds();
    _ = gameplay.energy.refresh(scope.playerMut(), now);

    try scope.respond(proto.pb.Energy{
        .Primary = @intFromEnum(scope.player.basic.primary_energy),
        .IsPrimary = true,
        .UpdateTime = scope.player.basic.energy_updated_at,
        .NextDuration = gameplay.energy.nextDuration(scope.player, now),
    });
}
