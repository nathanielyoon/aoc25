const std = @import("std");
const example =
    \\123 328  51 64 
    \\ 45 64  387 23 
    \\  6 98  215 314
    \\*   +   *   +  
;

const Operation = enum { add, mul };
const Inputs = struct {
    lines: std.mem.SplitBackwardsIterator(u8, .scalar),
    operations: std.ArrayList(Operation),
    accumulators: []u64,
};
fn parseInputs(allocator: std.mem.Allocator, input: []const u8) !Inputs {
    var lines = std.mem.splitBackwardsScalar(u8, std.mem.trim(u8, input, "\n"), '\n');

    var operations = try std.array_list.Aligned(Operation, null).initCapacity(allocator, 1);
    var it = std.mem.tokenizeScalar(u8, lines.first(), ' ');
    while (it.next()) |op| switch (op[0]) {
        '+' => try operations.append(allocator, .add),
        '*' => try operations.append(allocator, .mul),
        else => unreachable,
    };

    var accumulators = try allocator.alloc(u64, operations.items.len);
    for (operations.items, 0..) |op, i| accumulators[i] = switch (op) {
        .add => 0,
        .mul => 1,
    };

    return Inputs{ .lines = lines, .operations = operations, .accumulators = accumulators };
}
test "parseInputs(example) parses" {
    const allocator = std.testing.allocator;

    var actual = try parseInputs(allocator, example);
    defer actual.operations.deinit(allocator);
    defer allocator.free(actual.accumulators);

    try std.testing.expectEqualStrings("  6 98  215 314", actual.lines.next().?);
    try std.testing.expectEqualStrings(" 45 64  387 23 ", actual.lines.next().?);
    try std.testing.expectEqualStrings("123 328  51 64 ", actual.lines.next().?);

    try std.testing.expectEqualDeep(&[_]Operation{ .mul, .add, .mul, .add }, actual.operations.items);

    try std.testing.expectEqualDeep(&[_]u64{ 1, 0, 1, 0 }, actual.accumulators);
}

fn solve1(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var inputs = try parseInputs(allocator, input);

    while (inputs.lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        var i: usize = 0;
        while (it.next()) |slice| : (i += 1) {
            const int = try std.fmt.parseInt(u64, slice, 10);
            switch (inputs.operations.items[i]) {
                .add => inputs.accumulators[i] += int,
                .mul => inputs.accumulators[i] *= int,
            }
        }
    }
    var total: u64 = 0;
    for (inputs.accumulators) |a| total += a;
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
