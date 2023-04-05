const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;
const ns2sec = utils.ns2sec;

const test_input = Data.test_input;
const input = Data.input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var T = try std.time.Timer.start();

    var res1 = try part1(input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});
    std.debug.print("Part 1 took {d:.6}s\n", .{ns2sec(T.lap())});

    var res2 = try part2(input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
    std.debug.print("Part 2 took {d:.6}s\n", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    std.debug.print("[Test] Part 1: {d}\n", .{res});
    try std.testing.expect(res == 3);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part 2: {d}\n", .{res});
    try std.testing.expect(res == 1623178306);
}

// ------------ Part 1 Solution ------------

pub fn part1(data: []const u8, alloc: Allocator) !i32 {
    // Parse input number list
    var lines = std.mem.split(u8, data, "\n");
    var nums = ArrayList(i32).init(alloc);
    var idxs = ArrayList(usize).init(alloc);
    defer nums.deinit();
    defer idxs.deinit();

    // The input file is simply a list of signed integers (one per line)
    {
        var i: usize = 0;
        while (lines.next()) |line| {
            if (line.len < 1) continue;

            const num: i32 = try std.fmt.parseInt(i32, line, 10);
            try nums.append(num);
            try idxs.append(i);
            i += 1;
        }
    }

    // Permute the list
    try mixArray(i32, &nums, &idxs);

    // Get the mixed array
    var mixed = try unmixArray(i32, alloc, nums, idxs);
    defer mixed.deinit();
    const zero_idx = std.mem.indexOfScalar(i32, mixed.items, 0).?;

    var sum: i32 = 0;
    const sum_idxs = [_]usize{ 1000, 2000, 3000 };
    for (sum_idxs) |i| {
        const idx = i + zero_idx;
        std.debug.print("{d}\n", .{mixed.items[@mod(idx, idxs.items.len)]});
        sum += mixed.items[@mod(idx, mixed.items.len)];
    }

    return sum;
}

fn unmixArray(T: anytype, alloc: Allocator, nums: ArrayList(T), idxs: ArrayList(usize)) !ArrayList(T) {
    var list = try ArrayList(T).initCapacity(alloc, nums.items.len);
    for (idxs.items) |idx| {
        try list.append(nums.items[idx]);
    }
    return list;
}

fn printMixed(T: anytype, nums: ArrayList(T), idxs: ArrayList(usize)) void {
    for (idxs.items) |idx| {
        std.debug.print("{d}, ", .{nums.items[idx]});
    }
    std.debug.print(" | ", .{});

    for (idxs.items) |idx| {
        std.debug.print("{d}, ", .{idx});
    }
    std.debug.print("\n", .{});
}

// ------------ Part 2 Solution ------------

pub fn part2(data: []const u8, alloc: Allocator) !i64 {
    // Parse input number list
    var lines = std.mem.split(u8, data, "\n");
    var nums = ArrayList(i64).init(alloc);
    var idxs = ArrayList(usize).init(alloc);
    defer nums.deinit();
    defer idxs.deinit();

    // The input file is simply a list of signed integers (one per line)
    {
        const KEY: i64 = 811589153;
        var i: usize = 0;
        while (lines.next()) |line| {
            if (line.len < 1) continue;

            const num: i64 = try std.fmt.parseInt(i64, line, 10);
            try nums.append(num * KEY);
            try idxs.append(i);
            i += 1;
        }
    }

    // Permute the list 10 times
    {
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            try mixArray(i64, &nums, &idxs);
        }
    }

    // Get the mixed array
    var mixed = try unmixArray(i64, alloc, nums, idxs);
    defer mixed.deinit();
    const zero_idx = std.mem.indexOfScalar(i64, mixed.items, 0).?;

    var sum: i64 = 0;
    const sum_idxs = [_]usize{ 1000, 2000, 3000 };
    for (sum_idxs) |i| {
        const idx = i + zero_idx;
        std.debug.print("{d}\n", .{mixed.items[@mod(idx, idxs.items.len)]});
        sum += mixed.items[@mod(idx, mixed.items.len)];
    }

    return sum;
}

// ------------ Common Functions ------------

pub fn mixArray(T: anytype, nums: *ArrayList(T), idxs: *ArrayList(usize)) !void {
    const N: T = @intCast(T, nums.items.len);
    for (nums.items) |num, i| {
        const idx = std.mem.indexOfScalar(usize, idxs.items, i).?; // Current index for this number
        const offset = num + @intCast(T, idx);
        var rot = @intCast(usize, @mod(offset, N - 1)); // New index for this number

        if (rot == idx) continue;

        // std.debug.print("{d} is now in position {d}, ", .{ num, idx });
        // std.debug.print("to be swapped with position {d} (un-modded {d})\n", .{ rot, offset });

        _ = idxs.orderedRemove(idx);
        try idxs.insert(rot, i);

        // printMixed(nums, idxs);
    }
}
