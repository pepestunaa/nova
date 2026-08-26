const std = @import("std");
const Io = std.Io;

const star_tower_record = @import("../gameplay/star_tower/record.zig");
const journey_ticket_id = star_tower_record.journey_ticket_id;

const gameplay = @import("../gameplay.zig");
const Player = @import("../store/Player.zig");
const proto = @import("proto");
const Scope = @import("../Scope.zig");
const tables = @import("../tables.zig");

//

pub fn star_tower_build_brief_list_get_req(scope: *Scope) !void {
    _ = try scope.source.read(proto.pb.Nil);

    const builds = scope.player.star_tower_builds.slice();
    const characters = try scope.arena.alloc([Player.max_formation_characters]proto.pb.TowerBuildChar, builds.len);
    const disc_ids = try scope.arena.alloc([Player.max_formation_discs]u32, builds.len);
    const briefs = try scope.arena.alloc(proto.pb.StarTowerBuildBrief, builds.len);
    for (builds, 0..) |*build, index| {
        briefs[index] = writeBrief(build, &characters[index], &disc_ids[index]);
    }

    try scope.respond(proto.pb.StarTowerBuildBriefListGetResp{ .Briefs = .fromOwnedSlice(briefs) });
}

pub fn star_tower_build_detail_get_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_build_detail_get_req);

    const request = try scope.source.read(proto.pb.StarTowerBuildDetailGetReq);
    const build = findBuild(scope.player, request.BuildId) orelse {
        try scope.respondFailureEmpty();

        log.warn("received detail request for unknown record {d}", .{request.BuildId});

        return;
    };

    const potentials = try scope.arena.alloc(proto.pb.BuildPotential, build.potential_count);
    for (build.potential_ids[0..build.potential_count], 0..) |potential_id, index| {
        potentials[index] = .{
            .PotentialId = potential_id,
            .Level = build.potential_levels[index],
        };
    }
    const notes = try scope.arena.alloc(proto.pb.ItemTpl, build.tower_item_count);
    for (build.tower_item_ids[0..build.tower_item_count], 0..) |item_id, index| {
        notes[index] = .{
            .Tid = item_id,
            .Qty = @intCast(build.tower_item_quantities[index]),
        };
    }
    const active_secondary_ids = try scope.arena.alloc(u32, build.active_secondary_count);
    @memcpy(
        active_secondary_ids,
        build.active_secondary_ids[0..build.active_secondary_count],
    );

    try scope.respond(proto.pb.StarTowerBuildDetailGetResp{
        .Detail = .{
            .Potentials = .fromOwnedSlice(potentials),
            .SubNoteSkills = .fromOwnedSlice(notes),
            .ActiveSecondaryIds = .fromOwnedSlice(active_secondary_ids),
        },
    });
}

pub fn star_tower_build_delete_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_build_delete_req);

    const request = try scope.source.read(proto.pb.StarTowerBuildDeleteReq);
    var requested_build_ids: [Player.max_star_tower_builds]u64 = undefined;
    var requested_build_count: usize = 0;
    var requested_builds = request.BuildIds;
    while (try requested_builds.next()) |build_id| {
        if (requested_build_count == requested_build_ids.len)
            return scope.reject(.invalid_req);
        requested_build_ids[requested_build_count] = build_id;
        requested_build_count += 1;
    }

    var raw_ticket_count: u32 = 0;
    var deleted_count: usize = 0;
    for (scope.player.star_tower_builds.slice()) |build| {
        if (!containsBuildId(requested_build_ids[0..requested_build_count], build.id))
            continue;

        raw_ticket_count +|= star_tower_record.dismantleTicketCount(build.score);
        deleted_count += 1;
    }

    if (deleted_count == 0) {
        var encoded_resource: [16]u8 = undefined;
        var changes: [1]proto.pb.Any = undefined;
        const change = try ticketChange(0, &encoded_resource, &changes);
        return scope.respond(proto.pb.StarTowerBuildDeleteResp{
            .Change = change,
            .Ticket = 0,
        });
    }

    const player = scope.mutation().modify(.{});
    var index: usize = 0;
    while (index < player.star_tower_builds.len) {
        const build = &player.star_tower_builds.entries[index];
        if (!containsBuildId(requested_build_ids[0..requested_build_count], build.id)) {
            index += 1;
            continue;
        }
        removeBuildAt(&player.star_tower_builds, index);
    }

    const now = scope.now;
    const ticket_count = try star_tower_record.awardDismantleTickets(
        player,
        scope.gpa,
        raw_ticket_count,
        now,
    );

    var encoded_resource: [16]u8 = undefined;
    var changes: [1]proto.pb.Any = undefined;
    const change = try ticketChange(ticket_count, &encoded_resource, &changes);
    try scope.respond(proto.pb.StarTowerBuildDeleteResp{ .Change = change, .Ticket = ticket_count });

    log.info("deleted {d} Ascension record(s) for {d} Journey Ticket(s)", .{
        deleted_count,
        ticket_count,
    });
}

