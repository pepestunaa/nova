const proto = @import("proto");
const Scope = @import("../Scope.zig");

// The 1.13.0.143 client sends this while opening the main view and stalls
// when the response is not a valid encrypted packet. The partner-trace data
// model is not implemented yet, so acknowledge the request with an empty body.
pub fn soldier_partner_trace_info_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);
    try scope.respondEmpty();
}
