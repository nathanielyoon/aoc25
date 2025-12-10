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

const Color = enum(u2) { red_0, red_1, green, other };
const Floor = struct {
    min_rows: usize,
    min_cols: usize,
    max_rows: usize,
    max_cols: usize,
    colors: []Color,
    fn init(
        allocator: std.mem.Allocator,
        min_rows: usize,
        min_cols: usize,
        max_rows: usize,
        max_cols: usize,
    ) !Floor {
        std.debug.print("{d}\n", .{(max_rows - min_rows) * (max_cols - min_rows)});
        const colors = try allocator.alloc(Color, (max_rows - min_rows) * (max_cols - min_rows));
        @memset(colors, Color.other);
        return Floor{
            .min_rows = min_rows,
            .min_cols = min_cols,
            .max_rows = max_rows,
            .max_cols = max_cols,
            .colors = colors,
        };
    }
    fn getIndex(self: *Floor, row: usize, col: usize) usize {
        std.debug.assert(row >= self.min_rows);
        std.debug.assert(col >= self.min_cols);
        std.debug.assert(row < self.max_rows);
        std.debug.assert(col < self.max_cols);
        return (row - self.min_rows) * (self.max_cols - self.min_cols) + col - self.min_cols;
    }
    fn deinit(self: *Floor, allocator: std.mem.Allocator) void {
        allocator.free(self.colors);
    }
    fn set(self: *Floor, row: usize, col: usize, color: Color) void {
        self.colors[self.getIndex(row, col)] = color;
    }
    fn get(self: *Floor, row: usize, col: usize) Color {
        return self.colors[self.getIndex(row, col)];
    }
    fn print(self: *Floor) void {
        for (self.min_rows..self.max_rows) |row| {
            for (self.min_cols..self.max_cols) |col| {
                std.debug.print("{d}", .{self.get(row, col)});
            }
            std.debug.print("\n", .{});
        }
    }
};

fn colorFloor(allocator: std.mem.Allocator, tiles: []Tile) !Floor {
    // Calculate dimensions of (legal) floor.
    var min_cols = tiles[0][0];
    var min_rows = tiles[0][1];
    var max_cols = tiles[0][0];
    var max_rows = tiles[0][1];
    for (tiles[1..]) |tile| {
        if (tile[0] < min_cols) min_cols = tile[0];
        if (tile[1] < min_rows) min_rows = tile[1];
        if (tile[0] >= max_cols) max_cols = tile[0] + 1;
        if (tile[1] >= max_rows) max_rows = tile[1] + 1;
    }

    var floor = try Floor.init(allocator, min_rows, min_cols, max_rows, max_cols);
    var prev = tiles[tiles.len - 1];

    for (tiles) |tile| {
        const row = tile[1];
        // Set horizontal lines.
        if (row == prev[1]) {
            const min = @min(tile[0], prev[0]);
            const max = @max(tile[0], prev[0]);
            floor.set(row, min, .red_0);
            floor.set(row, max, .red_1);
            for (min + 1..max) |col| floor.set(row, col, .green);
        }
        prev = tile;
    }

    for (min_cols..max_cols) |col| {
        var is_green = false;
        var last_red = Color.other;
        for (min_rows..max_rows) |row| {
            const color = floor.get(row, col);
            switch (color) {
                .other => if (is_green or last_red != .other) floor.set(row, col, .green),
                .green => is_green = !is_green,
                .red_0, .red_1 => switch (last_red) {
                    .red_0, .red_1 => {
                        is_green = (last_red == color) == is_green;
                        last_red = .other;
                    },
                    .other => last_red = color,
                    .green => unreachable,
                },
            }
        }
    }

    return floor;
}
test "colorFloor(example)" {
    const allocator = std.testing.allocator;

    const tiles = try parseTiles(allocator, example);
    defer allocator.free(tiles);

    var floor = try colorFloor(allocator, tiles);
    defer floor.deinit(allocator);

    var i: usize = 0;
    for (
        \\.....#XXX#
        \\.....XXXXX
        \\#XXXX#XXXX
        \\XXXXXXXXXX
        \\#XXXXXX#XX
        \\.......XXX
        \\.......#X#
    ) |char| {
        const color = floor.colors[i];
        switch (char) {
            '.' => try std.testing.expectEqual(Color.other, color),
            '#' => try std.testing.expect(color == Color.red_0 or color == Color.red_1),
            'X' => try std.testing.expectEqual(Color.green, color),
            '\n' => continue,
            else => unreachable,
        }
        i += 1;
    }
    for (tiles) |tile| {
        const color = floor.get(tile[1], tile[0]);
        try std.testing.expect(color == .red_0 or color == .red_1);
    }
}

fn solve2(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const tiles = try parseTiles(allocator, input);
    var floor = try colorFloor(allocator, tiles);

    var max: u64 = 0;
    for (tiles, 0..) |one, i| {
        mid: for (tiles[i + 1 ..]) |two| {
            const area = calculateArea(one, two);
            if (area < max) continue :mid;
            const col_0 = @min(one[0], two[0]);
            const row_0 = @min(one[1], two[1]);
            const row_1 = @max(one[1], two[1]);
            const col_1 = @max(one[0], two[0]);
            for (row_0..row_1 + 1) |row| {
                for (col_0..col_1 + 1) |col| {
                    if (floor.get(row, col) == .other) continue :mid;
                }
            }
            max = area;
        }
    }
    return max;
}
test "solve2(example)" {
    try std.testing.expectEqual(24, try solve2(example));
}

pub fn main() !void {
    const input = @embedFile("./inputs/9.txt");
    try lib.print(try solve1(input));
    try lib.print(try solve2(input));
}
