const localization = @import("localization.zig");
const lookup = @import("lookup.zig");

pub const Code = @import("error_code_generated").Code;

const raw_list = @import("tables/ErrorCode");
const text = @import("tables/lang/ErrorCode");

//

const by_id = lookup.Lookup(i64, lookup.fieldKeys(i64, raw_list, "id"));

const messages: [raw_list.len][]const u8 = blk: {
    @setEvalBranchQuota(100 * raw_list.len + 1000);

    var result: [raw_list.len][]const u8 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = localization.get(text, entry.template);

    break :blk result;
};

pub fn message(code: Code) []const u8 {
    const row = by_id.find(@intFromEnum(code)) orelse return "";
    return messages[row];
}
