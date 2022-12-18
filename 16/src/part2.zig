const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const StringArrayMap = std.StringArrayHashMap;
const GPA = std.heap.GeneralPurposeAllocator;

const test_input = Data.test_input;
const input = Data.input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res2 = try part2(input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

// ------------ Part 2 Solution ------------

pub fn part2(data: []const u8, alloc: Allocator) !usize {
    var rooms = StringHashMap(Room).init(alloc);
    defer rooms.deinit();

    var n2i = StringHashMap(usize).init(alloc);
    defer n2i.deinit();

    var rarr = ArrayList(Room).init(alloc);
    defer rarr.deinit();

    // Parse input
    var lines = std.mem.split(u8, data, "\n");
    var idx: usize = 0;
    while (lines.next()) |line| {
        if (line.len < 10) continue;
        const name = line[6..8];
        const ic = std.mem.indexOfScalar(u8, line, ';').?;
        const rate = try std.fmt.parseInt(usize, line[23..ic], 10);
        if (rate > 0 or std.mem.eql(u8, name, "AA")) {
            try n2i.put(name, idx);
            try rarr.append(Room{});
            idx += 1;
        }

        try rooms.put(name, Room{});
        var room = rooms.getEntry(name).?.value_ptr;
        room.init(name, 255, rate, alloc);

        var tunnels = std.mem.tokenize(u8, line[ic + 24 ..], "valves ,");
        while (tunnels.next()) |tun| {
            try room.tunnel_set.append(tun);
        }
    }

    // Merge tunnels/rooms with 0 flowrate
    var room_iter = rooms.valueIterator();
    while (room_iter.next()) |room| {
        if (room.rate == 0 and !std.mem.eql(u8, room.name, "AA"))
            continue;

        const ridx = n2i.get(room.name).?;
        var rnew: *Room = &rarr.items[ridx];
        rnew.init(room.name, ridx, room.rate, alloc);

        const RD = struct {
            r: []const u8 = undefined,
            d: usize = 0,
        };

        var queue = ArrayList(RD).init(alloc);
        var visited = StringHashMap(void).init(alloc);
        defer queue.deinit();
        defer visited.deinit();

        try visited.put(room.name, {});
        try queue.insert(0, RD{ .r = room.name, .d = 0 });
        while (queue.items.len > 0) {
            const kv = queue.pop();
            const d = kv.d;
            var r2 = rooms.get(kv.r).?;
            for (r2.tunnel_set.items) |tun| {
                if (visited.contains(tun)) continue;
                try visited.put(tun, {});
                if (rooms.get(tun).?.rate > 0) {
                    try rnew.dists.put(n2i.get(tun).?, d + 1);
                }
                try queue.insert(0, RD{ .r = tun, .d = d + 1 });
            }
        }
    }

    // Print the connectiviry graph
    // var niter = n2i.iterator();
    // while (niter.next()) |ni| {
    //     std.debug.print("{s} -> {d}\n", .{ ni.key_ptr.*, ni.value_ptr.* });
    // }

    // for (rarr.items) |room| {
    //     std.debug.print("Room {s} ({d}):\n", .{ room.name, room.idx });
    //     var rditer = room.dists.iterator();
    //     while (rditer.next()) |rd| {
    //         std.debug.print("  {d} units to room {d}\n", .{ rd.value_ptr.*, rd.key_ptr.* });
    //     }
    // }

    var score: usize = try traverseRooms(rarr, alloc, n2i.get("AA").?);

    // Cleanup
    var riter = rooms.valueIterator();
    while (riter.next()) |room| {
        room.deinit();
    }

    for (rarr.items) |*room| room.deinit();

    return score;
}

// ------------ Common Functions ------------

pub const Room = struct {
    name: []const u8 = undefined,
    idx: usize = 0,
    rate: usize = 0,
    tunnel_set: ArrayList([]const u8) = undefined,
    dists: AutoHashMap(usize, usize) = undefined,
    alloc: Allocator = undefined,

    pub fn init(self: *Room, name: []const u8, idx: usize, rate: usize, alloc: Allocator) void {
        self.name = name;
        self.idx = idx;
        self.rate = rate;
        self.tunnel_set = ArrayList([]const u8).init(alloc);
        self.dists = AutoHashMap(usize, usize).init(alloc);
        self.alloc = alloc;
    }

    pub fn deinit(self: *Room) void {
        self.tunnel_set.deinit();
        self.dists.deinit();
    }
};

fn traverseRooms(rooms: ArrayList(Room), alloc: Allocator, start: usize) !usize {
    var cache = Cache.init(alloc);
    defer cache.deinit();

    var score: usize = 0;

    // Try every possible combination of splitting valves betwen the elf and the elephant
    const n: u6 = @intCast(u6, rooms.items.len);
    const N: usize = @intCast(usize, @intCast(u64, 1) << n) - 1;

    // The elf and elephant are interchangeable, so total combinations are N/2
    const ncombo = try std.math.divCeil(usize, N, 2);
    var i: usize = 0;
    while (i < ncombo) : (i += 1) {
        var elf_valves: u64 = i;
        var elephant_valves: u64 = N ^ i;

        var stats1 = Stats{ .room = start, .open_valves = elf_valves, .remtime = 26 };
        const score1 = try dfs(rooms, &cache, stats1);

        var stats2 = Stats{ .room = start, .open_valves = elephant_valves, .remtime = 26 };
        const score2 = try dfs(rooms, &cache, stats2);

        score = @max(score, score1 + score2);
    }
    return score;
}

const Stats = struct {
    remtime: i32 = 0,
    room: usize = 0,
    open_valves: u64 = 0,
};
const Cache = AutoHashMap(Stats, usize);

fn dfs(rooms: ArrayList(Room), cache: *Cache, stats: Stats) !usize {
    const remtime = stats.remtime;
    if (remtime < 0) return 0;

    if (cache.contains(stats))
        return cache.get(stats).?;

    // Try visiting and opening each reachable valve with nonzero flowrate
    var total: usize = 0;
    var iter = rooms.items[stats.room].dists.iterator();
    while (iter.next()) |rd| {
        const r = rd.key_ptr.*;
        const d = rd.value_ptr.*;

        // Check if the valve is already open
        if (isBitSet(stats.open_valves, r)) continue;

        // Check remaining time
        const rtime: i32 = remtime - @intCast(i32, d + 1);
        if (rtime <= 0) continue;

        // Total flow from opening this valve over the remaining time
        const vtot = rooms.items[r].rate * @intCast(usize, rtime);

        // Open this valve and update our stats struct
        var new_stats = Stats{ .room = r, .remtime = rtime };
        new_stats.open_valves = stats.open_valves;
        new_stats.open_valves |= (@intCast(u64, 1) << @intCast(u6, r));

        const tot_next = try dfs(rooms, cache, new_stats);
        total = @max(total, tot_next + vtot);
    }

    // Put the results of this search into our cache
    try cache.put(stats, total);

    return total;
}

fn isBitSet(mask: usize, index: u64) bool {
    return (mask & (@intCast(u64, 1) << @intCast(u6, index)) > 0);
}
