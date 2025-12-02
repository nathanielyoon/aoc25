const std = @import("std");
const example = @embedFile("./example.txt");
const input = @embedFile("./input.txt");

const Allocator = std.mem.Allocator;
const Range = struct { min: f64, max: f64 };

fn parse(allocator: Allocator, ranges: []const u8) Allocator.Error!std.ArrayList(Range) {
    var outer = std.mem.splitScalar(u8, ranges, ',');
    var list = try std.array_list.Aligned(Range, null).initCapacity(allocator, 1);
    while (outer.next()) |range| {
        var inner = std.mem.splitScalar(u8, std.mem.trim(u8, range, "\n"), '-');
        try list.append(allocator, .{
            .min = std.fmt.parseFloat(f64, inner.first()) catch unreachable,
            .max = std.fmt.parseFloat(f64, inner.peek().?) catch unreachable,
        });
    }
    return list;
}
test "parse example" {
    const allocator = std.testing.allocator;

    var actual = try parse(allocator, example);
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

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const list = try parse(allocator, input);

    std.debug.print("{any}\n", .{list});
}
