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

const Row = std.array_list.Aligned([2]usize, null);
fn drawRows(allocator: std.mem.Allocator, tiles: []Tile) ![]Row {
    var max: usize = 0;
    for (tiles) |tile| max = @max(tile[0] + 1, max);

    const rows = try allocator.alloc(Row, max);
    for (0..max) |row| rows[row] = try Row.initCapacity(allocator, 0);

    var prev = tiles[tiles.len - 1];
    for (tiles) |tile| {
        const row = tile[1];
        if (row == prev[1]) {
            try rows[row].append(allocator, .{
                @min(tile[0], prev[0]),
                @max(tile[0], prev[0]),
            });
        }
        prev = tile;
    }

    return rows;
}
test "drawRows(example)" {
    const allocator = std.testing.allocator;

    const tiles = try parseTiles(allocator, example);
    defer allocator.free(tiles);

    const rows = try drawRows(allocator, tiles);
    defer {
        for (rows) |row| @constCast(&row).deinit(allocator);
        allocator.free(rows);
    }

    try std.testing.expectEqualSlices([2]usize, &.{}, rows[0].items);
    try std.testing.expectEqualSlices([2]usize, &.{.{ 7, 11 }}, rows[1].items);
    try std.testing.expectEqualSlices([2]usize, &.{}, rows[2].items);
    try std.testing.expectEqualSlices([2]usize, &.{.{ 2, 7 }}, rows[3].items);
    try std.testing.expectEqualSlices([2]usize, &.{}, rows[4].items);
    try std.testing.expectEqualSlices([2]usize, &.{.{ 2, 9 }}, rows[5].items);
    try std.testing.expectEqualSlices([2]usize, &.{}, rows[6].items);
    try std.testing.expectEqualSlices([2]usize, &.{.{ 9, 11 }}, rows[7].items);
}

const Red = enum { none, min, max };
fn solve2(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const tiles = try parseTiles(allocator, input);
    const rows = try drawRows(allocator, tiles);

    var max: u64 = 0;
    // Loop over each tile.
    for (tiles, 0..) |one, i| {
        // Loop over each possible combination, except impossible/earlier ones.
        loop: for (tiles[i + 1 ..]) |two| {
            const area = calculateArea(one, two);
            if (area <= max) continue :loop;

            // This is the furthest-down row. Tiles between the top edge and
            // here affect the color of this rectangle.
            const end: usize = @max(one[1], two[1]);
            // Loop over each column.
            for (@min(one[0], two[0])..@max(one[0], two[0]) + 1) |col| {
                // Track whether inside/outside the loop.
                var is_green = false;
                // Track the most recently-visited red tile. If there's an
                // unmatched one, then all subsequent tiles are green until it's
                // matched. When that happens, the state may or may not change,
                // depending on whether the two red tiles are on the same end of
                // their respective lines.
                var last_red = Red.none;
                // Loop over each row's lines.
                for (rows[0..end]) |lines| for (lines.items) |line| {
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
                    } else if (col < line[0] and col > line[1]) {
                        is_green = !is_green;
                    } else if (!is_green and last_red == .none) continue :loop;
                };
            }
            max = area;
        }
    }

    return max;
}
test "solve2(example)" {
    try std.testing.expectEqual(24, try solve2(example));
}
