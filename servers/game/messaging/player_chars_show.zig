const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const Player = @import("../store/Player.zig");

//

pub fn player_chars_show_req(scope: *Scope) !void {
    var request = try scope.source.read(proto.pb.PlayerCharsShowReq);
    var ids: [Player.Basic.profile_char_slot_count]u32 = @splat(0);
    var count: usize = 0;
    while (request.CharIds.next() catch return error.MalformedMessage) |id| {
        if (count == ids.len)
            return scope.reject(.invalid_req);
        ids[count] = id;
        count += 1;
    }

    gameplay.player_profile.setProfileCharacters(scope.mutation(), ids) catch |err| switch (err) {
        error.InvalidCharacter => return scope.reject(.invalid_req),
    };

    try scope.respond(proto.pb.Nil{});
}
