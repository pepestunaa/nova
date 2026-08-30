const achievement = @import("../../gameplay/achievement.zig");
const missions = @import("../../gameplay/missions.zig");
const Mutation = @import("../../gameplay/mutation.zig");
const proto = @import("proto");

//

/// Copies achievement increments from a validated Ascension victory into the
/// request mutation. Other client event kinds are unrelated to achievements.
pub fn record(mutation: *Mutation, events: proto.pb.Events.Decoded) !void {
    var event_list = events.List;
    while (try event_list.next()) |event| {
        if (event.Id != @intFromEnum(achievement.ClientEvent.achievement_progress))
            continue;

        var data = event.Data;
        const delta = (try data.next()) orelse
            continue;
        const achievement_id = (try data.next()) orelse
            continue;
        if (mutation.recordClientReport(achievement_id, delta))
            missions.trigger(mutation, .client_report, delta, achievement_id);
    }
}

//

test "Ascension client reports aggregate known events" {
    const std = @import("std");
    const testing = std.testing;

    const Player = @import("../../store/Player.zig");
    const tables = @import("../../tables.zig");

    //

    var player = Player.init(1);
    defer player.deinit(testing.allocator);
    var mutation: Mutation = .init(&player);
    _ = mutation.modify(.{});

    const report = tables.achievement.client_reports[0];
    const achievement_id = tables.achievement.entry(report.entry_index).id;
    var first_data: [2]u32 = .{ 4, achievement_id };
    var second_data: [2]u32 = .{ 3, achievement_id };
    var unknown_data: [2]u32 = .{ 99, achievement_id };
    var short_data: [1]u32 = .{8};
    var event_values: [4]proto.pb.Event = .{
        .{
            .Id = @intFromEnum(achievement.ClientEvent.achievement_progress),
            .Data = .fromOwnedSlice(first_data[0..]),
        },
        .{
            .Id = @intFromEnum(achievement.ClientEvent.achievement_progress),
            .Data = .fromOwnedSlice(second_data[0..]),
        },
        .{
            .Id = 201,
            .Data = .fromOwnedSlice(unknown_data[0..]),
        },
        .{
            .Id = @intFromEnum(achievement.ClientEvent.achievement_progress),
            .Data = .fromOwnedSlice(short_data[0..]),
        },
    };
    const events = proto.pb.Events{
        .List = .fromOwnedSlice(event_values[0..]),
    };
    var encoded: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&encoded);
    try proto.encode(proto.pb.Events, &writer, &events);
    const decoded = try proto.decode(proto.pb.Events.Decoded, writer.buffered());

    try record(&mutation, decoded);
    try testing.expectEqual(
        @as(u32, 7),
        mutation.clientReportDelta(tables.achievement.clientReportIndex(achievement_id).?),
    );

    mutation.finish();
    mutation.committed();
}
