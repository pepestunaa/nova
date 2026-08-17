const Account = @This();

const std = @import("std");
const Io = std.Io;
const Dir = Io.Dir;

const LimitedString = @import("common").mem.LimitedString;

//

pub const OpenID = LimitedString(127);
pub const Token = LimitedString(40);

uid: u64,
token: Token,
device_id: OpenID,
created_at: i64,

pub const LoadError = error{
    NotFound,
    Corrupted,
    InputOutput,
} || Io.Cancelable;

pub const CreateError = error{InputOutput};

const Stored = struct {
    token: ?Token = null,
    device_id: OpenID = undefined,
    created_at: i64 = undefined,
};

pub fn loadRecord(io: Io, uid: u64) LoadError!Account {
    var path_buffer: [Io.Dir.max_path_bytes]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buffer, "store/account/{d}", .{uid}) catch
        return error.Corrupted;

    const file = Dir.openFile(.cwd(), io, path, .{}) catch |err|
        return switch (err) {
            error.Canceled => |e| e,
            error.FileNotFound => error.NotFound,
            else => error.InputOutput,
        };
    defer file.close(io);

    var reader_buffer: [256]u8 = undefined;
    var reader = file.reader(io, &reader_buffer);
    var stored: Stored = .{};
    readStored(&reader.interface, &stored) catch |err|
        return switch (err) {
            error.ReadFailed => switch (reader.err.?) {
                error.Canceled => |e| e,
                else => error.InputOutput,
            },
            else => error.Corrupted,
        };

    const account: Account = .{
        .uid = uid,
        .token = stored.token orelse randomToken(io),
        .device_id = stored.device_id,
        .created_at = stored.created_at,
    };

    if (stored.token == null)
        writeRecord(io, &account) catch
            return error.InputOutput;

    return account;
}

pub fn hasToken(account: *const Account, token: *const Token) bool {
    return std.crypto.timing_safe.eql(
        [Token.max_length + 1]u8,
        account.token.bytes,
        token.bytes,
    );
}

pub fn createRecord(io: Io, uid: u64, open_id: OpenID) CreateError!Account {
    const old_cancel_protection = io.swapCancelProtection(.blocked);
    defer _ = io.swapCancelProtection(old_cancel_protection);

    const account: Account = .{
        .uid = uid,
        .token = randomToken(io),
        .device_id = open_id,
        .created_at = Io.Timestamp.now(io, .real).toSeconds(),
    };
    try writeRecord(io, &account);

    return account;
}

fn writeRecord(io: Io, account: *const Account) CreateError!void {
    var path_buffer: [Io.Dir.max_path_bytes]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buffer, "store/account/{d}", .{account.uid}) catch
        return error.InputOutput;

    var atomic_file = Dir.createFileAtomic(.cwd(), io, path, .{
        .replace = true,
        .make_path = true,
    }) catch
        return error.InputOutput;
    defer atomic_file.deinit(io);

    var writer_buffer: [256]u8 = undefined;
    var writer = atomic_file.file.writer(io, &writer_buffer);
    writer.interface.print(
        "token = {s}\ndevice_id = {s}\ncreated_at = {d}\n",
        .{ account.token.view(), account.device_id.view(), account.created_at },
    ) catch
        return error.InputOutput;
    writer.interface.flush() catch
        return error.InputOutput;
    atomic_file.replace(io) catch
        return error.InputOutput;
}

fn readStored(reader: *Io.Reader, stored: *Stored) !void {
    var got_token = false;
    var got_device_id = false;
    var got_created_at = false;

    while (try reader.takeDelimiter('\n')) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0)
            continue;

        const separator = std.mem.indexOfScalar(u8, trimmed, '=') orelse
            return error.InvalidFormat;
        const key = std.mem.trim(u8, trimmed[0..separator], " \t");
        const value = std.mem.trim(u8, trimmed[separator + 1 ..], " \t");

        if (std.mem.eql(u8, key, "token")) {
            if (got_token)
                return error.InvalidFormat;
            stored.token = Token.init(value) catch
                return error.InvalidFormat;
            got_token = true;
        } else if (std.mem.eql(u8, key, "device_id")) {
            if (got_device_id)
                return error.InvalidFormat;
            stored.device_id.set(value) catch
                return error.InvalidFormat;
            got_device_id = true;
        } else if (std.mem.eql(u8, key, "created_at")) {
            if (got_created_at)
                return error.InvalidFormat;
            stored.created_at = std.fmt.parseInt(i64, value, 10) catch
                return error.InvalidFormat;
            got_created_at = true;
        } else {
            return error.InvalidFormat;
        }
    }

    if (!got_device_id or !got_created_at)
        return error.InvalidFormat;
}

fn randomToken(io: Io) Token {
    var entropy: [Token.max_length / 2]u8 = undefined;
    io.random(&entropy);

    var hex: [Token.max_length]u8 = undefined;
    const charset = "0123456789abcdef";
    for (entropy, 0..) |byte, index| {
        hex[index * 2] = charset[byte >> 4];
        hex[index * 2 + 1] = charset[byte & 0x0f];
    }

    return Token.init(&hex) catch unreachable;
}
