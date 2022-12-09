const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;

const Vec = ArrayList(u8);

const test_input = Data.test_input;
const part1_input = Data.part1_input;
const part2_input = Data.part2_input;

pub const MatSize = struct {
    rows: usize = 0,
    cols: usize = 0,
};

pub fn getSize(data: []const u8) MatSize {
    var size = MatSize{
        .rows = 0,
        .cols = 0,
    };
    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        size.cols = line.len;
        size.rows += 1;
    }

    return size;
}

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    // var res1 = try part1(part1_input, alloc);
    // std.debug.print("Part1: {d}\n", .{res1});

    var res2 = try part2(part1_input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    const size = getSize(data);

    var nums = try Vec.initCapacity(alloc, size.rows * size.cols);
    defer nums.deinit();

    var i: usize = 0;
    for (data) |c| {
        switch (c) {
            '0'...'9' => {
                const num = c - '0';
                try nums.append(num);
                i += 1;
            },
            else => continue,
        }
    }

    var count: usize = 0;
    treeloop: for (nums.items) |n, idx| {
        const row: usize = idx / size.cols;
        const col: usize = idx % size.cols;

        // Automatically count trees around the edges
        if (row == 0 or row == size.rows - 1 or col == 0 or col == size.cols - 1) {
            count += 1;
            continue :treeloop;
        }

        // Check top
        var j: usize = 0;
        var visible = true;
        while (j < row) : (j += 1) {
            if (nums.items[j * size.cols + col] >= n) {
                visible = false;
                break;
            }
        }
        if (visible) {
            count += 1;
            continue :treeloop;
        }

        // Check left
        j = 0;
        visible = true;
        while (j < col) : (j += 1) {
            if (nums.items[row * size.cols + j] >= n) {
                visible = false;
                break;
            }
        }
        if (visible) {
            count += 1;
            continue :treeloop;
        }

        // Check right
        j = col + 1;
        while (j < size.cols) : (j += 1) {
            if (nums.items[row * size.cols + j] >= n) {
                visible = false;
                break;
            }
        }
        if (visible) {
            count += 1;
            continue :treeloop;
        }

        // Check bottom
        j = row + 1;
        while (j < size.rows) : (j += 1) {
            if (nums.items[j * size.cols + col] >= n) {
                visible = false;
                break;
            }
        }
        if (visible) {
            count += 1;
            continue :treeloop;
        }
    }

    std.debug.print("Tree count: {d}\n", .{count});

    return count;
}

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    const size = getSize(data);

    var nums = try Vec.initCapacity(alloc, size.rows * size.cols);
    var score = try ArrayList(usize).initCapacity(alloc, size.rows * size.cols);
    defer nums.deinit();
    defer score.deinit();

    var i: usize = 0;
    for (data) |c| {
        switch (c) {
            '0'...'9' => {
                const num = c - '0';
                try nums.append(num);
                try score.append(0);
                i += 1;
            },
            else => continue,
        }
    }

    for (nums.items) |n, idx| {
        const row: usize = idx / size.cols;
        const col: usize = idx % size.cols;

        if (row == 0 or row == size.rows - 1) continue;
        if (col == 0 or col == size.cols - 1) continue;

        // Check top
        var j: usize = 0;
        var tscore: usize = 0;
        while (j < row) : (j += 1) {
            const H = nums.items[idx - (j + 1) * size.cols];
            tscore += 1;
            if (H >= n) break;
        }

        // Check left
        j = 0;
        var lscore: usize = 0;
        while (j < col) : (j += 1) {
            const H = nums.items[idx - j - 1];
            lscore += 1;
            if (H >= n) break;
        }

        // Check right
        j = col + 1;
        var rscore: usize = 0;
        while (j < size.cols) : (j += 1) {
            const H = nums.items[row * size.cols + j];
            rscore += 1;
            if (H >= n) break;
        }

        // Check bottom
        j = row + 1;
        var bscore: usize = 0;
        while (j < size.rows) : (j += 1) {
            const H = nums.items[j * size.cols + col];
            bscore += 1;
            if (H >= n) break;
        }

        std.debug.print("({d},{d}): Scores: {d}, {d}, {d}, {d}\n", .{ row, col, tscore, lscore, bscore, rscore });
        score.items[idx] = tscore * lscore * rscore * bscore;
    }

    const maxScore: usize = std.mem.max(usize, score.items);
    std.debug.print("Max scenic score: {d}\n", .{maxScore});

    return maxScore;
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    try std.testing.expect(res == 21);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    try std.testing.expect(res == 8);
}
