const raw_list = @import("tables/Activity");

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
                .end_at = if (@hasField(@TypeOf(raw), "end_time")) parseTime(raw.end_time) else -1,
                .permanent = true,
            },
            2 => {
                if (!@hasField(@TypeOf(raw), "start_time"))
                    @compileError("timed activity is missing start_time");

                entries[index] = .{
                    .id = raw.id,
                    .type = raw.activity_type,
                    .start_at = parseTime(raw.start_time),
                    .end_at = if (@hasField(@TypeOf(raw), "end_time")) parseTime(raw.end_time) else -1,
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

/// Parses the table's `YYYY-MM-DDTHH:MM:SS+08:00` timestamps at compile time.
fn parseTime(comptime text: []const u8) i64 {
    if (text.len != 25 or text[10] != 'T' or text[19] != '+' or text[22] != ':')
        @compileError("unsupported Activity timestamp: " ++ text);

    const year = digits(text[0..4]);
    const month = digits(text[5..7]);
    const day = digits(text[8..10]);
    const hour = digits(text[11..13]);
    const minute = digits(text[14..16]);
    const second = digits(text[17..19]);
    const offset_hour = digits(text[20..22]);
    const offset_minute = digits(text[23..25]);

    return daysFromCivil(year, month, day) * seconds_per_day +
        hour * seconds_per_hour + minute * seconds_per_minute + second -
        offset_hour * seconds_per_hour - offset_minute * seconds_per_minute;
}

fn digits(comptime text: []const u8) i64 {
    var result: i64 = 0;
    for (text) |byte| {
        if (byte < '0' or byte > '9') @compileError("expected decimal digit");
        result = result * 10 + byte - '0';
    }

    return result;
}

/// Returns days since 1970-01-01 using Howard Hinnant's civil-date algorithm.
fn daysFromCivil(year: i64, month: i64, day: i64) i64 {
    const adjusted_year = year - @intFromBool(month <= 2);
    const era = @divFloor(adjusted_year, 400);
    const year_of_era = adjusted_year - era * 400;
    const march_month = month + (if (month > 2) -3 else 9);
    const day_of_year = @divFloor(153 * march_month + 2, 5) + day - 1;
    const day_of_era = year_of_era * 365 + @divFloor(year_of_era, 4) - @divFloor(year_of_era, 100) + day_of_year;

    return era * 146_097 + day_of_era - 719_468;
}

const seconds_per_minute = 60;
const seconds_per_hour = 60 * seconds_per_minute;
const seconds_per_day = 24 * seconds_per_hour;
