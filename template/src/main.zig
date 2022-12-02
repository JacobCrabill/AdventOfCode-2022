const std = @import("std");
const Data = @import("data");

const test_input = Data.test_input;
const part1_input = Data.part1_input;
const part2_input = Data.part1_input;

pub fn main() !void {
    var res1 = part1(part1_input);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = part1(part2_input);
    std.debug.print("Part2: {d}\n", .{res2});
}

pub fn part1(_: []const u8) usize {
    return 0;
}

pub fn part2(_: []const u8) usize {
    return 0;
}

test "part1 test input" {
    var res = part1(test_input);
    try std.testing.expect(res == 0);
}

test "part2 test input" {
    var res = part2(test_input);
    try std.testing.expect(res == 0);
}
