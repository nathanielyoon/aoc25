const std = @import("std");
const lib = @import("lib.zig");
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
    const input = @embedFile("./inputs/09.txt");
    try lib.print(try solve1(input));
    try lib.print(try solve2(input));
}

const Tile = @Vector(2, usize);
fn parseTiles(allocator: std.mem.Allocator, input: []const u8) ![]Tile {
    const size = lib.count(input, '\n');
    var tiles = try allocator.alloc(Tile, size);
    var lines = lib.split(input, '\n');
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

const Box = struct {
    min: Tile,
    max: Tile,
    fn draw(one: Tile, two: Tile) Box {
        return .{
            .min = .{ @min(one[0], two[0]), @min(one[1], two[1]) },
            .max = .{ @max(one[0], two[0]), @max(one[1], two[1]) },
        };
    }
    fn overlaps(self: *Box, with: Box) bool {
        return with.min[0] <= self.max[0] and
            self.min[0] <= with.max[0] and
            with.min[1] <= self.max[1] and
            self.min[1] <= with.max[1];
    }
};
fn drawLines(allocator: std.mem.Allocator, tiles: []Tile) ![]Box {
    var lines = try allocator.alloc(Box, tiles.len);
    for (tiles, 0..) |tile, i| lines[i] = Box.draw(tile, tiles[(i + 1) % tiles.len]);
    return lines;
}
test "drawLines(example)" {
    const allocator = std.testing.allocator;

    const tiles = try parseTiles(allocator, example);
    defer allocator.free(tiles);

    var lines = try drawLines(allocator, tiles);
    defer allocator.free(lines);

    try std.testing.expectEqualSlices(Box, &.{
        .{ .min = .{ 7, 1 }, .max = .{ 11, 1 } },
        .{ .min = .{ 11, 1 }, .max = .{ 11, 7 } },
        .{ .min = .{ 9, 7 }, .max = .{ 11, 7 } },
        .{ .min = .{ 9, 5 }, .max = .{ 9, 7 } },
        .{ .min = .{ 2, 5 }, .max = .{ 9, 5 } },
        .{ .min = .{ 2, 3 }, .max = .{ 2, 5 } },
        .{ .min = .{ 2, 3 }, .max = .{ 7, 3 } },
        .{ .min = .{ 7, 1 }, .max = .{ 7, 3 } },
    }, lines);
    for (lines, 0..) |*line, i| {
        try std.testing.expect(line.overlaps(lines[(i + 1) % lines.len]));
    }
}

fn compareBoxes(_: void, one: Box, two: Box) bool {
    return calculateArea(one.min, one.max) < calculateArea(two.min, two.max);
}
fn solve2(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const tiles = try parseTiles(allocator, input);
    const lines = try drawLines(allocator, tiles);

    var boxes = try allocator.alloc(Box, tiles.len * (tiles.len - 1) / 2);
    var i: usize = 0;
    for (tiles, 0..) |one, j| {
        for (tiles[j + 1 ..]) |two| {
            boxes[i] = Box.draw(one, two);
            i += 1;
        }
    }

    std.sort.pdq(Box, boxes, {}, compareBoxes);

    std.debug.assert(i == boxes.len);
    top: while (i > 0) {
        i -= 1;
        var box = boxes[i];
        const area = calculateArea(box.min, box.max);
        box.min[0] += 1;
        box.min[1] += 1;
        box.max[0] -= 1;
        box.max[1] -= 1;
        for (lines) |line| if (box.overlaps(line)) continue :top;
        return area;
    }
    unreachable;
}
test "solve2(example)" {
    try std.testing.expectEqual(24, try solve2(example));
}
