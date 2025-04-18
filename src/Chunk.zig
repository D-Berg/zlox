const std = @import("std");
const log = std.log.scoped(.@"Chunk");
const memory = @import("memory.zig");


const Allocator = std.mem.Allocator;

const Chunk = @This();

code: []u8,
count: usize,

const OpCode = enum(u8) {
    @"return",
};


pub const init = Chunk {
    .count = 0,
    .code = &[_]u8{}
};

pub fn deinit(chunk: *Chunk, allocator: Allocator) void {
    allocator.free(chunk.code);
    chunk.code = &[_]u8{};
    chunk.count = 0;
}

pub fn writeByte(chunk: *Chunk, allocator: Allocator, byte: u8) !void {

    if (chunk.code.len < chunk.count + 1) {

        const new_len = memory.growCapacity(chunk.code.len);

        if (allocator.resize(chunk.code, new_len)) {
            log.debug("resize succeded", .{});
            chunk.code.len = new_len;
        } else {
            log.debug("resize failed, reallocating", .{});
            chunk.code = try allocator.realloc(chunk.code, new_len);
        }
    }

    chunk.code[chunk.count] = byte;
    chunk.count += 1;

}

pub fn getCode(chunk: *const Chunk) []const u8 {
    return chunk.code[0..chunk.count];
}

/// used for debugging
pub fn disassemble(chunk: *const Chunk, name: []const u8) void {
    std.debug.print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.count) {
        offset = chunk.disassembleInstruction(offset);
    }

}

fn disassembleInstruction(chunk: *const Chunk, offset: usize) usize {
    std.debug.print("{d:04} ", .{offset});

    const instruction = chunk.code[offset];
    const op = std.meta.intToEnum(OpCode, instruction) catch {
        std.debug.print("Unknown opcode {x}\n", .{instruction});
        return offset + 1;
    };
    switch (op) {
        inline else => |val| {
            std.debug.print("op_{s}\n", .{@tagName(val)});
        }
    }

    return offset + 1;
}

test "writeByte" {
    // std.testing.log_level = .debug;

    const allocator = std.testing.allocator;

    var chunk: Chunk = .init;

    try chunk.writeByte(allocator, 'h');
    try chunk.writeByte(allocator, 'e');
    try chunk.writeByte(allocator, 'l');
    try chunk.writeByte(allocator, 'l');
    try chunk.writeByte(allocator, 'o');

    try std.testing.expectEqualSlices(u8, "hello", chunk.getCode());

    chunk.deinit(allocator);

    try std.testing.expectEqual(0, chunk.code.len);
    try std.testing.expectEqualSlices(u8, "", chunk.getCode());
}

test "write return" {

    const allocator = std.testing.allocator;

    var chunk: Chunk = .init;
    defer chunk.deinit(allocator);

    try chunk.writeByte(allocator, @intFromEnum(OpCode.@"return"));

    chunk.disassemble("test chunk");

}
