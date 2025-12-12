const std = @import("std");
const example =
    \\987654321111111
    \\811111111111119
    \\234234234234278
    \\818181911112111
;

fn find(comptime size: usize, bank: []const u8) u64 {
    if (bank.len < size) return 0;
    var max = [_]u8{'0'} ** size;
    var i: usize = 0;
    while (i < bank.len) : (i += 1) {
        const joltage = bank[i];
        var digit = size - @min(bank.len - i, size);
        while (digit < size) : (digit += 1) if (joltage > max[digit]) {
            max[digit] = joltage;
            @memset(max[digit + 1 ..], '0');
            break;
        };
    }
    return std.fmt.parseInt(u64, &max, 10) catch unreachable;
}

test "find(2, line) finds largest joltage" {
    try std.testing.expectEqual(98, find(2, example[0..15]));
    try std.testing.expectEqual(89, find(2, example[16..31]));
    try std.testing.expectEqual(78, find(2, example[32..47]));
    try std.testing.expectEqual(92, find(2, example[48..63]));
}
test "find(12, line) finds largest joltage" {
    try std.testing.expectEqual(987654321111, find(12, example[0..15]));
    try std.testing.expectEqual(811111111119, find(12, example[16..31]));
    try std.testing.expectEqual(434234234278, find(12, example[32..47]));
    try std.testing.expectEqual(888911112111, find(12, example[48..63]));
}

fn solve(comptime size: usize, input: []const u8) u64 {
    var it = std.mem.splitScalar(u8, input, '\n');
    var total: u64 = 0;
    while (it.next()) |bank| total += find(size, bank);
    return total;
}
test "solve(2, example) calculates correct total" {
    try std.testing.expectEqual(357, solve(2, example));
}
test "solve(12, example) calculates correct total" {
    try std.testing.expectEqual(3121910778619, solve(12, example));
}

pub fn main() !void {
    const input = @embedFile("./inputs/03.txt");
    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n{d}\n", .{
        solve(2, input),
        solve(12, input),
    });
}
