const Player = @import("../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn player_formation_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.PlayerFormationReq);
    const formation = request.Formation orelse
        return scope.reject(.invalid_msg_body);

    var character_ids: [Player.max_formation_characters]u32 = undefined;
    var character_count: usize = 0;
    var characters = formation.CharIds;
    while (try characters.next()) |character_id| {
        if (character_count == character_ids.len)
            return scope.reject(.invalid_req);
        character_ids[character_count] = character_id;
        character_count += 1;
    }

    var disc_ids: [Player.max_formation_discs]u32 = undefined;
    var disc_count: usize = 0;
    var discs = formation.DiscIds;
    while (try discs.next()) |disc_id| {
        if (disc_count == disc_ids.len)
            return scope.reject(.invalid_req);
        disc_ids[disc_count] = disc_id;
        disc_count += 1;
    }

    try scope.playerMut().setFormation(
        scope.gpa,
        formation.Number,
        character_ids[0..character_count],
        disc_ids[0..disc_count],
        formation.PreselectionId,
    );

    scope.markDirty();

    try scope.respond(proto.pb.Nil{});
}
