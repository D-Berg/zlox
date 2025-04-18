const std = @import("std");
const log = std.log.scoped(.@"Chunk");
const memory = @import("memory.zig");
const value = @import("value.zig");

const Value = value.Value;
const ValueArray = value.ValueArray;


const Allocator = std.mem.Allocator;

const Chunk = @This();

count: usize,
items: []u8,
constants: ValueArray,
lines: []usize,

pub const OpCode = enum(u8) {
    @"return",
    constant,
    negate,
};


pub const init = Chunk {
    .count = 0,
    .items = &[_]u8{},
    .constants = ValueArray.init,
    .lines = &[_]usize{},
};

pub fn deinit(chunk: *Chunk, allocator: Allocator) void {
    allocator.free(chunk.items);
    chunk.items = &[_]u8{};
    chunk.count = 0;

    chunk.constants.deinit(allocator);

    allocator.free(chunk.lines);
}

pub fn writeOp(chunk: *Chunk, allocator: Allocator, op: OpCode, line: usize) !void {
    try chunk.writeByte(allocator, @intFromEnum(op), line);
}

pub fn writeByte(chunk: *Chunk, allocator: Allocator, byte: u8, line: usize) !void {

    if (chunk.items.len < chunk.count + 1) {
        try memory.growSlice(u8, allocator, &chunk.items);
        try memory.growSlice(usize, allocator, &chunk.lines);
    }

    chunk.items[chunk.count] = byte;
    chunk.lines[chunk.count] = line;
    chunk.count += 1;

}

pub fn addConstant(chunk: *Chunk, allocator: Allocator, val: Value) !usize {

    try chunk.constants.append(allocator, val);
    return chunk.constants.count - 1;


}

pub fn code(chunk: *const Chunk) []const u8 {
    return chunk.items[0..chunk.count];
}

/// used for debugging
pub fn disassemble(chunk: *const Chunk, name: []const u8) void {
    std.debug.print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.count) {
        offset = chunk.disassembleInstruction(offset);
    }

}

pub fn disassembleInstruction(chunk: *const Chunk, offset: usize) usize {
    std.debug.print("{d:04} ", .{offset});


    if (offset > 0 and chunk.lines[offset] == chunk.lines[offset - 1]) {
        std.debug.print("   | ", .{});
    } else {
        std.debug.print("{d:4} ", .{chunk.lines[offset]});
    }

    const instruction = chunk.items[offset];
    const op = std.meta.intToEnum(OpCode, instruction) catch {
        std.debug.print("Unknown opcode {x}\n", .{instruction});
        return offset + 1;
    };

    switch (op) {
        .constant => |c| {
            const constant = chunk.items[offset + 1];
            const name = @tagName(c);
            const val = chunk.constants.items[@intCast(constant)];
            std.debug.print("op_{s:<16}{d:<4}'{d}'\n", .{name, constant, val});
            return offset + 2;

        },
        inline else => |val| {
            std.debug.print("op_{s}\n", .{@tagName(val)});
            return offset + 1;
        }
    }

}

test "write" {
    // std.testing.log_level = .debug;

    const allocator = std.testing.allocator;

    var chunk: Chunk = .init;

    try chunk.writeByte(allocator, 'h', 1);
    try chunk.writeByte(allocator, 'e', 1);
    try chunk.writeByte(allocator, 'l', 1);
    try chunk.writeByte(allocator, 'l', 1);
    try chunk.writeByte(allocator, 'o', 1);

    try std.testing.expectEqualSlices(u8, "hello", chunk.code());

    chunk.deinit(allocator);

    try std.testing.expectEqual(0, chunk.items.len);
    try std.testing.expectEqualSlices(u8, "", chunk.code());
}

test "write return" {

    const allocator = std.testing.allocator;

    var chunk: Chunk = .init;
    defer chunk.deinit(allocator);

    try chunk.writeByte(allocator, @intFromEnum(OpCode.@"return"), 1);

    // chunk.disassemble("test chunk");

}


test "constants" {

    const allocator = std.testing.allocator;

    var chunk: Chunk = .init;
    defer chunk.deinit(allocator);

    const constant = try chunk.addConstant(allocator, 1.2);

    try chunk.writeOp(allocator, .constant, 1);
    try chunk.writeByte(allocator, @intCast(constant), 1);
    try chunk.writeOp(allocator, .@"return", 1);

    // chunk.disassemble("test chunk");

}
