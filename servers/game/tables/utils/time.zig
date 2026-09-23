const std = @import("std");

const seconds_per_minute = 60;
const seconds_per_hour = 60 * seconds_per_minute;
const seconds_per_day = 24 * seconds_per_hour;

/// Parses a compile-time ISO timestamp with a numeric timezone offset.
pub fn parseTime(comptime text: []const u8) i64 {
    if (text.len != 25 or
        text[4] != '-' or
        text[7] != '-' or
        text[10] != 'T' or
        text[13] != ':' or
        text[16] != ':' or
        (text[19] != '+' and text[19] != '-') or
        text[22] != ':')
        @compileError("unsupported timestamp: " ++ text);

    const year = parseI64(text[0..4]);
    const month = parseI64(text[5..7]);
    const day = parseI64(text[8..10]);
    const hour = parseI64(text[11..13]);
    const minute = parseI64(text[14..16]);
    const second = parseI64(text[17..19]);
    const offset_hour = parseI64(text[20..22]);
    const offset_minute = parseI64(text[23..25]);

    if (month < 1 or month > 12 or
        day < 1 or day > daysInMonth(year, month) or
        hour < 0 or hour > 23 or
        minute < 0 or minute > 59 or
        second < 0 or second > 59 or
        offset_hour < 0 or offset_hour > 23 or
        offset_minute < 0 or offset_minute > 59)
        @panic("invalid timestamp");

    const offset = offset_hour * seconds_per_hour + offset_minute * seconds_per_minute;
    return daysFromCivil(year, month, day) * seconds_per_day +
        hour * seconds_per_hour + minute * seconds_per_minute + second +
        if (text[19] == '+') -offset else offset;
}

/// Returns days since 1970-01-01 using Howard Hinnant's civil-date algorithm.
pub fn daysFromCivil(year: i64, month: i64, day: i64) i64 {
    const adjusted_year = year - @intFromBool(month <= 2);
    const era = @divFloor(adjusted_year, 400);
    const year_of_era = adjusted_year - era * 400;
    const march_month = month + (if (month > 2) @as(i64, -3) else 9);
    const day_of_year = @divFloor(153 * march_month + 2, 5) + day - 1;
    const day_of_era = year_of_era * 365 + @divFloor(year_of_era, 4) -
        @divFloor(year_of_era, 100) + day_of_year;

    return era * 146_097 + day_of_era - 719_468;
}

fn parseI64(comptime text: []const u8) i64 {
    var result: i64 = 0;
    inline for (text) |byte| {
        if (byte < '0' or byte > '9')
            @compileError("invalid timestamp number: " ++ text);
        result = result * 10 + @as(i64, byte - '0');
    }
    return result;
}

fn daysInMonth(year: i64, month: i64) i64 {
    return switch (month) {
        2 => if (@mod(year, 4) == 0 and (@mod(year, 100) != 0 or @mod(year, 400) == 0)) 29 else 28,
        4, 6, 9, 11 => 30,
        else => 31,
    };
}

test "parseTime converts numeric timezone offsets" {
    try std.testing.expectEqual(@as(i64, 0), parseTime("1970-01-01T00:00:00+00:00"));
    try std.testing.expectEqual(@as(i64, 0), parseTime("1970-01-01T08:00:00+08:00"));
    try std.testing.expectEqual(@as(i64, 0), parseTime("1969-12-31T19:00:00-05:00"));
}
