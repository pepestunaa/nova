const raw_list = @import("tables/SubNoteSkill");

const count: usize = raw_list.len;

//

const max_scores = blk: {
    var result: usize = 0;
    for (raw_list) |entry| result = @max(result, entry.scores.len);

    break :blk result;
};

pub const Entry = struct {
    id: u32,
    scores: [max_scores]u32,
    score_count: usize,
};

pub const list: [count]Entry = blk: {
    @setEvalBranchQuota(10_000);

    var result: [count]Entry = undefined;
    for (raw_list, 0..) |raw, entry_index| {
        var scores: [max_scores]u32 = @splat(0);
        for (raw.scores, 0..) |entry_score, score_index|
            scores[score_index] = entry_score;
        result[entry_index] = .{
            .id = raw.id,
            .scores = scores,
            .score_count = raw.scores.len,
        };
    }

    break :blk result;
};

pub fn contains(id: u32) bool {
    for (list) |entry|
        if (entry.id == id)
            return true;
    return false;
}
