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

    var res1 = part2(part1_input, 4, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = part2(part1_input, 14, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

pub fn part2(data: []const u8, N: usize, _: Allocator) usize {
    var i: usize = 0;
    outer: while (i < data.len - N) : (i += 1) {
        const slice = data[i .. i + N];
        var j: usize = 0;
        while (j < N - 1) : (j += 1) {
            if (std.mem.indexOfScalar(u8, slice[j + 1 ..], slice[j]) != null) {
                continue :outer;
            }
        }

        return i + N;
    }

    return 0;
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = part2(test_input, 4, alloc);
    try std.testing.expect(res == 7);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = part2(test_input, 14, alloc);
    try std.testing.expect(res == 19);
}
