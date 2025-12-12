const std = @import("std");
const lib = @import("lib.zig");
const example =
    \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
    \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
;
pub fn main() !void {
    const input = @embedFile("./inputs/10.txt");
    try lib.print(try solve1(input));
}

const Machine1 = struct { lights: u16, buttons: []u16 };
fn parse1(allocator: std.mem.Allocator, input: []const u8) ![]Machine1 {
    var machines = try allocator.alloc(Machine1, lib.count(input, '\n'));
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

    const machines = try parse1(allocator, example);
    defer {
        for (machines) |machine| allocator.free(machine.buttons);
        allocator.free(machines);
    }

    try std.testing.expectEqualDeep(Machine1{
        .lights = 0b0110,
        .buttons = @constCast(&[_]u16{ 0b1000, 0b1010, 0b0100, 0b1100, 0b0101, 0b0011 }),
    }, machines[0]);
    try std.testing.expectEqualDeep(Machine1{
        .lights = 0b01000,
        .buttons = @constCast(&[_]u16{ 0b11101, 0b01100, 0b10001, 0b00111, 0b11110 }),
    }, machines[1]);
    try std.testing.expectEqualDeep(Machine1{
        .lights = 0b101110,
        .buttons = @constCast(&[_]u16{ 0b011111, 0b011001, 0b110111, 0b000110 }),
    }, machines[2]);
}

fn solve1(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const machines = try parse1(allocator, input);

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

const Machine2 = struct { joltage: []u16, buttons: []@Vector(10, u16) };
fn parse2(allocator: std.mem.Allocator, input: []const u8) ![]Machine2 {
    var machines = try allocator.alloc(Machine2, lib.count(input, '\n'));
    var lines = lib.split(input, '\n');
    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        const lower = std.mem.findScalar(u8, line, ']').?;
        const upper = std.mem.findScalar(u8, line, '{').?;

        const middle = line[lower + 2 .. upper];
        var buttons = try allocator.alloc(@Vector(10, u16), lib.count(middle, ' '));
        var it = lib.split(middle, ' ');
        var j: usize = 0;
        while (it.next()) |button| : (j += 1) {
            var set = [_]u16{0} ** 10;
            for (button[1 .. button.len - 1]) |char| {
                if (char != ',') set[char - '0'] = 1;
            }
            inline for (0..10) |k| buttons[j][k] = set[k];
        }

        const joltage = try allocator.alloc(u16, 10);
        @memset(joltage, 0);
        var joltages = lib.split(line[upper + 1 .. line.len - 1], ',');
        j = 0;
        while (joltages.next()) |slice| : (j += 1) {
            joltage[j] = try std.fmt.parseInt(u16, slice, 10);
        }

        machines[i] = .{ .joltage = joltage, .buttons = buttons };
    }
    return machines;
}
test "parse2(example)" {
    const allocator = std.testing.allocator;

    const machines = try parse2(allocator, example);
    defer {
        for (machines) |machine| {
            allocator.free(machine.joltage);
            allocator.free(machine.buttons);
        }
        allocator.free(machines);
    }

    try std.testing.expectEqualDeep(Machine2{
        .buttons = @constCast(&[_]@Vector(10, u16){
            .{ 0, 0, 0, 1, 0, 0, 0, 0, 0, 0 },
            .{ 0, 1, 0, 1, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 1, 1, 0, 0, 0, 0, 0, 0 },
            .{ 1, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
            .{ 1, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
        }),
        .joltage = @constCast(&[_]u16{ 3, 5, 4, 7, 0, 0, 0, 0, 0, 0 }),
    }, machines[0]);
    try std.testing.expectEqualDeep(Machine2{
        .buttons = @constCast(&[_]@Vector(10, u16){
            .{ 1, 0, 1, 1, 1, 0, 0, 0, 0, 0 },
            .{ 0, 0, 1, 1, 0, 0, 0, 0, 0, 0 },
            .{ 1, 0, 0, 0, 1, 0, 0, 0, 0, 0 },
            .{ 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
        }),
        .joltage = @constCast(&[_]u16{ 7, 5, 12, 7, 2, 0, 0, 0, 0, 0 }),
    }, machines[1]);
    try std.testing.expectEqualDeep(Machine2{
        .buttons = @constCast(&[_]@Vector(10, u16){
            .{ 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
            .{ 1, 0, 0, 1, 1, 0, 0, 0, 0, 0 },
            .{ 1, 1, 1, 0, 1, 1, 0, 0, 0, 0 },
            .{ 0, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
        }),
        .joltage = @constCast(&[_]u16{ 10, 11, 11, 5, 10, 5, 0, 0, 0, 0 }),
    }, machines[2]);
}

fn solve2(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var total: u64 = 0;
    for (try parse2(allocator, input)) |machine| {
        var outer = try std.array_list.Aligned(struct { @Vector(10, u16), u16 }, null).initCapacity(allocator, 1);
        outer.appendAssumeCapacity(.{ @splat(0), 0 });
        var count: usize = 1;
        while (true) : (count += 1) {
            for (machine.buttons) |button| {
                var inner = try allocator.alloc(struct { @Vector(10, u16), u16 }, outer.items.len * count);
                for (outer.items, 0..) |prev, i| {
                    for (0..count) |j| {
                        inner[i * count + j] = .{ prev[0] + button, prev[1] + 1 };
                    }
                }
                try outer.appendSlice(allocator, inner);
            }
            var min: u16 = std.math.maxInt(u16);
            mid: for (outer.items) |item| {
                if (item[1] >= min) continue :mid;
                inline for (0..10) |i| {
                    if (item[0][i] != machine.joltage[i]) continue :mid;
                }
                min = item[1];
            }
            if (min != std.math.maxInt(u16)) {
                total += @intCast(min);
                break;
            }
        }
    }

    return total;
}
test "solve2(example)" {
    try std.testing.expectEqual(33, try solve2(example));
}
