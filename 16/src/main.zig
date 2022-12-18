const std = @import("std");
const Data = @import("data");
const utils = @import("utils");
const part2 = @import("part2.zig").part2;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const GPA = std.heap.GeneralPurposeAllocator;

const BitSet = std.StaticBitSet(59); // Number of valves in our input

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
    try std.testing.expect(res == 1651);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part 2: {d}\n", .{res});
    try std.testing.expect(res == 1707);
}

// ------------ Part 1 Solution ------------

pub fn part1(data: []const u8, alloc: Allocator) !usize {
    var rooms = std.ArrayList(Room).init(alloc);
    defer rooms.deinit();

    var n2i = StringHashMap(usize).init(alloc);
    defer n2i.deinit();

    // Parse input
    var lines = std.mem.split(u8, data, "\n");
    var idx: usize = 0;
    while (lines.next()) |line| {
        if (line.len < 10) continue;
        const name = line[6..8];
        const ic = std.mem.indexOfScalar(u8, line, ';').?;
        const rate = try std.fmt.parseInt(usize, line[23..ic], 10);

        try rooms.append(Room{});
        var room = &rooms.items[idx];
        try n2i.put(name, idx);
        room.init(name, idx, rate, alloc);

        var tunnels = std.mem.tokenize(u8, line[ic + 24 ..], "valves ,");
        while (tunnels.next()) |tun| {
            try room.tunnel_set.append(tun);
        }

        idx += 1;
    }

    // Turn the lists of strings into integer arrays for quicker access
    for (rooms.items) |*room| {
        for (room.tunnel_set.items) |tunnel| {
            const ti = n2i.get(tunnel).?;
            try room.tunnels.append(ti);
        }
    }

    var score: usize = try traverseRooms(rooms, alloc, n2i.get("AA").?);

    // Cleanup
    for (rooms.items) |*room| {
        room.deinit();
    }

    return score;
}

// ------------ Common Functions ------------

pub const Room = struct {
    name: []const u8 = undefined,
    idx: usize = 0,
    rate: usize = 0,
    tunnel_set: ArrayList([]const u8) = undefined,
    tunnels: ArrayList(usize) = undefined,
    alloc: Allocator = undefined,

    pub fn init(self: *Room, name: []const u8, idx: usize, rate: usize, alloc: Allocator) void {
        self.name = name;
        self.idx = idx;
        self.rate = rate;
        self.tunnel_set = ArrayList([]const u8).init(alloc);
        self.tunnels = ArrayList(usize).init(alloc);
        self.alloc = alloc;
    }

    pub fn deinit(self: *Room) void {
        self.tunnel_set.deinit();
        self.tunnels.deinit();
    }
};

fn traverseRooms(rooms: ArrayList(Room), alloc: Allocator, start: usize) !usize {
    var cache = Cache.init(alloc);
    defer cache.deinit();

    var valves: BitSet = BitSet.initEmpty(); // Number of valves in input
    var score: usize = try recurse(rooms, &cache, valves, start, 0, 0, 1);
    return score;
}

const Stats = struct {
    minute: usize = 0,
    room: usize = 0,
    score: usize = 0,
    open_valves: BitSet = BitSet.initEmpty(),
};
const Cache = AutoHashMap(Stats, usize);

// Recursively traverse the tree, trying all options at every room (opening the valve
// or continueing to another room), and return the final "best score" of all the options
fn recurse(rooms: ArrayList(Room), cache: *Cache, open_valves: BitSet, ridx: usize, flowrate: usize, score: usize, minute: usize) !usize {
    var new_score: usize = score + flowrate;

    // Check the cache for this setup
    const stats = Stats{ .minute = minute, .room = ridx, .score = new_score, .open_valves = open_valves };
    var cached_score = cache.get(stats);
    if (cached_score != null) {
        return cached_score.?;
    }

    // Break condition: 30-minute time limit reached
    if (minute == 30) return new_score;

    var room = rooms.items[ridx];
    // std.debug.print("Enter room {s} with score {d} and {d} minutes left\n", .{ room.name, new_score, 31 - minute });

    // Option 1: open the valve before continuing to another room
    var stay: usize = 0;
    if (room.rate > 0 and !open_valves.isSet(ridx)) {
        if (!open_valves.isSet(room.idx)) {
            var new_flowrate: usize = flowrate + room.rate;
            var new_valves = open_valves;
            new_valves.set(room.idx);
            // std.debug.print("[{d}] Stay to open valve {s} for a new flowrate of {d}\n", .{ minute, room.name, new_flowrate });
            stay = try recurse(rooms, cache, new_valves, ridx, new_flowrate, new_score, minute + 1);
        }
    }

    // Option 2: leave the valve closed and go to another room
    var go: usize = 0;
    for (room.tunnels.items) |tun| {
        // std.debug.print("[{d}] Go to room {s}\n", .{ minute, rooms.items[tun].name });
        go = @max(go, try recurse(rooms, cache, open_valves, tun, flowrate, new_score, minute + 1));
    }

    // std.debug.print("[backtrack][{d}] score {d},{d},{d}\n", .{ minute, new_score, stay, go });
    new_score = @max(stay, go);

    try cache.put(stats, new_score);

    return new_score;
}
