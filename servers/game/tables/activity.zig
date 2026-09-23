const raw_list = @import("tables/Activity");
const time = @import("utils/time.zig");

//

pub const Entry = struct {
    id: u32,
    type: u8,
    start_at: i64,
    end_at: i64,
    permanent: bool,
};

pub const list: [entry_count]Entry = blk: {
    @setEvalBranchQuota(1_000_000);

    var entries: [entry_count]Entry = undefined;
    var index: usize = 0;
    for (raw_list) |raw| {
        switch (raw.start_type) {
            1 => entries[index] = .{
                .id = raw.id,
                .type = raw.activity_type,
                .start_at = 0,
                .end_at = if (@hasField(@TypeOf(raw), "end_time")) time.parseTime(raw.end_time) else -1,
                .permanent = true,
            },
            2 => {
                if (!@hasField(@TypeOf(raw), "start_time"))
                    @compileError("timed activity is missing start_time");

                entries[index] = .{
                    .id = raw.id,
                    .type = raw.activity_type,
                    .start_at = time.parseTime(raw.start_time),
                    .end_at = if (@hasField(@TypeOf(raw), "end_time")) time.parseTime(raw.end_time) else -1,
                    .permanent = false,
                };
            },
            else => continue,
        }
        index += 1;
    }

    break :blk entries;
};

const entry_count = blk: {
    var count: usize = 0;
    for (raw_list) |raw| {
        if (raw.start_type == 1 or raw.start_type == 2) count += 1;
    }

    break :blk count;
};
