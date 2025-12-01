const std = @import("std");

pub fn solve1(input: []const u8) u32 {
    var reverse: bool = undefined;
    var distance: i32 = 0;
    var state: i32 = 50;
    var count: u32 = 0;
    for (input) |character| {
        switch (character) {
            'L' => reverse = true,
            'R' => reverse = false,
            '0'...'9' => {
                distance *= 10;
                distance += character - '0';
            },
            '\n' => {
                if (reverse) distance *= -1;
                state = @mod(state + distance, 100);
                if (state == 0) count += 1;
                distance = 0;
            },
            else => unreachable,
        }
    }
    return count;
}
test "example 1" {
    const example =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    try std.testing.expectEqual(solve1(example), 3);
}
