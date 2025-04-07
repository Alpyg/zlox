const std = @import("std");
const Scanner = @import("scanner.zig").Scanner;
const Token = @import("scanner.zig").Token;
const TokenType = @import("scanner.zig").TokenType;

pub fn compile(src: []const u8) !void {
    var scanner = Scanner.init(src);

    var line: usize = 0;
    while (true) {
        const token: Token = scanner.scanToken();

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
