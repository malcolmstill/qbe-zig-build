const c = @cImport({
    @cInclude("lib.h");
});

/// FIXME: this should return errors
pub fn emit(ssa_file_path: [*c]const u8, s_file_path: [*c]const u8) void {
    c.libemit(@constCast(ssa_file_path), @constCast(s_file_path));
}
