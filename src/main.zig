const std = @import("std");
const builtin = @import("builtin");

const VirtualMachine = @import("VirtualMachine.zig");
const Chunk = @import("Chunk.zig");
const Repl = @import("Repl.zig");
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

const LoxError = error {
    UnsupportedNumberOfArgs,
};

pub fn main() !void {

    runLox() catch |err| {
        if (builtin.mode == .Debug) {
            return err;
        } 

        switch (err) { // exit with status code
            LoxError.UnsupportedNumberOfArgs => {
                std.process.exit(2);
            },
            else => {
                std.process.exit(69);
            }
        }

    };
}


fn runLox() !void {

    const gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true},
            .ReleaseSmall, .ReleaseFast => .{ std.heap.smp_allocator, false }
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdOut().reader();
    const stderr = std.io.getStdOut().writer();

    switch (args.len) {
        1 => {
            try Repl.run(gpa, stdout.any(), stdin.any(), stderr.any());
        }, 
        2 => {
            // TODO: read file 
            return;
        },
        else => {
            try stderr.print("Usage: zlox [path]\n", .{});
            return LoxError.UnsupportedNumberOfArgs;
        }
    }

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
