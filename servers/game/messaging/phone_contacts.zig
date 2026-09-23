const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn phone_contacts_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);

    try scope.respond(proto.pb.PhoneContactsInfoResp{});
}
