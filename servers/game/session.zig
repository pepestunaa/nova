const Session = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

//

const config: @import("Config.zig") = @import("config");

pub const key_length = 32;
pub const nonce_length = 12;
pub const tag_length = 16;
pub const overhead = nonce_length + tag_length;

const expired_retention_seconds: i64 = 300;
const save_path = "store/session.bin";
const max_saved_sessions = 16 * 1024;

token: Token,
player_id: PlayerId,
key: Key,
last_seen: i64,
/// Set for the first request after restoring this session from disk.
restored: bool = false,

pub const Key = [key_length]u8;
pub const Nonce = [nonce_length]u8;

pub const Handshake = struct {
    key: Key,
    server_public_key: [65]u8,
    server_timestamp: i64,
};

pub const CryptoError = std.crypto.errors.EncodingError ||
    std.crypto.errors.NonCanonicalError ||
    std.crypto.errors.NotSquareError ||
    std.crypto.errors.IdentityElementError ||
    std.crypto.errors.AuthenticationError || error{
    InvalidPublicKey,
    PacketTooShort,
};

pub const Token = extern struct {
    pub const len = 16;

    bytes: [len]u8,

    pub fn random(io: Io) Token {
        var source: std.Random.IoSource = .{ .io = io };
        const rng = source.interface();
        var entropy: [12]u8 = undefined;
        rng.bytes(&entropy);

        var token: Token = undefined;

        std.debug.assert(std.base64.url_safe_no_pad.Encoder.calcSize(entropy.len) == token.bytes.len);

        _ = std.base64.url_safe_no_pad.Encoder.encode(&token.bytes, &entropy);

        return token;
    }

    pub fn fromSlice(bytes: []const u8) ?Token {
        if (bytes.len != len)
            return null;

        return .{ .bytes = bytes[0..len].* };
    }

    pub fn slice(token: *const Token) []const u8 {
        return &token.bytes;
    }
};

pub const PlayerId = enum(u64) {
    none = 0,
    _,

    pub fn fromInt(value: u64) PlayerId {
        std.debug.assert(value != 0);

        return @enumFromInt(value);
    }
};

pub fn beginHandshake(io: Io, client_public_key: []const u8) CryptoError!Handshake {
    if (client_public_key.len != 65)
        return error.InvalidPublicKey;

    const client_point = try std.crypto.ecc.P256.fromSec1(client_public_key);
    try client_point.rejectIdentity();

    const private_key = std.crypto.ecc.P256.scalar.random(io, .big);
    const public_key = (try std.crypto.ecc.P256.basePoint.mul(
        private_key,
        .big,
    )).toUncompressedSec1();
    const shared_point = try client_point.mul(private_key, .big);
    const shared_secret = shared_point.affineCoordinates().x.toBytes(.big);

    var info: [65]u8 = undefined;
    for (&info, client_public_key, &public_key) |*out, client_byte, server_byte| {
        const shifted = if (client_byte > server_byte)
            server_byte << 1
        else
            server_byte >> 1;
        out.* = shifted ^ client_byte;
    }

    const ikm = shared_secret;
    const prk = std.crypto.kdf.hkdf.HkdfSha256.extract(&public_key, &ikm);
    var key: Key = undefined;
    std.crypto.kdf.hkdf.HkdfSha256.expand(&key, &info, prk);

    return .{
        .key = key,
        .server_public_key = public_key,
        .server_timestamp = Io.Timestamp.now(io, .real).toSeconds(),
    };
}

/// Decrypts an AES-GCM packet sent after IKE.
pub fn decrypt(output: []u8, encrypted: []const u8, key: Key) CryptoError![]u8 {
    if (encrypted.len < overhead)
        return error.PacketTooShort;

    const nonce: Nonce = encrypted[0..nonce_length].*;
    const ciphertext = encrypted[nonce_length..][0 .. encrypted.len - overhead];
    const tag: [tag_length]u8 = encrypted[encrypted.len - tag_length ..][0..tag_length].*;
    const message = output[0..ciphertext.len];

    try std.crypto.aead.aes_gcm.Aes256Gcm.decrypt(message, ciphertext, tag, &nonce, nonce, key);

    return message;
}

