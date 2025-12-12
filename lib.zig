const std = @import("std");

/// Counts the number of separated chunks.
pub fn count(input: []const u8, separator: u8) usize {
    var lines: usize = 0;
    for (input, 0..) |char, i| {
        if (char == separator and i + 1 != input.len) lines += 1;
    }
    return lines + 1;
}
/// Trims trailing separators and splits on them.
pub fn split(input: []const u8, separator: u8) std.mem.SplitIterator(u8, .scalar) {
    var end = input.len;
    while (input[end - 1] == separator) end -= 1;
    return std.mem.splitScalar(u8, input[0..end], separator);
}
/// Prints a number to stdout.
pub fn print(solution: anytype) !void {
    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n", .{solution});
}
