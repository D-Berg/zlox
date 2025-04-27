const std = @import("std");
const log = std.log.scoped(.@"Scanner");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const Scanner = @This();

start: usize,
current: usize,
line: usize,
source: []const u8,

pub const Token = struct {
    kind: Kind,
    literal: []const u8,
    line: usize,

    pub const Kind = enum {
        // single char
        left_paren, right_paren,
        left_brace, right_brace,
        comma,
        dot,
        minus,
        plus,
        semicolon,
        slash,
        star,

        // One or two character tokens.
        bang,
        bang_equal,
        equal,
        equal_equal,
        greater,
        greater_equal,
        less,
        less_equal,
        
        // Literals
        identifier,
        string,
        number,
        

        // keywords
        @"and",
        class,
        @"else",
        @"false",
        @"for",
        fun,
        @"if",
        nil,
        @"or",
        print,
        @"return",
        super,
        this,
        @"true",
        @"var",
        @"while",

        @"error",
    };
};


pub fn init(source: []const u8) Scanner {
    log.debug("source_len = {}", .{source.len});
    return .{
        .start = 0,
        .current = 0,
        .line = 1,
        .source = source
    };
}

pub fn next(scanner: *Scanner) ?Token {

    log.debug("scanning...", .{});

    log.debug("skipping whitespace...", .{});
    scanner.skipWhitespace();
    log.debug("finished skipping whitespace", .{});

    scanner.start = scanner.current;

    if (scanner.isAtEnd()) return null;

    const c = scanner.advance();
    log.debug("current char = '{c}', {}", .{c, c});

    switch (c) {
        '(' => return scanner.makeToken(.left_paren),
        ')' => return scanner.makeToken(.right_paren),
        '{' => return scanner.makeToken(.left_brace),
        '}' => return scanner.makeToken(.right_brace),
        ';' => return scanner.makeToken(.semicolon),
        ',' => return scanner.makeToken(.comma),
        '+' => return scanner.makeToken(.plus),
        '-' => return scanner.makeToken(.minus),
        '*' => return scanner.makeToken(.star),
        '/' => {
            if (scanner.match('/')) { // skip over comment
                while (scanner.peek() != '\n' and !scanner.isAtEnd()) {
                    _ = scanner.advance();
                }
                return scanner.next();
            }
            return scanner.makeToken(.slash);
        },
        '.' => return scanner.makeToken(.dot),
        '!' => {
            if (scanner.match('=')) return scanner.makeToken(.bang_equal);
            return scanner.makeToken(.bang);
        },
        '=' => {
            if (scanner.match('=')) return scanner.makeToken(.equal_equal);
            return scanner.makeToken(.equal);
        },
        '<' => {
            if (scanner.match('=')) return scanner.makeToken(.less_equal);
            return scanner.makeToken(.less);
        },
        '>' => {
            if (scanner.match('=')) return scanner.makeToken(.greater_equal);
            return scanner.makeToken(.greater);
        },
        '"' => return scanner.makeTokenString(),
        0 => return null,
        else => |char| {
            if (isDigit(char)) return scanner.makeNumberToken();
            if (isAlpha(char)) return scanner.makeIdentifeirOrKeyWordToken();

            log.debug("unrecognized char '{c}'", .{c});
            return null;
        }
    }
}

fn makeToken(scanner: *const Scanner, kind: Token.Kind) Token {
    return Token {
        .kind = kind,
        .line = scanner.line,
        .literal = scanner.source[scanner.start..scanner.current],
    };
}

fn advance(scanner: *Scanner) u8 {
    const c = scanner.peek();
    log.debug("c = '{c}', idx = {}", .{c, scanner.current});
    scanner.current += 1;
    return c;
}

fn isAtEnd(scanner: *const Scanner) bool {
    if (scanner.current >= scanner.source.len) {
        log.debug("reached end, current = {}", .{scanner.current});
        return true;
    } else {
        return false;
    }
}

fn match(scanner: *Scanner, expected: u8) bool {
    if (scanner.isAtEnd()) return false;
    if (scanner.peek() != expected) return false;
    scanner.current += 1;
    return true;
}

fn peek(scanner: *const Scanner) u8 {
    if (scanner.current < scanner.source.len) {
        return scanner.source[scanner.current];
    }
    return 0;
}

fn peekNext(scanner: *const Scanner) u8 {
    if (scanner.isAtEnd()) return 0;
    return scanner.source[scanner.current + 1];
}

fn skipWhitespace(scanner: *Scanner) void {

    if (scanner.isAtEnd()) return;

    sw: switch (scanner.peek()) {
        '\r', '\t', ' ' => {
            _ = scanner.advance();
            continue :sw scanner.peek();
        },
        '\n' => {
            _ = scanner.advance();
            scanner.line += 1;
            continue :sw scanner.peek();
        },
        else => break :sw,
    }
}

