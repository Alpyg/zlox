const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
const compiler = @import("compiler.zig");
const debug = @import("debug.zig");
const OpCode = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;

pub const InterpretError = error{
    Compile,
    Runtime,
};

pub const VM = struct {
    const Self = @This();

    chunk: *Chunk,
    ip: [*]u8,

    stack: std.ArrayList(Value),
    stack_top: [*]Value,

    pub fn init(allocator: std.mem.Allocator) Self {
        const stack = std.ArrayList(Value).init(allocator);
        return Self{
            .chunk = undefined,
            .ip = undefined,
            .stack = stack,
            .stack_top = stack.items.ptr,
        };
    }

    pub fn deinit(self: *Self) void {
        self.stack.deinit();
        self.stack_top = undefined;
    }

    pub fn interpret(_: *Self, src: []const u8) InterpretError!void {
        try compiler.compile(src);
        // self.chunk = chunk;
        // self.ip = chunk.bytecode.items.ptr;
        //
        // return self.run();
    }

    pub fn run(self: *VM) !void {
        while (true) {
            std.debug.print("Stack: {any}\n", .{self.stack.items});
            _ = debug.disassembleInstruction(
                self.chunk,
                @intFromPtr(self.ip) - @intFromPtr(self.chunk.bytecode.items.ptr),
            );
            switch (@as(OpCode, @enumFromInt(self.readByte()))) {
                OpCode.@"const" => {
                    const constant = self.readConstant();
                    try self.push(constant);
                },
                OpCode.negate => try self.push(-self.pop()),
                OpCode.add => {
                    const b = self.pop();
                    const a = self.pop();
                    try self.push(a + b);
                },
                OpCode.subtract => {
                    const b = self.pop();
                    const a = self.pop();
                    try self.push(a - b);
                },
                OpCode.multiply => {
                    const b = self.pop();
                    const a = self.pop();
                    try self.push(a * b);
                },
                OpCode.divide => {
                    const b = self.pop();
                    const a = self.pop();
                    try self.push(a / b);
                },
                OpCode.ret => {
                    std.debug.print("{any}\n", .{self.pop()});
                    return;
                },
            }
        }
    }

    inline fn readByte(self: *Self) u8 {
        defer self.ip += 1;
        return self.ip[0];
    }

    inline fn readConstant(self: *Self) Value {
        return self.chunk.constants.items[self.readByte()];
    }

    fn push(self: *Self, value: Value) !void {
        if (self.stack.items.len == self.stack.capacity) {
            try self.stack.ensureUnusedCapacity(1);
            self.stack_top = self.stack.items.ptr + self.stack.items.len;
        }

        self.stack_top[0] = value;
        self.stack.items.len += 1;
        self.stack_top += 1;
    }

    fn pop(self: *Self) Value {
        self.stack_top -= 1;
        self.stack.items.len -= 1;
        return self.stack_top[0];
    }
};