/// Encrypts a post-IKE packet and prefixes its random nonce.
pub fn encrypt(io: Io, output: []u8, plaintext: []const u8, key: Key) CryptoError![]u8 {
    if (output.len < plaintext.len + overhead)
        return error.PacketTooShort;

    var nonce: Nonce = undefined;
    var source: std.Random.IoSource = .{ .io = io };
    source.interface().bytes(&nonce);
    @memcpy(output[0..nonce_length], &nonce);

    const ciphertext = output[nonce_length..][0..plaintext.len];
    const tag: *[tag_length]u8 = @ptrCast(output[nonce_length + plaintext.len ..].ptr);
    std.crypto.aead.aes_gcm.Aes256Gcm.encrypt(ciphertext, tag, plaintext, &nonce, nonce, key);

    return output[0 .. plaintext.len + overhead];
}

/// Reverses the client's byte transform, then decrypts the static IKE wrapper
/// with AES-256-GCM. The nonce is also the associated data.
pub fn decryptIke(output: []u8, encrypted: []u8, key: *const Key) CryptoError![]u8 {
    ungarble(encrypted, key);
    return decrypt(output, encrypted, key.*);
}

pub fn encryptIke(io: Io, output: []u8, plaintext: []const u8, key: *const Key) CryptoError![]u8 {
    const encrypted = try encrypt(io, output, plaintext, key.*);
    garble(encrypted, key);
    return encrypted;
}

fn garble(bytes: []u8, key: *const Key) void {
    const length: u8 = @truncate(bytes.len);
    for (bytes, 0..) |*byte, index| {
        byte.* ^= key[index % key.len];
        byte.* = std.math.rotl(u8, byte.*, 1);
        byte.* ^= length;
    }
}

fn ungarble(bytes: []u8, key: *const Key) void {
    const length: u8 = @truncate(bytes.len);
    for (bytes, 0..) |*byte, index| {
        byte.* ^= length;
        byte.* = std.math.rotr(u8, byte.*, 1);
        byte.* ^= key[index % key.len];
    }
}

