const gameplay = @import("../gameplay.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn player_signature_edit_req(scope: *Scope) !void {
    const request = try scope.source.read(proto.pb.PlayerSignatureEditReq);
    gameplay.player_profile.setSignature(scope.mutation(), request.Signature) catch |err| switch (err) {
        error.SignatureTooLong => return scope.reject(.signature_len_violation),
        error.InvalidSignature => return scope.reject(.signature_illegal),
        error.ForbiddenSignature => return scope.reject(.signature_forbidden),
    };

    try scope.respond(proto.pb.Nil{});
}
