const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;

const test_input = Data.test_input;
const part1_input = Data.part1_input;
const part2_input = Data.part1_input;

const idxs: [6]usize = [6]usize{ 20, 60, 100, 140, 180, 220 };

pub fn isInterestingCycle(cycle: usize) bool {
    return std.mem.indexOfScalar(usize, &idxs, cycle) != null;
}

const part2Output =
    \\========================================
    \\####.#..#.###..####.###....##..##..#....
    \\#....#..#.#..#....#.#..#....#.#..#.#....
    \\###..####.#..#...#..#..#....#.#....#....
    \\#....#..#.###...#...###.....#.#.##.#....
    \\#....#..#.#....#....#....#..#.#..#.#....
    \\####.#..#.#....####.#.....##...###.####.
    \\========================================
;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res1 = try part1(part1_input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    try part2(part2_input, alloc);
}

pub fn part1(data: []const u8, _: Allocator) !i64 {
    var lines: std.mem.SplitIterator(u8) = std.mem.split(u8, data, "\n");

    var cycles: usize = 0;
    var X: i64 = 1;
    var sum: i64 = 0;
    while (lines.next()) |line| {
        //std.debug.print("{s}\n", .{line});
        if (line.len < 4) continue;
        if (line[0] == 'a') {
            var num: i64 = try std.fmt.parseInt(i64, line[5..], 10);

            cycles += 1;
            if (isInterestingCycle(cycles)) {
                sum += @intCast(i64, cycles) * X;
                //std.debug.print("cycle {d}, X {d}, sum {d}\n", .{ cycles, X, sum });
            }

            cycles += 1;
            if (isInterestingCycle(cycles)) {
                sum += @intCast(i64, cycles) * X;
                //std.debug.print("cycle {d}, X {d}, sum {d}\n", .{ cycles, X, sum });
            }

            X += num;
        } else if (line[0] == 'n') {
            cycles += 1;
            if (isInterestingCycle(cycles)) {
                sum += @intCast(i64, cycles) * X;
                //std.debug.print("cycle {d}, X {d}, sum {d}\n", .{ cycles, X, sum });
            }
        }

        if (cycles > 220) return sum;
    }

    std.debug.print("{d}, {d}, {d}\n", .{ cycles, X, sum });
    return sum;
}

pub fn doCycle(cycle: *usize, X: i64) void {
    const px: i64 = @intCast(i64, cycle.* % 40);
    if (px == 0) std.debug.print("\n", .{});

    if (std.math.absCast(X - px) <= 1) {
        std.debug.print("##", .{});
    } else {
        std.debug.print("  ", .{});
    }
    cycle.* += 1;
}

pub fn part2(data: []const u8, _: Allocator) !void {
    var lines = std.mem.split(u8, data, "\n");

    const header: [40]u8 = .{'='} ** 40;
    std.debug.print("\n{s}", .{header});

    var cycle: usize = 0;
    var X: i64 = 1;
    while (lines.next()) |line| {
        if (line.len < 4) continue;
        if (line[0] == 'a') {
            var num: i64 = try std.fmt.parseInt(i64, line[5..], 10);

            doCycle(&cycle, X);
            doCycle(&cycle, X);

            X += num;
        } else if (line[0] == 'n') {
            doCycle(&cycle, X);
        }
    }

    std.debug.print("\n{s}\n", .{header});
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    try std.testing.expect(res == 13140);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    try part2(test_input, alloc);
}
