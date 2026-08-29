const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const Player = @import("../store/Player.zig");

//

pub fn player_honor_edit_req(scope: *Scope) !void {
    var request = try scope.source.read(proto.pb.PlayerHonorEditReq);
    var ids: [Player.Basic.honor_slot_count]u32 = @splat(0);
    var count: usize = 0;
    while (request.List.next() catch return error.MalformedMessage) |id| {
        if (count == ids.len)
            return scope.reject(.invalid_req);
        ids[count] = id;
        count += 1;
    }

    gameplay.player_profile.setHonors(scope.mutation(), ids) catch |err| switch (err) {
        error.InvalidHonor => return scope.reject(.invalid_req),
    };

    var honors: [ids.len]proto.pb.HonorInfo = undefined;
    for (&honors, ids) |*honor, id| honor.* = .{ .Id = id };
    const notify: proto.pb.HonorChangeNotify = .{
        .Honors = .fromOwnedSlice(&honors),
    };
    try scope.sink.sendProto(.honor_change_notify, &notify);
    try scope.respond(proto.pb.Nil{});
}
