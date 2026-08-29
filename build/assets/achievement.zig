const std = @import("std");
const Io = std.Io;

const raw_list = @import("tables/Achievement");
const raw_count: usize = raw_list.len;

//

const CollectionKind = enum(u2) {
    all_discs,
    five_star_discs,
    all_trekkers,
    five_star_trekkers,
};

const kind_count = @typeInfo(CollectionKind).@"enum".fields.len;

const Entry = struct {
    id: u32,
    target: u32,
    reward_id: u32,
    reward_quantity: i32,
};

const CollectionGroup = struct {
    kind: CollectionKind,
    first: u8,
    count: u8,
};

const ProgressKind = enum(u8) {
    advance_total,
    character_level,
    element_level,
    skill_level,
    disc_tier_total,
    disc_level,
};

const Progression = struct {
    entry_index: u8,
    kind: ProgressKind,
    minimum_level: u8,
    element: u8,
};

const ClientReportKind = enum(u3) {
    elemental_mark,
    skill_cast,
    single_attack_damage,
    low_hp_clear,
    specific_battle_condition,
    enemy_type_counter,
};

const ClientReport = struct {
    entry_index: u8,
    kind: ClientReportKind,
    client_condition: u32,
    parameters: []const u32,
};

const Raw = struct {
    id: u32,
    achievement_id: u32,
    target: u32,
    reward_id: u32,
    reward_quantity: i32,
    condition: u32,
    achievement_type: u32,
    prerequisite: ?u32,
    client_condition: u32,
    client_parameters: []const u32,
};

const entries: [raw_count]Raw = entries: {
    var result: [raw_count]Raw = undefined;

    for (raw_list, 0..) |entry, index| {
        const prerequisites: []const u32 = if (@hasField(@TypeOf(entry), "prerequisites"))
            &entry.prerequisites
        else
            &.{};
        const client_parameters: []const u32 = if (@hasField(@TypeOf(entry), "client_complete_params1"))
            &entry.client_complete_params1
        else
            &.{};
        if (prerequisites.len > 1)
            @compileError("achievement has multiple prerequisites");
        result[index] = .{
            .id = entry.id,
            .achievement_id = entry.achieve_id,
            .target = entry.aim_num_show,
            .reward_id = entry.tid1,
            .reward_quantity = entry.qty1,
            .condition = entry.complete_cond,
            .achievement_type = entry.type,
            .prerequisite = if (prerequisites.len == 0) null else prerequisites[0],
            .client_condition = if (@hasField(@TypeOf(entry), "complete_cond_client"))
                entry.complete_cond_client
            else
                0,
            .client_parameters = client_parameters,
        };
    }

    break :entries result;
};

const DiscoveredProgression = struct {
    source_index: usize,
    kind: ProgressKind,
    minimum_level: u8 = 0,
    element: u8 = 0,
};

const DiscoveredProgressions = struct {
    values: [entries.len]DiscoveredProgression = undefined,
    len: usize = 0,

    fn append(result: *DiscoveredProgressions, value: DiscoveredProgression) void {
        result.values[result.len] = value;
        result.len += 1;
    }
};

const DiscoveredClientReport = struct {
    source_index: usize,
    kind: ClientReportKind,
    client_condition: u32,
    parameters: []const u32,
};

const DiscoveredClientReports = struct {
    values: [entries.len]DiscoveredClientReport = undefined,
    len: usize = 0,

    fn append(result: *DiscoveredClientReports, value: DiscoveredClientReport) void {
        result.values[result.len] = value;
        result.len += 1;
    }
};

const Chain = struct {
    indices: [entries.len]usize = @splat(0),
    len: usize = 0,
};

