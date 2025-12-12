const std = @import("std");
const lib = @import("./lib.zig");
const example =
    \\162,817,812
    \\57,618,57
    \\906,360,560
    \\592,479,940
    \\352,342,300
    \\466,668,158
    \\542,29,236
    \\431,825,988
    \\739,650,466
    \\52,470,668
    \\216,146,977
    \\819,987,18
    \\117,168,530
    \\805,96,715
    \\346,949,466
    \\970,615,88
    \\941,993,340
    \\862,61,35
    \\984,92,344
    \\425,690,689
;

/// Point in 3-D space represented as X, Y, and Z coordinates.
const Node = @Vector(3, f32);
/// Calculates the straight-line distance between two points.
fn distance(lhs: Node, rhs: Node) f32 {
    const sub = lhs - rhs;
    return @sqrt(@reduce(.Add, sub * sub));
}
test "distance(example) follows comparisons" {
    const a = Node{ 162, 817, 812 };
    const b = Node{ 425, 690, 689 };
    const c = Node{ 431, 825, 988 };
    const d = Node{ 906, 360, 560 };
    const e = Node{ 805, 96, 715 };
    try std.testing.expect(distance(a, b) < distance(a, c));
    try std.testing.expect(distance(a, c) < distance(d, e));
    try std.testing.expect(distance(d, e) < distance(c, b));
}

/// Parses a list of nodes.
fn parse(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Node) {
    var lines = lib.split(input, '\n');
    var list = try std.array_list.Aligned(Node, null).initCapacity(allocator, 1);
    while (lines.next()) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        try list.append(allocator, .{
            try std.fmt.parseFloat(f32, it.next().?),
            try std.fmt.parseFloat(f32, it.next().?),
            try std.fmt.parseFloat(f32, it.next().?),
        });
    }
    return list;
}
test "parse(example) parses nodes" {
    const allocator = std.testing.allocator;
    var actual = try parse(allocator, example);
    defer actual.deinit(allocator);

    try std.testing.expectEqualSlices(Node, &.{
        .{ 162, 817, 812 },
        .{ 57, 618, 57 },
        .{ 906, 360, 560 },
        .{ 592, 479, 940 },
        .{ 352, 342, 300 },
        .{ 466, 668, 158 },
        .{ 542, 29, 236 },
        .{ 431, 825, 988 },
        .{ 739, 650, 466 },
        .{ 52, 470, 668 },
        .{ 216, 146, 977 },
        .{ 819, 987, 18 },
        .{ 117, 168, 530 },
        .{ 805, 96, 715 },
        .{ 346, 949, 466 },
        .{ 970, 615, 88 },
        .{ 941, 993, 340 },
        .{ 862, 61, 35 },
        .{ 984, 92, 344 },
        .{ 425, 690, 689 },
    }, actual.items);
}

/// Compares two floats.
fn compareF32s(context: f32, item: f32) std.math.Order {
    return std.math.order(context, item);
}
/// Ordered list of the lowest-cost edges.
const Graph = struct {
    max: f32 = std.math.floatMax(f32),
    size: usize,
    lowers: []usize,
    uppers: []usize,
    costs: []f32,
    fn init(allocator: std.mem.Allocator, size: usize) !Graph {
        const costs = try allocator.alloc(f32, size);
        @memset(costs, std.math.floatMax(f32));
        return Graph{
            .size = size,
            .lowers = try allocator.alloc(usize, size),
            .uppers = try allocator.alloc(usize, size),
            .costs = costs,
        };
    }
    fn deinit(self: *Graph, allocator: std.mem.Allocator) void {
        allocator.free(self.lowers);
        allocator.free(self.uppers);
        allocator.free(self.costs);
    }
    fn insert(self: *Graph, lower: usize, upper: usize, cost: f32) void {
        const bound = std.sort.upperBound(f32, self.costs, cost, compareF32s);
        // At least one of the current costs should be greater to call this
        // method.
        std.debug.assert(bound != self.size);

        var i = self.size - 1;
        while (i > bound) : (i -= 1) {
            self.lowers[i] = self.lowers[i - 1];
            self.uppers[i] = self.uppers[i - 1];
            self.costs[i] = self.costs[i - 1];
        }

        // Insert the new edge.
        self.lowers[bound] = lower;
        self.uppers[bound] = upper;
        self.costs[bound] = cost;

        // Update the max cost.
        self.max = self.costs[self.size - 1];
    }
    fn fill(self: *Graph, nodes: []Node) void {
        for (0..nodes.len) |i| {
            const one = nodes[i];
            for (i + 1..nodes.len) |j| {
                const cost = distance(one, nodes[j]);
                if (cost < self.max) self.insert(i, j, cost);
            }
        }
    }
};
test "Graph.init() initializes" {
    const allocator = std.testing.allocator;
    var graph = try Graph.init(allocator, 10);
    defer graph.deinit(allocator);

    try std.testing.expectEqualSlices(f32, graph.costs, &(.{std.math.floatMax(f32)} ** 10));
}
test "Graph.insert() inserts" {
    const allocator = std.testing.allocator;
    var graph = try Graph.init(allocator, 4);
    defer graph.deinit(allocator);

    for (0..4) |i| graph.insert(i, i + 4, @floatFromInt((i + 1) * 100));
    try std.testing.expectEqual(400, graph.max);
    try std.testing.expectEqualSlices(usize, &.{ 0, 1, 2, 3 }, graph.lowers);
    try std.testing.expectEqualSlices(usize, &.{ 4, 5, 6, 7 }, graph.uppers);
    try std.testing.expectEqualSlices(f32, &.{ 100, 200, 300, 400 }, graph.costs);

    graph.insert(8, 9, 350);
    graph.insert(10, 11, 50);
    graph.insert(12, 13, 50);
    try std.testing.expectEqual(200, graph.max);
    try std.testing.expectEqualSlices(usize, &.{ 10, 12, 0, 1 }, graph.lowers);
    try std.testing.expectEqualSlices(usize, &.{ 11, 13, 4, 5 }, graph.uppers);
    try std.testing.expectEqualSlices(f32, &.{ 50, 50, 100, 200 }, graph.costs);
}

