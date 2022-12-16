const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const abs = std.math.absCast;
const GPA = std.heap.GeneralPurposeAllocator;
const Set = utils.Set;

const test_input = Data.test_input;
const input = Data.input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    // var res1 = try part1(input, 2000000, alloc);
    // std.debug.print("Part1: {d}\n", .{res1});

    var res2 = try part2(input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

// ------------ Tests ------------

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, 10, alloc);
    std.debug.print("[Test] Part 1: {d}\n", .{res});
    try std.testing.expect(res == 26);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part 2: {d}\n", .{res});
    try std.testing.expect(res == 0);
}

// ------------ Part 1 Solution ------------

pub fn part1(data: []const u8, row: i32, alloc: Allocator) !usize {
    var lines = std.mem.tokenize(u8, data, "\n");

    // Parse all sensors and beacons
    var sensors = std.AutoHashMap(Pos, u32).init(alloc);
    var beacons = Set(Pos).init(alloc);
    defer sensors.deinit();
    defer beacons.deinit();

    var xmin: i32 = std.math.maxInt(i32);
    var xmax: i32 = std.math.minInt(i32);
    var dmax: u32 = 0;

    while (lines.next()) |line| {
        var nums = std.mem.tokenize(u8, line, "Sensoratxyiclbn,:= ");
        var s = Pos{};
        var b = Pos{};
        s.x = try std.fmt.parseInt(i32, nums.next().?, 10);
        s.y = try std.fmt.parseInt(i32, nums.next().?, 10);
        b.x = try std.fmt.parseInt(i32, nums.next().?, 10);
        b.y = try std.fmt.parseInt(i32, nums.next().?, 10);
        const d: u32 = dist(s, b);
        try sensors.put(s, d);
        try beacons.put(b);
        xmin = @min(xmin, @min(s.x, b.x));
        xmax = @max(xmax, @max(s.x, b.x));
        dmax = @max(dmax, d);
    }

    std.debug.print("x extents: {d} - {d}\n", .{ xmin, xmax });

    // For the row in question, find all positions closer to a sensor than
    // a known beacon
    var i: i32 = xmin - @intCast(i32, dmax);
    var count: usize = 0;
    //var t0 = std.time.microTimestamp();
    //var cycles: i64 = 0;
    xloop: while (i <= xmax + @intCast(i32, dmax)) : (i += 1) {
        var p = Pos{ .x = i, .y = row };
        if (beacons.contains(p)) continue;

        var iter = sensors.keyIterator();
        while (iter.next()) |s| {
            //cycles += 1;
            const sd = sensors.get(s.*).?;
            if (dist(p, s.*) <= sd) {
                count += 1;
                continue :xloop;
            }
        }
    }
    //const t1 = std.time.microTimestamp();
    //const ttot: i64 = t1 - t0;

    //const tavg: f64 = try std.math.divExact(f64, @intToFloat(f64, ttot * 1000), @intToFloat(f64, cycles));
    //std.debug.print("Search elapsed time: {d}us for {d} cycles; time per iter: {d:.3}ns\n", .{ ttot, cycles, tavg });

    return count;
}

// ------------ Part 2 Solution ------------

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.tokenize(u8, data, "\n");

    // Parse all sensors and beacons
    var sensors = ArrayList(PosD).init(alloc);
    var beacons = ArrayList(Pos).init(alloc);
    var plines = ArrayList(i32).init(alloc);
    var mlines = ArrayList(i32).init(alloc);
    defer sensors.deinit();
    defer beacons.deinit();
    defer plines.deinit();
    defer mlines.deinit();

    while (lines.next()) |line| {
        var nums = std.mem.tokenize(u8, line, "Sensoratxyiclbn,:= ");
        var s = PosD{};
        var b = Pos{};
        s.x = try std.fmt.parseInt(i32, nums.next().?, 10);
        s.y = try std.fmt.parseInt(i32, nums.next().?, 10);
        b.x = try std.fmt.parseInt(i32, nums.next().?, 10);
        b.y = try std.fmt.parseInt(i32, nums.next().?, 10);
        s.d = dist(s, b);
        const d = @intCast(i32, s.d);
        try sensors.append(s);
        try beacons.append(b);
        try plines.append(s.x + s.y + (d + 1));
        try plines.append(s.x + s.y - (d + 1));
        try mlines.append(s.x - s.y + (d + 1));
        try mlines.append(s.x - s.y - (d + 1));
    }

    // Compare every pair of +/-45deg lines from each square to every other pair
    const N: usize = plines.items.len;
    var xys = std.AutoHashMap(Pos, void).init(alloc);
    var i: usize = 0;
    while (i < N) : (i += 1) {
        var j: usize = i;
        while (j < N) : (j += 1) {
            const p = plines.items[i];
            const m = mlines.items[j];
            var Y = try std.math.divFloor(i32, p - m, 2);
            var X = p - Y;
            try xys.put(Pos{ .x = X, .y = Y }, {});
        }
    }

    // Try each point...
    var iter = xys.keyIterator();
    ploop: while (iter.next()) |p| {
        for (sensors.items) |s| {
            if (dist(s, p.*) < s.d) {
                continue :ploop;
            }
        }
        // Found the point!
        std.debug.print("{any}\n", .{p.*});
        return 4000000 * p.x + p.y;
    }

    // var i: usize = 0;
    // while (i < N) : (i += 2) {
    //     var j: usize = i + 2;
    //     while (j < N) : (j += 2) {
    //         var ii: usize = 0;
    //         while (ii < 2) : (ii += 1) {
    //             var jj: usize = 0;
    //             while (jj < 2) : (jj += 1) {
    //                 var kk: usize = 0;
    //                 while (kk < 2) : (kk += 1) {
    //                     var ll: usize = 0;
    //                     while (ll < 2) : (ll += 1) {
    //                         const p1 = plines.items[i + ii];
    //                         const m1 = mlines.items[i + kk];
    //                         const p2 = plines.items[j + jj];
    //                         const m2 = mlines.items[j + ll];
    //                         if (p1 == p2 and m1 == m2) {
    //                             // Winner!
    //                             // Intersection at (p - m) / 2, (
    //                             // p-lines: p = x + y
    //                             // m-lines: m = x - y
    //                             //     x = p - y
    //                             //     x = m + y
    //                             //     p - y = m + y
    //                             //     y = (p - m) / 2
    //                             //     x = p - y
    //                             var Y = try std.math.divFloor(i32, p1 - m1, 2);
    //                             var X = p1 - Y;
    //                             return X * 4000000 + Y;
    //                         }
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }

    return 0;
}

// ------------ Common Functions ------------

pub const Pos = struct {
    x: i32 = 0,
    y: i32 = 0,
};

pub const PosD = struct {
    x: i32 = 0,
    y: i32 = 0,
    d: u32 = 0,
};

// (unsigned) Manhattan distance
pub fn dist(p1: anytype, p2: Pos) u32 {
    return abs(p1.x - p2.x) + abs(p1.y - p2.y);
}
