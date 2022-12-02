const std = @import("std");
const Data = @import("data");
const GPA = std.heap.GeneralPurposeAllocator;

const test_input = Data.test_input;
const part1_input = Data.part1_input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    const res1 = try part1(part1_input, alloc);
    std.debug.print("Max calories: {}\n", .{res1});

    const res2 = try part2(part1_input, alloc);
    std.debug.print("Top 3 calories sum: {}\n", .{res2});
}

pub fn part1(data: []const u8, alloc: std.mem.Allocator) !usize {
    var elves = std.mem.split(u8, data, "\n\n");
    var calories = std.ArrayList(usize).init(alloc);
    defer calories.deinit();

    var cals: usize = 0;
    while (elves.next()) |elf| {
        var snacks = std.mem.tokenize(u8, elf, "\n");
        while (snacks.next()) |snack| {
            var cal: usize = try std.fmt.parseInt(usize, snack, 10);
            cals += cal;
        }

        try calories.append(cals);
        cals = 0;
    }

    return std.mem.max(usize, calories.items);
}

pub fn part2(data: []const u8, alloc: std.mem.Allocator) !usize {
    var elves = std.mem.split(u8, data, "\n\n");
    var calories = std.ArrayList(usize).init(alloc);
    defer calories.deinit();

    // Parse the calorie values per elf
    var cals: usize = 0;
    while (elves.next()) |elf| {
        var snacks = std.mem.tokenize(u8, elf, "\n");
        while (snacks.next()) |snack| {
            var cal: usize = try std.fmt.parseInt(usize, snack, 10);
            cals += cal;
        }

        try calories.append(cals);
        cals = 0;
    }

    // Top 3 calorie values
    var sum: usize = 0;
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        var idx: usize = std.mem.indexOfMax(usize, calories.items);
        sum += calories.orderedRemove(idx);
    }

    return sum;
}

test "Part 1 test input" {
    var alloc = std.testing.allocator;

    var res = try part1(test_input, alloc);
    try std.testing.expect(res == 24000);
}

test "Part 2 test input" {
    var alloc = std.testing.allocator;

    var res = try part2(test_input, alloc);
    try std.testing.expect(res == 45000);
}
