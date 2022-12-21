const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;
const ns2sec = utils.ns2sec;
const Timer = utils.Timer;

const test_input = Data.test_input;
const input = Data.input;

const WIDTH: usize = 7;
const N_PART1: usize = 2022;
const N_PART2: usize = 1000000000000;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var T = try Timer();

    var res1 = try part1(input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});
    std.debug.print("Part 1 took {d:.6}s\n", .{ns2sec(T.lap())});

    var res2 = try part2(input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
    std.debug.print("Part 2 took {d:.6}s\n", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    std.debug.print("[Test] Part 1: {d}\n", .{res});
    try std.testing.expect(res == 3068);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part 2: {d}\n", .{res});
    try std.testing.expect(res == 0);
}

// ------------ Part 1 Solution ------------

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    // Initialize our grid to the max height we could get
    // (2022 blocks stacked on top of each other, none side-by-side)
    var grid = try ArrayList(u1).initCapacity(alloc, WIDTH * 13 * N_PART1);
    defer grid.deinit();
    try grid.appendNTimes(0, WIDTH * 13 * N_PART1);

    var block: Block = Block.Row;
    var x: usize = 2;
    var y: usize = 3;
    var max_y: usize = 3;

    // printGrid(grid, max_y);
    var i: usize = 0;
    var bid: usize = 0;
    while (bid < N_PART1) {
        const c: u8 = data[i % data.len];
        i += 1;
        switch (c) {
            '>' => {
                // std.debug.print("right\n", .{});
                tickRight(grid, block, &x, y);
            },
            '<' => {
                // std.debug.print("left\n", .{});
                tickLeft(grid, block, &x, y);
            },
            else => {
                continue;
            },
        }

        // std.debug.print("down?", .{});
        if (!tickDown(grid, block, x, &y)) {
            // std.debug.print(" no\n", .{});
            // Block landed
            fillBlock(&grid, block, x, y);
            max_y = topRow(grid, y);
            // std.debug.print("Block landed at ({d},{d}); max_y {d}\n", .{ x, y, max_y });
            // printGrid(grid, max_y);
            y = max_y + 3;
            x = 2;
            block.next();
            bid += 1;
        }
        // std.debug.print(" yes\n", .{});
    }

    // printGrid(grid, max_y);
    return max_y;
}

// ------------ Part 2 Solution ------------

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    // Initialize our grid to the max height we could get
    const GRID_HEIGHT = data.len + 100;
    const RESET_Y = data.len;
    var grid = try ArrayList(u1).initCapacity(alloc, WIDTH * 13 * GRID_HEIGHT);
    defer grid.deinit();
    try grid.appendNTimes(0, WIDTH * 13 * GRID_HEIGHT);

    var block: Block = Block.Row;
    var x: usize = 2;
    var y: usize = 3;
    var max_y: usize = 3;
    var y_offset: usize = 0;

    var i: usize = 0;
    var bid: usize = 0;
    while (bid < 10 * data.len) {
        const c: u8 = data[i % data.len];
        i += 1;
        switch (c) {
            '>' => {
                tickRight(grid, block, &x, y);
            },
            '<' => {
                tickLeft(grid, block, &x, y);
            },
            else => {
                continue;
            },
        }

        if (!tickDown(grid, block, x, &y)) {
            // Block landed
            fillBlock(&grid, block, x, y);
            max_y = topRow(grid, y);
            y = max_y + 3;
            x = 2;
            block.next();
            bid += 1;
            if (bid % data.len == 0) {
                std.debug.print("height: {d}\n", .{max_y});
            }
            if (bid % 1000000 == 0) {
                std.debug.print("--{d}\n", .{bid});
            }

            // Update the offset reset y and max_y, and reset the grid
            // (Copy top rows to bottom of grid)
            if (y > GRID_HEIGHT - 10) {
                y_offset += RESET_Y;
                y -= RESET_Y;
                resetGrid(&grid, RESET_Y, GRID_HEIGHT);
            }
        }
    }

    return max_y + y_offset;
}

// ------------ Common Functions ------------

