const config: @import("../Config.zig") = @import("config");
const gameplay = @import("../gameplay.zig");
const Player = @import("../store/Player.zig");
const player_data = @import("player_data.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

const tutorial_skip_error_code = 110_107;

pub fn player_reg_req(scope: *Scope) !void {
    const log = scope.logger(.player_reg_req);

    const request = try scope.source.read(proto.pb.PlayerReg);
    const registered_at = scope.timestamp;
    const now = registered_at.toSeconds();
    gameplay.registration.register(
        scope.mutation(),
        scope.gpa,
        request.Nickname,
        if (request.Gender) .male else .female,
        registered_at,
    ) catch |err| switch (err) {
        error.AlreadyRegistered => return scope.reject(.invalid_req),
        else => return err,
    };
    _ = gameplay.energy.refresh(scope.mutation(), now);
    try gameplay.missions.login(scope.mutation(), scope.gpa, now);

    if (config.skip_tutorial) {
        try scope.mutation().modify(.{}).completeGuides(
            scope.gpa,
            &tables.guide_group.all_ids,
        );
        log.info("marked all {d} guide groups complete", .{tables.guide_group.all_ids.len});
    }

    if (config.skip_tutorial) {
        // Reconnect after registration so the next login treats this as an
        // existing account and skips the prologue and tutorials.
        try scope.respondFailure(proto.pb.Error{ .Code = tutorial_skip_error_code });

        log.info("registered player '{s}'; returned relogin error for tutorial skip", .{scope.player.nickname()});

        return;
    }

    try player_data.response.send(scope);

    log.info("registered player '{s}'", .{scope.player.nickname()});
}
