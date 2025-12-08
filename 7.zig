const std = @import("std");
const lib = @import("./lib.zig");
const example =
    \\.......S.......
    \\...............
    \\.......^.......
    \\...............
    \\......^.^......
    \\...............
    \\.....^.^.^.....
    \\...............
    \\....^.^...^....
    \\...............
    \\...^.^...^.^...
    \\...............
    \\..^...^.....^..
    \\...............
    \\.^.^.^.^.^...^.
    \\...............
;

fn solve1(input: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = lib.split(input);
    const first = lines.first();
    var set = try allocator.alloc(bool, first.len);
    for (first, 0..) |char, i| set[i] = char == 'S';
    var splits: u32 = 0;
    while (lines.next()) |line| {
        for (line, 0..) |char, i| if (char == '^' and set[i]) {
            set[i - 1] = true;
            set[i] = false;
            set[i + 1] = true;
            splits += 1;
        };
    }
    return splits;
}
test "solve1(example) solves 1" {
    try std.testing.expectEqual(21, try solve1(example));
}

pub fn main() !void {
    const input = @embedFile("./inputs/7.txt");
    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n", .{
        try solve1(input),
    });
}
