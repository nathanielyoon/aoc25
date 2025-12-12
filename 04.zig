const std = @import("std");
const example =
    \\..@@.@@@@.
    \\@@@.@.@.@@
    \\@@@@@.@.@@
    \\@.@@@@..@.
    \\@@.@@@@.@@
    \\.@@@@@@@.@
    \\.@.@.@.@@@
    \\@.@@@.@@@@
    \\.@@@@@@@@.
    \\@.@.@@@.@.
;

fn measure(comptime diagram: []const u8) comptime_int {
    for (diagram, 0..) |c, i| if (c == '\n') return i;
    unreachable;
}
test "measure(example) finds right width" {
    try std.testing.expectEqual(10, measure(example));
}

fn isRoll(character: u8) u8 {
    return @intFromBool(character == '@');
}
fn check(above: []const u8, below: []const u8) u8 {
    std.debug.assert(above.len == below.len);
    var total: u8 = 0;
    for (above) |c| total += isRoll(c);
    for (below) |c| total += isRoll(c);
    return total;
}

fn count(width: comptime_int, source: []const u8, target: []u8) void {
    std.debug.assert(target.len == source.len);

    var above = [_]u8{'.'} ** width;
    var it = std.mem.splitScalar(u8, std.mem.trimEnd(u8, source, "\n"), '\n');
    var i: usize = 0;
    while (it.next()) |row| : (i += width + 1) {
        const below = it.peek() orelse &[_]u8{'.'} ** width;

        // Check leftmost edge.
        target[i] += check(above[0..2], below[0..2]);
        target[i] += isRoll(row[1]);

        // Check inner characters.
        var j: usize = 1;
        while (j < width - 1) : (j += 1) {
            target[i + j] += check(above[j - 1 .. j + 2], below[j - 1 .. j + 2]);
            target[i + j] += isRoll(row[j - 1]) + isRoll(row[j + 1]);
        }

        // Check rightmost edge.
        target[i + width - 1] += check(above[width - 2 ..], below[width - 2 ..]);
        target[i + width - 1] += isRoll(row[width - 2]);

        // This row is above the next one.
        @memcpy(&above, row);
    }
}

fn solve1(comptime source: []const u8) u32 {
    var target = [_]u8{0} ** source.len;
    count(measure(source), source, &target);
    var total: u32 = 0;
    for (source, target) |s, t| if (s == '@' and t < 4) {
        total += 1;
    };
    return total;
}
test "solve1(example) solves 1" {
    try std.testing.expectEqual(13, solve1(example));
}

fn solve2(comptime source: []u8) u32 {
    var target: [source.len]u8 = undefined;

    const width = measure(source);
    var total: u32 = 0;
    // This value gets overwritten on each iteration, it just has to start out
    // different from `total`.
    var prev: u32 = 1;
    while (total != prev) {
        prev = total;
        @memset(&target, 0);
        count(width, source, &target);
        for (source, target, 0..) |s, t, i| if (s == '@' and t < 4) {
            total += 1;
            source[i] = '.';
        };
    }
    return total;
}
test "solve2(example) solves 2" {
    try std.testing.expectEqual(43, solve2(@constCast(example)));
}

pub fn main() !void {
    const input = @embedFile("./inputs/04.txt");
    var writer = std.fs.File.stdout().writer(&.{}).interface;
    try writer.print("{d}\n{d}\n", .{
        solve1(input),
        solve2(@constCast(input)),
    });
}
