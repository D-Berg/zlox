const std = @import("std");

const Allocator = std.mem.Allocator;
const AnyReader = std.io.AnyReader;
const AnyWriter = std.io.AnyWriter;
const ArrayList = std.ArrayListUnmanaged;

const Scanner = @import("Scanner.zig");

pub fn run(gpa: Allocator, writer: AnyWriter, reader: AnyReader, err_writer: AnyWriter) !void {
    _ = err_writer;

    while (true) {

        try writer.print("> ", .{});
    
        var line_list: ArrayList(u8) = .empty;
        errdefer line_list.deinit(gpa);

        const line_writer = line_list.writer(gpa);

        try reader.streamUntilDelimiter(line_writer, '\n', null);

        const line = try line_list.toOwnedSlice(gpa);
        defer gpa.free(line);

        if (std.mem.eql(u8, "exit", line)) return; 

    }

}

test "exit" {
    const allocator = std.testing.allocator;

    var out_buffer: [300]u8 = undefined;
    var in_buffer: [300]u8 = undefined;
    var err_buffer: [300]u8 = undefined;

    var stdout = std.io.fixedBufferStream(out_buffer[0..]);
    var stdin = std.io.fixedBufferStream(in_buffer[0..]);
    var stderr = std.io.fixedBufferStream(err_buffer[0..]);

    _ = try stdin.write("jeowfjoejoiw\nexit\n");

    stdin.reset();

    try run(
        allocator, 
        stdout.writer().any(), 
        stdin.reader().any(), 
        stderr.writer().any()
    );

}

