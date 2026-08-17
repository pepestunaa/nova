const std = @import("std");

//

pub fn get(request: *std.http.Server.Request) !void {
    try request.respond(@embedFile("client_code.json"), .{ .status = .ok });
}
