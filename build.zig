const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});
    _ = optimize; // See comment below

    // Generate config.h with appropriate default qbe target
    var config_file = try std.fs.cwd().createFile("config.h", .{});
    defer config_file.close();

    switch (target.result.os.tag) {
        .macos => switch (target.result.cpu.arch) {
            .aarch64 => try config_file.writeAll(
                \\#define Deftgt T_arm64_apple
            ),
            .x86_64 => try config_file.writeAll(
                \\#define Deftgt T_amd64_apple
            ),
            else => return error.MacosUnsupportedArchitectureOn,
        },
        else => switch (target.result.cpu.arch) {
            .aarch64 => try config_file.writeAll(
                \\#define Deftgt T_arm64
            ),
            .x86_64 => try config_file.writeAll(
                \\#define Deftgt T_amd64_sysv
            ),
            .riscv64 => try config_file.writeAll(
                \\#define Deftgt T_rv64
            ),
            else => return error.UnsupportedArchitecture,
        },
    }

    const qbe_exe = b.addExecutable(.{
        .name = "qbe",
        .target = target,
        .optimize = .ReleaseFast, // If we try to use .ReleaseSafe or .Debug invoking qbe traps
    });

    qbe_exe.addCSourceFiles(.{
        .files = &.{
            "abi.c",
            "alias.c",
            "cfg.c",
            "copy.c",
            "emit.c",
            "fold.c",
            "live.c",
            "load.c",
            "main.c",
            "mem.c",
            "parse.c",
            "rega.c",
            "simpl.c",
            "spill.c",
            "ssa.c",
            "util.c",
            // amd64
            "amd64/emit.c",
            "amd64/isel.c",
            "amd64/sysv.c",
            "amd64/targ.c",
            // arm64
            "arm64/abi.c",
            "arm64/emit.c",
            "arm64/isel.c",
            "arm64/targ.c",
            // rv64
            "rv64/abi.c",
            "rv64/emit.c",
            "rv64/isel.c",
            "rv64/targ.c",
        },
    });

    b.installArtifact(qbe_exe);

    qbe_exe.linkLibC();

    const libqbe = b.addStaticLibrary(.{
        .name = "qbe-lib",
        .root_source_file = b.path("src/qbe.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    libqbe.linkLibC();

    libqbe.addCSourceFiles(.{
        .files = &.{
            "abi.c",
            "alias.c",
            "cfg.c",
            "copy.c",
            "emit.c",
            "fold.c",
            "live.c",
            "load.c",
            "lib.c", // lib.c instead of main.c
            "mem.c",
            "parse.c",
            "rega.c",
            "simpl.c",
            "spill.c",
            "ssa.c",
            "util.c",
            // amd64
            "amd64/emit.c",
            "amd64/isel.c",
            "amd64/sysv.c",
            "amd64/targ.c",
            // arm64
            "arm64/abi.c",
            "arm64/emit.c",
            "arm64/isel.c",
            "arm64/targ.c",
            // rv64
            "rv64/abi.c",
            "rv64/emit.c",
            "rv64/isel.c",
            "rv64/targ.c",
        },
    });

    const module = b.addModule("qbe-zig", .{
        .root_source_file = b.path("src/qbe.zig"),
    });

    module.addIncludePath(b.path(""));

    b.installArtifact(libqbe);
}
