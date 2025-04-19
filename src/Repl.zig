const std = @import("std");

const Allocator = std.mem.Allocator;
const AnyReader = std.io.AnyReader;
const AnyWriter = std.io.AnyWriter;
const ArrayList = std.ArrayListUnmanaged;

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
