const Player = @import("../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn npc_affinity_book_get_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    const player = scope.player;
    const infos = try scope.arena.alloc(proto.pb.NPCAffinity, player.npc_affinities.len);
    for (player.npc_affinities.slice(), 0..) |entry, index| {
        infos[index] = .{ .NPCId = entry.npc_id, .Affinity = entry.affinity };
    }

    try scope.respond(proto.pb.NPCAffinityBookGetResp{
        .Infos = .fromOwnedSlice(infos),
        .Number = @intCast(player.npc_affinities.len),
    });
}
