const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;

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

pub fn part1(_: []const u8, _: Allocator) !usize {
    return 0;
}

pub fn part2(_: []const u8, _: Allocator) !usize {
    return 0;
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    try std.testing.expect(res == 0);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    try std.testing.expect(res == 0);
}
