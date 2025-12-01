const std = @import("std");
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
    \\
;

pub fn solve1(input: []const u8) u32 {
    var direction: u8 = undefined;
    var distance: u32 = 0;
    var state: i32 = 50;
    var count: u32 = 0;
    for (input) |character| {
        switch (character) {
            'L', 'R' => direction = character,
            '0'...'9' => {
                distance *= 10;
                distance += character - '0';
            },
            '\n' => {
                switch (direction) {
                    'L' => state -= @intCast(distance),
                    'R' => state += @intCast(distance),
                    else => unreachable,
                }
                state = @mod(state, 100);
                if (state == 0) count += 1;
                direction = undefined;
                distance = 0;
            },
            else => unreachable,
        }
    }
    return count;
}
test "part 1" {
    try std.testing.expectEqual(3, solve1(example));
}