pub fn star_tower_build_name_set_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_build_name_set_req);

    const request = try scope.source.read(proto.pb.StarTowerBuildNameSetReq);
    const current = findBuild(scope.player, request.BuildId) orelse {
        try scope.respondFailureEmpty();

        log.warn("received name change for unknown record {d}", .{request.BuildId});

        return;
    };
    var name = current.name;
    name.set(request.Name) catch
        return scope.reject(.build_name_max_len_limit);
    if (std.mem.eql(u8, current.name.view(), name.view()))
        return scope.respond(proto.pb.Nil{});

    const build = findBuildMut(
        scope.mutation().modify(.{}),
        request.BuildId,
    ).?;
    build.name = name;

    try scope.respond(proto.pb.Nil{});

    log.info("renamed Ascension record {d}", .{build.id});
}

pub fn star_tower_build_lock_unlock_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_build_lock_unlock_req);

    const request = try scope.source.read(proto.pb.StarTowerBuildLockUnlockReq);
    const current = findBuild(scope.player, request.BuildId) orelse {
        try scope.respondFailureEmpty();

        log.warn("received lock change for unknown record {d}", .{request.BuildId});

        return;
    };
    if (current.flags.locked == request.Lock)
        return scope.respond(proto.pb.Nil{});

    const build = findBuildMut(
        scope.mutation().modify(.{}),
        request.BuildId,
    ).?;

    build.flags.locked = request.Lock;

    try scope.respond(proto.pb.Nil{});

    log.info("{s} Ascension record {d}", .{
        if (build.flags.locked) "locked" else "unlocked",
        build.id,
    });
}

pub fn star_tower_build_preference_set_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_build_preference_set_req);

    const request = try scope.source.read(proto.pb.StarTowerBuildPreferenceSetReq);
    var check_in_buffer: [Player.max_star_tower_builds]u64 = undefined;
    var check_in_count: usize = 0;
    var check_in_ids = request.CheckInIds;
    while (try check_in_ids.next()) |build_id| {
        if (check_in_count == check_in_buffer.len)
            return scope.reject(.invalid_req);
        check_in_buffer[check_in_count] = build_id;
        check_in_count += 1;
    }

    var check_out_buffer: [Player.max_star_tower_builds]u64 = undefined;
    var check_out_count: usize = 0;
    var check_out_ids = request.CheckOutIds;
    while (try check_out_ids.next()) |build_id| {
        if (check_out_count == check_out_buffer.len)
            return scope.reject(.invalid_req);
        check_out_buffer[check_out_count] = build_id;
        check_out_count += 1;
    }

    var changed: usize = 0;
    for (scope.player.star_tower_builds.slice()) |build| {
        const preferred = requestedPreference(
            build.id,
            check_in_buffer[0..check_in_count],
            check_out_buffer[0..check_out_count],
        ) orelse
            continue;
        if (build.flags.preferred != preferred)
            changed += 1;
    }
    if (changed == 0)
        return scope.respond(proto.pb.Nil{});

    const player = scope.mutation().modify(.{});
    for (player.star_tower_builds.entries[0..player.star_tower_builds.len]) |*build| {
        build.flags.preferred = requestedPreference(
            build.id,
            check_in_buffer[0..check_in_count],
            check_out_buffer[0..check_out_count],
        ) orelse
            continue;
    }
    try scope.respond(proto.pb.Nil{});

    log.info("updated preference on {d} Ascension record(s)", .{changed});
}

