const std = @import("std");

// Convert timer value to seconds (float)
pub fn ns2sec(nanos: u64) f64 {
    return @intToFloat(f64, nanos) / 1.0e9;
}

pub fn Timer() !std.time.Timer {
    return try std.time.Timer.start();
}

fn abs(T: anytype) @TypeOf(T) {
    if (T < 0)
        return -T
    else
        return T;
}

// Simple wrapper around std.io.getStdOut
pub fn stdout(comptime fmt: []const u8, args: anytype) void {
    const out = std.io.getStdOut().writer();
    out.print(fmt, args) catch @panic("stdout failed!");
}

// Classic Set container type, like C++'s std::undordered_set
pub fn Set(comptime keytype: type) type {
    return struct {
        const Self = @This();
        const Key = keytype;
        const MapType = std.AutoHashMap(keytype, void);
        const Size = MapType.Size;
        map: MapType,
        alloc: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) Self {
            return Self{
                .alloc = alloc,
                .map = MapType.init(alloc),
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn count(self: *Self) Size {
            return self.map.count();
        }

        pub fn capacity(self: *Self) Size {
            return self.map.capacity();
        }

        pub fn getOrPut(self: *Self, key: Key) !void {
            try self.map.getOrPut(key, {});
        }

        pub fn put(self: *Self, key: Key) !void {
            try self.map.put(key, {});
        }

        pub fn putNoClobber(self: *Self, key: Key) !void {
            try self.map.putNoClobber(key, {});
        }

        pub fn contains(self: *Self, key: Key) bool {
            return self.map.contains(key);
        }

        pub fn remove(self: *Self, key: Key) bool {
            return self.map.remove(key);
        }

        pub fn iterator(self: *Self) MapType.Iterator {
            return self.map.iterator();
        }

        // Alias for remove
        pub fn pop(self: *Self, key: Key) bool {
            return self.remove(key);
        }
    };
}

test "AutoHashMap set test" {
    var set = Set(u8).init(std.testing.allocator);
    defer set.deinit();

    try set.put(10);
    try set.put(50);
    try set.put(8);

    std.debug.print("count: {d}\n", .{set.count()});
    std.debug.print("capacity: {d}\n", .{set.capacity()});

    try std.testing.expect(set.count() == 3);
    try std.testing.expect(set.capacity() == 8);
    try std.testing.expect(set.contains(8));
    try std.testing.expect(set.contains(10));
    try std.testing.expect(set.contains(1) == false);

    try std.testing.expect(set.pop(10) == true);
    try std.testing.expect(set.pop(10) == false);
    try std.testing.expect(set.count() == 2);
}
