const std = @import("std");

//

pub const response_buffer_size = 4096;

pub fn respondJson(request: *std.http.Server.Request, value: anytype) !void {
    var buffer: [response_buffer_size]u8 = undefined;
    const body = try std.fmt.bufPrint(
        &buffer,
        "{f}",
        .{std.json.fmt(value, .{})},
    );
    try request.respond(body, .{ .status = .ok });
}