const Definitions = struct {
    entries: [entries.len]Entry = undefined,
    len: usize = 0,
    collection_count: usize = 0,
    collection_groups: [kind_count]CollectionGroup = undefined,
    progressions: [entries.len]Progression = undefined,
    progression_count: usize = 0,
    client_reports: [entries.len]ClientReport = undefined,
    client_report_count: usize = 0,
    first_id: u32 = std.math.maxInt(u32),
    last_id: u32 = 0,

    fn append(result: *Definitions, raw: Raw) u8 {
        if (result.len == std.math.maxInt(u8))
            @compileError("too many tracked achievements for u8 indexes");
        for (result.entries[0..result.len]) |existing| {
            if (existing.id == raw.id)
                @compileError("achievement definition was emitted twice");
        }
        result.entries[result.len] = .{
            .id = raw.id,
            .target = raw.target,
            .reward_id = raw.reward_id,
            .reward_quantity = raw.reward_quantity,
        };
        result.first_id = @min(result.first_id, raw.id);
        result.last_id = @max(result.last_id, raw.id);
        const index: u8 = @intCast(result.len);
        result.len += 1;

        return index;
    }
};

pub fn generate(_: std.process.Init, writer: *Io.Writer) !void {
    const chains = comptime discoverChains();
    const progressions = comptime discoverProgressions();
    const client_reports = comptime discoverClientReports();
    const definitions = comptime buildDefinitions(chains, progressions, client_reports);

    try writer.writeAll(
        "//! Generated by `zig build generate-assets -- achievement`.\n" ++
            "//! Do not edit manually.\n\n",
    );
    try writeEnumDeclaration(writer, "CollectionKind", CollectionKind);
    try writeStructDeclaration(writer, "Entry", Entry);
    try writeStructDeclaration(writer, "CollectionGroup", CollectionGroup);
    try writeEnumDeclaration(writer, "ProgressKind", ProgressKind);
    try writeStructDeclaration(writer, "Progression", Progression);
    try writeEnumDeclaration(writer, "ClientReportKind", ClientReportKind);
    try writeStructDeclaration(writer, "ClientReport", ClientReport);

    try writer.writeAll("pub const entries = [_]Entry{\n");
    for (definitions.entries[0..definitions.len]) |entry|
        try writeEntry(writer, entry);
    try writer.writeAll("};\n\n");

    try writer.writeAll("pub const client_reports = [_]ClientReport{\n");
    for (definitions.client_reports[0..definitions.client_report_count]) |report|
        try writeClientReport(writer, report);
    try writer.writeAll("};\n\n");

    try writer.writeAll("pub const collection_groups = [_]CollectionGroup{\n");
    for (definitions.collection_groups) |group| {
        try writer.print(
            "    .{{ .kind = .{s}, .first = {d}, .count = {d} }},\n",
            .{ @tagName(group.kind), group.first, group.count },
        );
    }
    try writer.writeAll("};\n\n");

    try writer.writeAll("pub const progressions = [_]Progression{\n");
    for (definitions.progressions[0..definitions.progression_count]) |progression| {
        try writer.print(
            "    .{{ .entry_index = {d}, .kind = .{s}, .minimum_level = {d}, .element = {d} }},\n",
            .{
                progression.entry_index,
                @tagName(progression.kind),
                progression.minimum_level,
                progression.element,
            },
        );
    }
    try writer.writeAll("};\n\n");

    try writer.print("pub const collection_entry_count = {d};\n", .{definitions.collection_count});
    try writer.print("pub const client_report_count = {d};\n", .{definitions.client_report_count});
    try writer.print("pub const tracked_entry_count = {d};\n\n", .{definitions.len});

    try writer.print("const first_entry_id = {d};\n", .{definitions.first_id});
    try writer.writeAll("const entry_index_by_id = [_]u8{\n");
    for (definitions.first_id..definitions.last_id + 1, 0..) |id, offset| {
        var index: u8 = 0;
        for (definitions.entries[0..definitions.len], 0..) |entry, entry_index| {
            if (entry.id == id) {
                index = @intCast(entry_index + 1);
                break;
            }
        }
        try writer.print("    {d}{s}\n", .{
            index,
            if (offset + 1 == definitions.last_id - definitions.first_id + 1) "" else ",",
        });
    }
    try writer.writeAll(
        \\};
        \\
        \\const client_report_index_by_entry = [_]u8{
    );
    for (definitions.entries[0..definitions.len], 0..) |_, entry_index| {
        var report_index: u8 = std.math.maxInt(u8);
        for (definitions.client_reports[0..definitions.client_report_count], 0..) |report, index| {
            if (report.entry_index != entry_index)
                continue;
            report_index = @intCast(index);
            break;
        }
        try writer.print("    {d}{s}\n", .{
            report_index,
            if (entry_index + 1 == definitions.len) "" else ",",
        });
    }
    try writer.writeAll(
        \\};
        \\
        \\pub fn index(id: u32) ?u8 {
        \\    if (id < first_entry_id)
        \\        return null;
        \\    const offset = id - first_entry_id;
        \\    if (offset >= entry_index_by_id.len)
        \\        return null;
        \\    const encoded = entry_index_by_id[offset];
        \\
        \\    return if (encoded == 0) null else encoded - 1;
        \\}
        \\
        \\pub fn clientReportIndex(id: u32) ?u8 {
        \\    const entry_index = index(id) orelse return null;
        \\    const report_index = client_report_index_by_entry[entry_index];
        \\
        \\    return if (report_index == 255) null else report_index;
        \\}
        \\
        \\pub fn collectionEntries(group: CollectionGroup) []const Entry {
        \\    return entries[group.first..][0..group.count];
        \\}
        \\
        \\pub fn entry(entry_index: u8) Entry {
        \\    return entries[entry_index];
        \\}
        \\
        \\pub fn get(id: u32) ?Entry {
        \\    const entry_index = index(id) orelse return null;
        \\    return entries[entry_index];
        \\}
    );
}

