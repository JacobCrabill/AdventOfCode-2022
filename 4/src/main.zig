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

    var res1 = try part1(part1_input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = try part2(part1_input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

pub fn part1(data: []const u8, _: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    var count: usize = 0;
    while (lines.next()) |line| {
        var pairs = std.mem.tokenize(u8, line, "-,");
        var x0: u8 = try std.fmt.parseInt(u8, pairs.next() orelse break, 10);
        var y0: u8 = try std.fmt.parseInt(u8, pairs.next() orelse break, 10);
        var x1: u8 = try std.fmt.parseInt(u8, pairs.next() orelse break, 10);
        var y1: u8 = try std.fmt.parseInt(u8, pairs.next() orelse break, 10);

        if ((x0 >= x1 and y0 <= y1) or (x1 >= x0 and y1 <= y0)) {
            count += 1;
        }
    }

    return count;
}

pub fn part2(data: []const u8, _: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    var count: usize = 0;
    while (lines.next()) |line| {
        var pairs = std.mem.tokenize(u8, line, "-,");
        var x0: u8 = try std.fmt.parseInt(u8, pairs.next() orelse break, 10);
        var y0: u8 = try std.fmt.parseInt(u8, pairs.next() orelse break, 10);
        var x1: u8 = try std.fmt.parseInt(u8, pairs.next() orelse break, 10);
        var y1: u8 = try std.fmt.parseInt(u8, pairs.next() orelse break, 10);

        if ((x1 <= x0 and x0 <= y1) or (x1 <= y0 and y0 <= y1) or
            (x0 <= x1 and x1 <= y0) or (x0 <= y1 and y1 <= y0))
        {
            count += 1;
        }
    }

    return count;
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    try std.testing.expect(res == 2);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    try std.testing.expect(res == 4);
}
