const PlayerCache = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Player = @import("Player.zig");
const Save = @import("player/Save.zig");

//

/// Idle entries are cleaned up when a new IKE session begins.
const idle_retention_seconds: i64 = 300;
const max_evictions_per_sweep = 8;

lock: Io.Mutex = .init,
entries: std.AutoHashMapUnmanaged(u64, *Entry) = .empty,

pub const Entry = struct {
    uid: u64,
    lock: Io.Mutex = .init,
    active_requests: usize = 0,
    last_used: i64,
    valid: bool = true,
    player: Player,
};

pub const AcquireError = Save.LoadError;

/// Returns a locked entry that must later be passed to `release`.
pub fn acquire(
    cache: *PlayerCache,
    gpa: Allocator,
    io: Io,
    uid: u64,
) AcquireError!*Entry {
    cache.lock.lockUncancelable(io);
    if (cache.pinLocked(uid, Io.Timestamp.now(io, .real).toSeconds())) |entry| {
        cache.lock.unlock(io);
        entry.lock.lockUncancelable(io);

        return cache.validateAcquired(gpa, io, entry);
    }
    cache.lock.unlock(io);

    const loaded = try Save.load(gpa, io, uid) orelse Player.init(uid);
    const candidate = gpa.create(Entry) catch |err| {
        var player = loaded;
        player.deinit(gpa);

        return err;
    };
    candidate.* = .{
        .uid = uid,
        .last_used = Io.Timestamp.now(io, .real).toSeconds(),
        .player = loaded,
    };

    cache.lock.lockUncancelable(io);
    if (cache.pinLocked(uid, candidate.last_used)) |entry| {
        cache.lock.unlock(io);
        candidate.player.deinit(gpa);
        gpa.destroy(candidate);
        entry.lock.lockUncancelable(io);

        return cache.validateAcquired(gpa, io, entry);
    }

    cache.entries.put(gpa, uid, candidate) catch |err| {
        cache.lock.unlock(io);
        candidate.player.deinit(gpa);
        gpa.destroy(candidate);

        return err;
    };
    candidate.active_requests = 1;
    cache.lock.unlock(io);
    candidate.lock.lockUncancelable(io);

    return candidate;
}

/// Unlocks an acquired entry and makes it eligible for idle cleanup.
pub fn release(cache: *PlayerCache, gpa: Allocator, io: Io, entry: *Entry) void {
    entry.lock.unlock(io);

    cache.lock.lockUncancelable(io);
    std.debug.assert(entry.active_requests != 0);
    entry.active_requests -= 1;
    entry.last_used = Io.Timestamp.now(io, .real).toSeconds();

    const evict = !entry.valid and entry.active_requests == 0;
    if (evict)
        std.debug.assert(cache.entries.remove(entry.uid));
    cache.lock.unlock(io);

    if (evict) {
        entry.player.deinit(gpa);
        gpa.destroy(entry);
    }
}

/// Reloads a locked entry from disk, discarding changes from a request that
/// failed before saving.
pub fn rollback(cache: *PlayerCache, gpa: Allocator, io: Io, entry: *Entry) void {
    _ = cache;

    const restored = Save.load(gpa, io, entry.uid) catch |err| {
        std.log.err("failed to discard uncommitted player {d} state: {t}", .{
            entry.uid,
            err,
        });

        entry.valid = false;

        return;
    } orelse Player.init(entry.uid);

    entry.player.deinit(gpa);
    entry.player = restored;
    entry.valid = true;
}

/// Drops idle entries with no users. This runs after new IKE handshakes rather
/// than scanning the cache on every request.
pub fn sweep(cache: *PlayerCache, gpa: Allocator, io: Io, now: i64) void {
    cache.lock.lockUncancelable(io);
    defer cache.lock.unlock(io);

    var evicted: usize = 0;
    while (evicted != max_evictions_per_sweep) : (evicted += 1) {
        const uid = findIdleUidLocked(cache, now) orelse
            return;
        const entry = cache.entries.get(uid).?;
        std.debug.assert(cache.entries.remove(uid));
        entry.player.deinit(gpa);
        gpa.destroy(entry);
    }
}

pub fn deinit(cache: *PlayerCache, gpa: Allocator) void {
    var iterator = cache.entries.valueIterator();
    while (iterator.next()) |entry_ptr| {
        const entry = entry_ptr.*;
        std.debug.assert(entry.active_requests == 0);
        entry.player.deinit(gpa);
        gpa.destroy(entry);
    }
    cache.entries.deinit(gpa);
}

fn pinLocked(cache: *PlayerCache, uid: u64, now: i64) ?*Entry {
    const entry = cache.entries.get(uid) orelse
        return null;
    entry.active_requests += 1;
    entry.last_used = now;

    return entry;
}

fn validateAcquired(
    cache: *PlayerCache,
    gpa: Allocator,
    io: Io,
    entry: *Entry,
) AcquireError!*Entry {
    if (entry.valid)
        return entry;

    cache.release(gpa, io, entry);

    return error.Corrupted;
}

fn findIdleUidLocked(cache: *const PlayerCache, now: i64) ?u64 {
    var iterator = cache.entries.iterator();
    while (iterator.next()) |map_entry| {
        const entry = map_entry.value_ptr.*;
        if (entry.active_requests == 0 and
            now -| entry.last_used > idle_retention_seconds)
            return map_entry.key_ptr.*;
    }

    return null;
}
