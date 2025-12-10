const std = @import("std");
const lib = @import("./lib.zig");
const example =
    \\7,1
    \\11,1
    \\11,7
    \\9,7
    \\9,5
    \\2,5
    \\2,3
    \\7,3
;

const Tile = @Vector(2, usize);
fn parseTiles(allocator: std.mem.Allocator, input: []const u8) ![]Tile {
    const size = lib.count(input);
    var tiles = try allocator.alloc(Tile, size);
    var lines = lib.split(input);
    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        const comma = std.mem.findScalar(u8, line, ',').?;
        tiles[i] = .{
            try std.fmt.parseInt(usize, line[0..comma], 10),
            try std.fmt.parseInt(usize, line[comma + 1 ..], 10),
        };
    }
    return tiles;
}
test "parseTiles(example)" {
    const allocator = std.testing.allocator;
    const tiles = try parseTiles(allocator, example);
    defer allocator.free(tiles);

    try std.testing.expectEqualSlices(Tile, &.{
        .{ 7, 1 },
        .{ 11, 1 },
        .{ 11, 7 },
        .{ 9, 7 },
        .{ 9, 5 },
        .{ 2, 5 },
        .{ 2, 3 },
        .{ 7, 3 },
    }, tiles);
}

const offset: @Vector(2, u64) = @splat(1);
fn calculateArea(lhs: Tile, rhs: Tile) u64 {
    const a: @Vector(2, i64) = @intCast(lhs);
    const b: @Vector(2, i64) = @intCast(rhs);
    return @reduce(.Mul, @abs(a - b) + offset);
}
test "calculateArea(example)" {
    try std.testing.expectEqual(24, calculateArea(.{ 2, 5 }, .{ 9, 7 }));
    try std.testing.expectEqual(35, calculateArea(.{ 7, 1 }, .{ 11, 7 }));
    try std.testing.expectEqual(6, calculateArea(.{ 7, 3 }, .{ 2, 3 }));
    try std.testing.expectEqual(50, calculateArea(.{ 2, 5 }, .{ 11, 1 }));
}

fn solve1(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const tiles = try parseTiles(allocator, input);
    var max: u64 = 0;
    for (tiles, 0..) |tile, i| {
        for (i + 1..tiles.len) |j| {
            const area = calculateArea(tile, tiles[j]);
            if (area > max) max = area;
        }
    }
    return max;
}
test "solve1(example)" {
    try std.testing.expectEqual(50, try solve1(example));
}

fn colorFloor(allocator: std.mem.Allocator, tiles: []Tile) ![]bool {
    // Calculate dimensions of (legal) floor.
    var length: usize = 0;
    var height: usize = 0;
    for (tiles) |tile| {
        if (tile[0] >= length) length = tile[0] + 1;
        if (tile[1] >= height) height = tile[1] + 1;
    }

    // Flattened 2-D array.
    var floor = try allocator.alloc(bool, length * height);
    @memset(floor, false);

    // Mark all red tiles.
    for (tiles) |tile| floor[tile[1] * length + tile[0]] = true;

    // These temporary arrays hold, for each row/column respectively, the number
    // of red tiles to the left of each tile (inclusive).
    var lengthwise = try allocator.alloc(u16, length * height);
    defer allocator.free(lengthwise);
    var heightwise = try allocator.alloc(u16, length * height);
    defer allocator.free(heightwise);

    var prev: u16 = undefined;
    for (0..height) |i| {
        prev = 0;
        for (0..length) |j| {
            if (floor[i * length + j]) prev += 1;
            lengthwise[i * length + j] = prev;
        }
    }
    for (0..length) |i| {
        prev = 0;
        for (0..height) |j| {
            if (floor[j * length + i]) prev += 1;
            heightwise[j * length + i] = prev;
        }
    }
    for (lengthwise, 0..) |prevs, i| {
        if (i % 12 == 0) std.debug.print("\n", .{});
        std.debug.print("{}", .{prevs});
    }
    std.debug.print("\n", .{});
    for (heightwise, 0..) |prevs, i| {
        if (i % 12 == 0) std.debug.print("\n", .{});
        std.debug.print("{}", .{prevs});
    }
    std.debug.print("\n", .{});

    for (0..height) |i| {
        for (0..length) |j| {
            const index = i * length + j;
            floor[index] = lengthwise[index] % 2 == 1 and heightwise[index] % 2 == 1;
        }
    }

    return floor;
}
test "colorFloor(example)" {
    const allocator = std.testing.allocator;

    const tiles = try parseTiles(allocator, example);
    defer allocator.free(tiles);

    const floor = try colorFloor(allocator, tiles);
    defer allocator.free(floor);

    for (floor, 0..) |ok, i| {
        if (i % 12 == 0) std.debug.print("\n", .{});
        if (ok) {
            std.debug.print("1", .{});
        } else {
            std.debug.print("0", .{});
        }
    }
    std.debug.print("\n", .{});
    std.debug.print("\n{s}\n", .{
        \\000000000000
        \\000000011111
        \\000000011111
        \\001111111111
        \\001111111111
        \\001111111111
        \\000000000111
        \\000000000111
    });

    var i: usize = 0;
    for (
        \\............
        \\.......#XXX#
        \\.......XXXXX
        \\..#XXXX#XXXX
        \\..XXXXXXXXXX
        \\..#XXXXXX#XX
        \\.........XXX
        \\.........#X#
    ) |char| {
        switch (char) {
            '#' => try std.testing.expectEqual(true, floor[i]),
            'X' => try std.testing.expectEqual(true, floor[i]),
            '.' => try std.testing.expectEqual(false, floor[i]),
            '\n' => continue,
            else => unreachable,
        }
        i += 1;
        if (i >= floor.len) break;
    }
}

pub fn main() !void {
    const input = @embedFile("./inputs/9.txt");
    try lib.print(try solve1(input));
    // try lib.print(try solve2(input));
}
