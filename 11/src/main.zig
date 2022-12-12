const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;

const test_input = Data.test_input;
const part1_input = Data.part1_input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var res1 = try part1(part1_input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});

    var res2 = try part2(part1_input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
}

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    try std.testing.expect(res == 10605);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    try std.testing.expect(res == 2713310158);
}

pub fn part1(data: []const u8, alloc: Allocator) !u64 {
    var monkey_defs = std.mem.split(u8, data, "\n\n");

    var monkeys = ArrayList(Monkey).init(alloc);
    defer monkeys.deinit();

    var lcm: u64 = 1;
    while (monkey_defs.next()) |m| {
        var lines = std.mem.split(u8, m, "\n");

        // Get the different lines; we'll parse them later
        _ = lines.next() orelse break;
        var items_line = lines.next() orelse break;
        var op_line = lines.next() orelse break;
        var test_line = lines.next() orelse break;
        var if_true = lines.next() orelse break;
        var if_false = lines.next() orelse break;

        // Parse the items
        var item_list = std.mem.tokenize(u8, items_line[18..], ": ,");
        var items = ArrayList(u64).init(alloc);
        while (item_list.next()) |item| {
            try items.append(try std.fmt.parseInt(u64, item, 10));
        }

        // Parse the operation (new = old ...)
        // if we can't parse an integer, it's becuase it's the string "old"
        var op_string = op_line[23..];
        var op: *const OpFunc = undefined;
        var operand: ?u64 = null;

        operand = std.fmt.parseInt(u64, op_string[2..], 10) catch null;
        switch (op_string[0]) {
            '*' => {
                op = mul;
            },
            '+' => {
                op = add;
            },
            else => {},
        }

        // Parse the test (just need the divisor)
        var divisor: u64 = try std.fmt.parseInt(u64, test_line[21..], 10);
        lcm *= divisor;

        // Parse the monkey IDs
        var true_idx = try std.fmt.parseInt(u64, if_true[29..], 10);
        var false_idx = try std.fmt.parseInt(u64, if_false[30..], 10);

        var monkey = Monkey{
            .items = items,
            .monkeys = &monkeys,
            .op = op,
            .operand = operand,
            .divisor = divisor,
            .true_idx = true_idx,
            .false_idx = false_idx,
        };
        try monkeys.append(monkey);
    }

    // Update our least common multiples
    for (monkeys.items) |*m| {
        m.lcm = lcm;
    }

    // Run for 20 rounds
    var i: u64 = 0;
    while (i < 20) : (i += 1) {
        for (monkeys.items) |*m| {
            m.inspect();
        }
    }

    std.sort.sort(Monkey, monkeys.items, {}, compareMonkeys);

    var val1 = monkeys.items[0].inspect_count;
    var val2 = monkeys.items[1].inspect_count;
    var res = val1 * val2;
    std.debug.print("val1: {d}, val2: {d}\n", .{ val1, val2 });
    std.debug.print("result: {d}\n", .{res});

    for (monkeys.items) |m| {
        m.items.deinit();
    }

    return res;
}

pub fn part2(data: []const u8, alloc: Allocator) !u64 {
    var monkey_defs = std.mem.split(u8, data, "\n\n");

    var monkeys = ArrayList(Monkey).init(alloc);
    defer monkeys.deinit();

    var lcm: u64 = 1;
    while (monkey_defs.next()) |m| {
        var lines = std.mem.split(u8, m, "\n");

        // Get the different lines; we'll parse them later
        _ = lines.next() orelse break;
        var items_line = lines.next() orelse break;
        var op_line = lines.next() orelse break;
        var test_line = lines.next() orelse break;
        var if_true = lines.next() orelse break;
        var if_false = lines.next() orelse break;

        // Parse the items
        var item_list = std.mem.tokenize(u8, items_line[18..], ": ,");
        var items = ArrayList(u64).init(alloc);
        while (item_list.next()) |item| {
            try items.append(try std.fmt.parseInt(u64, item, 10));
        }

        // Parse the operation (new = old ...)
        // if we can't parse an integer, it's becuase it's the string "old"
        var op_string = op_line[23..];
        var op: *const OpFunc = undefined;
        var operand: ?u64 = null;

        operand = std.fmt.parseInt(u64, op_string[2..], 10) catch null;
        switch (op_string[0]) {
            '*' => {
                op = mul;
            },
            '+' => {
                op = add;
            },
            else => {},
        }

        // Parse the test (just need the divisor)
        var divisor: u64 = try std.fmt.parseInt(u64, test_line[21..], 10);
        lcm *= divisor;

        // Parse the monkey IDs
        var true_idx = try std.fmt.parseInt(u64, if_true[29..], 10);
        var false_idx = try std.fmt.parseInt(u64, if_false[30..], 10);

        var monkey = Monkey{
            .items = items,
            .monkeys = &monkeys,
            .op = op,
            .operand = operand,
            .divisor = divisor,
            .true_idx = true_idx,
            .false_idx = false_idx,
            .p1d = 1,
        };
        try monkeys.append(monkey);
    }

    // Update our least common multiples
    for (monkeys.items) |*m| {
        m.lcm = lcm;
    }

    // Run for N rounds
    var i: u64 = 0;
    while (i < 10000) : (i += 1) {
        for (monkeys.items) |*m| {
            m.inspect();
        }
    }

    std.sort.sort(Monkey, monkeys.items, {}, compareMonkeys);

    var val1 = monkeys.items[0].inspect_count;
    var val2 = monkeys.items[1].inspect_count;
    var res = val1 * val2;
    std.debug.print("val1: {d}, val2: {d}\n", .{ val1, val2 });
    std.debug.print("result: {d}\n", .{res});

    for (monkeys.items) |m| {
        m.items.deinit();
    }

    return res;
}

// Item operation functions
pub const OpFunc: type = fn (u64, ?u64) u64;

pub fn mul(old: u64, x: ?u64) u64 {
    if (x == null) return old * old;
    return old * x.?;
}

pub fn add(old: u64, x: ?u64) u64 {
    if (x == null) return old + old;
    return old + x.?;
}

pub const Monkey = struct {
    items: ArrayList(u64) = undefined,
    monkeys: *ArrayList(Monkey) = undefined,
    op: *const OpFunc = undefined,
    operand: ?u64 = null,
    divisor: u64 = undefined,
    true_idx: u64 = undefined,
    false_idx: u64 = undefined,
    inspect_count: u64 = 0,
    p1d: u64 = 3, // 3 for Part 1, 1 for Part 2
    lcm: u64 = 1,

    pub fn catchItem(self: *Monkey, item: u64) void {
        self.items.append(item) catch return;
    }

    pub fn inspect(self: *Monkey) void {
        for (self.items.items) |item| {
            var val = self.op(item, self.operand) / self.p1d;
            val = std.math.mod(u64, val, self.lcm) catch return;
            if (self.testItem(val, self.divisor)) {
                self.monkeys.items[self.true_idx].catchItem(val);
            } else {
                self.monkeys.items[self.false_idx].catchItem(val);
            }

            self.inspect_count += 1;
        }
        self.items.clearRetainingCapacity();
    }

    pub fn testItem(_: Monkey, item: u64, divisor: u64) bool {
        if (item % divisor == 0) return true;
        return false;
    }

    pub fn print_items(self: Monkey) void {
        std.debug.print("  items: ", .{});
        for (self.items.items) |item| {
            std.debug.print("{d}, ", .{item});
        }
        std.debug.print("\n", .{});
    }
};

fn compareMonkeys(_: void, a: Monkey, b: Monkey) bool {
    return a.inspect_count > b.inspect_count;
}
