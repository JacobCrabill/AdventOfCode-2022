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

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res1 = try part1(part1_input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = part2(part2_input, alloc);
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

    pub fn total_size(self: Dir) usize {
        var sum: usize = self.size;
        for (self.dirs.items) |dir| {
            sum += dir.total_size();
        }
        return sum;
    }

    pub fn weird_size_recurse(self: Dir, cur_total: usize) usize {
        var total: usize = self.total_size();
        if (total > 100000)
            total = 0;

        for (self.dirs.items) |dir| {
            total += dir.weird_size_recurse(cur_total);
        }
        return cur_total + total;
    }
};

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    // initialize with root directory we know exists
    var root_line = lines.next() orelse return 0;
    const root_dir = root_line[5..];

    var root: Dir = Dir.init(root_dir, undefined, alloc);

    // Store the current working directory
    var cwd: *Dir = &root;

    while (lines.next()) |line| {
        std.debug.print("<<{s}>>\n", .{line});
        if (std.mem.startsWith(u8, line, "$ cd ..")) {
            // Go up a directory
            cwd = cwd.parent orelse undefined;
        } else if (std.mem.startsWith(u8, line, "$ cd /")) {
            // Do nothing

        } else if (std.mem.startsWith(u8, line, "$ cd ")) {
            const dir = line[5..];
            for (cwd.dirs.items) |*d| {
                std.debug.print("Compare: '{s}' '{s}'\n", .{ dir, d.name });
                if (std.mem.eql(u8, dir, d.name)) {
                    cwd = d;
                    std.debug.print("  cd {s}\n", .{cwd.name});
                    break;
                }
            }
        } else if (std.mem.startsWith(u8, line, "$ ls")) {
            // do nothing

        } else if (std.mem.startsWith(u8, line, "dir ")) {
            const dir = line[4..];
            std.debug.print("  Add dir: {s} to {s}\n", .{ dir, cwd.name });
            try cwd.dirs.append(Dir.init(dir, cwd, alloc));
        } else if (line.len < 2) {
            // EOF?

        } else if (std.mem.indexOfScalar(u8, "0123456789", line[0]) != null) {
            // file
            var f = std.mem.split(u8, line, " ");
            const size = try std.fmt.parseInt(usize, f.next() orelse "", 10);
            cwd.size += size;
            std.debug.print("  Add {d} bytes to {s}\n", .{ size, cwd.name });

            // The weird bit: Recursively add the size to all parent dirs
            // var parent = cwd.parent;
            // while (parent != null) {
            //     std.debug.print("  -- Add to parent {s}\n", .{parent.?.name});
            //     parent.?.size += size;
            //     parent = parent.?.parent;
            // }
        }
    }

    // sum all directories with a size < 1000000
    //var total: usize = 0;
    //for (dirmap.items) |*dir| {
    //    std.debug.print("Found dir {s} with size {d}\n", .{ dir.name, dir.size });
    //    if (dir.total_size() > 100000) continue;
    //    total += dir.size;
    //}
    const total = root.weird_size_recurse(0);

    root.deinit();

    std.debug.print("===========\n", .{});
    std.debug.print("Total: {d}\n", .{total});
    std.debug.print("===========\n", .{});
    return total;
}

pub fn part2(_: []const u8, _: Allocator) usize {
    return 0;
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    try std.testing.expect(res == 95437);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = part2(test_input, alloc);
    try std.testing.expect(res == 0);
}
