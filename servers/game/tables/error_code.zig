const localization = @import("utils/localization.zig");
const lookup = @import("lookup.zig");

pub const Code = @import("error_code_generated").Code;

const raw_list = @import("tables/ErrorCode");
const text = @import("tables/lang/ErrorCode");

const count: usize = raw_list.len;

//

const by_id = lookup.Lookup(i64, lookup.fieldKeys(i64, raw_list, "id"));

const messages: [count][]const u8 = blk: {
    @setEvalBranchQuota(100 * count + 1000);

    var result: [count][]const u8 = undefined;
    for (raw_list, 0..) |entry, index| result[index] = localization.get(text, entry.template);

    break :blk result;
};

pub fn message(code: Code) []const u8 {
    const row = by_id.find(@intFromEnum(code)) orelse return "";
    return messages[row];
}
