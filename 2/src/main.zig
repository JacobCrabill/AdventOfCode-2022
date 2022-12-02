const std = @import("std");
const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;

var input = @embedFile("input1.txt");

pub fn main() !void {
    var res1 = part1(input);
    std.debug.print("Part1 Score: {d}\n", .{res1});

    var res2 = part2(input);
    std.debug.print("Part2 Score: {d}\n", .{res2});
}

pub fn part1(data: []const u8) usize {
    var lines = std.mem.tokenize(u8, data, "\n");

    var score: usize = 0;
    while (lines.next()) |line| {
        if (line.len < 3) {
            @panic("Incorrect line length!");
        }

        var them = line[0];
        var me = line[2];
        score += switch (me) {
            'X' => switch (them) {
                'A' => 1 + 3, // Rock <> Rock
                'B' => 1 + 0, // Paper <> Rock
                'C' => 1 + 6, // Scissors <> Rock
                else => 1,
            },
            'Y' => switch (them) {
                'A' => 2 + 6, // Rock <> Paper
                'B' => 2 + 3, // Paper <> Paper
                'C' => 2 + 0, // Scissors <> Paper
                else => 2,
            },
            'Z' => switch (them) {
                'A' => 3 + 0, // Rock <> Scissors
                'B' => 3 + 6, // Paper <> Scissors
                'C' => 3 + 3, // Scissors <> Scissors
                else => 3,
            },
            else => 0,
        };
    }

    return score;
}

pub fn part2(data: []const u8) usize {
    var lines = std.mem.tokenize(u8, data, "\n");

    var score: usize = 0;
    while (lines.next()) |line| {
        if (line.len < 3) {
            @panic("Incorrect line length!");
        }

        var them = line[0];
        var me = line[2];
        score += switch (me) {
            'X' => switch (them) {
                'A' => 0 + 3, // Lose to Rock
                'B' => 0 + 1, // Lose to Paper
                'C' => 0 + 2, // Lose to Scissors
                else => 0,
            },
            'Y' => switch (them) {
                'A' => 3 + 1, // Draw to Rock
                'B' => 3 + 2, // Draw to Paper
                'C' => 3 + 3, // Draw to Scissors
                else => 3,
            },
            'Z' => switch (them) {
                'A' => 6 + 2, // Win to Rock
                'B' => 6 + 3, // Win to Paper
                'C' => 6 + 1, // Win to Scissors
                else => 6,
            },
            else => 0,
        };
    }

    return score;
}

test "part1 test input" {
    var test_input =
        \\A Y
        \\B X
        \\C Z
    ;
    var res = part1(test_input);
    std.debug.print("Score: {d}\n", .{res});
    try std.testing.expect(res == 15);
}

test "part2 test input" {
    var test_input =
        \\A Y
        \\B X
        \\C Z
    ;
    var res = part2(test_input);
    std.debug.print("Score: {d}\n", .{res});
    try std.testing.expect(res == 12);
}
