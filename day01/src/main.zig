const std = @import("std");
const day01 = @import("day01");

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const solution = day01.solve2(input);

    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n", .{solution});
}
