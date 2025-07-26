# QBE via zig

This repo provides QBE installable / dependable on via the zig package manager. QBE
can be invoked either as a binary or a library (with `qbe.emit`, see below).

If you're looking to generate the QBE intermediate language from zig code programmatically, check out
https://github.com/ciathefed/qbe-zig.

## QBE binary

The `qbe-zig` provides an artifact `qbe` that some other module can depend on:

```zig
// Depend on qbe-zig via a build.zig.zon
const qbe = b.dependency("qbe-zig", .{ .target = target, .optimize = optimize });

// Extract the `qbe` binary artifact
const qbe_bin = qbe.artifact("qbe");
```

## QBE library

The upstream QBE repository does not expose a anyway of using QBE as a library.
`qbe-zig` offers the ability to call QBE as library by more or less duplicating
the existing `main.c` as `lib.c` and replacing the `main` function with `libemit`.

A tiny wrapper around `libemit` is then provided via `src/qbe.zig`.

To use QBE as a library in a zig project, in your `build.zig` have something like:

```zig
// Depend on qbe-zig via a build.zig.zon
const qbe = b.dependency("qbe-zig", .{ .target = target, .optimize = optimize });

const exe = b.addExecutable(...);

// Link against the static library
exe.linkLibrary(qbe.artifact("qbe-lib"));

// Expose to your exe code
exe.root_module.addImport("qbe-zig", qbe.module("qbe-zig"));
```

In your zig code import the module:

```zig
const qbe = @import("qbe-zig");
```

Call `emit` where you need:

```zig
qbe.emit("test.ssa", "test.s");
```

See `example/` for full example of library usage.
