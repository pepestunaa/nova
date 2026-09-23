const std = @import("std");

const comptime_utils = @import("utils/comptime.zig");
const localization = @import("utils/localization.zig");
const lookup = @import("lookup.zig");
const progression = @import("character_progression.zig");

const raw_list = @import("tables/Character");
const text = @import("tables/lang/Character");

//

pub const max_level = progression.max_level;
pub const max_exp = progression.max_exp;
pub const max_advance = progression.max_advance;
pub const max_affinity_level = progression.max_affinity_level;
pub const max_affinity_exp = progression.max_affinity_exp;
pub const max_skill_level = progression.max_skill_level;

pub const count: usize = raw_list.len;

pub const Index = enum(u8) {
    _,

    pub fn fromId(value: u32) ?Index {
        return @enumFromInt(indexOf(value) orelse return null);
    }

    pub fn id(index: Index) u32 {
        return ids[@intFromEnum(index)];
    }

    pub fn gemSlots(index: Index) [3]u32 {
        return gem_slots[@intFromEnum(index)];
    }
};

pub const Element = enum(u8) {
    aqua = 1,
    ignis = 2,
    terra = 3,
    ventus = 4,
    lux = 5,
    umbra = 6,
};

pub const Grade = enum(u8) {
    five_star = 1,
    four_star = 2,
};

const by_id = lookup.Lookup(u32, &ids);

pub fn indexOf(id: u32) ?usize {
    return by_id.find(id);
}

pub fn gemSlots(id: u32) ?[3]u32 {
    return (Index.fromId(id) orelse
        return null).gemSlots();
}

const gem_slots: [count][3]u32 = blk: {
    var result: [count][3]u32 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = entry.gem_slots;

    break :blk result;
};

const ids: [count]u32 = blk: {
    var result: [count]u32 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = entry.id;

    break :blk result;
};

pub const Id = blk: {
    @setEvalBranchQuota(10_000);

    var field_names: [count][:0]const u8 = undefined;
    var field_values: [count]u16 = undefined;
    var name_storage: [count][max_enum_name_length + 1]u8 = undefined;

    for (raw_list, 0..) |raw, index| {
        const id = std.math.cast(u16, raw.id) orelse
            @compileError("character ID exceeds u16");

        field_values[index] = id;
        field_names[index] = comptime_utils.enumFieldName(
            &name_storage[index],
            localization.get(text, raw.name),
            id,
            field_names[0..index],
        );
    }

    break :blk @Enum(
        u16,
        .exhaustive,
        &field_names,
        &field_values,
    );
};

pub fn element(id: u32) ?Element {
    const row = by_id.find(id) orelse return null;
    return std.enums.fromInt(Element, elements[row]);
}

pub fn grade(id: u32) ?Grade {
    const row = by_id.find(id) orelse return null;
    return std.enums.fromInt(Grade, grades[row]);
}

pub fn fragmentsId(id: u32) ?u32 {
    const row = by_id.find(id) orelse return null;
    return fragment_ids[row];
}

pub fn transformQuantity(id: u32) ?i32 {
    const row = by_id.find(id) orelse return null;
    return transform_quantities[row];
}

const elements = column(u8, "eet");
const grades = column(u8, "grade");
const fragment_ids = column(u32, "fragments_id");
const transform_quantities = column(i32, "transform_qty");

fn column(comptime Value: type, comptime field: []const u8) [count]Value {
    @setEvalBranchQuota(100 * count + 1000);

    var result: [count]Value = undefined;
    for (raw_list, 0..) |raw, index| result[index] = @field(raw, field);

    return result;
}

const max_enum_name_length = blk: {
    @setEvalBranchQuota(10_000);

    var longest: usize = 0;
    for (raw_list) |raw|
        longest = @max(longest, localization.get(text, raw.name).len);

    break :blk longest + 1 + 5;
};
