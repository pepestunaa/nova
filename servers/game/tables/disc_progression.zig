const std = @import("std");

const config = @import("config.zig");

const raw_promote_limits = @import("tables/DiscPromoteLimit");
const raw_strengthen = @import("tables/DiscStrengthen");

//

pub const max_level = maxStringField(raw_promote_limits, "max_level");
pub const max_phase = maxStringField(raw_promote_limits, "phase");
pub const max_exp = maxOptionalField(raw_strengthen, "exp");
pub const max_star = maxConfigValue("DiscRarityLimitBreakMax");

fn maxStringField(comptime list: anytype, comptime name: []const u8) u32 {
    @setEvalBranchQuota(1_000_000);

    var maximum: u32 = 0;
    inline for (list) |entry| {
        const value = std.fmt.parseInt(u32, @field(entry, name), 10) catch
            @compileError("invalid Disc progression value");
        maximum = @max(maximum, value);
    }

    return maximum;
}

fn maxOptionalField(comptime list: anytype, comptime name: []const u8) u32 {
    @setEvalBranchQuota(1_000_000);

    var maximum: u32 = 0;
    inline for (list) |entry| {
        if (@hasField(@TypeOf(entry), name))
            maximum = @max(maximum, @field(entry, name));
    }

    return maximum;
}

fn maxConfigValue(comptime id: []const u8) u32 {
    var maximum: u32 = 0;
    inline for (config.unsignedList(u32, id)) |value|
        maximum = @max(maximum, value);

    return maximum;
}
