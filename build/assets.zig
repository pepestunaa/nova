//! Discovers the generators in `build/assets/`. Normal builds use their
//! checked-in output from `generated/assets/`.

const std = @import("std");
const Io = std.Io;
const process = std.process;

const registry = @import("asset_registry");

//

pub fn main(init: process.Init) u8 {
    const args = init.minimal.args.toSlice(init.arena.allocator()) catch {
        std.log.err("unable to read command-line arguments", .{});
        return 1;
    };

    if (args.len == 1 or isHelp(args[1])) {
        printUsage(args[0]);
        return 0;
    }

    if (std.mem.eql(u8, args[1], "all")) {
        if (args.len != 2) {
            std.log.err("'all' cannot be combined with individual asset names", .{});
            return 2;
        }
        for (registry.list) |generator|
            generate(init, generator) catch |err| {
                std.log.err("failed to generate '{s}': {t}", .{ generator.name, err });
                return 1;
            };

        return 0;
    }

    for (args[1..]) |name| {
        const generator = find(name) orelse {
            std.log.err("unknown generated asset '{s}'", .{name});
            printUsage(args[0]);
            return 2;
        };
        generate(init, generator) catch |err| {
            std.log.err("failed to generate '{s}': {t}", .{ generator.name, err });
            return 1;
        };
    }

    return 0;
}

fn generate(init: process.Init, generator: registry.Generator) !void {
    var path_buffer: [Io.Dir.max_path_bytes]u8 = undefined;
    const path = std.fmt.bufPrint(
        &path_buffer,
        "generated/assets/{s}.zig",
        .{generator.name},
    ) catch
        return error.NameTooLong;

    var atomic_file = try Io.Dir.createFileAtomic(.cwd(), init.io, path, .{
        .replace = true,
        .make_path = true,
    });
    defer atomic_file.deinit(init.io);

    var buffer: [4096]u8 = undefined;
    var writer = atomic_file.file.writer(init.io, &buffer);
    try generator.generate(init, &writer.interface);
    try writer.interface.flush();
    try atomic_file.replace(init.io);

    std.debug.print("generated {s}\n", .{path});
}

fn find(name: []const u8) ?registry.Generator {
    for (registry.list) |generator|
        if (std.mem.eql(u8, name, generator.name))
            return generator;

    return null;
}

fn isHelp(argument: []const u8) bool {
    return std.mem.eql(u8, argument, "-h") or
        std.mem.eql(u8, argument, "--help");
}

fn printUsage(executable: []const u8) void {
    std.debug.print(
        \\Usage: {s} <all|asset> [asset...]
        \\
        \\Available assets:
        \\  all
        \\
    , .{executable});
    for (registry.list) |generator|
        std.debug.print("  {s}\n", .{generator.name});
}
