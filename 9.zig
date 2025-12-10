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
pub fn main() !void {
    const input = @embedFile("./inputs/9.txt");
    try lib.print(try solve1(input));
    try lib.print(try solve2(input));
}

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

fn drawLines(allocator: std.mem.Allocator, tiles: []Tile) ![]?[2]usize {
    var max: usize = 0;
    for (tiles) |tile| max = @max(tile[1] + 1, max);

    const lines = try allocator.alloc(?[2]usize, max);
    for (0..max) |row| lines[row] = null;

    var prev = tiles[tiles.len - 1];
    for (tiles) |tile| {
        const row = tile[1];
        if (row == prev[1]) lines[row] = .{ @min(tile[0], prev[0]), @max(tile[0], prev[0]) };
        prev = tile;
    }

    return lines;
}
test "drawLines(example)" {
    const allocator = std.testing.allocator;

    const tiles = try parseTiles(allocator, example);
    defer allocator.free(tiles);

    const lines = try drawLines(allocator, tiles);
    defer allocator.free(lines);

    try std.testing.expectEqual(null, lines[0]);
    try std.testing.expectEqual(.{ 7, 11 }, lines[1]);
    try std.testing.expectEqual(null, lines[2]);
    try std.testing.expectEqual(.{ 2, 7 }, lines[3]);
    try std.testing.expectEqual(null, lines[4]);
    try std.testing.expectEqual(.{ 2, 9 }, lines[5]);
    try std.testing.expectEqual(null, lines[6]);
    try std.testing.expectEqual(.{ 9, 11 }, lines[7]);
}

const Red = enum { none, min, max };
fn validateRectangle(lines: []?[2]usize, one: Tile, two: Tile) bool {
    // Rectangle's vertical bounds.
    const upper: usize = @min(one[1], two[1]);
    const lower: usize = @max(one[1], two[1]);
    // Loop over each column.
    for (@min(one[0], two[0])..@max(one[0], two[0]) + 1) |col| {
        // Track whether inside/outside the loop.
        var is_green = false;
        // Track unmatched red tiles, which make all subsequent tiles green
        // until the next. When that happens, the state may or may not change,
        // depending on whether the two red tiles are on the same end of their
        // respective lines.
        var last_red = Red.none;
        // Loop over each line.
        for (0..lower + 1) |row| if (lines[row]) |line| {
            if (col == line[0]) switch (last_red) {
                .none => last_red = .min,
                .min => last_red = .none,
                .max => {
                    is_green = !is_green;
                    last_red = .none;
                },
            } else if (col == line[1]) switch (last_red) {
                .none => last_red = .max,
                .min => {
                    is_green = !is_green;
                    last_red = .none;
                },
                .max => last_red = .none,
            } else if (col > line[0] and col < line[1]) {
                is_green = !is_green;
            } else if (row >= upper and !is_green and last_red == .none) return false;
        };
    }
    return true;
}
test "validateRectangle(example)" {
    const allocator = std.testing.allocator;

    const tiles = try parseTiles(allocator, example);
    defer allocator.free(tiles);

    const lines = try drawLines(allocator, tiles);
    defer allocator.free(lines);

    try std.testing.expectEqual(true, validateRectangle(lines, .{ 7, 3 }, .{ 11, 1 }));
    try std.testing.expectEqual(true, validateRectangle(lines, .{ 9, 7 }, .{ 9, 5 }));
    try std.testing.expectEqual(true, validateRectangle(lines, .{ 9, 5 }, .{ 2, 3 }));
    try std.testing.expectEqual(false, validateRectangle(lines, .{ 2, 5 }, .{ 9, 7 }));
    try std.testing.expectEqual(false, validateRectangle(lines, .{ 7, 1 }, .{ 11, 7 }));
    try std.testing.expectEqual(false, validateRectangle(lines, .{ 2, 5 }, .{ 11, 1 }));
}

fn solve2(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const tiles = try parseTiles(allocator, input);
    const lines = try drawLines(allocator, tiles);

    var max: u64 = 0;
    for (tiles, 0..) |one, i| {
        for (tiles[i + 1 ..]) |two| {
            const area = calculateArea(one, two);
            if (area > max and validateRectangle(lines, one, two)) max = area;
        }
    }
    return max;
}
test "solve2(example)" {
    try std.testing.expectEqual(24, try solve2(example));
}