fn writeEnumDeclaration(writer: *Io.Writer, comptime name: []const u8, comptime T: type) !void {
    const info = @typeInfo(T).@"enum";
    try writer.print("pub const {s} = enum({s}) {{\n", .{ name, typeName(info.tag_type) });
    inline for (info.fields) |field|
        try writer.print("    {s},\n", .{field.name});
    try writer.writeAll("};\n\n");
}

fn writeStructDeclaration(writer: *Io.Writer, comptime name: []const u8, comptime T: type) !void {
    const info = @typeInfo(T).@"struct";
    try writer.print("pub const {s} = struct {{\n", .{name});
    inline for (info.fields) |field|
        try writer.print("    {s}: {s},\n", .{ field.name, typeName(field.type) });
    try writer.writeAll("};\n\n");
}

fn typeName(comptime T: type) []const u8 {
    const full_name = @typeName(T);
    return full_name[(std.mem.lastIndexOfScalar(u8, full_name, '.') orelse
        return full_name) + 1 ..];
}

fn writeEntry(writer: *Io.Writer, entry: Entry) !void {
    try writer.print(
        "    .{{ .id = {d}, .target = {d}, .reward_id = {d}, .reward_quantity = {d} }},\n",
        .{ entry.id, entry.target, entry.reward_id, entry.reward_quantity },
    );
}

fn writeClientReport(writer: *Io.Writer, report: ClientReport) !void {
    try writer.print(
        "    .{{ .entry_index = {d}, .kind = .{s}, .client_condition = {d}, .parameters = &.{{",
        .{ report.entry_index, @tagName(report.kind), report.client_condition },
    );
    for (report.parameters, 0..) |parameter, index| {
        try writer.print("{d}{s}", .{
            parameter,
            if (index + 1 == report.parameters.len) "" else ", ",
        });
    }
    try writer.writeAll("}},\n");
}

