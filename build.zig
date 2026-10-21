const std = @import("std");
const Io = std.Io;

//

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const strip = b.option(
        bool,
        "strip",
        "Strip debug information from compiled binaries",
    ) orelse false;

    const table_assets = collectTableAssets(b);
    const asset_generators = discoverAssetGenerators(b);
    const table_time = b.createModule(.{
        .root_source_file = b.path("servers/game/tables/utils/time.zig"),
    });
    const asset_registry_source = writeAssetRegistry(b, asset_generators);
    const asset_registry = b.createModule(.{
        .root_source_file = asset_registry_source,
    });
    for (asset_generators) |generator| {
        const module = b.createModule(.{
            .root_source_file = b.path(generator.path),
            .target = b.graph.host,
            .optimize = optimize,
        });
        addModuleAssets(module, table_assets);
        module.addImport("table_time", table_time);
        asset_registry.addImport(
            b.fmt("asset/{s}", .{generator.name}),
            module,
        );
    }

    const asset_generator = b.addExecutable(.{
        .name = "generate-assets",
        .root_module = b.createModule(.{
            .root_source_file = b.path("build/assets.zig"),
            .imports = &.{.{
                .name = "asset_registry",
                .module = asset_registry,
            }},
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });
    const run_asset_generator = b.addRunArtifact(asset_generator);
    if (b.args) |args| run_asset_generator.addArgs(args);
    b.step(
        "generate-assets",
        "Regenerate one or all committed normalized game assets",
    ).dependOn(&run_asset_generator.step);

    //

    const error_code_gen = b.addExecutable(.{
        .name = "error_code_gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("build/error_code.zig"),
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });
    error_code_gen.root_module.addAnonymousImport(
        "error_code",
        .{ .root_source_file = b.path("assets/tables/ErrorCode.zon") },
    );
    const generated_error_code_output = b.addRunArtifact(error_code_gen).captureStdOut(.{
        .basename = "error_code.zig",
    });
    const install_generated_error_code = b.addInstallFile(
        generated_error_code_output,
        "generated/error_code.zig",
    );
    b.step(
        "generate-error-codes",
        "Regenerate generated/error_code.zig from the ErrorCode table",
    ).dependOn(&install_generated_error_code.step);

    //

    const net_msg_id_gen = b.addExecutable(.{
        .name = "net_msg_id_gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("build/net_msg_id.zig"),
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });
    net_msg_id_gen.root_module.addAnonymousImport(
        "net_msg_id",
        .{ .root_source_file = b.path("assets/protocol/net_msg_id.zon") },
    );
    const generated_net_msg_id_output = b.addRunArtifact(net_msg_id_gen).captureStdOut(.{
        .basename = "net_msg_id.zig",
    });
    const update_generated_net_msg_id = b.addUpdateSourceFiles();
    update_generated_net_msg_id.addCopyFileToSource(
        generated_net_msg_id_output,
        "generated/net_msg_id.zig",
    );
    b.step(
        "generate-net-msg-id",
        "Regenerate generated/net_msg_id.zig from NetMsgId",
    ).dependOn(&update_generated_net_msg_id.step);

    const generate_protocol = b.step(
        "generate-protocol",
        "Regenerate generated/protocol.zig from .proto files",
    );
    if (collectProtocolSources(b)) |protocol_sources| {
        const protocol_gen = b.addExecutable(.{
            .name = "protocol_gen",
            .root_module = b.createModule(.{
                .root_source_file = b.path("build/proto.zig"),
                .target = b.graph.host,
                .optimize = optimize,
            }),
        });
        const run_protocol_gen = b.addRunArtifact(protocol_gen);
        for (protocol_sources) |source|
            run_protocol_gen.addFileArg(b.path(source));

        const generated_protocol_output = run_protocol_gen.captureStdOut(.{
            .basename = "protocol.zig",
        });
        const update_generated_protocol = b.addUpdateSourceFiles();
        update_generated_protocol.addCopyFileToSource(
            generated_protocol_output,
            "generated/protocol.zig",
        );
        generate_protocol.dependOn(&update_generated_protocol.step);
    } else {
        const missing_sources = b.addFail(
            ".proto files are unavailable, move them to assets/protocol/pb before generating",
        );
        generate_protocol.dependOn(&missing_sources.step);
    }

    const generated_net_msg_id = b.createModule(.{
        .root_source_file = b.path("generated/net_msg_id.zig"),
    });

    //

    const proto = b.createModule(.{
        .root_source_file = b.path("servers/game/protobuf.zig"),
        .imports = &.{.{
            .name = "net_msg_id",
            .module = generated_net_msg_id,
        }},
        .target = target,
        .optimize = optimize,
    });
    const generated_proto = b.createModule(.{
        .root_source_file = b.path("generated/protocol.zig"),
        .imports = &.{.{
            .name = "proto",
            .module = proto,
        }},
    });
    proto.addImport("stella_sora_proto", generated_proto);

    //

    const common = b.createModule(
        .{
            .root_source_file = b.path("common/src/root.zig"),
        },
    );

    const game_server = b.addExecutable(.{
        .name = "nova-game-server",
        .root_module = b.createModule(
            .{
                .root_source_file = b.path("servers/game/main.zig"),
                .imports = &.{
                    .{ .name = "common", .module = common },
                    .{ .name = "net_msg_id", .module = generated_net_msg_id },
                    .{ .name = "proto", .module = proto },
                },
                .target = target,
                .optimize = optimize,
                .strip = strip,
            },
        ),
    });
    addModuleAssets(game_server.root_module, table_assets);
    addGeneratedAssets(b, game_server.root_module);
    game_server.root_module.addAnonymousImport(
        "config",
        .{ .root_source_file = b.path("servers/game/config.zon") },
    );
    game_server.root_module.addAnonymousImport(
        "error_code_generated",
        .{ .root_source_file = b.path("generated/error_code.zig") },
    );
    b.installArtifact(game_server);
    const run_game_server = b.addRunArtifact(game_server);
    if (b.args) |args| run_game_server.addArgs(args);
    b.step(
        "run-game-server",
        "Start the game server",
    ).dependOn(&run_game_server.step);

    //

    const sdk_server = b.addExecutable(.{
        .name = "nova-sdk-server",
        .root_module = b.createModule(
            .{
                .root_source_file = b.path("servers/sdk/main.zig"),
                .imports = &.{
                    .{ .name = "common", .module = common },
                },
                .target = target,
                .optimize = optimize,
                .strip = strip,
            },
        ),
    });
    sdk_server.root_module.addAnonymousImport(
        "config",
        .{ .root_source_file = b.path("servers/sdk/config.zon") },
    );
    sdk_server.root_module.addAnonymousImport(
        "client_code.json",
        .{
            .root_source_file = b.path("assets/sdk/client_code.json"),
        },
    );
    b.installArtifact(sdk_server);
    const run_sdk_server = b.addRunArtifact(sdk_server);
    if (b.args) |args| run_sdk_server.addArgs(args);
    b.step(
        "run-sdk-server",
        "Start the sdk server",
    ).dependOn(&run_sdk_server.step);

    //

    const proto_tests = b.addTest(.{ .root_module = proto });
    const run_proto_tests = b.addRunArtifact(proto_tests);

    const game_server_tests = b.addTest(.{ .root_module = game_server.root_module });
    const run_game_server_tests = b.addRunArtifact(game_server_tests);

    const common_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("common/src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_common_tests = b.addRunArtifact(common_tests);

    const serve_all_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/serve_all.zig"),
            .imports = &.{
                .{ .name = "common", .module = common },
            },
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });
    const run_serve_all_tests = b.addRunArtifact(serve_all_tests);

    const test_step = b.step("test", "Run the unit tests");
    test_step.dependOn(&run_common_tests.step);
    test_step.dependOn(&run_proto_tests.step);
    test_step.dependOn(&run_game_server_tests.step);
    test_step.dependOn(&run_serve_all_tests.step);

    //

    const serve_all_exe = b.addExecutable(.{
        .name = "serve-all",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/serve_all.zig"),
            .imports = &.{
                .{ .name = "common", .module = common },
            },
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });
    const run_serve_all = b.addRunArtifact(serve_all_exe);
    const supervised_servers = [_]SupervisedServer{
        .{
            .name = "sdk-server",
            .executable = sdk_server,
            .peer_options = &.{"game-server-address"},
        },
        .{
            .name = "game-server",
            .executable = game_server,
            .peer_options = &.{"sdk-server-address"},
        },
    };
    for (supervised_servers) |server|
        addSupervisedServer(b, run_serve_all, server);
    run_serve_all.addArg("--");
    if (b.args) |args| run_serve_all.addArgs(args);
    b.step(
        "serve-all",
        "Start the SDK server and the game server at the same time",
    ).dependOn(&run_serve_all.step);
}

