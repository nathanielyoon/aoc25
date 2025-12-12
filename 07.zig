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

    var lines = lib.split(input, '\n');
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

fn solve2(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = lib.split(input, '\n');
    const first = lines.first();
    var set = try allocator.alloc(u64, first.len);
    for (first, 0..) |char, i| set[i] = if (char == 'S') 1 else 0;
    while (lines.next()) |line| {
        for (line, 0..) |char, i| if (char == '^') {
            const in = set[i];
            set[i - 1] += in;
            set[i] = 0;
            set[i + 1] += in;
        };
    }
    var timelines: u64 = 0;
    for (set) |particles| timelines += particles;
    return timelines;
}
test "solve2() solves trivial examples" {
    try std.testing.expectEqual(2, try solve2(
        \\.S.
        \\.^.
    ));
    try std.testing.expectEqual(4, try solve2(
        \\..S..
        \\..^..
        \\.^.^.
    ));
    try std.testing.expectEqual(8, try solve2(
        \\...S...
        \\...^...
        \\..^.^..
        \\.^.^.^.
    ));
}
test "solve2(example) solves 2" {
    try std.testing.expectEqual(40, try solve2(example));
}

pub fn main() !void {
    const input = @embedFile("./inputs/07.txt");
    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n{d}\n", .{
        try solve1(input),
        try solve2(input),
    });
}
