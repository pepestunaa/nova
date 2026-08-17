const builtin = @import("builtin");
const native_os = builtin.os.tag;

const std = @import("std");
const posix = std.posix;
const windows = std.os.windows;

//

const CTRL_C_EVENT: windows.DWORD = 0;

var user_callback: ?*const fn () void = null;

pub fn setup(callback: *const fn () void) void {
    user_callback = callback;
    switch (native_os) {
        .windows => registerWindows(),
        else => registerPosix(),
    }
}

/// Removes the callback before resources captured by it are released.
pub fn clear() void {
    user_callback = null;
    switch (native_os) {
        .windows => _ = SetConsoleCtrlHandler(windowsCallback, .FALSE),
        else => {},
    }
}

fn registerPosix() void {
    _ = posix.system.sigaction(.INT, &.{
        .handler = .{ .handler = posixCallback },
        .mask = std.mem.zeroes(@FieldType(posix.Sigaction, "mask")),
        .flags = 0,
    }, null);
}

fn registerWindows() void {
    _ = SetConsoleCtrlHandler(windowsCallback, .TRUE);
}

fn posixCallback(_: posix.SIG) callconv(.c) void {
    const callback = user_callback orelse return;
    callback();
}

fn windowsCallback(ctrl_type: windows.DWORD) callconv(.winapi) windows.BOOL {
    if (ctrl_type != CTRL_C_EVENT) return .FALSE;
    const callback = user_callback orelse return .FALSE;
    callback();
    return .TRUE;
}

extern "kernel32" fn SetConsoleCtrlHandler(
    handler_routine: *const fn (windows.DWORD) callconv(.winapi) windows.BOOL,
    add: windows.BOOL,
) windows.BOOL;
