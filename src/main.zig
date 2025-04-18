const std = @import("std");
const lib = @import("zlox");

const Chunk = @import("Chunk.zig");

pub fn main() !void {

    const chunk: Chunk = .init;
    _ = chunk;

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