fn buildDefinitions(
    chains: [kind_count]Chain,
    progressions: DiscoveredProgressions,
    client_reports: DiscoveredClientReports,
) Definitions {
    var result: Definitions = .{};

    inline for (std.enums.values(CollectionKind)) |kind| {
        const first: u8 = @intCast(result.len);
        const chain = chains[@intFromEnum(kind)];
        for (chain.indices[0..chain.len]) |index|
            _ = result.append(entries[index]);
        result.collection_groups[@intFromEnum(kind)] = .{
            .kind = kind,
            .first = first,
            .count = @intCast(chain.len),
        };
    }

    result.collection_count = result.len;

    for (progressions.values[0..progressions.len]) |progression| {
        result.progressions[result.progression_count] = .{
            .entry_index = result.append(entries[progression.source_index]),
            .kind = progression.kind,
            .minimum_level = progression.minimum_level,
            .element = progression.element,
        };
        result.progression_count += 1;
    }

    for (client_reports.values[0..client_reports.len]) |report| {
        result.client_reports[result.client_report_count] = .{
            .entry_index = result.append(entries[report.source_index]),
            .kind = report.kind,
            .client_condition = report.client_condition,
            .parameters = report.parameters,
        };
        result.client_report_count += 1;
    }

    if (result.last_id - result.first_id + 1 > result.len * 4)
        @compileError("tracked achievement IDs are too sparse for a dense lookup table");

    return result;
}

fn discoverChains() [kind_count]Chain {
    @setEvalBranchQuota(1_000_000);

    var roots: [kind_count]?usize = @splat(null);
    var candidates: [entries.len]bool = @splat(false);
    var candidate_count: usize = 0;

    for (entries, 0..) |entry, index| {
        if (!isCollectionEntry(entry))
            continue;
        candidates[index] = true;
        candidate_count += 1;

        if (entry.prerequisite != null)
            continue;

        const kind = rootKind(entry.condition, entry.target) orelse
            @compileError("unknown collection achievement root; update build/assets/achievement.zig");
        if (roots[@intFromEnum(kind)] != null)
            @compileError("duplicate collection achievement root");
        roots[@intFromEnum(kind)] = index;
    }

    var chains: [kind_count]Chain = @splat(.{});
    var visited: [entries.len]bool = @splat(false);

    for (std.enums.values(CollectionKind)) |kind| {
        var current = roots[@intFromEnum(kind)] orelse
            @compileError("missing collection achievement chain");
        while (true) {
            if (visited[current])
                @compileError("collection achievement prerequisite cycle");
            visited[current] = true;
            chains[@intFromEnum(kind)].indices[chains[@intFromEnum(kind)].len] = current;
            chains[@intFromEnum(kind)].len += 1;

            const id = entries[current].id;
            var successor: ?usize = null;
            for (entries, 0..) |entry, index| {
                if (!candidates[index] or entry.prerequisite == null)
                    continue;
                if (entry.prerequisite.? != id)
                    continue;
                if (successor != null)
                    @compileError("collection achievement chain branches");
                successor = index;
            }
            current = successor orelse
                break;
        }
    }

    var visited_count: usize = 0;
    for (candidates, visited) |candidate, was_visited| {
        if (!candidate)
            continue;
        if (!was_visited)
            @compileError("collection achievement is disconnected from its root");
        visited_count += 1;
    }
    if (visited_count != candidate_count)
        @compileError("collection achievement discovery lost an entry");

    return chains;
}

fn isCollectionEntry(entry: Raw) bool {
    return entry.achievement_type == 4 and switch (entry.condition) {
        20, 29 => true,
        else => false,
    };
}

fn rootKind(condition: u32, target: u32) ?CollectionKind {
    return switch (condition) {
        29 => switch (target) {
            10 => .all_discs,
            5 => .five_star_discs,
            else => null,
        },
        20 => switch (target) {
            10 => .all_trekkers,
            5 => .five_star_trekkers,
            else => null,
        },
        else => null,
    };
}

