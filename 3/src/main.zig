const std = @import("std");
const Data = @import("data");

const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;

const test_input = Data.test_input;
const part1_input = Data.part1_input;
const part2_input = Data.part1_input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res1 = part1(part1_input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = part2(part1_input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

pub fn part1(data: []const u8, _: Allocator) usize {
    var sum: usize = 0;

    // For each rucksack...
    var lines = std.mem.split(u8, data, "\n");
    while (lines.next()) |line| {
        // Split by compartment...
        var len: usize = line.len;
        var c1 = line[0 .. len / 2];
        var c2 = line[len / 2 ..];

        // Find shared character
        var idx = std.mem.indexOfAny(u8, c1, c2);
        if (idx != null) {
            var c = c1[idx.?];
            var val: u8 = switch (c) {
                'a'...'z' => c - 'a' + 1,
                'A'...'Z' => c - 'A' + 27,
                else => 0,
            };
            sum += val;
        }
    }

    return sum;
}

pub fn part2(data: []const u8, _: Allocator) usize {
    var sum: usize = 0;

    // For each group of 3 lines...
    var lines = std.mem.split(u8, data, "\n");
    while (lines.next()) |bag1| {
        var bag2 = lines.next() orelse break;
        var bag3 = lines.next() orelse break;
        // Find a shared character between the 3 lines
        // I know this is inefficient... whatevs
        cmp: for (bag1) |c| {
            if (std.mem.indexOfScalar(u8, bag2, c) != null and std.mem.indexOfScalar(u8, bag3, c) != null) {
                sum += switch (c) {
                    'a'...'z' => c + 1 - 'a',
                    'A'...'Z' => c + 27 - 'A',
                    else => 0,
                };
                break :cmp;
            }
        }
    }
    return sum;
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = part1(test_input, alloc);
    try std.testing.expect(res == 157);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = part2(test_input, alloc);
    try std.testing.expect(res == 70);
}
