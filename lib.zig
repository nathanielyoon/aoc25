const std = @import("std");

pub fn split(input: []const u8) std.mem.SplitIterator(u8, .scalar) {
    return std.mem.splitScalar(u8, std.mem.trimEnd(u8, input, "\n"), '\n');
}
