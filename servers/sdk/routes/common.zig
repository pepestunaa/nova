const std = @import("std");

const http = @import("../http.zig");
const sdk_server_config: @import("../Config.zig") = @import("config");

//

pub fn config(request: *std.http.Server.Request) !void {
    var body_buffer: [1024]u8 = undefined;
    const request_body = try request.readerExpectContinue(&body_buffer);
    _ = try request_body.discardRemaining();

    const response = .{
        .Code = 200,
        .Data = .{
            .AppConfig = .{
                .USER_AGREEMENT = "",
                .NICKNAME_REG = "^[A-Za-z0-9]{2,20}$",
                .PRIVACY_AGREEMENT = "",
            },
            .EuropeUnion = true,
            .StoreConfig = .{
                .GUEST_CREATE_METHOD = 0,
                .LOGIN = .{
                    .DEFAULT = "device",
                },
            },
        },
        .Msg = "OK",
    };

    try http.respondJson(request, response);
}