test "Graph.fill(example) fills" {
    const allocator = std.testing.allocator;
    var nodes = try parse(allocator, example);
    defer nodes.deinit(allocator);
    var graph = try Graph.init(allocator, 4);
    defer graph.deinit(allocator);
    graph.fill(nodes.items);

    try std.testing.expectEqualSlices(usize, &.{ 0, 0, 2, 7 }, graph.lowers);
    try std.testing.expectEqualSlices(usize, &.{ 19, 7, 13, 19 }, graph.uppers);
}

/// Set of connected nodes.
const Circuit = std.bit_set.DynamicBitSetUnmanaged;
/// Compares two sets by size.
fn circuitsLessThan(_: void, lhs: Circuit, rhs: Circuit) bool {
    return lhs.count() < rhs.count();
}
/// Solves part 1.
fn solve1(input: []const u8, size: usize) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const nodes = (try parse(allocator, input)).items;
    var graph = try Graph.init(allocator, size);
    graph.fill(nodes);

    // Track all sub-graphs with 2+ nodes, starting with the first.
    var first = try Circuit.initEmpty(allocator, nodes.len);
    first.set(graph.lowers[0]);
    first.set(graph.uppers[0]);
    var stack = try std.array_list.Aligned(Circuit, null).initCapacity(allocator, size);
    stack.appendAssumeCapacity(first);

    // For each edge past the first, merge it into the superset of all sets
    // containing either of its nodes.
    for (graph.lowers[1..], graph.uppers[1..]) |lower, upper| {
        // Pop the inclusive circuits into here.
        var local = try std.array_list.Aligned(Circuit, null).initCapacity(allocator, 0);

        var i: usize = stack.items.len;
        while (i > 0) {
            i -= 1;
            if (stack.items[i].isSet(lower) or stack.items[i].isSet(upper)) {
                try local.append(allocator, stack.orderedRemove(i));
            }
        }
        // Use the last element if it exists. Merged supersets get pushed to the
        // back of the list, so they're probably bigger, so make use of their
        // memory (while discarding the rest).
        var superset = local.pop() orelse {
            // No existing sets included either of these nodes, so push a new
            // one that just has them.
            var set = try Circuit.initEmpty(allocator, nodes.len);
            set.set(lower);
            set.set(upper);
            try stack.append(allocator, set);
            continue;
        };
        for (local.items) |subset| superset.setUnion(subset);

        // At least one of these was already set, but setting both is easier
        // than checking which.
        superset.set(lower);
        superset.set(upper);

        try stack.append(allocator, superset);
    }

    std.sort.pdq(Circuit, stack.items, {}, circuitsLessThan);
    var total: u64 = 1;
    for (stack.items[stack.items.len - 3 ..]) |circuit| total *= circuit.count();
    return total;
}
test "solve1(example) solves 1" {
    try std.testing.expectEqual(40, solve1(example, 10));
}

fn solve2(input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const nodes = (try parse(allocator, input)).items;
    // Each node has a circuit storing all the ones it's connected to.
    var circuits = try allocator.alloc(Circuit, nodes.len);
    for (0..nodes.len) |i| {
        circuits[i] = try Circuit.initEmpty(allocator, nodes.len);
        circuits[i].set(i);
    }
    // Hopefully this is enough.
    var graph = try Graph.init(allocator, nodes.len * 10);
    graph.fill(nodes);

    // This is copied from part 1, but with an extra check at the end of each
    // iteration.
    var first = try Circuit.initEmpty(allocator, nodes.len);
    first.set(graph.lowers[0]);
    first.set(graph.uppers[0]);
    var stack = try std.array_list.Aligned(Circuit, null).initCapacity(allocator, 1);
    stack.appendAssumeCapacity(first);

    for (graph.lowers[1..], graph.uppers[1..]) |lower, upper| {
        var local = try std.array_list.Aligned(Circuit, null).initCapacity(allocator, 0);

        var i: usize = stack.items.len;
        while (i > 0) {
            i -= 1;
            if (stack.items[i].isSet(lower) or stack.items[i].isSet(upper)) {
                try local.append(allocator, stack.orderedRemove(i));
            }
        }
        var superset = local.pop() orelse {
            var set = try Circuit.initEmpty(allocator, nodes.len);
            set.set(lower);
            set.set(upper);
            try stack.append(allocator, set);
            continue;
        };
        for (local.items) |subset| superset.setUnion(subset);

        superset.set(lower);
        superset.set(upper);

        // These were the last two!
        if (superset.count() == nodes.len) {
            const lower_x: u64 = @intFromFloat(nodes[lower][0]);
            const upper_x: u64 = @intFromFloat(nodes[upper][0]);
            return lower_x * upper_x;
        }

        try stack.append(allocator, superset);
    }
    unreachable;
}
test "solve2(example) solves 2" {
    try std.testing.expectEqual(25272, try solve2(example));
}

pub fn main() !void {
    const input = @embedFile("./inputs/08.txt");
    var writer = std.fs.File.stdout().writer(&.{}).interface;
    try writer.print("{d}\n{d}\n", .{
        try solve1(input, 1000),
        try solve2(input),
    });
}
