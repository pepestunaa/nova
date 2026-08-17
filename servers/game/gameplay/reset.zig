/// Daily reset occurs at 04:00 UTC+8, or 20:00 UTC.
pub const daily_reset_seconds = 20 * 60 * 60;
pub const seconds_per_day = 24 * 60 * 60;

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
