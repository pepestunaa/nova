const std = @import("std");

const generated = @import("generated/assets/research_project");

const raw_quests = @import("tables/StarTowerQuest");

//

pub const max_required_nodes = generated.max_required_nodes;
pub const max_prerequisites = 3;

pub const Kind = enum(u8) {
    core = 1,
    normal = 2,
};

/// A server-tracked value used by a normal Research Project task.
pub const Condition = generated.Condition;

pub const Reward = struct {
    item_id: u32,
    quantity: i32,
};

pub const Definition = struct {
    id: u32,
    kind: Kind,
    condition: Condition,
    condition_param: u32,
    target: u32,
    rewards: [2]Reward,
    required_nodes: [max_required_nodes]u32,
    required_node_count: u8,
    prerequisites: [max_prerequisites]u32,
    prerequisite_count: u8,
};

pub const list = build();

pub fn get(id: u32) ?*const Definition {
    for (&list) |*definition| if (definition.id == id) return definition;
    return null;
}

fn build() [raw_quests.len]Definition {
    if (raw_quests.len != generated.quests.len)
        @compileError(std.fmt.comptimePrint(
            "StarTowerQuest has {d} entries, but the generated Research Project asset has {d}; run `zig build generate-assets -- research_project`",
            .{ raw_quests.len, generated.quests.len },
        ));

    var result: [raw_quests.len]Definition = undefined;
    for (raw_quests, 0..) |raw, index| {
        const generated_quest = generated.quests[index];
        if (generated_quest.id != raw.id)
            @compileError("StarTowerQuest does not match the generated Research Project asset; run `zig build generate-assets -- research_project`");
        const kind: Kind = @enumFromInt(raw.tower_quest_type);
        const prerequisites = prerequisitesFor(raw);
        result[index] = .{
            .id = raw.id,
            .kind = kind,
            .condition = generated_quest.condition,
            .condition_param = generated_quest.parameter,
            .target = generated_quest.target,
            .rewards = .{
                .{ .item_id = raw.reward1, .quantity = @intCast(raw.reward_qty1) },
                .{ .item_id = raw.reward2, .quantity = @intCast(raw.reward_qty2) },
            },
            .required_nodes = generated_quest.required_nodes,
            .required_node_count = generated_quest.required_node_count,
            .prerequisites = prerequisites.ids,
            .prerequisite_count = prerequisites.count,
        };
    }

    return result;
}

const IdList = struct {
    ids: [max_prerequisites]u32 = @splat(0),
    count: u8 = 0,
};

fn prerequisitesFor(comptime raw: anytype) IdList {
    var result: IdList = .{};
    if (!@hasField(@TypeOf(raw), "pre_tower_quest_ids"))
        return result;

    inline for (@typeInfo(@TypeOf(raw.pre_tower_quest_ids)).@"struct".fields) |field| {
        if (result.count == result.ids.len)
            @compileError("StarTowerQuest has more prerequisites than Research Project supports");
        result.ids[result.count] = @field(raw.pre_tower_quest_ids, field.name);
        result.count += 1;
    }
    return result;
}
