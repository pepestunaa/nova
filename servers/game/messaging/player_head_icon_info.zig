const proto = @import("proto");
const Player = @import("../store/Player.zig");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn player_head_icon_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);

    const icons = try scope.arena.alloc(u32, scope.player.handbook.slice().len + 1);
    var count: usize = 0;
    icons[count] = Player.Basic.headIconForGender(scope.player.basic.gender);
    count += 1;
    for (scope.player.handbook.slice()) |unlock| {
        const entry = tables.handbook.get(unlock.handbook_id) orelse continue;
        if (entry.type != tables.handbook.skin_type or
            entry.skin_id == Player.Basic.main_head_icon)
            continue;

        icons[count] = entry.skin_id;
        count += 1;
    }

    try scope.respond(proto.pb.PlayerHeadIconInfoResp{
        .List = .fromOwnedSlice(icons[0..count]),
    });
}
