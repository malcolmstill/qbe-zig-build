const std = @import("std");
const qbe = @import("qbe-zig");

pub fn main() !void {
    qbe.emit("test.ssa", "test.s");
}
