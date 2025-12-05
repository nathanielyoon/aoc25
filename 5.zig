const std = @import("std");
const example =
    \\3-5
    \\10-14
    \\16-20
    \\12-18
    \\
    \\1
    \\5
    \\8
    \\11
    \\17
    \\32
;

fn parseU64(digits: []const u8) u64 {
    return std.fmt.parseInt(u64, digits, 10) catch unreachable;
}
/// Trims trailing linefeeds and splits into the remaining lines.
fn split(lines: []const u8) std.mem.SplitIterator(u8, .scalar) {
    return std.mem.splitScalar(u8, std.mem.trim(u8, lines, "\n"), '\n');
}
/// Finds the index of the double linefeed.
fn blank(input: []const u8) usize {
    return std.mem.find(u8, input, "\n\n") orelse input.len;
}
/// Creates a list of fresh ranges in ascending order of their respective lower bounds.
/// While the input's ranges are inclusive, the returned ranges exclude the upper bound.
fn parseFresh(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList([2]u64) {
    var list = try std.array_list.Aligned([2]u64, null).initCapacity(allocator, 1);
    var it = split(input[0..blank(input)]);
    top: while (it.next()) |slice| {
        const dash = std.mem.findScalar(u8, slice, '-').?;
        const min = parseU64(slice[0..dash]);
        const max = parseU64(slice[dash + 1 ..]) + 1;
        for (list.items, 0..) |next, i| {
            if (min <= next[0]) {
                try list.insert(allocator, i, .{ min, max });
                continue :top;
            }
        }
        try list.append(allocator, .{ min, max });
    }
    std.debug.assert(list.items.len > 0);
    return list;
}
test "parseFresh(example) parses" {
    const allocator = std.testing.allocator;

    var expected = try std.array_list.Aligned([2]u64, null).initCapacity(allocator, 4);
    defer expected.deinit(allocator);
    expected.appendSliceAssumeCapacity(&.{
        .{ 3, 6 },
        .{ 10, 15 },
        .{ 12, 19 },
        .{ 16, 21 },
    });

    var actual = try parseFresh(allocator, example);
    defer actual.deinit(allocator);

    try std.testing.expectEqualDeep(expected.items, actual.items);
}

/// Creates a list of available IDs in ascending order.
fn parseAvailable(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(u64) {
    var list = try std.array_list.Aligned(u64, null).initCapacity(allocator, 1);
    var it = split(input[blank(input) + 1 ..]);
    top: while (it.next()) |slice| {
        const id = parseU64(slice);
        for (list.items, 0..) |next, i| {
            if (id <= next) {
                try list.insert(allocator, i, id);
                continue :top;
            }
        }
        try list.append(allocator, id);
    }
    std.debug.assert(list.items.len > 0);
    return list;
}
test "parseAvailable(example) parses" {
    const allocator = std.testing.allocator;

    var expected = try std.array_list.Aligned(u64, null).initCapacity(allocator, 6);
    defer expected.deinit(allocator);
    expected.appendSliceAssumeCapacity(&.{ 1, 5, 8, 11, 17, 32 });

    var actual = try parseAvailable(allocator, example);
    defer actual.deinit(allocator);
    try std.testing.expectEqualDeep(expected.items, actual.items);
}

fn solve1(input: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const fresh = try parseFresh(allocator, input);
    const available = try parseAvailable(allocator, input);
    var total: u32 = 0;
    var last: usize = 0;
    top: for (available.items) |id| {
        while (last < fresh.items.len) : (last += 1) {
            // Spoiled!
            if (id < fresh.items[last][0]) continue :top;
            // Fresh!
            if (id < fresh.items[last][1]) {
                total += 1;
                continue :top;
            }
        }
    }
    return total;
}
test "solve1(example) solves 1" {
    try std.testing.expectEqual(3, try solve1(example));
}

fn solve2(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const fresh = try parseFresh(allocator, input);
    var total: u64 = 0;
    var prev: u64 = 0;
    for (fresh.items) |range| {
        total += range[1] -| @max(range[0], prev);
        prev = @max(range[1], prev);
    }
    return total;
}
test "solve2() solves trivial cases" {
    const cases: [6][]const u8 = [6][]const u8{
        "1-8",
        "1-8\n1-8",
        "1-3\n3-5\n5-8",
        "1-4\n3-6\n5-8",
        "1-4\n1-6\n1-8",
        "1-6\n3-4\n4-8", // aha!
    };
    for (cases) |input| try std.testing.expectEqual(8, try solve2(input));
}
test "solve2(example) solves 2" {
    try std.testing.expectEqual(14, try solve2(example));
}

pub fn main() !void {
    const input = @embedFile("./inputs/5.txt");
    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n{d}\n", .{
        try solve1(input),
        try solve2(input),
    });
}
