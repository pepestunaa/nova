const Mutation = @import("mutation.zig");
const Player = @import("../store/Player.zig");

//

const maximum: u32 = @intFromEnum(Player.Basic.PrimaryEnergy.regeneration_max);
const gain_seconds: i64 = 4 * 60;

pub fn refresh(mutation: *Mutation, now: i64) bool {
    var basic = mutation.read().basic;
    if (!refreshBasic(&basic, now))
        return false;

    mutation.modify(.{ .player_progression = true }).basic = basic;
    return true;
}

fn refreshBasic(basic: *Player.Basic, now: i64) bool {
    if (basic.energy_next_at <= 0) {
        basic.energy_next_at = nextTick(now);

        return true;
    }

    const current_energy: u32 = @intFromEnum(basic.primary_energy);
    if (current_energy >= maximum) {
        const next_at = nextTick(now);

        if (basic.energy_next_at == next_at)
            return false;

        basic.energy_next_at = next_at;

        return true;
    }

    if (now < basic.energy_next_at)
        return false;

    const elapsed_ticks: u32 = @intCast(
        1 + @divFloor(now - basic.energy_next_at, gain_seconds),
    );
    const granted = @min(elapsed_ticks, maximum - current_energy);
    basic.primary_energy = @enumFromInt(current_energy + granted);
    basic.energy_updated_at = now;
    basic.energy_next_at = if (basic.primary_energy == .regeneration_max)
        nextTick(now)
    else
        basic.energy_next_at + @as(i64, granted) * gain_seconds;

    return true;
}

pub fn nextDuration(player: *const Player, now: i64) i64 {
    return @max(0, player.basic.energy_next_at - now);
}

pub fn nextTick(now: i64) i64 {
    return now - @mod(now, gain_seconds) + gain_seconds;
}
