const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;
const abs = std.math.absCast;

const test_input = Data.test_input;
const part1_input = Data.part1_input;
const part2_input = Data.part1_input;

pub const Pos = struct {
    x: i64,
    y: i64,
};

pub const PosSet = utils.Set(Pos);

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res1 = try part1(part1_input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = try part2(part2_input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

pub fn follow(h: Pos, t: *Pos) void {
    const dx: i64 = h.x - t.x;
    const dy: i64 = h.y - t.y;
    if (abs(dx) <= 1 and abs(dy) <= 1)
        return; // nothing to do

    if (abs(dx) > 0)
        t.x += std.math.sign(dx) * 1;
    if (abs(dy) > 0)
        t.y += std.math.sign(dy) * 1;
}

pub fn moveRight(h: *Pos, t: *Pos) void {
    h.x += 1;
    follow(h.*, t);

    std.debug.print("New loc: H({d},{d}), T({d},{d})\n", .{ h.x, h.y, t.x, t.y });
}

pub fn moveLeft(h: *Pos, t: *Pos) void {
    h.x -= 1;
    follow(h.*, t);

    std.debug.print("New loc: H({d},{d}), T({d},{d})\n", .{ h.x, h.y, t.x, t.y });
}

pub fn moveUp(h: *Pos, t: *Pos) void {
    h.y += 1;
    follow(h.*, t);

    std.debug.print("New loc: H({d},{d}), T({d},{d})\n", .{ h.x, h.y, t.x, t.y });
}
pub fn moveDown(h: *Pos, t: *Pos) void {
    h.y -= 1;
    follow(h.*, t);

    std.debug.print("New loc: H({d},{d}), T({d},{d})\n", .{ h.x, h.y, t.x, t.y });
}

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    var hpos = Pos{
        .x = 0,
        .y = 0,
    };
    var tpos = Pos{
        .x = 0,
        .y = 0,
    };

    var seen = PosSet.init(alloc);
    defer seen.deinit();

    const FnType: type = fn (*Pos, *Pos) void;

    while (lines.next()) |line| {
        if (line.len < 3) break;
        std.debug.print("{s}, '{c}'\n", .{ line, line[0] });
        const n: i64 = try std.fmt.parseInt(i64, line[2..], 10);
        const func: *const FnType = switch (line[0]) {
            'R' => moveRight,
            'L' => moveLeft,
            'U' => moveUp,
            'D' => moveDown,
            else => continue,
        };

        var i: i64 = 0;
        while (i < n) : (i += 1) {
            func(&hpos, &tpos);
            try seen.put(tpos);
        }
    }

    return seen.count();
}

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    var lines = std.mem.split(u8, data, "\n");

    var hpos = Pos{
        .x = 0,
        .y = 0,
    };
    var tpos = Pos{
        .x = 0,
        .y = 0,
    };

    var seen = PosSet.init(alloc);
    defer seen.deinit();

    const FnType: type = fn (*Pos, *Pos) void;

    while (lines.next()) |line| {
        if (line.len < 3) break;
        std.debug.print("{s}, '{c}'\n", .{ line, line[0] });
        const n: i64 = try std.fmt.parseInt(i64, line[2..], 10);
        const func: *const FnType = switch (line[0]) {
            'R' => moveRight,
            'L' => moveLeft,
            'U' => moveUp,
            'D' => moveDown,
            else => continue,
        };

        var i: i64 = 0;
        while (i < n) : (i += 1) {
            func(&hpos, &tpos);
            try seen.put(tpos);
        }
    }

    return seen.count();
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    try std.testing.expect(res == 13);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    try std.testing.expect(res == 0);
}
