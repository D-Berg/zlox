const std = @import("std");
const Allocator = std.mem.Allocator;
const memory = @import("memory.zig");

pub const Value = f64;

pub const ValueArray = struct {
    count: usize,
    items: []Value,

    pub const init = ValueArray {
        .count = 0,
        .items = &[_]Value{},
    };

    pub fn deinit(value_array: *ValueArray, allocator: Allocator) void {
        allocator.free(value_array.items);
        value_array.items = &[_]Value{};
        value_array.count = 0;
    }

    pub fn append(array: *ValueArray, allocator: Allocator, value: Value) !void {
        if (array.items.len < array.count + 1) {

            const new_len = memory.growCapacity(array.items.len);

            if (allocator.resize(array.items, new_len)) {
                array.items.len = new_len;
            } else {
                array.items = try allocator.realloc(array.items, new_len);
            }
        }

        array.items[array.count] = value;
        array.count += 1;

    }

};