const AssetGenerator = struct {
    name: []const u8,
    path: []const u8,

    fn lessThan(_: void, lhs: AssetGenerator, rhs: AssetGenerator) bool {
        return std.mem.lessThan(u8, lhs.name, rhs.name);
    }
};

fn discoverAssetGenerators(b: *std.Build) []const AssetGenerator {
    const root_path = b.pathFromRoot("build/assets");
    var root = Io.Dir.openDirAbsolute(b.graph.io, root_path, .{ .iterate = true }) catch |err|
        std.debug.panic("couldn't open assets directory: {t}", .{err});
    defer root.close(b.graph.io);

    var walker = root.walk(b.allocator) catch |err|
        std.debug.panic("couldn't walk assets directory: {t}", .{err});
    defer walker.deinit();

    var generators: std.ArrayList(AssetGenerator) = .empty;
    while (walker.next(b.graph.io) catch |err|
        std.debug.panic("couldn't read assets directory: {t}", .{err})) |entry|
    {
        if (entry.kind != .file or
            std.fs.path.dirname(entry.path) != null or
            !std.mem.endsWith(u8, entry.path, ".zig"))
            continue;

        const basename = entry.path[0 .. entry.path.len - ".zig".len];
        for (basename) |byte| {
            if (!std.ascii.isLower(byte) and !std.ascii.isDigit(byte) and byte != '_')
                std.debug.panic("invalid asset-generator name '{s}'", .{basename});
        }
        generators.append(b.allocator, .{
            .name = b.allocator.dupe(u8, basename) catch @panic("out of memory"),
            .path = b.fmt("build/assets/{s}", .{entry.path}),
        }) catch @panic("out of memory");
    }

    const result = generators.toOwnedSlice(b.allocator) catch
        @panic("out of memory");
    std.mem.sort(AssetGenerator, result, {}, AssetGenerator.lessThan);

    return result;
}

