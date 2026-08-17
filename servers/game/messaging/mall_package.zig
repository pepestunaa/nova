const proto = @import("proto");
const Scope = @import("../Scope.zig");

//

pub fn mall_package_list_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.respond(proto.pb.MallPackageList{});
}
