const std = @import("std");

fn solve(comptime find: fn (bank: []const u8) u32, input: []const u8) u32 {
    var it = std.mem.splitScalar(u8, input, '\n');
    var total: u32 = 0;
    while (it.next()) |bank| {
        if (bank.len >= 2) total += find(bank);
    }
    return total;
}

fn find1(bank: []const u8) u32 {
    std.debug.assert(bank.len >= 2);
    var upper = bank[0] - '0';
    var lower = bank[1] - '0';
    var index: usize = 1;
    while (index < bank.len - 1) : (index += 1) {
        const joltage = bank[index] - '0';
        if (joltage > upper) {
            upper = joltage;
            lower = bank[index + 1] - '0';
        } else if (joltage > lower) lower = joltage;
    }
    return upper * 10 + @max(lower, bank[index] - '0');
}
test "find1(line) finds largest joltage" {
    try std.testing.expectEqual(98, find1("987654321111111"));
    try std.testing.expectEqual(89, find1("811111111111119"));
    try std.testing.expectEqual(78, find1("234234234234278"));
    try std.testing.expectEqual(92, find1("818181911112111"));
}
test "solve(find1, example) calculates correct total" {
    try std.testing.expectEqual(357, solve(find1,
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    ));
}

pub fn main() !void {
    const input = @embedFile("./inputs/3.txt");

    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n", .{
        solve(find1, input),
    });
}
