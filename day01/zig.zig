const std = @import("std");

fn solve1(input: []const u8) u32 {
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

fn solve2(input: []const u8) u32 {
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
                while (distance > 100) : (distance -= 100) count += 1;
                switch (direction) {
                    'L' => {
                        const prev = state;
                        state -= @intCast(distance);
                        if (state < 0) {
                            state += 100;
                            if (prev != 0) count += 1;
                        } else if (state == 0) count += 1;
                    },
                    'R' => {
                        state += @intCast(distance);
                        if (state >= 100) {
                            state -= 100;
                            count += 1;
                        } else if (state == 0) count += 1;
                    },
                    else => unreachable,
                }
                direction = undefined;
                distance = 0;
            },
            else => unreachable,
        }
    }
    return count;
}

const example = @embedFile("./example.txt");
test "part 1" {
    try std.testing.expectEqual(3, solve1(example));
}
test "part 2" {
    try std.testing.expectEqual(6, solve2(example));
}

pub fn main() !void {
    const input = @embedFile("./input.txt");

    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("1: {d}\n2: {d}\n", .{
        solve1(input),
        solve2(input),
    });
}
