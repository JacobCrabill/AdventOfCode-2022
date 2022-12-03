const std = @import("std");
const Data = @import("data");

const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;

const test_input = Data.test_input;
const part1_input = Data.part1_input;
const part2_input = Data.part2_input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res1 = part1(part1_input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = part2(part2_input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

pub fn part1(_: []const u8, _: Allocator) usize {
    return 0;
}

pub fn part2(_: []const u8, _: Allocator) usize {
    return 0;
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = part1(test_input, alloc);
    try std.testing.expect(res == 0);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = part2(test_input, alloc);
    try std.testing.expect(res == 0);
}
