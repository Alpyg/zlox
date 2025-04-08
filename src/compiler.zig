const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("lexer.zig").Token;
const TokenType = @import("lexer.zig").TokenType;

pub fn compile(src: []const u8) !void {
    var lexer = Lexer.init(src);

    var line: usize = 0;
    while (true) {
        const token: Token = lexer.scanToken();

        if (token.line != line) {
            std.debug.print("{d:>4} ", .{token.line});
            line = token.line;
        } else {
            std.debug.print("   | ", .{});
        }

        std.debug.print("{s:<12} {s}\n", .{
            @tagName(token.type),
            token.start[0..token.length],
        });

        if (token.type == TokenType.eof) break;
    }
}
