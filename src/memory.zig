const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn growCapacity(capacity: usize) usize {
    if (capacity < 8) {
        return 8;
    } else {
        return capacity * 2;
    }
}


pub fn growSlice(T: type, allocator: Allocator, slice: *[]T) !void {

    // const new_len = memory.growCapacity(chunk.items.len);
    //
    // const Slice = @typeInfo(@TypeOf(slice)).pointer;
    // const T = Slice.child;
    const new_len = growCapacity(slice.len);

    if (allocator.resize(slice.*, new_len)) {
        // log.debug("resize succeded", .{});
        slice.len = new_len;
    } else {
        // log.debug("resize failed, reallocating", .{});
        slice.* = try allocator.realloc(slice.*, new_len);
    }
}
