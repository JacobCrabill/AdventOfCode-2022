const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const GPA = std.heap.GeneralPurposeAllocator;
const Set = utils.Set;

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
    std.debug.print("[Test] Part 1: {d}\n", .{res});
    try std.testing.expect(res == 64);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part 2: {d}\n", .{res});
    try std.testing.expect(res == 58);
}

// ------------ Part 1 Solution ------------

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    var nums = std.mem.tokenize(u8, data, ",\n");

    var cubes = AutoHashMap(Pos, void).init(alloc);
    defer cubes.deinit();

    // No negative numbers in the input, so use (0,0,0) as the min and only track max
    var maxx = Pos{};
    while (nums.next()) |num| {
        // Note: Adding 1 to each makes the algorithm later easier
        var x: i32 = 1 + try std.fmt.parseInt(i32, num, 10);
        var y: i32 = 1 + try std.fmt.parseInt(i32, nums.next().?, 10);
        var z: i32 = 1 + try std.fmt.parseInt(i32, nums.next().?, 10);
        try cubes.put(Pos{ .x = x, .y = y, .z = z }, {});

        maxx.x = @max(maxx.x, x);
        maxx.y = @max(maxx.y, y);
        maxx.z = @max(maxx.z, z);
    }

    const dx = maxx.x + 3;
    const dy = maxx.y + 3;
    const dz = maxx.z + 3;
    var count: usize = 0;

    // We'll scan through the whole "grid" 3 times - one time for each cardinal direction
    // Every time we transition from not-filled to filled (or vice-versa), we've crossed
    // an "exposed" face

    const DX: i32 = @max(@max(dx, dy), dz);
    count += scan(cubes, DX, Axis.X);
    count += scan(cubes, DX, Axis.Y);
    count += scan(cubes, DX, Axis.Z);

    return count;
}

// ------------ Part 2 Solution ------------

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    var nums = std.mem.tokenize(u8, data, ",\n");

    //var cubes = ArrayList(Pos).init(alloc);
    var cubes = AutoHashMap(Pos, void).init(alloc);
    defer cubes.deinit();

    // No negative numbers in the input, so use (0,0,0) as the min and only track max
    var maxx = Pos{};
    while (nums.next()) |num| {
        // Note: Adding 1 to each makes the algorithm later easier
        var x: i32 = 1 + try std.fmt.parseInt(i32, num, 10);
        var y: i32 = 1 + try std.fmt.parseInt(i32, nums.next().?, 10);
        var z: i32 = 1 + try std.fmt.parseInt(i32, nums.next().?, 10);
        try cubes.put(Pos{ .x = x, .y = y, .z = z }, {});

        maxx.x = @max(maxx.x, x);
        maxx.y = @max(maxx.y, y);
        maxx.z = @max(maxx.z, z);
    }

    const dx = maxx.x + 3;
    const dy = maxx.y + 3;
    const dz = maxx.z + 3;
    var count: usize = 0;

    // First, create the grid and fill in the known cubes
    const DX: usize = @intCast(usize, dx * dy * dz);
    var grid = try ArrayList(Fill).initCapacity(alloc, DX);
    defer grid.deinit();
    try grid.appendNTimes(Fill.Interior, DX);

    var x: i32 = 0;
    while (x < dx) : (x += 1) {
        var y: i32 = 0;
        while (y < dy) : (y += 1) {
            var z: i32 = 0;
            while (z < dz) : (z += 1) {
                if (cubes.contains(Pos{ .x = x, .y = y, .z = z }))
                    grid.items[@intCast(usize, x + dx * (y + dy * z))] = Fill.Filled;
            }
        }
    }

    // Next, flood fill from an outside node
    var open = ArrayList(Pos).init(alloc);
    defer open.deinit();
    try open.append(Pos{}); // 0,0,0
    while (open.items.len > 0) {
        const cell = open.pop();
        var poss: []const Pos = &[6]Pos{
            Pos{ .x = cell.x + 1, .y = cell.y, .z = cell.z },
            Pos{ .x = cell.x - 1, .y = cell.y, .z = cell.z },
            Pos{ .x = cell.x, .y = cell.y + 1, .z = cell.z },
            Pos{ .x = cell.x, .y = cell.y - 1, .z = cell.z },
            Pos{ .x = cell.x, .y = cell.y, .z = cell.z + 1 },
            Pos{ .x = cell.x, .y = cell.y, .z = cell.z - 1 },
        };
        for (poss) |pos| {
            if (pos.x < 0 or pos.y < 0 or pos.z < 0) continue;

            const idx: usize = @intCast(usize, pos.x + dy * (pos.y + dy * pos.z));
            if (idx >= grid.items.len) continue;

            // If empty, set to "exterior" (-1) (Don't override filled!)
            if (grid.items[idx] == Fill.Interior) {
                grid.items[idx] = Fill.Exterior;
                try open.append(pos);
            }
        }
    }

    // We'll scan through the whole "grid" 3 times - one time for each cardinal direction
    // Every time we transition from Exterior to filled (or vice-versa), we've crossed
    // an "exposed" exterior face
    const Dx = @intCast(usize, dx);
    const Dy = @intCast(usize, dy);
    const Dz = @intCast(usize, dz);
    count += scan2(grid, Dx, Dy, Dz, Axis.X);
    count += scan2(grid, Dx, Dy, Dz, Axis.Y);
    count += scan2(grid, Dx, Dy, Dz, Axis.Z);

    return count;
}

