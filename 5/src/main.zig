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

    var res1 = try part1(part1_input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = try part2(part2_input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

pub fn parseSetup(data: []const u8, alloc: Allocator) !std.ArrayList(std.ArrayList(u8)) {
    var lines = std.mem.split(u8, data, "\n");
    const idx: usize = std.mem.indexOfScalar(u8, data, '\n') orelse 0;
    const N: usize = (idx + 1) / 4; // Number of crate stacks

    var stacks = std.ArrayList(std.ArrayList(u8)).init(alloc);
    var i: usize = 0;
    while (i < N) : (i += 1) {
        try stacks.append(std.ArrayList(u8).init(alloc));
    }

    lineloop: while (lines.next()) |line| {
        i = 0;
        while (i < N) : (i += 1) {
            const c: u8 = line[4 * i + 1];
            switch (c) {
                'A'...'Z' => try stacks.items[i].insert(0, c),
                ' ' => {},
                '[' => {},
                ']' => {},
                0...9 => break :lineloop,
                else => {},
            }
        }
    }

    return stacks;
}

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    // Parse the input into the two sections: setup and instructions
    var sections = std.mem.split(u8, data, "\n\n");
    var setup = sections.next() orelse return 0;
    var instr = sections.next() orelse return 0;

    var stacks = try parseSetup(setup, alloc);
    std.debug.print("got {d} stacks\n", .{stacks.items.len});

    var lines = std.mem.split(u8, instr, "\n");
    while (lines.next()) |line| {
        if (line.len < 10) break;
        var tokens = std.mem.tokenize(u8, line, "move from to");
        var count: u8 = try std.fmt.parseInt(u8, tokens.next() orelse "", 10);
        var from: u8 = try std.fmt.parseInt(u8, tokens.next() orelse "", 10) - 1;
        var to: u8 = try std.fmt.parseInt(u8, tokens.next() orelse "", 10) - 1;
        // std.debug.print("move {} from {} to {}\n", .{ count, from, to });
        var i: usize = 0;
        while (i < count) : (i += 1) {
            var box: u8 = stacks.items[from].pop();
            try stacks.items[to].append(box);
        }
    }

    for (stacks.items) |*stack| {
        std.debug.print("{c}", .{stack.pop()});
    }
    std.debug.print("\n", .{});

    for (stacks.items) |*stack| {
        stack.deinit();
    }
    stacks.deinit();

    return 0;
}

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    // Parse the input into the two sections: setup and instructions
    var sections = std.mem.split(u8, data, "\n\n");
    var setup = sections.next() orelse return 0;
    var instr = sections.next() orelse return 0;

    var stacks = try parseSetup(setup, alloc);
    std.debug.print("got {d} stacks\n", .{stacks.items.len});

    var lines = std.mem.split(u8, instr, "\n");
    while (lines.next()) |line| {
        if (line.len < 10) break;
        var tokens = std.mem.tokenize(u8, line, "move from to");
        var count: u8 = try std.fmt.parseInt(u8, tokens.next() orelse "", 10);
        var from: u8 = try std.fmt.parseInt(u8, tokens.next() orelse "", 10) - 1;
        var to: u8 = try std.fmt.parseInt(u8, tokens.next() orelse "", 10) - 1;
        // std.debug.print("move {} from {} to {}\n", .{ count, from, to });
        var i: usize = 0;
        var tmp = std.ArrayList(u8).init(alloc);
        while (i < count) : (i += 1) {
            var box: u8 = stacks.items[from].pop();
            try tmp.insert(0, box);
        }

        for (tmp.items) |box| {
            try stacks.items[to].append(box);
        }
        tmp.deinit();
    }

    for (stacks.items) |*stack| {
        std.debug.print("{c}", .{stack.pop()});
    }
    std.debug.print("\n", .{});

    for (stacks.items) |*stack| {
        stack.deinit();
    }
    stacks.deinit();

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
