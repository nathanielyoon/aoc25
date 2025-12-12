const std = @import("std");
const lib = @import("./lib.zig");
const example =
    \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
    \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
;
pub fn main() !void {
    const input = @embedFile("./inputs/10.txt");
    try lib.print(try solve1(input));
}

const Machine = struct { lights: u16, buttons: []u16 };
fn parse(allocator: std.mem.Allocator, input: []const u8) ![]Machine {
    var machines = try allocator.alloc(Machine, lib.count(input, '\n'));
    var lines = lib.split(input, '\n');
    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        const lower = std.mem.findScalar(u8, line, ']').?;
        const upper = std.mem.findScalar(u8, line, '{').?;

        var lights: u16 = 0;
        for (line[1..lower], 0..) |char, j| {
            if (char == '#') lights |= @as(u16, 1) << @intCast(j);
        }

        const middle = line[lower + 2 .. upper];
        var buttons = try allocator.alloc(u16, lib.count(middle, ' '));
        var it = lib.split(middle, ' ');
        var j: usize = 0;
        while (it.next()) |button| : (j += 1) {
            buttons[j] = 0;
            for (button[1 .. button.len - 1]) |char| {
                if (char != ',') buttons[j] |= @as(u16, 1) << @intCast(char - '0');
            }
        }

        machines[i] = .{ .lights = lights, .buttons = buttons };
    }
    return machines;
}
test "parse(example)" {
    const allocator = std.testing.allocator;

    const machines = try parse(allocator, example);
    defer {
        for (machines) |machine| allocator.free(machine.buttons);
        allocator.free(machines);
    }

    try std.testing.expectEqualDeep(Machine{
        .lights = 0b0110,
        .buttons = @constCast(&[_]u16{ 0b1000, 0b1010, 0b0100, 0b1100, 0b0101, 0b0011 }),
    }, machines[0]);
    try std.testing.expectEqualDeep(Machine{
        .lights = 0b01000,
        .buttons = @constCast(&[_]u16{ 0b11101, 0b01100, 0b10001, 0b00111, 0b11110 }),
    }, machines[1]);
    try std.testing.expectEqualDeep(Machine{
        .lights = 0b101110,
        .buttons = @constCast(&[_]u16{ 0b011111, 0b011001, 0b110111, 0b000110 }),
    }, machines[2]);
}

fn solve1(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const machines = try parse(allocator, input);

    var total: u64 = 0;
    top: for (machines) |machine| {
        var outer = try std.array_list.Aligned([2]u16, null).initCapacity(allocator, 1);
        outer.appendAssumeCapacity(.{ 0, 0 });
        for (machine.buttons) |button| {
            if (button == machine.lights) {
                total += 1;
                continue :top;
            }
            var inner = try allocator.alloc([2]u16, outer.items.len);
            for (outer.items, 0..) |prev, i| inner[i] = .{ prev[0] ^ button, prev[1] + 1 };
            try outer.appendSlice(allocator, inner);
        }
        var min: u16 = std.math.maxInt(u16);
        for (outer.items) |item| {
            if (item[0] == machine.lights and item[1] < min) min = item[1];
        }
        total += @intCast(min);
    }
    return total;
}
test "solve1(example)" {
    try std.testing.expectEqual(7, try solve1(example));
}
