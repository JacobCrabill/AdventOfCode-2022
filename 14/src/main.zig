const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;
const ArrayList = std.ArrayList;
const abs = std.math.absInt;

const test_input = Data.test_input;
const input = Data.input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res1 = try part1(input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = try part2(input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

// ------------ Tests ------------

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    std.debug.print("[Test] Part1: {d}\n", .{res});
    try std.testing.expect(res == 24);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part2: {d}\n", .{res});
    try std.testing.expect(res == 93);
}

// ------------ Part 1 Solution ------------

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    var cave = try buildGrid(data, alloc, false);
    defer cave.deinit();

    // Starting cave layout
    cave.print();

    var count: usize = 0;
    while (cave.fillSand()) {
        count += 1;
    }

    // Just for fun! Final cave filled with sand.
    cave.print();

    return count;
}

// ------------ Part 2 Solution ------------

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    var cave = try buildGrid(data, alloc, true);
    defer cave.deinit();

    var count: usize = 0;
    while (cave.fillSand()) {
        count += 1;
    }

    // Just for fun!
    cave.print();

    return count;
}

// ------------ Common Functions ------------

const itype: type = i32;
const Pos = struct {
    x: itype,
    y: itype,
};

const PosArr: type = ArrayList(Pos);

const Material = enum(u8) {
    Air = 0,
    Rock = 1,
    Sand = 2,
};

pub const Cave = struct {
    grid: ArrayList(Material),
    stride: usize,
    height: usize,
    sandx: usize,

    pub fn deinit(self: *Cave) void {
        self.grid.deinit();
    }

    pub fn at(self: Cave, ix: itype, jx: itype) ?Material {
        if (ix < 0 or jx < 0) return null;
        const i = @intCast(usize, ix);
        const j = @intCast(usize, jx);
        if (i >= self.stride or j >= self.height) return null;
        return self.grid.items[i + j * self.stride];
    }

    pub fn place(self: *Cave, mat: Material, ix: anytype, iy: anytype) void {
        if (ix < 0 or iy < 0 or ix >= self.stride or iy >= self.height) return;
        const idx = @intCast(usize, ix) + @intCast(usize, iy) * self.stride;
        self.grid.items[idx] = mat;
    }

    pub fn print(self: Cave) void {
        std.debug.print("\nCave with extents {d}x{d}, ", .{ self.stride, self.height });
        std.debug.print("filling with sand at ({d},0)\n", .{self.sandx});
        var idx: usize = 0;
        for (self.grid.items) |mat| {
            const c: []const u8 = switch (mat) {
                .Air => " ",
                .Rock => "█",
                .Sand => "x",
            };
            std.debug.print("{s}", .{c});
            idx += 1;

            if (idx % self.stride == 0) std.debug.print("\n", .{});
        }
    }

    pub fn fillSand(self: *Cave) bool {
        var sx: itype = @intCast(i32, self.sandx);
        var sy: itype = 0;
        while (true) {
            if (sy >= self.height) // Cave is filled
                return false;

            if ((self.at(sx, sy + 1) orelse Material.Air) == Material.Air) {
                // Move straight down
                sy += 1;
            } else if ((self.at(sx - 1, sy + 1) orelse Material.Air) == Material.Air) {
                // Move down and to the left
                sx -= 1;
                sy += 1;
            } else if ((self.at(sx + 1, sy + 1) orelse Material.Air) == Material.Air) {
                // Move down and to the right
                sx += 1;
                sy += 1;
            } else {
                // Nowhere left to move
                if (sx == self.sandx and sy == 0 and self.at(sx, sy).? == Material.Sand) {
                    return false;
                }
                self.place(Material.Sand, sx, sy);
                return true;
            }
        }
    }
};

pub fn buildGrid(data: []const u8, alloc: Allocator, pad: bool) !Cave {
    // Parse the lines into pairs of (x,y) values
    // Each line defines a list of line segments of rocks
    var lines = std.mem.tokenize(u8, data, "\n");
    var segments = ArrayList(PosArr).init(alloc);
    while (lines.next()) |line| {
        var pairs = PosArr.init(alloc);
        var nums = std.mem.tokenize(u8, line, ",-> ");
        while (nums.next()) |num| {
            const x: itype = try std.fmt.parseInt(itype, num, 10);
            const num2 = nums.next().?;
            const y: itype = try std.fmt.parseInt(itype, num2, 10);
            try pairs.append(Pos{ .x = x, .y = y });
        }
        try segments.append(pairs);
    }

    // Get the extents of our grid ("cave")
    var minPos = Pos{ .x = std.math.maxInt(itype), .y = std.math.maxInt(itype) };
    var maxPos = Pos{ .x = 0, .y = 0 };
    for (segments.items) |row| {
        for (row.items) |pair| {
            minPos.x = @min(minPos.x, pair.x);
            minPos.y = @min(minPos.y, pair.y);
            maxPos.x = @max(maxPos.x, pair.x);
            maxPos.y = @max(maxPos.y, pair.y);
        }
    }

    if (pad) {
        minPos.x -= maxPos.y + 2 - (500 - minPos.x);
        maxPos.x += maxPos.y + 2 - (maxPos.x - 500);
        maxPos.y += 2;
    }

    const nx: usize = @intCast(usize, maxPos.x - minPos.x) + 1;
    const ny: usize = @intCast(usize, maxPos.y) + 1; // Note: AoC explicitly says sand comes in at (500, 0)
    const sandx: usize = 500 - @intCast(usize, minPos.x); // Local x index of sand-fill location

    // Initialize the "cave" grid
    var cave = Cave{
        .grid = try ArrayList(Material).initCapacity(alloc, nx * ny),
        .stride = nx,
        .height = ny,
        .sandx = sandx,
    };
    try cave.grid.appendNTimes(Material.Air, nx * ny);

    if (pad) {
        var i: usize = 0;
        while (i < nx) : (i += 1) {
            cave.place(Material.Rock, i, ny - 1);
        }
    }

    // Fill the cave with the mapped obstacles / rock / whatever
    for (segments.items) |row| {
        var start = row.items[0];
        cave.place(Material.Rock, start.x - minPos.x, start.y);
        for (row.items) |pair| {
            const end = pair;
            const dx = end.x - start.x;
            const dy = end.y - start.y;
            const n = @max(try abs(dx), try abs(dy));
            var i: itype = 0;
            while (i < n + 1) : (i += 1) {
                cave.place(Material.Rock, start.x - minPos.x, start.y);
                start.x += std.math.sign(dx) * 1;
                start.y += std.math.sign(dy) * 1;
            }
            start = end;
        }
    }

    for (segments.items) |arr| arr.deinit();
    segments.deinit();

    return cave;
}
