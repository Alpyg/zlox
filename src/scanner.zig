const std = @import("std");

pub const Scanner = struct {
    const Self = @This();

    start: []const u8,
    current: []const u8,
    line: usize,

    pub fn init(src: []const u8) Self {
        return Self{
            .start = src,
            .current = src,
            .line = 1,
        };
    }

    pub fn scanToken(self: *Self) Token {
        self.skipWhiteSpace();
        self.start = self.current;
        if (self.isAtEnd()) return self.makeToken(TokenType.eof);

        const c = self.advance();

        const token = switch (c) {
            '(' => self.makeToken(TokenType.@"("),
            ')' => self.makeToken(TokenType.@")"),
            '{' => self.makeToken(TokenType.@"{"),
            '}' => self.makeToken(TokenType.@"}"),
            ';' => self.makeToken(TokenType.@";"),
            ',' => self.makeToken(TokenType.@","),
            '.' => self.makeToken(TokenType.@"."),
            '-' => self.makeToken(TokenType.@"-"),
            '+' => self.makeToken(TokenType.@"+"),
            '/' => self.makeToken(TokenType.@"/"),
            '*' => self.makeToken(TokenType.@"*"),
            '!' => self.makeToken(if (self.match('=')) TokenType.@"!=" else TokenType.@"!"),
            '=' => self.makeToken(if (self.match('=')) TokenType.@"==" else TokenType.@"="),
            '<' => self.makeToken(if (self.match('=')) TokenType.@"<=" else TokenType.@"<"),
            '>' => self.makeToken(if (self.match('=')) TokenType.@">=" else TokenType.@">"),
            '"' => self.string(),
            '0'...'9' => self.number(),
            'a'...'z', 'A'...'Z', '_' => self.identifier(),
            else => self.errorToken("Unexpected character"),
        };

        return token;
    }

    inline fn makeToken(self: *Self, token_type: TokenType) Token {
        return Token{
            .type = token_type,
            .start = self.start.ptr,
            .length = self.current.ptr - self.start.ptr,
            .line = self.line,
        };
    }

    inline fn errorToken(self: *Self, message: []const u8) Token {
        return Token{
            .type = TokenType.@"error",
            .start = message.ptr,
            .length = message.len,
            .line = self.line,
        };
    }

    inline fn advance(self: *Self) u8 {
        defer self.current = self.current[1..];
        return self.current[0];
    }

    inline fn peek(self: *Self) u8 {
        return self.current[0];
    }

    inline fn peekNext(self: *Self) u8 {
        if (self.isAtEnd()) return 0;
        return self.current[1];
    }

    inline fn match(self: *Self, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.current[0] != expected) return false;

        _ = self.advance();
        return true;
    }

    inline fn isAtEnd(self: *Self) bool {
        return self.current[0] == 0;
    }

    inline fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    inline fn isAlpha(c: u8) bool {
        return switch (c) {
            'a'...'z', 'A'...'Z', '_' => true,
            else => false,
        };
    }

    inline fn skipWhiteSpace(self: *Self) void {
        while (true) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => _ = self.advance(),
                '\n' => {
                    _ = self.advance();
                    self.line += 1;
                    return;
                },
                '/' => if (self.peekNext() == '/') {
                    while (self.peek() != '\n' and !self.isAtEnd()) {
                        _ = self.advance();
                    }
                } else return,
                else => return,
            }
        }
    }

    inline fn string(self: *Self) Token {
        while (self.peek() != '"' and !self.isAtEnd()) {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }

        if (self.isAtEnd()) return self.errorToken("Unterminated string");

        _ = self.advance();
        return self.makeToken(TokenType.string);
    }

    inline fn number(self: *Self) Token {
        while (isDigit(self.peek())) _ = self.advance();

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            while (isDigit(self.peek())) _ = self.advance();
        }

        return self.makeToken(TokenType.number);
    }

    inline fn identifier(self: *Self) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) _ = self.advance();

        return self.makeToken(self.identifierType());
    }

    inline fn identifierType(self: *Self) TokenType {
        return switch (self.start[0]) {
            'a' => self.checkKeyword(1, "nd", TokenType.@"and"),
            'c' => self.checkKeyword(1, "lass", TokenType.class),
            'e' => self.checkKeyword(1, "lse", TokenType.@"else"),
            'f' => if (self.current.ptr - self.start.ptr > 1)
                switch (self.start[1]) {
                    'a' => self.checkKeyword(2, "lse", TokenType.false),
                    'o' => self.checkKeyword(2, "r", TokenType.@"for"),
                    'n' => TokenType.@"fn",
                    else => TokenType.identifier,
                }
            else
                TokenType.identifier,
            'i' => self.checkKeyword(1, "f", TokenType.@"if"),
            'n' => self.checkKeyword(1, "il", TokenType.nil),
            'o' => self.checkKeyword(1, "r", TokenType.@"or"),
            'p' => self.checkKeyword(1, "rint", TokenType.print),
            'r' => self.checkKeyword(1, "eturn", TokenType.@"return"),
            's' => self.checkKeyword(1, "uper", TokenType.super),
            't' => if (self.current.ptr - self.start.ptr > 1)
                switch (self.start[1]) {
                    'h' => self.checkKeyword(2, "is", TokenType.this),
                    'r' => self.checkKeyword(2, "ue", TokenType.true),
                    else => TokenType.identifier,
                }
            else
                TokenType.identifier,
            'v' => self.checkKeyword(1, "ar", TokenType.@"var"),
            'w' => self.checkKeyword(1, "hile", TokenType.@"while"),
            else => TokenType.identifier,
        };
    }

    inline fn checkKeyword(self: *Self, start: usize, rest: []const u8, token_type: TokenType) TokenType {
        if (self.current.ptr - self.start.ptr == start + rest.len and std.mem.eql(u8, self.start[start .. start + rest.len], rest)) {
            return token_type;
        }

        return TokenType.identifier;
    }
};

pub const Token = struct {
    type: TokenType,
    start: [*]const u8,
    length: usize,
    line: usize,
};

pub const TokenType = enum(u8) {
    @"(",
    @")",
    @"{",
    @"}",
    @",",
    @".",
    @"-",
    @"+",
    @";",
    @"/",
    @"*",
    @"!",
    @"!=",
    @"=",
    @"==",
    @"<",
    @"<=",
    @">",
    @">=",
    identifier,
    string,
    number,
    @"and",
    class,
    @"else",
    false,
    @"for",
    @"fn",
    @"if",
    nil,
    @"or",
    print,
    @"return",
    super,
    this,
    true,
    @"var",
    @"while",
    @"error",
    eof,
};