fn writeAssetRegistry(
    b: *std.Build,
    generators: []const AssetGenerator,
) std.Build.LazyPath {
    var source: Io.Writer.Allocating = .init(b.allocator);
    defer source.deinit();
    source.writer.writeAll(
        \\const std = @import("std");
        \\
        \\pub const Generator = struct {
        \\    name: []const u8,
        \\    generate: *const fn (std.process.Init, *std.Io.Writer) anyerror!void,
        \\};
        \\
        \\pub const list = [_]Generator{
        \\
    ) catch @panic("out of memory while writing the asset registry");
    for (generators) |generator| source.writer.print(
        "    .{{ .name = \"{s}\", .generate = @import(\"asset/{s}\").generate }},\n",
        .{ generator.name, generator.name },
    ) catch @panic("out of memory while writing the asset registry");
    source.writer.writeAll("};\n") catch
        @panic("out of memory while writing the asset registry");

    const files = b.addWriteFiles();

    return files.add("asset_registry.zig", source.written());
}

const ModuleAsset = struct {
    name: []const u8,
    module: *std.Build.Module,
};

fn collectTableAssets(b: *std.Build) []const ModuleAsset {
    const root_path = b.pathFromRoot("assets/tables");
    var root = Io.Dir.openDirAbsolute(
        b.graph.io,
        root_path,
        .{ .iterate = true },
    ) catch |err|
        std.debug.panic("couldn't open table directory: {t}", .{err});
    defer root.close(b.graph.io);

    var walker = root.walk(b.allocator) catch |err|
        std.debug.panic("couldn't walk table directory: {t}", .{err});
    defer walker.deinit();

    var assets: std.ArrayList(ModuleAsset) = .empty;
    while (walker.next(b.graph.io) catch |err|
        std.debug.panic("couldn't read table directory: {t}", .{err})) |entry|
    {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.path, ".zon"))
            continue;

        const table_path = entry.path[0 .. entry.path.len - ".zon".len];
        const module_name = b.allocator.alloc(u8, "tables/".len + table_path.len) catch
            @panic("out of memory while registering a table asset");
        @memcpy(module_name[0.."tables/".len], "tables/");
        @memcpy(module_name["tables/".len..], table_path);
        std.mem.replaceScalar(u8, module_name, std.fs.path.sep, '/');

        assets.append(b.allocator, .{
            .name = module_name,
            .module = b.createModule(.{
                .root_source_file = b.path(b.fmt("assets/tables/{s}", .{entry.path})),
            }),
        }) catch @panic("out of memory while registering table assets");
    }

    return assets.toOwnedSlice(b.allocator) catch
        @panic("out of memory while registering table assets");
}

