const std = @import("std");

/// Daily reset occurs at 04:00 UTC+8, or 20:00 UTC.
pub const daily_reset_seconds = 20 * 60 * 60;
pub const seconds_per_day = 24 * 60 * 60;
const seconds_until_reset_day = seconds_per_day - daily_reset_seconds;

pub fn nextDaily(now: i64) i64 {
    const day_start = now - @mod(now, seconds_per_day);
    const today_reset = day_start + daily_reset_seconds;

    return if (now < today_reset) today_reset else today_reset + seconds_per_day;
}

pub fn nextWeekly(now: i64) i64 {
    const day_start = now - @mod(now, seconds_per_day);
    const weekday: i64 = @mod(@divFloor(day_start, seconds_per_day) + 4, 7);
    const days_until_monday = @mod(1 - weekday, 7);
    var reset = day_start + days_until_monday * seconds_per_day + daily_reset_seconds;
    if (now >= reset) reset += 7 * seconds_per_day;

    return reset;
}

pub fn dayIndex(now: i64) i64 {
    return @divFloor(now + seconds_until_reset_day, seconds_per_day);
}

pub fn nextMonthly(now: i64) i64 {
    const epoch = shiftedEpoch(now);
    const day = epoch.getEpochDay();
    const year_day = day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const days_remaining = std.time.epoch.getDaysInMonth(year_day.year, month_day.month) - month_day.day_index;
    return @intCast((day.day + days_remaining) * seconds_per_day - seconds_until_reset_day);
}

fn shiftedEpoch(now: i64) std.time.epoch.EpochSeconds {
    return .{ .secs = @intCast(now + seconds_until_reset_day) };
}