const Block = enum(u8) {
    Row = 0,
    Plus = 1,
    Angle = 2,
    Column = 3,
    Square = 4,

    // NOTE: coord (0,0) at btm-left, so these appear upside-down
    var row_fill: [16]u1 = [_]u1{
        1, 1, 1, 1,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    };
    var plus_fill: [16]u1 = [_]u1{
        0, 1, 0, 0,
        1, 1, 1, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    };
    var angle_fill: [16]u1 = [_]u1{
        1, 1, 1, 0,
        0, 0, 1, 0,
        0, 0, 1, 0,
        0, 0, 0, 0,
    };
    var column_fill: [16]u1 = [_]u1{
        1, 0, 0, 0,
        1, 0, 0, 0,
        1, 0, 0, 0,
        1, 0, 0, 0,
    };
    var square_fill: [16]u1 = [_]u1{
        1, 1, 0, 0,
        1, 1, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
    };

    pub fn next(self: *Block) void {
        self.* = switch (self.*) {
            .Row => .Plus,
            .Plus => .Angle,
            .Angle => .Column,
            .Column => .Square,
            .Square => .Row,
        };
    }

    pub fn at(self: Block, x: usize, y: usize) bool {
        const data = switch (self) {
            .Row => row_fill,
            .Plus => plus_fill,
            .Angle => angle_fill,
            .Column => column_fill,
            .Square => square_fill,
        };
        return (data[x + 4 * y] == 1);
    }

    // Return the right-most column of this block
    pub fn right(self: Block) usize {
        return switch (self) {
            .Row => 3,
            .Plus => 2,
            .Angle => 2,
            .Column => 0,
            .Square => 1,
        };
    }
};

fn tickLeft(grid: ArrayList(u1), block: Block, x: *usize, y: usize) void {
    if (x.* == 0) return; // Nothing to do

    // Move left if not blocked
    var new_x = x.* - 1;
    if (!occupied(grid, block, new_x, y)) {
        x.* = new_x;
    }
}

fn tickRight(grid: ArrayList(u1), block: Block, x: *usize, y: usize) void {
    if (x.* + block.right() >= WIDTH - 1) return; // Nothing to do

    // Move right if not blocked
    const new_x = x.* + 1;
    if (!occupied(grid, block, new_x, y)) {
        x.* = new_x;
    }
}

// Return 'true' if the block moved, else 'false' if it landed
fn tickDown(grid: ArrayList(u1), block: Block, x: usize, y: *usize) bool {
    if (y.* == 0) return false;
    // std.debug.print("{any} {d},{d}\n", .{ block, x, y.* });

    const new_y = y.* - 1;
    if (!occupied(grid, block, x, new_y)) {
        y.* = new_y;
        return true;
    }

    return false;
}

fn fillBlock(grid: *ArrayList(u1), block: Block, x: usize, y: usize) void {
    var j: usize = 0;
    while (j < 4) : (j += 1) {
        const yy = y + j;
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            const xx = x + i;
            if (xx >= WIDTH) break;
            if (block.at(i, j)) {
                grid.items[xx + WIDTH * yy] = 1;
            }
        }
    }
}

fn occupied(grid: ArrayList(u1), block: Block, x: usize, y: usize) bool {
    // Check if a block of the given type placed at (x, y) overlaps an existing block
    var j: usize = 0;
    while (j < 4) : (j += 1) {
        const yy = y + j;
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            const xx = x + i;
            if (xx >= WIDTH) continue;

            if (grid.items[xx + WIDTH * yy] == 1 and block.at(i, j)) {
                return true;
            }
        }
    }

    return false;
}

fn topRow(grid: ArrayList(u1), start_y: usize) usize {
    var j: usize = 0;
    yloop: while (true) : (j += 1) {
        var y = j + start_y;
        var x: usize = 0;
        while (x < WIDTH) : (x += 1) {
            if (grid.items[x + WIDTH * y] == 1) {
                continue :yloop;
            }
        }

        // We finished the last row w/o any occupied cells
        return y;
    }
}

fn printGrid(grid: ArrayList(u1), max_y: usize) void {
    var y: i64 = @intCast(i64, max_y);
    while (y >= 0) : (y -= 1) {
        var x: usize = 0;
        std.debug.print("{d:4} |", .{y});
        while (x < WIDTH) : (x += 1) {
            const iy: usize = @intCast(usize, y);
            var val = grid.items[x + WIDTH * iy];
            if (val == 1) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(" ", .{});
            }
        }
        std.debug.print("|\n", .{});
    }
    std.debug.print("---------\n", .{});
}

fn resetGrid(grid: *ArrayList(u1), shift: usize, max_y: usize) void {
    const dy: usize = max_y - shift;
    var y: usize = 0;
    while (y < max_y) : (y += 1) {
        var x: usize = 0;
        while (x < WIDTH) : (x += 1) {
            if (y < dy) {
                grid.items[x + WIDTH * y] = grid.items[x + WIDTH * (y + shift)];
            } else {
                grid.items[x + WIDTH * y] = 0;
            }
        }
    }
}
