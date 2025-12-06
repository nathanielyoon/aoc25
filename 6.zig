const std = @import("std");
const example =
    \\123 328  51 64 
    \\ 45 64  387 23 
    \\  6 98  215 314
    \\*   +   *   +  
;

const Operation = enum { add, mul };

fn solve1(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var lines = std.mem.splitBackwardsScalar(u8, std.mem.trim(u8, input, "\n"), '\n');
    var operations = try std.array_list.Aligned(Operation, null).initCapacity(allocator, 1);
    defer operations.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, lines.first(), ' ');
    while (it.next()) |s| switch (s[0]) {
        '+' => try operations.append(allocator, .add),
        '*' => try operations.append(allocator, .mul),
        else => unreachable,
    };

    var accumulators = try allocator.alloc(u64, operations.items.len);
    defer allocator.free(accumulators);

    for (operations.items, 0..) |o, i| switch (o) {
        .add => accumulators[i] = 0,
        .mul => accumulators[i] = 1,
    };
    while (lines.next()) |line| {
        it = std.mem.tokenizeScalar(u8, line, ' ');
        var i: usize = 0;
        while (it.next()) |s| : (i += 1) {
            const int = try std.fmt.parseInt(u64, s, 10);
            switch (operations.items[i]) {
                .add => accumulators[i] += int,
                .mul => accumulators[i] *= int,
            }
        }
    }
    var total: u64 = 0;
    for (accumulators) |a| total += a;
    return total;
}
test "solve1(example) solves 1" {
    try std.testing.expectEqual(4277556, solve1(example));
}

pub fn main() !void {
    const input = @embedFile("./inputs/6.txt");
    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n", .{
        try solve1(input),
    });
}
