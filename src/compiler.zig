const std = @import("std");
const Scanner = @import("Scanner.zig");
const Chunk = @import("Chunk.zig");

const Token = Scanner.Token;

const Allocator = std.mem.Allocator;
const AnyWriter = std.io.AnyWriter;

const EnumArray = std.EnumArray;


pub const CompileError = error {
    
} || Allocator.Error || AnyWriter.Error;

const Parser = struct {
    current: Token,
    previous: Token,
    panic_mode: bool,
    err: ?CompileError,

    const Rule = struct {
        prefix: ?ParseFn,
        infix: ?ParseFn,
        precedence: Precedence,

        const Precedence = enum {
            none,
            assignment,  // =
            @"or",          // or
            @"and",         // and
            equality,    // == !=
            comparison,  // < > <= >=
            term,        // + -
            factor,      // * /
            unary,       // ! -
            call,        // . ()
            primary
        };
    };

    const ParseFn = *fn () void;

    const rules: EnumArray(Token.Kind, Rule) = .init(.{
        .left_paren = .{ .prefix = null, .infix = null, .precedence = .none },
        .right_paren = .{ .prefix = null, .infix = null, .precedence = .none },
        .left_brace = .{ .prefix = null, .infix = null, .precedence = .none }, 
        .right_brace = .{ .prefix = null, .infix = null, .precedence = .none },
        .comma = .{ .prefix = null, .infix = null, .precedence = .none },
        .dot = .{ .prefix = null, .infix = null, .precedence = .none },
        .minus = .{ .prefix = null, .infix = null, .precedence = .none },
        .plus = .{ .prefix = null, .infix = null, .precedence = .none },
        .semicolon = .{ .prefix = null, .infix = null, .precedence = .none },
        .slash = .{ .prefix = null, .infix = null, .precedence = .none },
        .star = .{ .prefix = null, .infix = null, .precedence = .none },

        // One or two character tokens.
        .bang = .{ .prefix = null, .infix = null, .precedence = .none },
        .bang_equal = .{ .prefix = null, .infix = null, .precedence = .none },
        .equal = .{ .prefix = null, .infix = null, .precedence = .none },
        .equal_equal = .{ .prefix = null, .infix = null, .precedence = .none },
        .greater = .{ .prefix = null, .infix = null, .precedence = .none },
        .greater_equal = .{ .prefix = null, .infix = null, .precedence = .none },
        .less = .{ .prefix = null, .infix = null, .precedence = .none },
        .less_equal = .{ .prefix = null, .infix = null, .precedence = .none },
        // Literals
        .identifier = .{ .prefix = null, .infix = null, .precedence = .none },
        .string = .{ .prefix = null, .infix = null, .precedence = .none },
        .number = .{ .prefix = null, .infix = null, .precedence = .none },

        // keywords
        .@"and" = .{ .prefix = null, .infix = null, .precedence = .none },
        .class = .{ .prefix = null, .infix = null, .precedence = .none },
        .@"else" = .{ .prefix = null, .infix = null, .precedence = .none },
        .@"false" = .{ .prefix = null, .infix = null, .precedence = .none },
        .@"for" = .{ .prefix = null, .infix = null, .precedence = .none },
        .fun = .{ .prefix = null, .infix = null, .precedence = .none },
        .@"if" = .{ .prefix = null, .infix = null, .precedence = .none },
        .nil = .{ .prefix = null, .infix = null, .precedence = .none },
        .@"or" = .{ .prefix = null, .infix = null, .precedence = .none },
        .print = .{ .prefix = null, .infix = null, .precedence = .none },
        .@"return" = .{ .prefix = null, .infix = null, .precedence = .none },
        .super = .{ .prefix = null, .infix = null, .precedence = .none },
        .this = .{ .prefix = null, .infix = null, .precedence = .none },
        .@"true" = .{ .prefix = null, .infix = null, .precedence = .none },
        .@"var" = .{ .prefix = null, .infix = null, .precedence = .none },
        .@"while" = .{ .prefix = null, .infix = null, .precedence = .none },

        .@"error" = .{ .prefix = null, .infix = null, .precedence = .none },
    });

    const init = Parser {
        .current = undefined,
        .previous = undefined,
        .panic_mode = false,
        .err = null,
    };

    fn expression(parser: *Parser) void {
        _ = parser;

    }

    /// Reads the next token. But it also validates that the token 
    /// has an expected kind. If not, it reports an error. 
    fn consume(
        parser: *Parser, 
        scanner: *Scanner, 
        writer: AnyWriter, 
        expected_kind: Token.Kind, 
        message: []const u8
    ) AnyWriter.Error!void {
        if (expected_kind == parser.current.kind) {
            parser.advance(scanner);
            return;
        }
        try parser.errorAtCurrent(writer, message);
    }

    fn advance(parser: *Parser, scanner: *Scanner) void {

        while (scanner.next()) |token| {
            parser.current = token;

            if (parser.current.kind == .@"error") break;
        }

    }

    fn errorAtCurrent(parser: *Parser, writer: AnyWriter, message: []const u8) !void{
        try errorAt(parser, writer, &parser.current, message);
    }

    fn errorAtPrevious(parser: *Parser, writer: AnyWriter, message: []const u8) !void{
        try errorAt(parser, writer, &parser.previous, message);
    }

    fn errorAt(parser: *Parser, writer: AnyWriter, token: *Token, message: []const u8) !void {

        if (parser.panic_mode) return;

        parser.panic_mode = true;
        defer parser.err = CompileError.Unknown;

        try writer.print("[line {}] Error", .{token.line});

        switch (token.kind) {
            .@"error" => {}, // do nothing
            else => {
                try writer.print(" at '{s}'", .{token.literal});
            }
        }

        try writer.print(": {s}\n", .{message});

    }
};

pub fn compile(gpa: Allocator, writer: AnyWriter, source: []const u8, chunk: *Chunk) CompileError!void {

    _ = gpa;
    _ = chunk;

    var scanner: Scanner = .init(source);
    var parser: Parser = .init;

    parser.advance(&scanner);
    parser.expression();

    if (scanner.next() != null) {
        try parser.errorAtCurrent(writer, "Expect end of Expression");
    }

    if (parser.err) |err| return err;

}

test "compile" {
    const allocator = std.testing.allocator;

    var chunk = Chunk.init;
    defer chunk.deinit(allocator);

    const stderr = std.io.getStdErr().writer();

    try compile(allocator, stderr.any(), "hello", &chunk);
}

