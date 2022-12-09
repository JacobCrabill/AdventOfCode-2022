const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const stdout = utils.stdout;
const Set = utils.Set;
const Map = std.StringHashMap;
const ArrayList = std.ArrayList;

const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;

const test_input = Data.test_input;
const part1_input = Data.part1_input;
const part2_input = Data.part2_input;

const TOTAL_SPACE = 70000000;
const SPACE_REQUIRED = 30000000;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res1 = try part1(part1_input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = try part2(part1_input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

const DirMap = Map(Dir);

pub const Dir = struct {
    name: []const u8,
    parent: ?*Dir,
    dirs: ArrayList(Dir),
    size: usize,
    alloc: Allocator,

    pub fn init(name: []const u8, parent: *Dir, alloc: Allocator) Dir {
        return Dir{
            .name = name,
            .parent = parent,
            .dirs = ArrayList(Dir).init(alloc),
            .size = 0,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *Dir) void {
        for (self.dirs.items) |*dir| {
            dir.deinit();
        }
        self.dirs.deinit();
    }

    pub fn totalSize(self: Dir) usize {
        var sum: usize = self.size;
        for (self.dirs.items) |dir| {
            sum += dir.totalSize();
        }
        return sum;
    }

    pub fn weirdSizeRecurse(self: Dir, cur_total: usize) usize {
        var total: usize = self.totalSize();
        if (total > 100000)
            total = 0;

        for (self.dirs.items) |dir| {
            total += dir.weirdSizeRecurse(cur_total);
        }
        return cur_total + total;
    }

    pub fn getBestToDelete(self: Dir, min_to_delete: usize, cur_best: usize) usize {
        var new_best = cur_best;
        if (self.totalSize() >= min_to_delete) {
            new_best = @min(cur_best, self.totalSize());

            for (self.dirs.items) |dir| {
                new_best = dir.getBestToDelete(min_to_delete, new_best);
            }
        }

        return new_best;
    }
};

pub fn parseLog(lines: *std.mem.SplitIterator(u8), root: *Dir, alloc: Allocator) !void {
    // Store the current working directory
    var cwd: *Dir = root;

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "$ cd ..")) {
            // Go up a directory
            cwd = cwd.parent orelse undefined;
        } else if (std.mem.startsWith(u8, line, "$ cd /")) {
            // Do nothing

        } else if (std.mem.startsWith(u8, line, "$ cd ")) {
            const dir = line[5..];
            for (cwd.dirs.items) |*d| {
                if (std.mem.eql(u8, dir, d.name)) {
                    cwd = d;
                    break;
                }
            }
        } else if (std.mem.startsWith(u8, line, "$ ls")) {
            // do nothing

        } else if (std.mem.startsWith(u8, line, "dir ")) {
            const dir = line[4..];
            try cwd.dirs.append(Dir.init(dir, cwd, alloc));
        } else if (line.len < 2) {
            // EOF?

        } else if (std.mem.indexOfScalar(u8, "0123456789", line[0]) != null) {
            // file
            var f = std.mem.split(u8, line, " ");
            const size = try std.fmt.parseInt(usize, f.next() orelse "", 10);
            cwd.size += size;
        }
    }
}

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    // initialize with root directory we know exists
    var root_line = lines.next() orelse return 0;
    const root_dir = root_line[5..];

    var root: Dir = Dir.init(root_dir, undefined, alloc);

    // Parse the input, creating the directory tree
    try parseLog(&lines, &root, alloc);

    const total = root.weirdSizeRecurse(0);

    root.deinit();

    std.debug.print("===========\n", .{});
    std.debug.print("Total: {d}\n", .{total});
    std.debug.print("===========\n", .{});
    return total;
}

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    // initialize with root directory we know exists
    var root_line = lines.next() orelse return 0;
    const root_dir = root_line[5..];

    var root: Dir = Dir.init(root_dir, undefined, alloc);

    // Parse the input, creating the directory tree
    try parseLog(&lines, &root, alloc);

    const total_size = root.totalSize();
    const free_space = TOTAL_SPACE - total_size;
    const min_to_delete = SPACE_REQUIRED - free_space;

    std.debug.print("\n", .{});
    std.debug.print("Total Size: {d}\n", .{total_size});
    std.debug.print("min_to_delete: {d}\n", .{min_to_delete});

    const best_size = root.getBestToDelete(min_to_delete, total_size);

    root.deinit();

    return best_size;
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    try std.testing.expect(res == 95437);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    try std.testing.expect(res == 24933642);
}
