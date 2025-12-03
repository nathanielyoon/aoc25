const std = @import("std");

fn find(comptime T: type, comptime size: usize, bank: []const u8) T {
    std.debug.assert(bank.len >= size);
    var max = [_]u8{'0'} ** size;
    var i: usize = 0;
    while (i < bank.len) : (i += 1) {
        const joltage = bank[i];
        var digit = size - @min(bank.len - i, size);
        while (digit < size) : (digit += 1) {
            if (joltage > max[digit]) {
                max[digit] = joltage;
                @memset(max[digit + 1 ..], '0');
                break;
            }
        }
    }
    return std.fmt.parseInt(T, &max, 10) catch unreachable;
}

test "find(u32, 2, line) finds largest joltage" {
    try std.testing.expectEqual(98, find(u32, 2, "987654321111111"));
    try std.testing.expectEqual(89, find(u32, 2, "811111111111119"));
    try std.testing.expectEqual(78, find(u32, 2, "234234234234278"));
    try std.testing.expectEqual(92, find(u32, 2, "818181911112111"));
}
test "find(u64, 12, line) finds largest joltage" {
    try std.testing.expectEqual(987654321111, find(u64, 12, "987654321111111"));
    try std.testing.expectEqual(811111111119, find(u64, 12, "811111111111119"));
    try std.testing.expectEqual(434234234278, find(u64, 12, "234234234234278"));
    try std.testing.expectEqual(888911112111, find(u64, 12, "818181911112111"));
}

fn solve(comptime T: type, comptime size: usize, input: []const u8) T {
    var it = std.mem.splitScalar(u8, input, '\n');
    var total: T = 0;
    while (it.next()) |bank| {
        if (bank.len > 0) total += find(T, size, bank);
    }
    return total;
}
test "solve(u32, 2, example) calculates correct total" {
    try std.testing.expectEqual(357, solve(u32, 2,
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ));
}
test "solve(u64, 12, example) calculates correct total" {
    try std.testing.expectEqual(3121910778619, solve(u64, 12,
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ));
}

pub fn main() !void {
    const input = @embedFile("./inputs/3.txt");

    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n{d}\n", .{
        solve(u32, 2, input),
        solve(u64, 12, input),
    });
}
