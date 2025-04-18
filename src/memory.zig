const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn growCapacity(capacity: usize) usize {
    if (capacity < 8) {
        return 8;
    } else {
        return capacity * 2;
    }
}

