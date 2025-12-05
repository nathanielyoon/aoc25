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

const Ingredients = struct {
    fresh: std.ArrayList([2]u64),
    available: std.ArrayList(u64),
};
fn parseU64(digits: []const u8) u64 {
    return std.fmt.parseInt(u64, digits, 10) catch unreachable;
}
fn split(lines: []const u8) std.mem.SplitIterator(u8, .scalar) {
    return std.mem.splitScalar(u8, std.mem.trimEnd(u8, lines, "\n"), '\n');
}
fn parseIngredients(allocator: std.mem.Allocator, input: []const u8) !Ingredients {
    const blank = std.mem.find(u8, input, "\n\n").?;
    std.debug.assert(std.mem.findLast(u8, input, "\n\n").? == blank);

    // Insert fresh ranges in ascending order of lower bounds.
    var fresh = try std.array_list.Aligned([2]u64, null).initCapacity(allocator, 4);
    var it_fresh = split(input[0..blank]);
    top: while (it_fresh.next()) |slice| {
        const dash = std.mem.findScalar(u8, slice, '-').?;
        const min = parseU64(slice[0..dash]);
        const max = parseU64(slice[dash + 1 ..]);
        for (fresh.items, 0..) |next, i| {
            if (min <= next[0]) {
                try fresh.insert(allocator, i, .{ min, max });
                continue :top;
            }
        }
        try fresh.append(allocator, .{ min, max });
    }
    std.debug.assert(fresh.items.len > 0);

    // Insert available IDs in ascending order.
    var available = try std.array_list.Aligned(u64, null).initCapacity(allocator, 4);
    var it_available = split(input[blank + 2 ..]);
    top: while (it_available.next()) |slice| {
        const id = parseU64(slice);
        for (available.items, 0..) |next, i| {
            if (id <= next) {
                try available.insert(allocator, i, id);
                continue :top;
            }
        }
        try available.append(allocator, id);
    }
    std.debug.assert(available.items.len > 0);

    return Ingredients{ .fresh = fresh, .available = available };
}
test "parseIngredients(example) parses correctly" {
    const allocator = std.testing.allocator;

    var fresh = try std.array_list.Aligned([2]u64, null).initCapacity(allocator, 4);
    defer fresh.deinit(allocator);
    fresh.appendSliceAssumeCapacity(&.{
        .{ 3, 5 },
        .{ 10, 14 },
        .{ 12, 18 },
        .{ 16, 20 },
    });
    var available = try std.array_list.Aligned(u64, null).initCapacity(allocator, 6);
    defer available.deinit(allocator);
    available.appendSliceAssumeCapacity(&.{ 1, 5, 8, 11, 17, 32 });

    var actual = try parseIngredients(allocator, example);
    defer actual.fresh.deinit(allocator);
    defer actual.available.deinit(allocator);

    try std.testing.expectEqualDeep(fresh.items, actual.fresh.items);
    try std.testing.expectEqualDeep(available.items, actual.available.items);
}

fn solve1(input: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ingredients = try parseIngredients(allocator, input);
    var total: u32 = 0;
    var fresh: usize = 0;
    top: for (ingredients.available.items) |id| {
        while (fresh < ingredients.fresh.items.len) : (fresh += 1) {
            const min, const max = ingredients.fresh.items[fresh];
            // Spoiled!
            if (id < min) continue :top;
            // Fresh!
            if (id <= max) {
                total += 1;
                continue :top;
            }
        }
    }
    return total;
}
test "solve1(example) solves 1" {
    try std.testing.expectEqual(3, solve1(example));
}

pub fn main() !void {
    const input = @embedFile("./inputs/5.txt");
    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n", .{
        try solve1(input),
    });
}
