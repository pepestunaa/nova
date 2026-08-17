const Auth = @This();

const std = @import("std");

//

http: *std.http.Client,
sdk_server_address: []const u8,

pub const Error = std.http.Client.FetchError || error{
    RequestTooLarge,
    UnexpectedStatus,
};

/// Asks the SDK server, which owns the account credentials, to validate a
/// login attempt.
pub fn validate(auth: *Auth, uid: u64, token: []const u8) Error!bool {
    // SDK account tokens use lowercase hexadecimal.
    if (token.len != 40)
        return false;
    for (token) |byte| {
        if (!std.ascii.isHex(byte) or std.ascii.isUpper(byte))
            return false;
    }

    var url_buffer: [256]u8 = undefined;
    const url = std.fmt.bufPrint(
        &url_buffer,
        "http://{s}/internal/account/validate",
        .{auth.sdk_server_address},
    ) catch
        return error.RequestTooLarge;

    var payload_buffer: [128]u8 = undefined;
    const payload = std.fmt.bufPrint(
        &payload_buffer,
        "{{\"uid\":{d},\"token\":\"{s}\"}}",
        .{ uid, token },
    ) catch
        return error.RequestTooLarge;

    const result = try auth.http.fetch(.{
        .location = .{ .url = url },
        .payload = payload,
        .extra_headers = &.{.{
            .name = "content-type",
            .value = "application/json",
        }},
    });

    return switch (result.status) {
        .no_content => true,
        .unauthorized => false,
        else => error.UnexpectedStatus,
    };
}