fn makeTokenString(scanner: *Scanner) Token {

    scanner.start = scanner.current;

    while (scanner.peek() != '"' and !scanner.isAtEnd()) {
        if (scanner.peek() == '\n') scanner.line += 1;
        _ = scanner.advance();
    }

    if (scanner.isAtEnd()) return scanner.makeErrorToken("Unterminated string");

    const string_token = scanner.makeToken(.string);

    _ = scanner.advance();

    return string_token;

}

fn makeErrorToken(scanner: *Scanner, message: []const u8) Token {

    return Token {
        .line = scanner.line,
        .kind = .@"error",
        .literal = message,
    };

}

fn makeNumberToken(scanner: *Scanner) Token {

    while (isDigit(scanner.peek())) _ = scanner.advance();

    if (scanner.peek() == '.' and isDigit(scanner.peekNext())) {
        _ = scanner.advance();

        while (isDigit(scanner.peek())) _ = scanner.advance();
    }

    return scanner.makeToken(.number);

}

fn makeIdentifeirOrKeyWordToken(scanner: *Scanner) Token {
    while (isAlpha(scanner.peek()) or isDigit(scanner.peek())) {
        _ = scanner.advance();
    }
    if (scanner.makeKeyWordToken()) |keyword| return keyword;
    return scanner.makeToken(.identifier);
}

fn makeKeyWordToken(scanner: *Scanner) ?Token {

    const str = scanner.source[scanner.start..scanner.current];

    if (std.meta.stringToEnum(Token.Kind, str)) |kind| {
        switch (kind) {
            .@"and", .class, .@"else", .@"false",
            .@"for", .fun, .@"if", .nil, .@"or",
            .print, .@"return", .super, .this, .@"true",
            .@"var", .@"while" => return scanner.makeToken(kind),
            else =>  return null,
        }
    } 

    return null;
}

fn isDigit(char: u8) bool {
    return char >= '0' and char <= '9';
}

fn isAlpha(char: u8) bool {
    return (char >= 'A' and char <= 'Z') or 
        (char >= 'a' and char <= 'z') or
        char == '_';
}

test "scanner" {

    // std.testing.log_level = .w;

    const input =
        \\( ) { } ;
        \\, . - + / *
        \\"Hello, world!";
        \\1234; // An integer.
        \\12.34; // A decimal number.
        \\add + me;
        \\if
        \\
        \\
        \\""; // The empty string.
        // \\subtract - me;
        // \\multiply * me;
        // \\divide / me;
        // \\-negateMe;
        // \\
        // \\less < than;
        // \\lessThan <= orEqual;
        // \\greater > than;
        // \\greaterThan >= orEqual;
        // \\
        // \\1 == 2; // false.
        // \\"cat" != "dog"; // true.
        // \\314 == "pi"; // false.
        // \\123 == "123"; // false.
        // \\!true; // false.
        // \\!false; // true.
    ;

    const answers = [_]Token {
        Token { .kind = .left_paren, .literal = "(", .line = 1 },
        Token { .kind = .right_paren, .literal = ")", .line = 1 },
        Token { .kind = .left_brace, .literal = "{", .line = 1 },
        Token { .kind = .right_brace, .literal = "}", .line = 1 },
        Token { .kind = .semicolon, .literal = ";", .line = 1 },
        Token { .kind = .comma, .literal = ",", .line = 2 },
        Token { .kind = .dot, .literal = ".", .line = 2 },
        Token { .kind = .minus, .literal = "-", .line = 2 },
        Token { .kind = .plus, .literal = "+", .line = 2 },
        Token { .kind = .slash, .literal = "/", .line = 2 },
        Token { .kind = .star, .literal = "*", .line = 2 },
        Token { .kind = .string, .literal = "Hello, world!", .line = 3 },
        Token { .kind = .semicolon, .literal = ";", .line = 3 },
        Token { .kind = .number, .literal = "1234", .line = 4 },
        Token { .kind = .semicolon, .literal = ";", .line = 4 },
        Token { .kind = .number, .literal = "12.34", .line = 5 },
        Token { .kind = .semicolon, .literal = ";", .line = 5 },
        Token { .kind = .identifier, .literal = "add", .line = 6 },
        Token { .kind = .plus, .literal = "+", .line = 6 },
        Token { .kind = .identifier, .literal = "me", .line = 6 },
        Token { .kind = .semicolon, .literal = ";", .line = 6 },
        Token { .kind = .@"if", .literal = "if", .line = 7 },
        Token { .kind = .string, .literal = "", .line = 10 },
        Token { .kind = .semicolon, .literal = ";", .line = 10 },


    };


    var scanner: Scanner = .init(input[0..]);

    var i: usize = 0;

    while (scanner.next()) |token| : (i += 1) {
        log.debug("token = {}\n", .{token});
        const expected_token = answers[i];

        try expectEqual(expected_token.kind, token.kind);
        try expectEqualSlices(u8, expected_token.literal, token.literal);
        try expectEqual(expected_token.line, token.line);
    }

    try expectEqual(answers.len, i);

}