// ------------ Common Functions ------------

pub const Pos = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
};

const Axis = enum(u8) {
    X = 0,
    Y = 1,
    Z = 2,
};

const Fill = enum(i8) {
    Exterior = -1,
    Interior = 0,
    Filled = 1,
};

fn scan(cubes: AutoHashMap(Pos, void), dx: i32, axis: Axis) usize {
    var count: usize = 0;
    var i: i32 = 0;
    while (i < dx) : (i += 1) {
        var j: i32 = 0;
        while (j < dx) : (j += 1) {
            // Reset status at the start of each scan line
            var fill_status: bool = false;
            var k: i32 = 0;
            while (k < dx) : (k += 1) {
                const pos: Pos = switch (axis) {
                    .X => Pos{ .x = k, .y = j, .z = i },
                    .Y => Pos{ .x = i, .y = k, .z = j },
                    .Z => Pos{ .x = j, .y = i, .z = k },
                };
                const filled = cubes.contains(pos);
                if (filled != fill_status) {
                    count += 1;
                    fill_status = filled;
                }
            }
        }
    }

    return count;
}

fn scan2(grid: ArrayList(Fill), dx: usize, dy: usize, dz: usize, axis: Axis) usize {
    var count: usize = 0;

    var ddx: usize = 0;
    var ddy: usize = 0;
    var ddz: usize = 0;
    switch (axis) {
        .X => {
            ddx = dx;
            ddy = dy;
            ddz = dz;
        },
        .Y => {
            ddy = dx;
            ddz = dy;
            ddx = dz;
        },
        .Z => {
            ddz = dx;
            ddx = dy;
            ddy = dz;
        },
    }

    var x: usize = 0;
    while (x < ddx) : (x += 1) {
        var y: usize = 0;
        while (y < ddy) : (y += 1) {
            // Reset status at the start of each scan line
            var fill_status: Fill = Fill.Exterior;
            var z: usize = 0;
            while (z < ddz) : (z += 1) {
                const idx = switch (axis) {
                    .X => x + dx * (y + dy * z),
                    .Y => y + dx * (z + dy * x),
                    .Z => z + dx * (x + dy * y),
                };
                const filled = grid.items[idx];
                if (grid.items[idx] != Fill.Interior and filled != fill_status) {
                    count += 1;
                    fill_status = filled;
                }
            }
        }
    }

    return count;
}
