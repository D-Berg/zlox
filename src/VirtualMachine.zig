const std = @import("std");
const builtin = @import("builtin");

const Chunk = @import("Chunk.zig");
const value = @import("value.zig");
const Value = value.Value;
const VirtualMachine = @This();

const log = std.log.scoped(.@"VM");

const Allocator = std.mem.Allocator;
const OpCode = Chunk.OpCode;

const STACK_MAX = 256;

chunk: *Chunk,
ip: [*]u8,
stack: [STACK_MAX]Value,
top: [*]Value = undefined,

const InterpreterResult = enum {
    ok,
    compile_error,
    runtime_error,
};

pub fn init(chunk: *Chunk) VirtualMachine {
    log.debug("initializing vm", .{});
    var vm =  VirtualMachine {
        .chunk = chunk,
        .ip = chunk.items.ptr,
        .stack = [1]Value{ 0.0 } ** STACK_MAX,
    };

    vm.resetStack();

    return vm;
}

// pub fn deinit(vm: *VirtualMachine, allocator: Allocator) void {
//     log.debug("deinit vm", .{});
//     vm.chunk.deinit(allocator);
// }

pub fn interpret(vm: *VirtualMachine) InterpreterResult {
    log.debug("interpreting...", .{});
    vm.resetStack();
    return vm.run();
}

inline fn resetStack(vm: *VirtualMachine) void {
    vm.top = vm.stack[0..1].ptr;
    log.debug("top_start = {*}", .{vm.top});
}

fn run(vm: *VirtualMachine) InterpreterResult {

    log.debug("running...", .{});


    while (true) {

        if (builtin.mode == .Debug) {
            std.debug.print("stack: ", .{});
            const stack_start = vm.stack[0..1].ptr;

            log.debug("top = {*}, stack_start: {*}", .{vm.top, stack_start});
            
            const stack_len = vm.top - stack_start;
            log.debug("stack_len = {}", .{stack_len});

            for (vm.stack[0..stack_len]) |val| {
                std.debug.print("[ {d} ]", .{val});
            }

            std.debug.print("\n", .{});

            const offset: usize = vm.ip - vm.chunk.items.ptr;
            _ = vm.chunk.disassembleInstruction(offset);
        }

        log.debug("reading instruction", .{});
        const instruction = vm.readByte();
        switch (instruction) {

            @intFromEnum(OpCode.@"return") => {
                std.debug.print("{d}\n", .{vm.pop()});
                return InterpreterResult.ok;
            },

            @intFromEnum(OpCode.constant) => {
                const constant: Value = vm.readConstant();
                vm.push(constant);
                // std.debug.print("{}", .{constant});
            },

            else => {
                return InterpreterResult.compile_error;
            }


        }
    }
}

// TODO: err when top is outside of range
fn push(vm: *VirtualMachine, v: Value) void {
    vm.top[0] = v;
    log.debug("top = {*}", .{vm.top});
    vm.top += 1;
    log.debug("top = {*}", .{vm.top});
}

fn pop(vm: *VirtualMachine) Value {
    vm.top -= 1;
    return vm.top[0];
}

pub inline fn readByte(vm: *VirtualMachine) u8 {

    const op = vm.ip[0];
    log.debug("current ip address = {*}", .{vm.ip});
    vm.ip +=  1;
    log.debug("next ip address = {*}", .{vm.ip});
    return op;
}

pub inline fn readConstant(vm: *VirtualMachine) Value {
    
    return vm.chunk.constants.items[@intCast(readByte(vm))];

}

test "VirtualMachine" {
    // std.testing.log_level = .debug;
    const gpa = std.testing.allocator;

    var chunk: Chunk = .init;
    defer chunk.deinit(gpa);

    const constant = try chunk.addConstant(gpa, 1.2);

    try chunk.writeOp(gpa, .constant, 1);
    try chunk.writeByte(gpa, @intCast(constant), 1);
    try chunk.writeOp(gpa, .@"return", 1);

    var vm: VirtualMachine = .init(&chunk);
    // defer vm.deinit(gpa);

    const result = vm.interpret();

    std.debug.print("vm: {}\n", .{result});
}    
