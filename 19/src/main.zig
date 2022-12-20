const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;

const test_input = Data.test_input;
const input = Data.input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var t0 = std.time.microTimestamp();
    // var res1 = try part1(input, alloc);
    var t1 = std.time.microTimestamp();
    var dt: f64 = @intToFloat(f64, t1 - t0) / 1e6;
    // std.debug.print("Part1: {d}\n", .{res1});
    // std.debug.print("Part 1 took {d:.6}s\n", .{dt});

    t0 = std.time.microTimestamp();
    var res2 = try part2(input, alloc);
    t1 = std.time.microTimestamp();
    dt = @intToFloat(f64, t1 - t0) / 1e6;
    std.debug.print("Part2: {d}\n", .{res2});
    std.debug.print("Part 2 took {d:.6}s\n", .{dt});
}

// ------------ Tests ------------

// test "part1 test input" {
//     var alloc = std.testing.allocator;
//     var res = try part1(test_input, alloc);
//     std.debug.print("[Test] Part 1: {d}\n", .{res});
//     try std.testing.expect(res == 0);
// }

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part 2: {d}\n", .{res});
    try std.testing.expect(res == 0);
}

// ------------ Part 1 Solution ------------

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    var bps = ArrayList(Counts).init(alloc);
    defer bps.deinit();

    while (lines.next()) |line| {
        if (line.len < 10) break;
        var costs = std.mem.tokenize(u8, line, "BEabcdefghijklmnopqrstuvwxyz.: ");

        // blueprint ID
        _ = costs.next().?;

        // Ore, clay, obsidian, geodo
        var arr: [6]i16 = [_]i16{0} ** 6;
        arr[0] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[1] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[2] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[3] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[4] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[5] = try std.fmt.parseInt(i16, costs.next().?, 10);

        // Maximum usage of each ressource per minute
        var max: [4]i16 = [_]i16{0} ** 4;
        max[0] = @max(arr[0], @max(arr[1], @max(arr[2], arr[4])));
        max[1] = arr[3];
        max[2] = arr[5];
        max[3] = 99999;

        try bps.append(Counts{ .values = arr, .maxspend = max });
    }

    var total: usize = 0;
    for (bps.items) |bp, i| {
        const bpscore = try useBlueprint(bp, alloc, 24);
        std.debug.print("bp {d}: {d}\n", .{ i, bpscore });
        total += (i + 1) * @intCast(usize, bpscore);
    }

    return total;
}

// ------------ Part 2 Solution ------------

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    var bps = ArrayList(Counts).init(alloc);
    defer bps.deinit();

    while (lines.next()) |line| {
        if (line.len < 10) break;
        var costs = std.mem.tokenize(u8, line, "BEabcdefghijklmnopqrstuvwxyz.: ");

        // blueprint ID
        _ = costs.next().?;

        // Ore, clay, obsidian, geodo
        var arr: [6]i16 = [_]i16{0} ** 6;
        arr[0] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[1] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[2] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[3] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[4] = try std.fmt.parseInt(i16, costs.next().?, 10);
        arr[5] = try std.fmt.parseInt(i16, costs.next().?, 10);

        // Maximum usage of each ressource per minute
        var max: [4]i16 = [_]i16{0} ** 4;
        max[0] = @max(arr[0], @max(arr[1], @max(arr[2], arr[4])));
        max[1] = arr[3];
        max[2] = arr[5];
        max[3] = 9999;

        try bps.append(Counts{ .values = arr, .maxspend = max });
    }

    var total: usize = 1;
    for (bps.items) |bp, i| {
        if (i >= 3) break;
        const bpscore = try useBlueprint(bp, alloc, 32);
        std.debug.print("bp {d}: {d}\n", .{ i, bpscore });
        total *= @intCast(usize, bpscore);
    }

    return total;
}

// ------------ Common Functions ------------

const Counts = struct {
    // ore/ore, clay/ore, obsidian/(ore, clay), geode/(ore, obsidian)
    values: [6]i16 = [6]i16{ 0, 0, 0, 0, 0, 0 },
    maxspend: [4]i16 = [4]i16{ 0, 0, 0, 0 },
};

const CacheKey = struct {
    robots: Counts,
    resources: Counts,
    time_rem: i16,
};
const Cache = std.AutoHashMap(CacheKey, i16);

fn useBlueprint(bp: Counts, alloc: Allocator, time_rem: i16) !i16 {
    var robots = Counts{};
    robots.values[0] = 1; // Start with 1 ore-collecting robot

    const resources = Counts{};
    var cache = Cache.init(alloc);
    defer cache.deinit();

    return try dfs(bp, &cache, robots, resources, time_rem);
}

fn dfs(bp: Counts, cache: *Cache, robots: Counts, rsrc: Counts, time_rem: i16) !i16 {
    if (time_rem <= 0) return rsrc.values[3];

    const key = CacheKey{ .robots = robots, .resources = rsrc, .time_rem = time_rem };
    if (cache.contains(key)) {
        return cache.get(key).?;
    }

    // Accumulate resources
    var new_rsrc = rsrc;
    for (robots.values) |n, i| {
        new_rsrc.values[i] += n;
        const max_spend = (time_rem - 1) * bp.maxspend[i];
        if (i < 3 and new_rsrc.values[i] > max_spend) {
            // More of this resource than we could possibly use
            new_rsrc.values[i] = max_spend;
        }
    }

    var score: i16 = 0;

    // Try the 'what-if' of building each robot type
    // NOTE: resources must come from start of minute!
    var i: usize = 0;
    while (i < 2) : (i += 1) {
        // Obsidian or Geode
        const c1 = bp.values[2 * i + 2];
        const c2 = bp.values[2 * i + 3];
        if (c1 <= rsrc.values[0] and c2 <= rsrc.values[i + 1]) {
            var rsrci = new_rsrc;
            rsrci.values[0] -= c1;
            rsrci.values[i + 1] -= c2;
            var new_robots = robots;
            new_robots.values[i + 2] += 1;
            score = @max(score, try dfs(bp, cache, new_robots, rsrci, time_rem - 1));
        }
    }

    i = 0;
    while (i < 2) : (i += 1) {
        // Ore or Clay
        // Don't bother building more if we have more than enough
        const max_spend = (time_rem - 1) * bp.maxspend[i];
        if (new_rsrc.values[i] >= max_spend) continue;

        const cost = bp.values[i];
        if (cost <= rsrc.values[0]) {
            var rsrci = new_rsrc;
            rsrci.values[0] -= cost;
            var new_robots = robots;
            new_robots.values[i] += 1;
            score = @max(score, try dfs(bp, cache, new_robots, rsrci, time_rem - 1));
        }
    }

    // Try simply waiting another minute
    score = @max(score, try dfs(bp, cache, robots, new_rsrc, time_rem - 1));

    try cache.put(key, score);

    if (cache.count() % 1000000 == 0) {
        std.debug.print("Cache size: {d}\n", .{cache.count()});
    }

    return score;
}
