const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
const debug = @import("debug.zig");
const Lexer = @import("lexer.zig").Lexer;
const OpCode = @import("chunk.zig").OpCode;
const Token = @import("lexer.zig").Token;
const TokenType = @import("lexer.zig").TokenType;
const Value = @import("value.zig").Value;

pub const Compiler = struct {
    const Self = @This();

    lexer: Lexer,
    chunk: *Chunk,

    previous: Token,
    current: Token,

    hadError: bool = false,
    panicMode: bool = false,

    pub fn init(src: []const u8, chunk: *Chunk) Self {
        return Self{
            .lexer = Lexer.init(src),
            .chunk = chunk,
            .previous = undefined,
            .current = undefined,
        };
    }

    pub fn compile(self: *Self) void {
        self.advance();
        self.expression();
        self.consume(TokenType.eof, "Expect end of expression.");
        self.end();
    }

    fn advance(self: *Self) void {
        self.previous = self.current;

        while (true) {
            self.current = self.lexer.scanToken();

            if (self.current.type != .@"error") break;

            self.errorAt(self.current, self.current.start);
        }
    }

    fn consume(self: *Self, token_type: TokenType, msg: []const u8) void {
        if (self.current.type == token_type) {
            self.advance();
            return;
        }

        self.errorAt(self.current, msg);
    }

    fn emit(self: *Self, data: anytype) void {
        const DataType = @typeInfo(@TypeOf(data));

        switch (DataType) {
            .@"struct" => |tupleInfo| {
                if (!tupleInfo.is_tuple) @panic("emit: Unsupported field type in tuple");

                const tupleFields = tupleInfo.fields;
                inline for (tupleFields) |fieldName| {
                    self.emit(@field(data, fieldName.name));
                }
            },
            .int => |intInfo| {
                if (intInfo.bits == 8 and intInfo.signedness == .unsigned) {
                    self.chunk.push(data, self.previous.line) catch unreachable;
                } else {
                    @panic("emit: Unsupported integer type");
                }
            },
            .@"enum" => |_| {
                self.chunk.push(@intFromEnum(data), self.previous.line) catch unreachable;
            },
            else => @panic("emit: Unsupported data type"),
        }
    }

    fn emitReturn(self: *Self) void {
        self.emit(OpCode.ret);
    }

    fn emitConstant(self: *Self, value: Value) void {
        self.emit(.{ OpCode.@"const", self.makeConstant(value) });
    }

    fn makeConstant(self: *Self, value: Value) u8 {
        const constant = self.chunk.addConstant(value) catch unreachable;
        if (constant > 255) {
            self.errorAt(self.previous, "Too many constants in one chunk.");
            return 0;
        }
        return constant;
    }

    fn end(self: *Self) void {
        self.emitReturn();

        debug.disassembleChunk(self.chunk, "code");
    }

    fn errorAt(self: *Self, token: Token, msg: []const u8) void {
        if (self.panicMode) return;
        self.panicMode = true;

        std.debug.print("[line {d}] Error", .{token.line});

        switch (token.type) {
            TokenType.eof => std.debug.print(" at end", .{}),
            TokenType.@"error" => {},
            else => std.debug.print(" at {s}", .{token.start}),
        }

        std.debug.print(": {s}", .{msg});

        self.hadError = true;
    }

    fn parsePrecedence(self: *Self, precedence: Precedence) void {
        self.advance();

        const prefix_rule = getRule(self.previous.type).prefix;
        if (prefix_rule == null) {
            self.errorAt(self.previous, "Exprect expression.");
            return;
        }

        prefix_rule.?(self);

        while (@intFromEnum(precedence) <= @intFromEnum(getRule(self.current.type).precedence)) {
            self.advance();

            const infix_rule = getRule(self.previous.type).infix;
            infix_rule.?(self);
        }
    }

    fn getRule(token_type: TokenType) ParseRule {
        return rules[@intFromEnum(token_type)];
    }

    fn expression(self: *Self) void {
        self.parsePrecedence(Precedence.assignment);
    }

    fn number(self: *Self) void {
        const value: f32 = std.fmt.parseFloat(f32, self.previous.start) catch unreachable;
        self.emitConstant(value);
    }

    fn grouping(self: *Self) void {
        self.expression();
        self.consume(TokenType.@")", "Expected `)` after expression.");
    }

    fn unary(self: *Self) void {
        const operator_type = self.previous.type;

        self.parsePrecedence(Precedence.unary);

        switch (operator_type) {
            TokenType.@"-" => self.emit(OpCode.negate),
            else => unreachable,
        }
    }

    fn binary(self: *Self) void {
        const operator_type = self.previous.type;
        const rule = getRule(operator_type);
        self.parsePrecedence(@enumFromInt(@intFromEnum(rule.precedence) + 1));

        switch (operator_type) {
            .@"+" => self.emit(OpCode.add),
            .@"-" => self.emit(OpCode.subtract),
            .@"*" => self.emit(OpCode.multiply),
            .@"/" => self.emit(OpCode.divide),
            else => unreachable,
        }
    }
};

const Precedence = enum {
    none,
    assignment,
    @"or",
    @"and",
    equality,
    comparison,
    term,
    factor,
    unary,
    call,
    primary,
};

const ParseRule = struct {
    prefix: ?*const fn (*Compiler) void,
    infix: ?*const fn (*Compiler) void,
    precedence: Precedence,
};

const rules: [40]ParseRule = .{
    ParseRule{ .prefix = Compiler.grouping, .infix = null, .precedence = .none }, // (
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // )
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // {
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // }
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // ,
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // .
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // ;
    ParseRule{ .prefix = Compiler.unary, .infix = Compiler.binary, .precedence = .term }, // -
    ParseRule{ .prefix = null, .infix = Compiler.binary, .precedence = .term }, // +
    ParseRule{ .prefix = null, .infix = Compiler.binary, .precedence = .factor }, // *
    ParseRule{ .prefix = null, .infix = Compiler.binary, .precedence = .factor }, // /
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // !
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // !=
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // =
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // ==
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // <
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // <=
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // >
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // >=
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // var
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // identifier
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // string
    ParseRule{ .prefix = Compiler.number, .infix = null, .precedence = .none }, // number
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // true
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // false
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // nil
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // and
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // or
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // if
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // else
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // for
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // while
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // fn
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // return
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // class
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // this
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // super
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // print
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // error
    ParseRule{ .prefix = null, .infix = null, .precedence = .none }, // eof
};
