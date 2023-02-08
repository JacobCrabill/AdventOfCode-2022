const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const GPA = std.heap.GeneralPurposeAllocator;
const ns2sec = utils.ns2sec;
const Timer = utils.Timer;

const test_input = Data.test_input;
const input = Data.input;

const WIDTH: u64 = 7;
const N_PART1: u64 = 2022;
const N_PART2: u64 = 1000000000000;
const BLOCK_HEIGHT_SUM: u64 = 13; // Height of all block types stacked up

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var T = try Timer();

    // var res1 = try part1(input, alloc);
    // std.debug.print("Part1: {d}\n", .{res1});
    // std.debug.print("Part 1 took {d:.6}s\n", .{ns2sec(T.lap())});

    var res2 = try part2(input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
    std.debug.print("Part 2 took {d:.6}s\n", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input\n" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    std.debug.print("[Test] Part 1: {d}\n", .{res});
    try std.testing.expect(res == 3068);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part 2: {d}\n", .{res});
    try std.testing.expect(res == 1514285714288);
}

// ------------ Part 1 Solution ------------

pub fn part1(data: []const u8, alloc: Allocator) !u64 {
    // Initialize our grid to the max height we could get
    // (2022 blocks stacked on top of each other, none side-by-side)
    var grid = try ArrayList(u1).initCapacity(alloc, WIDTH * BLOCK_HEIGHT_SUM * N_PART1);
    defer grid.deinit();
    try grid.appendNTimes(0, WIDTH * BLOCK_HEIGHT_SUM * N_PART1);

    std.debug.print("data.len = {d}\n", .{data.len});
    var block: Block = Block.Row;
    var x: u64 = 2;
    var y: u64 = 3;
    var max_y: u64 = 0;
    var prev_maxy: u64 = 0;

    // printGrid(grid, max_y);
    var i: u64 = 0;
    var bid: u64 = 0;
    while (bid < N_PART1) {
        if (i % (data.len - 2) == 0) {
            // std.debug.print("{any} | {d}: prev/max-y {d}, {d} delta: {d}\n", .{ block, i, prev_maxy, max_y, max_y - prev_maxy });
            prev_maxy = max_y;
        }

        const c: u8 = data[i % (data.len - 1)]; // last char is '\n'
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

pub fn part2(data: []const u8, alloc: Allocator) !u64 {
    // Initialize our grid to the max height we could get
    const GRID_HEIGHT = data.len * 20;
    var grid = try ArrayList(u1).initCapacity(alloc, WIDTH * BLOCK_HEIGHT_SUM * GRID_HEIGHT);
    defer grid.deinit();
    try grid.appendNTimes(0, WIDTH * BLOCK_HEIGHT_SUM * GRID_HEIGHT);

    var cache = AutoHashMap(Config, Status).init(alloc);
    defer cache.deinit();

    var block: Block = Block.Row;
    var x: u64 = 2;
    var y: u64 = 3;
    var max_y: u64 = 1;
    var jump_offset: u64 = 0;
    var jumped: bool = false;

    var bid_limit: u64 = N_PART2;
    var i: u64 = 0;
    var bid: u64 = 0;
    while (bid < bid_limit) {
        const c: u8 = data[i];
        i = @mod(i + 1, data.len - 1);
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

            if (!jumped) {
                // Check the cache to see if we've found the pattern yet
                const topo = getTopoMap(grid, max_y - 1);
                var config = Config{
                    .idx = i,
                    .block = block,
                    .topo = topo,
                };

                if (cache.contains(config)) {
                    const pres: Status = cache.get(config).?;
                    const delta: u64 = max_y - pres.maxy;
                    const dbid: u64 = bid - pres.bid;
                    std.debug.print("Cache hit! {any}, {any}\n", .{ config, pres });

                    // Now we can jump ahead to the end!  ...Almost
                    // Each interval adds 'delta' to the stack; we need N_PART2
                    // We can jump ahead M intervals to then finish it off
                    // (we actually just keep going in our current grid, but store the
                    // intervening height to apply at the end)
                    const M = @divFloor(N_PART2 - bid, dbid);
                    std.debug.print("Jumping ahead {d} blocks times {d}\n", .{ M, dbid });
                    std.debug.print("Delta-height: {d}, new height: {d}\n", .{ delta, M * delta + max_y });
                    bid_limit -= M * dbid;
                    jump_offset = M * delta;
                    jumped = true;
                } else {
                    const status = Status{
                        .bid = bid,
                        .maxy = max_y,
                    };
                    try cache.put(config, status);
                }
            }
        }
    }

    return max_y + jump_offset;
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

    pub fn at(self: Block, x: u64, y: u64) bool {
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
    pub fn right(self: Block) u64 {
        return switch (self) {
            .Row => 3,
            .Plus => 2,
            .Angle => 2,
            .Column => 0,
            .Square => 1,
        };
    }
};

const Config = struct {
    idx: u64 = 0,
    block: Block = Block.Row,
    topo: [7]u8 = [1]u8{255} ** 7, // Block stack depth map below current max_y
};

const Status = struct {
    bid: u64 = 0,
    maxy: u64 = 0,
};

fn tickLeft(grid: ArrayList(u1), block: Block, x: *u64, y: u64) void {
    if (x.* == 0) return; // Nothing to do

    // Move left if not blocked
    var new_x = x.* - 1;
    if (!occupied(grid, block, new_x, y)) {
        x.* = new_x;
    }
}

fn tickRight(grid: ArrayList(u1), block: Block, x: *u64, y: u64) void {
    if (x.* + block.right() >= WIDTH - 1) return; // Nothing to do

    // Move right if not blocked
    const new_x = x.* + 1;
    if (!occupied(grid, block, new_x, y)) {
        x.* = new_x;
    }
}

// Return 'true' if the block moved, else 'false' if it landed
fn tickDown(grid: ArrayList(u1), block: Block, x: u64, y: *u64) bool {
    if (y.* == 0) return false;

    const new_y = y.* - 1;
    if (!occupied(grid, block, x, new_y)) {
        y.* = new_y;
        return true;
    }

    return false;
}

fn fillBlock(grid: *ArrayList(u1), block: Block, x: u64, y: u64) void {
    var j: u64 = 0;
    while (j < 4) : (j += 1) {
        const yy = y + j;
        var i: u64 = 0;
        while (i < 4) : (i += 1) {
            const xx = x + i;
            if (xx >= WIDTH) break;
            if (block.at(i, j)) {
                grid.items[xx + WIDTH * yy] = 1;
            }
        }
    }
}

fn occupied(grid: ArrayList(u1), block: Block, x: u64, y: u64) bool {
    // Check if a block of the given type placed at (x, y) overlaps an existing block
    var j: u64 = 0;
    while (j < 4) : (j += 1) {
        const yy = y + j;
        var i: u64 = 0;
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

fn topRow(grid: ArrayList(u1), start_y: u64) u64 {
    var j: u64 = 0;
    yloop: while (true) : (j += 1) {
        var y = j + start_y;
        var x: u64 = 0;
        while (x < WIDTH) : (x += 1) {
            if (grid.items[x + WIDTH * y] == 1) {
                continue :yloop;
            }
        }

        // We finished the last row w/o any occupied cells
        return y;
    }
}

fn getTopoMap(grid: ArrayList(u1), y: u64) [7]u8 {
    // Starting y == 0
    // Scan left to right
    // Store 'depth' (below y) of first block found
    var i: u3 = 0;
    var out = [1]u8{255} ** 7;
    while (i < WIDTH) : (i += 1) {
        var j: u8 = 0;
        depth: while (j < 50 and j < y) : (j += 1) {
            if (grid.items[i + WIDTH * (y - j)] > 0) {
                out[i] = j;
                break :depth;
            }
        }
    }

    return out;
}

fn printGrid(grid: ArrayList(u1), max_y: u64) void {
    var y: i64 = @intCast(i64, max_y);
    while (y >= 0) : (y -= 1) {
        var x: u64 = 0;
        std.debug.print("{d:4} |", .{y + 1});
        while (x < WIDTH) : (x += 1) {
            const iy: u64 = @intCast(u64, y);
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
