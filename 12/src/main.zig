const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Deque = std.mem.PriorityDeque;
const GPA = std.heap.GeneralPurposeAllocator;
const Set = utils.Set;
const AutoHashMap = std.AutoHashMap;

const test_input = Data.test_input;
const input = Data.input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res1 = try part1(input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = try part2(input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    std.debug.print("[Test] Part 1 res: {d}\n", .{res});
    try std.testing.expect(res == 31);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part 2 res: {d}\n", .{res});
    try std.testing.expect(res == 29);
}

pub const Pos = struct {
    row: i64 = 0,
    col: i64 = 0,
    //dist: i64 = 0,

    pub fn eql(self: Pos, rhs: Pos) bool {
        return self.row == rhs.row and self.col == rhs.col;
    }
};

pub const Node = struct {
    pos: Pos,
    dist: usize,
};

// ---------------- Part 1 Solution ----------------
pub fn part1(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    const ncol: usize = std.mem.indexOfScalar(u8, data, '\n').?;
    const nrow: usize = data.len / (ncol + 1);

    var grid = try ArrayList(u8).initCapacity(alloc, ncol * nrow);
    defer grid.deinit();

    // Start and End, row and col
    var start = Pos{};
    var end = Pos{};

    // Create the grid; find start and end positions,
    // and replace with elevation values
    var row: usize = 0;
    while (lines.next()) |line| {
        var col: usize = 0;
        for (line) |c| {
            var C = c;
            if (c == 'S') {
                start.row = @intCast(i64, row);
                start.col = @intCast(i64, col);
                C = 'a';
            } else if (c == 'E') {
                end.row = @intCast(i64, row);
                end.col = @intCast(i64, col);
                C = 'z';
            }
            try grid.append(C);
            col += 1;
        }
        row += 1;
    }

    return dijkstra(grid, nrow, ncol, start, end, alloc);
}

// ---------------- Part 2 Solution ----------------
pub fn part2(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    const ncol: usize = std.mem.indexOfScalar(u8, data, '\n').?;
    const nrow: usize = data.len / (ncol + 1);

    var grid = try ArrayList(u8).initCapacity(alloc, ncol * nrow);
    defer grid.deinit();

    // Start and End, row and col
    var start = Pos{};
    var end = Pos{};

    // Create the grid; find start and end positions,
    // and replace with elevation values
    var row: usize = 0;
    while (lines.next()) |line| {
        var col: usize = 0;
        for (line) |c| {
            var C = c;
            if (c == 'S') {
                C = 'a';
            } else if (c == 'E') {
                end.row = @intCast(i64, row);
                end.col = @intCast(i64, col);
                C = 'z';
            }
            try grid.append(C);
            col += 1;
        }
        row += 1;
    }

    // I know this is all super slow.  I don't really care.
    var min_dist: usize = nrow * ncol;
    row = 0;
    while (row < nrow) : (row += 1) {
        var col: usize = 0;
        while (col < ncol) : (col += 1) {
            if (grid.items[row * ncol + col] != 'a') continue;

            start.row = @intCast(i64, row);
            start.col = @intCast(i64, col);
            var new_dist = try dijkstra(grid, nrow, ncol, start, end, alloc);
            min_dist = @min(min_dist, new_dist);
        }
    }

    return min_dist;
}

// ---------------- Common Functions ----------------

pub fn dijkstra(grid: ArrayList(u8), nrow: usize, ncol: usize, start: Pos, end: Pos, alloc: Allocator) !usize {
    var pq = ArrayList(Node).init(alloc);
    var neighbors = ArrayList(Pos).init(alloc);
    var visited = Set(Pos).init(alloc);
    defer pq.deinit();
    defer visited.deinit();
    defer neighbors.deinit();

    // Start the A* algorithm at our start location
    try pq.append(Node{ .pos = start, .dist = 0 });

    while (pq.items.len > 0) {
        // Get the next node - the one with the smallest distance
        std.sort.sort(Node, pq.items, void, Sorter(Node).lessThan);
        var p = pq.orderedRemove(0);
        if (visited.contains(p.pos)) // The node got added multiple times
            continue;

        try visited.put(p.pos);

        const r = p.pos.row;
        const c = p.pos.col;
        const d = p.dist;

        // Get the node's neighbors
        if (r + 1 < @intCast(i64, nrow))
            try neighbors.append(Pos{ .row = r + 1, .col = c });
        if (r - 1 >= 0)
            try neighbors.append(Pos{ .row = r - 1, .col = c });
        if (c + 1 < @intCast(i64, ncol))
            try neighbors.append(Pos{ .row = r, .col = c + 1 });
        if (c - 1 >= 0)
            try neighbors.append(Pos{ .row = r, .col = c - 1 });
        defer neighbors.clearRetainingCapacity();

        // Process each neighbor
        for (neighbors.items) |neighbor| {

            // Skip already-visited nodes
            if (visited.contains(neighbor))
                continue;

            // If the elevation difference is > 1, skip
            const i_nc = @intCast(i64, ncol);
            const pe: i32 = grid.items[@intCast(usize, r * i_nc + c)];
            const ne: i32 = grid.items[@intCast(usize, neighbor.row * i_nc + neighbor.col)];
            if (ne - pe > 1)
                continue;

            // If it's the goal, return the path cost
            if (neighbor.eql(end))
                return d + 1;

            // If all checks pass, append to our priority queue
            try pq.append(Node{ .pos = neighbor, .dist = d + 1 });
        }
    }

    return std.math.maxInt(usize);
}

fn Sorter(comptime T: anytype) type {
    // Type 'T' must have a field 'dist'
    return struct {
        pub fn lessThan(comptime _: type, lhs: T, rhs: T) bool {
            return lhs.dist < rhs.dist;
        }
    };
}
