const AccountStore = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const Account = @import("store.zig").Account;

//

lock: Io.RwLock = .init,
accounts: std.ArrayList(Account) = .empty,
by_open_id: OpenIDMap = .empty,
by_uid: std.AutoHashMapUnmanaged(u64, usize) = .empty,
next_uid: u64,

pub const LoadError = Account.LoadError || Allocator.Error;
pub const CreateError = Account.CreateError || Allocator.Error;
pub const GetOrCreateResult = struct {
    account: Account,
    is_new: bool,
};

const OpenIDContext = struct {
    pub fn hash(_: OpenIDContext, open_id: Account.OpenID) u64 {
        return std.hash.Wyhash.hash(0, open_id.view());
    }

    pub fn eql(_: OpenIDContext, lhs: Account.OpenID, rhs: Account.OpenID) bool {
        return std.mem.eql(u8, lhs.view(), rhs.view());
    }
};

const OpenIDMap = std.HashMapUnmanaged(Account.OpenID, usize, OpenIDContext, 80);

pub fn load(gpa: Allocator, io: Io, initial_uid: u64) LoadError!AccountStore {
    var store: AccountStore = .{ .next_uid = initial_uid };
    errdefer store.deinit(gpa);

    const dir = Io.Dir.openDir(.cwd(), io, "store/account", .{ .iterate = true }) catch |err|
        return switch (err) {
            error.Canceled => |e| e,
            error.FileNotFound => store,
            else => error.InputOutput,
        };
    defer dir.close(io);

    var iterator = dir.iterateAssumeFirstIteration();
    while (iterator.next(io) catch |err|
        return switch (err) {
            error.Canceled => |e| e,
            else => error.InputOutput,
        }) |entry|
    {
        if (entry.kind != .file)
            continue;

        const uid = std.fmt.parseInt(u64, entry.name, 10) catch
            continue;
        const account = try Account.loadRecord(io, uid);
        if (store.by_open_id.getContext(account.device_id, .{}) != null or
            store.by_uid.get(account.uid) != null)
            return error.Corrupted;
        try store.append(gpa, account);
        store.next_uid = @max(store.next_uid, std.math.add(u64, uid, 1) catch
            return error.Corrupted);
    }

    return store;
}

pub fn deinit(store: *AccountStore, gpa: Allocator) void {
    store.accounts.deinit(gpa);
    store.by_open_id.deinit(gpa);
    store.by_uid.deinit(gpa);
}

pub fn fetch(store: *AccountStore, io: Io, open_id: Account.OpenID) ?Account {
    store.lock.lockSharedUncancelable(io);
    defer store.lock.unlockShared(io);

    const index = store.by_open_id.getContext(open_id, .{}) orelse
        return null;
    return store.accounts.items[index];
}

pub fn getByUid(store: *AccountStore, io: Io, uid: u64) ?Account {
    store.lock.lockSharedUncancelable(io);
    defer store.lock.unlockShared(io);

    const index = store.by_uid.get(uid) orelse
        return null;
    return store.accounts.items[index];
}

pub fn getOrCreate(
    store: *AccountStore,
    gpa: Allocator,
    io: Io,
    open_id: Account.OpenID,
) CreateError!GetOrCreateResult {
    store.lock.lockUncancelable(io);
    defer store.lock.unlock(io);

    if (store.by_open_id.getContext(open_id, .{})) |index|
        return .{ .account = store.accounts.items[index], .is_new = false };

    const next_uid = std.math.add(u64, store.next_uid, 1) catch
        return error.InputOutput;
    try store.reserveOne(gpa);
    const account = try Account.createRecord(io, store.next_uid, open_id);
    store.appendAssumeCapacity(account);
    store.next_uid = next_uid;

    return .{ .account = account, .is_new = true };
}

fn append(store: *AccountStore, gpa: Allocator, account: Account) Allocator.Error!void {
    try store.reserveOne(gpa);
    store.appendAssumeCapacity(account);
}

fn reserveOne(store: *AccountStore, gpa: Allocator) Allocator.Error!void {
    try store.accounts.ensureUnusedCapacity(gpa, 1);
    try store.by_open_id.ensureUnusedCapacityContext(gpa, 1, .{});
    try store.by_uid.ensureUnusedCapacity(gpa, 1);
}

fn appendAssumeCapacity(store: *AccountStore, account: Account) void {
    const index = store.accounts.items.len;

    std.debug.assert(store.by_open_id.getContext(account.device_id, .{}) == null);
    std.debug.assert(store.by_uid.get(account.uid) == null);

    store.accounts.appendAssumeCapacity(account);
    store.by_open_id.putAssumeCapacityNoClobberContext(account.device_id, index, .{});
    store.by_uid.putAssumeCapacityNoClobber(account.uid, index);
}
