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
    \\
;

fn countRows(comptime diagram: []const u8) comptime_int {
    @setEvalBranchQuota(1e5);
    var rows = 0;
    for (diagram) |c| {
        if (c == '\n') rows += 1;
    }
    return rows;
}
test "countRows(example) finds right height" {
    try std.testing.expectEqual(10, countRows(example));
}
fn countCols(comptime diagram: []const u8) comptime_int {
    for (diagram, 0..) |c, i| {
        if (c == '\n') return i;
    }
    unreachable;
}
test "countCols(example) finds right width" {
    try std.testing.expectEqual(10, countCols(example));
}

fn check(diagram: []const u8, i: usize) u8 {
    if (i >= diagram.len) return 0;
    var total: u8 = 0;
    if (i > 0 and diagram[i - 1] == '@') total += 1;
    if (diagram[i] == '@') total += 1;
    if (i < diagram.len - 1 and diagram[i + 1] == '@') total += 1;
    return total;
}

fn solve1(comptime diagram: []const u8) u32 {
    const rows = countRows(diagram);
    const cols = countCols(diagram) + 1;
    const size = rows * cols;
    var counts = [_]u8{0} ** size;
    for (&counts, 0..) |*c, i| if (diagram[i] == '@') {
        c.* = check(diagram, i) - 1 + check(diagram, i + cols);
        if (i >= cols) c.* += check(diagram, i - cols);
    };
    var total: u32 = 0;
    for (diagram, 0..) |c, i| {
        if (c == '@' and counts[i] < 4) total += 1;
    }
    return total;
}
test "solve1(example) solves" {
    try std.testing.expectEqual(13, solve1(example));
}

pub fn main() !void {
    const input = @embedFile("./inputs/4.txt");
    var writer = std.fs.File.stdout().writer(&.{});
    try writer.interface.print("{d}\n", .{
        solve1(input),
    });
}