fn collectProtocolSources(b: *std.Build) ?[]const []const u8 {
    const root_path = b.pathFromRoot("assets/protocol/pb");
    var root = Io.Dir.openDirAbsolute(
        b.graph.io,
        root_path,
        .{ .iterate = true },
    ) catch |err|
        switch (err) {
            error.FileNotFound => return null,
            else => std.debug.panic("couldn't open proto directory: {t}", .{err}),
        };
    defer root.close(b.graph.io);

    var walker = root.walk(b.allocator) catch |err|
        std.debug.panic("couldn't walk proto directory: {t}", .{err});
    defer walker.deinit();

    var sources: std.ArrayList([]const u8) = .empty;
    while (walker.next(b.graph.io) catch |err|
        std.debug.panic("couldn't read proto directory: {t}", .{err})) |entry|
    {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.path, ".proto"))
            continue;

        sources.append(b.allocator, b.fmt("assets/protocol/pb/{s}", .{entry.path})) catch
            @panic("out of memory while registering proto sources");
    }

    if (sources.items.len == 0) {
        sources.deinit(b.allocator);
        return null;
    }

    const result = sources.toOwnedSlice(b.allocator) catch
        @panic("out of memory while registering proto sources");
    std.mem.sort(
        []const u8,
        result,
        {},
        struct {
            fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
                return std.mem.lessThan(u8, lhs, rhs);
            }
        }.lessThan,
    );

    return result;
}

fn addModuleAssets(module: *std.Build.Module, assets: []const ModuleAsset) void {
    for (assets) |asset|
        module.addImport(asset.name, asset.module);
}

fn addGeneratedAssets(b: *std.Build, module: *std.Build.Module) void {
    const root_path = b.pathFromRoot("generated/assets");
    var root = Io.Dir.openDirAbsolute(
        b.graph.io,
        root_path,
        .{ .iterate = true },
    ) catch |err|
        std.debug.panic("couldn't open the generated assets directory: {t}", .{err});
    defer root.close(b.graph.io);

    var walker = root.walk(b.allocator) catch |err|
        std.debug.panic("couldn't walk the generated assets directory: {t}", .{err});
    defer walker.deinit();

    while (walker.next(b.graph.io) catch |err|
        std.debug.panic("couldn't read the generated assets directory: {t}", .{err})) |entry|
    {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.path, ".zig"))
            continue;

        const asset_path = entry.path[0 .. entry.path.len - ".zig".len];
        const module_name = b.fmt("generated/assets/{s}", .{asset_path});
        std.mem.replaceScalar(u8, @constCast(module_name), std.fs.path.sep, '/');
        module.addAnonymousImport(module_name, .{
            .root_source_file = b.path(b.fmt("generated/assets/{s}", .{entry.path})),
        });
    }
}

const SupervisedServer = struct {
    name: []const u8,
    executable: *std.Build.Step.Compile,
    peer_options: []const []const u8,
};

fn addSupervisedServer(
    b: *std.Build,
    run: *std.Build.Step.Run,
    server: SupervisedServer,
) void {
    run.addArg(server.name);
    run.addArtifactArg(server.executable);
    run.addArg(b.fmt("{d}", .{server.peer_options.len}));
    run.addArgs(server.peer_options);
}