pub const Store = struct {
    lock: Io.RwLock = .init,
    entries: std.MultiArrayList(Session) = .empty,
    token_map: std.array_hash_map.Auto(void, void) = .empty,

    const ByToken = struct {
        entries: std.MultiArrayList(Session).Slice,

        pub fn hash(_: ByToken, token: Token) u32 {
            return std.array_hash_map.hashString(token.slice());
        }

        pub fn eql(context: ByToken, token: Token, _: void, index: usize) bool {
            return std.mem.eql(
                u8,
                context.entries.items(.token)[index].slice(),
                token.slice(),
            );
        }
    };

    pub fn deinit(store: *Store, gpa: Allocator) void {
        store.entries.deinit(gpa);
        store.token_map.deinit(gpa);
    }

    /// Restores sessions saved during the previous graceful shutdown. Their
    /// X-Token and AES key are needed to answer the client's reconnect ping.
    pub fn load(store: *Store, io: Io, gpa: Allocator) (Allocator.Error || Io.Cancelable || error{
        Corrupted,
        InputOutput,
    })!usize {
        const file = Io.Dir.cwd().openFile(io, save_path, .{}) catch |err|
            return switch (err) {
                error.FileNotFound => 0,
                error.Canceled => |e| e,
                else => error.InputOutput,
            };

        {
            defer file.close(io);

            const file_size = std.math.cast(
                usize,
                file.length(io) catch
                    return error.InputOutput,
            ) orelse
                return error.Corrupted;
            if (file_size < @sizeOf(u64))
                return error.Corrupted;

            var reader_buffer: [1024]u8 = undefined;
            var file_reader = file.reader(io, &reader_buffer);
            const saved_count = file_reader.interface.takeInt(u64, .little) catch |err|
                return switch (err) {
                    error.ReadFailed => switch (file_reader.err.?) {
                        error.Canceled => |e| e,
                        else => error.InputOutput,
                    },
                    error.EndOfStream => error.Corrupted,
                };
            const len = std.math.cast(usize, saved_count) orelse
                return error.Corrupted;
            if (len > max_saved_sessions)
                return error.Corrupted;

            const bytes_per_session = @sizeOf(Token) + @sizeOf(Key) + @sizeOf(PlayerId) + @sizeOf(i64);
            const expected_size = std.math.add(
                usize,
                @sizeOf(u64),
                std.math.mul(usize, len, bytes_per_session) catch
                    return error.Corrupted,
            ) catch
                return error.Corrupted;
            if (file_size != expected_size)
                return error.Corrupted;

            try store.entries.ensureTotalCapacity(gpa, len);
            store.entries.len = len;
            errdefer {
                store.entries.len = 0;
                store.token_map.clearRetainingCapacity();
            }

            const entries = store.entries.slice();
            var fields = [_][]u8{
                std.mem.sliceAsBytes(entries.items(.token)),
                std.mem.sliceAsBytes(entries.items(.key)),
                std.mem.sliceAsBytes(entries.items(.player_id)),
                std.mem.sliceAsBytes(entries.items(.last_seen)),
            };
            file_reader.interface.readVecAll(&fields) catch |err|
                return switch (err) {
                    error.ReadFailed => switch (file_reader.err.?) {
                        error.Canceled => |e| e,
                        else => error.InputOutput,
                    },
                    error.EndOfStream => error.Corrupted,
                };
        }

        // A second login may finish without the old connection logging out.
        // Only the newest authenticated session is useful.
        discardDuplicatePlayers(&store.entries);

        const loaded_entries = store.entries.slice();
        @memset(loaded_entries.items(.restored), true);
        try store.token_map.ensureTotalCapacity(gpa, loaded_entries.len);
        for (loaded_entries.items(.token), 0..) |token, index| {
            const inserted = try store.token_map.getOrPutAdapted(
                gpa,
                token,
                ByToken{ .entries = loaded_entries },
            );
            if (inserted.found_existing or inserted.index != index)
                return error.Corrupted;
        }

        // Loading consumes the snapshot. The next graceful shutdown writes a
        // fresh one from the sessions still active.
        try discardSavedSnapshot(io);

        return store.entries.len;
    }

    /// Atomically saves every live session during graceful shutdown.
    pub fn save(store: *Store, io: Io) (Io.Cancelable || error{InputOutput})!void {
        const old_cancel_protection = io.swapCancelProtection(.blocked);
        defer _ = io.swapCancelProtection(old_cancel_protection);

        store.lock.lockUncancelable(io);
        defer store.lock.unlock(io);

        // Do not preserve sessions too old to receive an encrypted expiry
        // response in the next server process.
        store.sweepLocked(Io.Timestamp.now(io, .real).toSeconds());

        if (store.entries.len == 0) {
            Io.Dir.cwd().deleteFile(io, save_path) catch |err| switch (err) {
                error.FileNotFound => return,
                else => return error.InputOutput,
            };

            return;
        }

        var atomic_file = Io.Dir.cwd().createFileAtomic(io, save_path, .{
            .make_path = true,
            .replace = true,
        }) catch
            return error.InputOutput;
        defer atomic_file.deinit(io);

        const entries = store.entries.slice();
        const saved_count: u64 = @intCast(entries.len);
        var fields = [_][]const u8{
            std.mem.asBytes(&saved_count),
            std.mem.sliceAsBytes(entries.items(.token)),
            std.mem.sliceAsBytes(entries.items(.key)),
            std.mem.sliceAsBytes(entries.items(.player_id)),
            std.mem.sliceAsBytes(entries.items(.last_seen)),
        };

        var writer_buffer: [1024]u8 = undefined;
        var file_writer = atomic_file.file.writer(io, &writer_buffer);
        file_writer.interface.writeVecAll(&fields) catch
            return error.InputOutput;
        file_writer.interface.flush() catch
            return error.InputOutput;
        atomic_file.replace(io) catch
            return error.InputOutput;
    }

    pub const Lookup = union(enum) {
        /// The token is unknown, so the request cannot be decrypted.
        unknown,
        /// The session expired, but its key is returned so the client can
        /// decrypt the expiry response.
        expired: Session,
        active: Session,
    };

    /// Resolves `token` and refreshes `last_seen` for a live session. Updating
    /// that timestamp requires the exclusive lock.
    pub fn lookup(store: *Store, io: Io, token: Token, now: i64) Lookup {
        store.lock.lockUncancelable(io);
        defer store.lock.unlock(io);

        const entries = store.entries.slice();
        const adapter: ByToken = .{ .entries = entries };
        const index = store.token_map.getIndexAdapted(token, adapter) orelse
            return .unknown;

        var session = entries.get(index);
        if (now -| session.last_seen > config.session_ttl_seconds)
            return .{ .expired = session };

        entries.items(.last_seen)[index] = now;
        entries.items(.restored)[index] = false;
        session.last_seen = now;

        return .{ .active = session };
    }

    /// Discards sessions old enough that a returning client would already be
    /// sent back to the login screen.
    pub fn sweep(store: *Store, io: Io, now: i64) void {
        store.lock.lockUncancelable(io);
        defer store.lock.unlock(io);

        store.sweepLocked(now);
    }

    fn sweepLocked(store: *Store, now: i64) void {
        const limit = config.session_ttl_seconds + expired_retention_seconds;

        var index = store.entries.len;
        while (index != 0) {
            index -= 1;
            if (now -| store.entries.items(.last_seen)[index] <= limit)
                continue;
            store.removeLocked(store.entries.items(.token)[index], index);
        }
    }

    pub fn put(
        store: *Store,
        io: Io,
        gpa: Allocator,
        session: Session,
    ) Allocator.Error!void {
        store.lock.lockUncancelable(io);
        defer store.lock.unlock(io);

        if (session.player_id != .none)
            store.discardOtherPlayerSessionsLocked(session.player_id, session.token);

        const existing_entries = store.entries.slice();
        const adapter: ByToken = .{ .entries = existing_entries };
        if (store.token_map.getIndexAdapted(session.token, adapter)) |index| {
            store.entries.set(index, session);
            return;
        }

        const index = store.entries.len;
        try store.entries.append(gpa, session);
        errdefer _ = store.entries.swapRemove(index);
        const entries = store.entries.slice();
        const inserted = try store.token_map.getOrPutAdapted(
            gpa,
            session.token,
            ByToken{ .entries = entries },
        );
        std.debug.assert(inserted.index == index);
        std.debug.assert(!inserted.found_existing);
    }

    pub fn remove(store: *Store, io: Io, token: Token) void {
        store.lock.lockUncancelable(io);
        defer store.lock.unlock(io);

        const adapter: ByToken = .{ .entries = store.entries.slice() };
        const index = store.token_map.getIndexAdapted(token, adapter) orelse
            return;

        store.removeLocked(token, index);
    }

    /// Swap-removes both containers to keep their indices aligned. The caller
    /// must hold the exclusive lock and verify `token` is at `index`.
    fn removeLocked(store: *Store, token: Token, index: usize) void {
        const adapter: ByToken = .{ .entries = store.entries.slice() };
        std.debug.assert(store.token_map.swapRemoveAdapted(token, adapter));
        _ = store.entries.swapRemove(index);
    }

    /// Removes older sessions for the same player. The caller must hold the
    /// exclusive lock.
    fn discardOtherPlayerSessionsLocked(
        store: *Store,
        player_id: PlayerId,
        keep_token: Token,
    ) void {
        var index = store.entries.len;
        while (index != 0) {
            index -= 1;
            const existing = store.entries.get(index);
            if (existing.player_id != player_id or
                std.meta.eql(existing.token, keep_token))
                continue;
            store.removeLocked(existing.token, index);
        }
    }

    pub fn count(store: *Store) usize {
        return store.entries.len;
    }
};

/// Deletes the restored shutdown snapshot. A later graceful shutdown writes a
/// new one.
fn discardSavedSnapshot(io: Io) (Io.Cancelable || error{InputOutput})!void {
    Io.Dir.cwd().deleteFile(io, save_path) catch |err| switch (err) {
        error.FileNotFound => {},
        error.Canceled => |e| return e,
        else => return error.InputOutput,
    };
}

/// Removes duplicate player sessions before rebuilding the token index,
/// keeping the most recently used one.
fn discardDuplicatePlayers(entries: *std.MultiArrayList(Session)) void {
    var index: usize = 0;
    while (index < entries.len) {
        const player_id = entries.items(.player_id)[index];
        if (player_id == .none) {
            index += 1;
            continue;
        }

        var duplicate = index + 1;
        while (duplicate < entries.len) {
            if (entries.items(.player_id)[duplicate] != player_id) {
                duplicate += 1;
                continue;
            }

            if (entries.items(.last_seen)[duplicate] > entries.items(.last_seen)[index]) {
                _ = entries.swapRemove(index);
                continue;
            }
            _ = entries.swapRemove(duplicate);
        }
        index += 1;
    }
}
