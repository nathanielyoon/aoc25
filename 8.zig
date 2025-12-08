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
/// Parses a list of nodes.
fn parse(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Node) {
    var lines = lib.split(input);
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
fn Graph(comptime size: usize) type {
    return struct {
        lowers: [size]usize,
        uppers: [size]usize,
        costs: [size]f32,
        fn insert(self: *Graph(size), lower: usize, upper: usize, cost: f32) void {
            const bound = std.sort.upperBound(f32, &self.costs, cost, compareF32s);
            // At least one of the current costs should be greater to call this
            // method.
            std.debug.assert(bound != size);

            // Each index greater than `bound` has a higher-cost edge, so shift
            // them up one space.
            var i = size - 1;
            while (i > bound) : (i -= 1) {
                self.lowers[i] = self.lowers[i - 1];
                self.uppers[i] = self.uppers[i - 1];
                self.costs[i] = self.costs[i - 1];
            }

            // Insert the new edge.
            self.lowers[bound] = lower;
            self.uppers[bound] = upper;
            self.costs[bound] = cost;
        }
    };
}
test "Graph().insert() inserts" {
    var graph = Graph(4){
        .lowers = .{ 0, 1, 2, 3 },
        .uppers = .{ 4, 5, 6, 7 },
        .costs = .{ 100, 200, 300, 400 },
    };
    graph.insert(8, 9, 350);
    graph.insert(10, 11, 50);
    graph.insert(12, 13, 50);
    try std.testing.expectEqualDeep(Graph(4){
        .lowers = .{ 10, 12, 0, 1 },
        .uppers = .{ 11, 13, 4, 5 },
        .costs = .{ 50, 50, 100, 200 },
    }, graph);
}

/// Calculates the straight-line distance between two points.
fn distance(lhs: Node, rhs: Node) f32 {
    const sub = lhs - rhs;
    return @sqrt(@reduce(.Add, sub * sub));
}
/// Creates a graph by considering every possible edge.
fn createGraph(allocator: std.mem.Allocator, nodes: std.ArrayList(Node), comptime size: usize) !*Graph(size) {
    std.debug.assert(nodes.items.len >= 2);

    // Allocate memory for the graph.
    const graph = try allocator.create(Graph(size));

    // Initialize graph with "impossible" values: indices equal to the number of
    // nodes, and max costs.
    var max: f32 = std.math.floatMax(f32);
    graph.* = .{
        .lowers = .{nodes.items.len} ** size,
        .uppers = .{nodes.items.len} ** size,
        .costs = .{max} ** size,
    };

    // Loop over each edge and insert it if its cost is lower than the current
    // maximum.
    for (nodes.items, 0..) |one, i| {
        for (nodes.items[i + 1 ..], i + 1..) |two, j| {
            const cost = distance(one, two);
            if (cost < max) {
                graph.insert(i, j, cost);
                // Update the maximum (though it might not have changed).
                max = graph.costs[size - 1];
            }
        }
    }

    return graph;
}
test "createGraph(example) creates graph 1" {
    const allocator = std.testing.allocator;
    var nodes = try parse(allocator, example);
    defer nodes.deinit(allocator);
    const graph = try createGraph(allocator, nodes, 4);
    defer allocator.destroy(graph);

    try std.testing.expectEqualSlices(usize, &.{ 0, 0, 2, 7 }, &graph.lowers);
    try std.testing.expectEqualSlices(usize, &.{ 19, 7, 13, 19 }, &graph.uppers);
}

/// Set of connected nodes.
const Circuit = std.bit_set.DynamicBitSetUnmanaged;
/// Compares two sets by size.
fn circuitsLessThan(_: void, lhs: Circuit, rhs: Circuit) bool {
    return lhs.count() < rhs.count();
}
/// Solves part 1.
fn solve1(input: []const u8, comptime size: usize) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const nodes = try parse(allocator, input);
    const graph = try createGraph(allocator, nodes, size);

    // Track all sub-graphs with 2+ nodes, starting with the first.
    var first = try Circuit.initEmpty(allocator, nodes.items.len);
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
            var set = try Circuit.initEmpty(allocator, nodes.items.len);
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

pub fn main() !void {
    const input = @embedFile("./inputs/8.txt");
    var writer = std.fs.File.stdout().writer(&.{}).interface;
    try writer.print("{d}\n", .{
        try solve1(input, 1000),
    });
}
