const handbook = @import("../view/handbook.zig");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn send(scope: *Scope) !void {
    var bitmap: [tables.handbook.max_bitmap_len]u8 = undefined;
    var types = scope.mutation().handbookTypeIterator();
    while (types.next()) |handbook_type| {
        const message = handbook.info(scope.player, handbook_type, &bitmap) orelse
            continue;
        try scope.sink.sendProto(.handbook_change_notify, &message);
    }
}