fn discoverProgressions() DiscoveredProgressions {
    var result: DiscoveredProgressions = .{};
    for (entries, 0..) |entry, index| {
        if (entry.achievement_type != 4)
            continue;
        const progression = progressionFor(entry) orelse
            continue;
        result.append(.{
            .source_index = index,
            .kind = progression.kind,
            .minimum_level = progression.minimum_level,
            .element = progression.element,
        });
    }

    return result;
}

fn discoverClientReports() DiscoveredClientReports {
    var result: DiscoveredClientReports = .{};
    for (entries, 0..) |entry, index| {
        if (entry.condition != 200)
            continue;
        if (entry.client_condition == 0)
            @compileError(std.fmt.comptimePrint(
                "achievement {d} is a client report but has no client condition",
                .{entry.id},
            ));

        const kind: ClientReportKind = switch (entry.client_condition) {
            5 => .skill_cast,
            10 => .elemental_mark,
            11 => .single_attack_damage,
            12 => .low_hp_clear,
            14 => .enemy_type_counter,
            else => if (entry.client_condition >= 1_000_000)
                .specific_battle_condition
            else
                @compileError(std.fmt.comptimePrint(
                    "unknown client achievement condition {d} for achievement {d}",
                    .{ entry.client_condition, entry.id },
                )),
        };

        const requires_parameter = kind != .specific_battle_condition;
        if (requires_parameter and entry.client_parameters.len == 0)
            @compileError(std.fmt.comptimePrint(
                "client achievement {d} is missing its client parameter",
                .{entry.id},
            ));
        if (!requires_parameter and entry.client_parameters.len != 0)
            @compileError(std.fmt.comptimePrint(
                "specific client achievement {d} unexpectedly has a parameter",
                .{entry.id},
            ));

        result.append(.{
            .source_index = index,
            .kind = kind,
            .client_condition = entry.client_condition,
            .parameters = entry.client_parameters,
        });
    }

    return result;
}

fn progressionFor(entry: Raw) ?struct {
    kind: ProgressKind,
    minimum_level: u8 = 0,
    element: u8 = 0,
} {
    return switch (entry.condition) {
        7 => .{ .kind = .advance_total },
        16 => .{
            .kind = .character_level,
            .minimum_level = levelMilestone(entry.achievement_id, 403),
        },
        17 => .{
            .kind = .element_level,
            .minimum_level = levelMilestone(entry.achievement_id, null),
            .element = elementMilestone(entry.achievement_id),
        },
        60 => .{
            .kind = .skill_level,
            .minimum_level = skillMilestone(entry.achievement_id),
        },
        34 => blk: {
            if (entry.achievement_id / 100 != 402)
                @compileError("unexpected Runic Disc tier achievement group");
            break :blk .{ .kind = .disc_tier_total };
        },
        36 => blk: {
            if (entry.achievement_id / 100 != 410)
                @compileError("unexpected Runic Disc level achievement group");
            break :blk .{
                .kind = .disc_level,
                .minimum_level = levelMilestone(entry.achievement_id, 410),
            };
        },
        else => null,
    };
}

fn levelMilestone(achievement_id: u32, expected_group: ?u32) u8 {
    const group = achievement_id / 100;
    if (expected_group) |value| {
        if (group != value)
            @compileError("unexpected character-level achievement group");
    } else if (group < 404 or group > 409) {
        @compileError("unexpected element-level achievement group");
    }

    return switch (achievement_id % 100) {
        1 => 20,
        2 => 30,
        3 => 50,
        4...9 => 90,
        else => @compileError("unexpected character-level achievement milestone"),
    };
}

fn elementMilestone(achievement_id: u32) u8 {
    const group = achievement_id / 100;
    if (group < 404 or group > 409)
        @compileError("unexpected element-level achievement group");

    return @intCast(group - 403);
}

fn skillMilestone(achievement_id: u32) u8 {
    if (achievement_id / 100 != 416)
        @compileError("unexpected character-skill achievement group");

    return switch (achievement_id % 100) {
        1...3 => 4,
        4...6 => 7,
        else => @compileError("unexpected character-skill achievement milestone"),
    };
}
