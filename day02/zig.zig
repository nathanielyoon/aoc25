const std = @import("std");
const Range = struct { min: u64, max: u64 };

fn parse(allocator: std.mem.Allocator, ranges: []const u8) !std.ArrayList(Range) {
    var outer = std.mem.splitScalar(u8, ranges, ',');
    var list = try std.array_list.Aligned(Range, null).initCapacity(allocator, 1);
    while (outer.next()) |range| {
        var inner = std.mem.splitScalar(u8, std.mem.trim(u8, range, "\n"), '-');
        try list.append(allocator, .{
            .min = std.fmt.parseInt(u64, inner.first(), 10) catch unreachable,
            .max = std.fmt.parseInt(u64, inner.peek().?, 10) catch unreachable,
        });
    }
    return list;
}
test "parse() handles example" {
    const allocator = std.testing.allocator;

    var actual = try parse(allocator, @embedFile("./example.txt"));
    defer actual.deinit(allocator);

    var expected = try std.array_list.Aligned(Range, null).initCapacity(allocator, 11);
    defer expected.deinit(allocator);
    expected.appendSliceAssumeCapacity(&.{
        .{ .min = 11, .max = 22 },
        .{ .min = 95, .max = 115 },
        .{ .min = 998, .max = 1012 },
        .{ .min = 1188511880, .max = 1188511890 },
        .{ .min = 222220, .max = 222224 },
        .{ .min = 1698522, .max = 1698528 },
        .{ .min = 446443, .max = 446449 },
        .{ .min = 38593856, .max = 38593862 },
        .{ .min = 565653, .max = 565659 },
        .{ .min = 824824821, .max = 824824827 },
        .{ .min = 2121212118, .max = 2121212124 },
    });

    try std.testing.expectEqualDeep(expected, actual);
}

fn countDigits(id: u64) u64 {
    const float: f64 = @floatFromInt(id);
    const log: u64 = @intFromFloat(@log10(float));
    return log + 1;
}

fn solve(comptime validate: fn (id: u64) bool, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const list = try parse(allocator, input);
    var invalid: u64 = 0;
    for (list.items) |range| {
        var id = range.min;
        while (id <= range.max) : (id += 1) {
            if (!validate(id)) invalid += id;
        }
    }
    return invalid;
}

fn validate1(id: u64) bool {
    const digits = countDigits(id);
    // Odd number of digits, so can't be a doubled sequence.
    if (digits & 1 != 0) return true;
    const half = std.math.pow(u64, 10, digits >> 1);
    return id % half != id / half;
}
test "validate1() handles trivial cases" {
    try std.testing.expect(validate1(1) == true);
    try std.testing.expect(validate1(11) == false);
}
test "validate1() handles invalid examples" {
    const ids = [_]u64{ 11, 22, 99, 1010, 1188511885, 222222, 446446, 38593859 };
    for (ids) |id| try std.testing.expect(validate1(id) == false);
}
test "validate1() handles example" {
    try std.testing.expectEqual(1227775554, try solve(validate1, @embedFile("./example.txt")));
}

fn validate2(id: u64) bool {
    const digits = countDigits(id);
    top: for (1..(digits >> 1) + 1) |size| {
        // Subsequence length doesn't fit evenly into the overall sequence.
        if (digits % size != 0) continue;

        const part = std.math.pow(u64, 10, size);
        const base = id % part;
        for (1..digits / size) |step| {
            if (id / std.math.pow(u64, part, step) % part != base) continue :top;
        }
        return false;
    }
    return true;
}
test "validateId2() handles trivial cases" {
    try std.testing.expect(validate2(1) == true);
    try std.testing.expect(validate2(11) == false);
    try std.testing.expect(validate2(111) == false);
}
test "validateId2() handles invalid examples" {
    const ids = [_]u64{ 11, 22, 99, 111, 999, 1010, 1188511885, 222222, 446446, 38593859, 565656, 824824824, 2121212121 };
    for (ids) |id| try std.testing.expect(validate2(id) == false);
}
test "validate2() handles example" {
    try std.testing.expectEqual(4174379265, try solve(validate2, @embedFile("./example.txt")));
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    var writer = std.fs.File.stdout().writer(&.{}).interface;
    try writer.print("1: {d}\n2: {d}\n", .{
        try solve(validate1, input),
        try solve(validate2, input),
    });
}
