const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});
    _ = optimize; // See comment below

    // Generate config.h with appropriate default qbe target
    const wf = b.addWriteFiles();
    const config_h_path = "config.h";

    const config_h_define = switch (target.result.os.tag) {
        .macos => switch (target.result.cpu.arch) {
            .aarch64 =>
            \\#define Deftgt T_arm64_apple
            ,
            .x86_64 =>
            \\#define Deftgt T_amd64_apple
            ,
            else => return error.MacosUnsupportedArchitectureOn,
        },
        else => switch (target.result.cpu.arch) {
            .aarch64 =>
            \\#define Deftgt T_arm64
            ,
            .x86_64 =>
            \\#define Deftgt T_amd64_sysv
            ,
            .riscv64 =>
            \\#define Deftgt T_rv64
            ,
            else => return error.UnsupportedArchitecture,
        },
    };
    _ = wf.add(config_h_path, config_h_define);

    const qbe_exe = b.addExecutable(.{
        .name = "qbe",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = .ReleaseFast, // If we try to use .ReleaseSafe or .Debug invoking qbe traps
        }),
    });

    qbe_exe.addCSourceFiles(.{
        .files = &.{
            "qbe/abi.c",
            "qbe/alias.c",
            "qbe/cfg.c",
            "qbe/copy.c",
            "qbe/emit.c",
            "qbe/fold.c",
            "qbe/live.c",
            "qbe/load.c",
            "qbe/main.c",
            "qbe/mem.c",
            "qbe/parse.c",
            "qbe/rega.c",
            "qbe/simpl.c",
            "qbe/spill.c",
            "qbe/ssa.c",
            "qbe/util.c",
            // amd64
            "qbe/amd64/emit.c",
            "qbe/amd64/isel.c",
            "qbe/amd64/sysv.c",
            "qbe/amd64/targ.c",
            // arm64
            "qbe/arm64/abi.c",
            "qbe/arm64/emit.c",
            "qbe/arm64/isel.c",
            "qbe/arm64/targ.c",
            // rv64
            "qbe/rv64/abi.c",
            "qbe/rv64/emit.c",
            "qbe/rv64/isel.c",
            "qbe/rv64/targ.c",
        },
    });

    qbe_exe.addIncludePath(b.path("qbe/"));
    qbe_exe.addIncludePath(wf.getDirectory());

    b.installArtifact(qbe_exe);

    qbe_exe.linkLibC();

    const libqbe = b.addLibrary(.{
        .name = "qbe-lib",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/qbe.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        }),
        .linkage = .static,
    });

    libqbe.linkLibC();

    libqbe.addCSourceFiles(.{
        .files = &.{
            "qbe/abi.c",
            "qbe/alias.c",
            "qbe/cfg.c",
            "qbe/copy.c",
            "qbe/emit.c",
            "qbe/fold.c",
            "qbe/live.c",
            "qbe/load.c",
            "src/lib.c", // lib.c instead of main.c
            "qbe/mem.c",
            "qbe/parse.c",
            "qbe/rega.c",
            "qbe/simpl.c",
            "qbe/spill.c",
            "qbe/ssa.c",
            "qbe/util.c",
            // amd64
            "qbe/amd64/emit.c",
            "qbe/amd64/isel.c",
            "qbe/amd64/sysv.c",
            "qbe/amd64/targ.c",
            // arm64
            "qbe/arm64/abi.c",
            "qbe/arm64/emit.c",
            "qbe/arm64/isel.c",
            "qbe/arm64/targ.c",
            // rv64
            "qbe/rv64/abi.c",
            "qbe/rv64/emit.c",
            "qbe/rv64/isel.c",
            "qbe/rv64/targ.c",
        },
    });

    libqbe.addIncludePath(b.path("qbe/"));
    libqbe.addIncludePath(wf.getDirectory());

    const module = b.addModule("qbe-zig", .{
        .root_source_file = b.path("src/qbe.zig"),
    });

    // src/qbe.zig needs to be able to find src/lib.h
    module.addIncludePath(b.path("src"));

    b.installArtifact(libqbe);
}