pub fn star_tower_build_whether_save_req(scope: *Scope) !void {
    const log = scope.logger(.star_tower_build_whether_save_req);

    const request = try scope.source.read(proto.pb.StarTowerBuildWhetherSaveReq);
    const current_pending = &scope.player.pending_star_tower_build;
    if (!current_pending.flags.valid) {
        return try scope.respond(proto.pb.StarTowerBuildWhetherSaveResp{});
    }

    if (!request.Delete) {
        if (scope.player.star_tower_builds.len >= Player.max_star_tower_builds) {
            try scope.respondFailureEmpty();

            log.warn("cannot save record {d}: record storage is full", .{current_pending.id});

            return;
        }
        var checked_name = current_pending.name;
        checked_name.set(request.BuildName) catch
            return scope.reject(.build_name_max_len_limit);
        const player = scope.mutation().modify(.{});
        const pending = &player.pending_star_tower_build;
        pending.flags.locked = request.Lock;
        pending.flags.preferred = request.Preference;
        pending.name = checked_name;
        const build_id = pending.id;
        const rating = tables.star_tower.buildRating(pending.score);
        try player.star_tower_builds.append(scope.gpa, pending.*);
        pending.* = .{};
        gameplay.research_project.savedRecord(scope.mutation(), rating);

        try scope.respond(proto.pb.StarTowerBuildWhetherSaveResp{});

        log.info("saved Ascension record {d}", .{build_id});

        return;
    }

    const player = scope.mutation().modify(.{});
    const pending = &player.pending_star_tower_build;
    const now = scope.now;
    const ticket_count = try star_tower_record.awardDismantleTickets(
        player,
        scope.gpa,
        star_tower_record.dismantleTicketCount(pending.score),
        now,
    );
    const build_id = pending.id;
    pending.* = .{};
    var encoded_resource: [16]u8 = undefined;
    var changes: [1]proto.pb.Any = undefined;
    const change = try ticketChange(ticket_count, &encoded_resource, &changes);
    try scope.respond(proto.pb.StarTowerBuildWhetherSaveResp{ .Change = change, .Ticket = ticket_count });

    log.info("dismantled pending Ascension record {d} for {d} Journey Ticket(s)", .{
        build_id,
        ticket_count,
    });
}

fn writeBrief(
    build: *const Player.StarTowerBuild,
    characters: *[Player.max_formation_characters]proto.pb.TowerBuildChar,
    disc_ids: *[Player.max_formation_discs]u32,
) proto.pb.StarTowerBuildBrief {
    for (build.character_ids[0..build.character_count], 0..) |character_id, index| {
        var potential_levels: u32 = 0;
        for (build.potential_ids[0..build.potential_count], 0..) |potential_id, potential_index| {
            if (tables.potential.characterId(potential_id) == character_id)
                potential_levels +|= build.potential_levels[potential_index];
        }
        characters[index] = .{
            .CharId = character_id,
            .PotentialCnt = potential_levels,
        };
    }
    @memcpy(disc_ids[0..build.disc_count], build.disc_ids[0..build.disc_count]);

    return .{
        .Id = build.id,
        .Name = build.name.view(),
        .Lock = build.flags.locked,
        .Preference = build.flags.preferred,
        .Score = build.score,
        .DiscIds = .fromOwnedSlice(disc_ids[0..build.disc_count]),
        .Chars = .fromOwnedSlice(characters[0..build.character_count]),
        .StarTowerId = build.tower_id,
    };
}

fn findBuild(
    player: *const Player,
    build_id: u64,
) ?*const Player.StarTowerBuild {
    for (player.star_tower_builds.slice()) |*build| {
        if (build.id == build_id)
            return build;
    }

    return null;
}

fn findBuildMut(
    player: *Player,
    build_id: u64,
) ?*Player.StarTowerBuild {
    for (player.star_tower_builds.entries[0..player.star_tower_builds.len]) |*build| {
        if (build.id == build_id)
            return build;
    }

    return null;
}

fn containsBuildId(build_ids: []const u64, wanted: u64) bool {
    for (build_ids) |build_id|
        if (build_id == wanted)
            return true;

    return false;
}

fn requestedPreference(
    build_id: u64,
    check_in_ids: []const u64,
    check_out_ids: []const u64,
) ?bool {
    if (containsBuildId(check_out_ids, build_id))
        return false;
    if (containsBuildId(check_in_ids, build_id))
        return true;

    return null;
}

fn removeBuildAt(builds: *Player.StarTowerBuildTable, index: usize) void {
    std.debug.assert(index < builds.len);
    const remaining = builds.len - index - 1;
    if (remaining != 0) {
        std.mem.copyForwards(
            Player.StarTowerBuild,
            builds.entries[index .. index + remaining],
            builds.entries[index + 1 .. index + 1 + remaining],
        );
    }
    builds.len -= 1;
}

fn ticketChange(
    ticket_count: u32,
    encoded_resource: *[16]u8,
    changes: *[1]proto.pb.Any,
) proto.EncodeError!proto.pb.ChangeInfo {
    if (ticket_count == 0)
        return .{};

    var writer = Io.Writer.fixed(encoded_resource);
    const resource: proto.pb.Res = .{
        .Tid = journey_ticket_id,
        .Qty = @intCast(ticket_count),
    };
    try proto.encode(proto.pb.Res, &writer, &resource);
    changes[0] = .{
        .type_url = "type.googleapis.com/proto.Res",
        .value = writer.buffered(),
    };

    return .{
        .Props = .fromOwnedSlice(changes),
    };
}
