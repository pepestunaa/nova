const std = @import("std");

//

pub const response_buffer_size = 4096;

pub fn respondJson(request: *std.http.Server.Request, value: anytype) !void {
    var buffer: [response_buffer_size]u8 = undefined;
    var response = try request.respondStreaming(&buffer, .{
        .respond_options = .{ .status = .ok },
    });
    try response.writer.print("{f}", .{std.json.fmt(value, .{})});
    try response.end();
}
