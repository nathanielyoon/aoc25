const std = @import("std");

/// Counts the number of "real" lines.
pub fn count(input: []const u8) usize {
    var lines: usize = 0;
    for (input, 0..) |char, i| {
        if (char == '\n' and i + 1 != input.len) lines += 1;
    }
    return lines + 1;
}
/// Trims trailing linefeeds and splits into lines.
pub fn split(input: []const u8) std.mem.SplitIterator(u8, .scalar) {
    return std.mem.splitScalar(u8, std.mem.trimEnd(u8, input, "\n"), '\n');
}
/// Prints a number to stdout.
pub fn print(solution: anytype) !void {
    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n", .{solution});
}
