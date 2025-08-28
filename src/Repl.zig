const std = @import("std");

const Allocator = std.mem.Allocator;
const Reader = std.Io.Reader;
const Writer = std.Io.Writer;
const assert = std.debug.assert;

const ArrayList = std.ArrayListUnmanaged;

const Scanner = @import("Scanner.zig");

pub fn run(gpa: Allocator, in: *Reader, out: *Writer, err_out: *Writer) !void {
    _ = gpa;
    _ = err_out;

    var buf: [1024]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    while (true) {
        try out.print("> ", .{});
        try out.flush();

        const n = try in.streamDelimiter(&w, '\n');
        in.toss(1);

        const line = w.buffer[0..n];

        if (std.mem.eql(u8, "exit", line)) return;

        assert(n == w.consume(n));
    }
}

test "exit" {
    const allocator = std.testing.allocator;

    var in_buffer: [300]u8 = undefined;
    var out_buffer: [300]u8 = undefined;
    var err_buffer: [300]u8 = undefined;

    const input = "jeowfjoejoiw\nexit\n";

    @memcpy(in_buffer[0..input.len], input[0..]);

    var stdin = std.Io.Reader.fixed(in_buffer[0..]);
    var stdout = std.io.Writer.fixed(out_buffer[0..]);
    var stderr = std.Io.Writer.fixed(err_buffer[0..]);

    try run(allocator, &stdin, &stdout, &stderr);
}
