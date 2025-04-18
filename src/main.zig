const std = @import("std");
const builtin = @import("builtin");
const lib = @import("zlox");

const VirtualMachine = @import("VirtualMachine.zig");
const Chunk = @import("Chunk.zig");
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {

    const gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true},
            .ReleaseSmall, .ReleaseFast => .{ std.heap.smp_allocator, false }
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    var chunk: Chunk = .init;
    defer chunk.deinit(gpa);

    const constant = try chunk.addConstant(gpa, 1.2);

    try chunk.writeOp(gpa, .constant, 1);
    try chunk.writeByte(gpa, @intCast(constant), 1);
    try chunk.writeOp(gpa, .@"return", 1);

    var vm: VirtualMachine = .init(&chunk);
    // defer vm.deinit(gpa);

    const result = try vm.interpret();

    std.debug.print("vm: {}\n", .{result});

}


test "all" {
    std.testing.refAllDeclsRecursive(@This());
}

// test "fuzz example" {
//     const Context = struct {
//         fn testOne(context: @This(), input: []const u8) anyerror!void {
//             _ = context;
//             // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
//             try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
//         }
//     };
//     try std.testing.fuzz(Context{}, Context.testOne, .{});
// }
//
//
