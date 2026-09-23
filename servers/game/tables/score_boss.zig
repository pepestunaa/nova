const raw_controls = @import("tables/ScoreBossControl");
const time = @import("utils/time.zig");

//

pub const Control = struct {
    id: u32,
    start_at: i64,
    end_at: i64,
};

pub const list: [raw_controls.len]Control = blk: {
    @setEvalBranchQuota(100_000);

    var controls: [raw_controls.len]Control = undefined;
    for (raw_controls, 0..) |raw, index| controls[index] = .{
        .id = raw.id,
        .start_at = time.parseTime(raw.start_time),
        .end_at = time.parseTime(raw.end_time),
    };

    break :blk controls;
};

pub fn active(now: i64) ?Control {
    for (list) |control| {
        if (now >= control.start_at and now < control.end_at)
            return control;
    }

    return null;
}
