const std = @import("std");

const proto = @import("proto");
const Scope = @import("../Scope.zig");
const Session = @import("../session.zig");

//

pub fn ike_req(scope: *Scope) !void {
    const log = scope.logger(.ike_req);

    const request = try scope.source.read(proto.pb.IKEReq);

    log.info(
        "request: protocol version {d}, client timestamp {d}, public key {d} bytes",
        .{ request.ProtoVersion, request.ClientTs, request.PubKey.len },
    );

    const handshake = try Session.beginHandshake(scope.io, request.PubKey);

    try scope.respond(proto.pb.IKEResp{
        .Token = scope.createSession(handshake.key),
        .Cipher = 0,
        .ServerTs = handshake.server_timestamp,
        .PubKey = &handshake.server_public_key,
    });
}
