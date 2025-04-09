const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
const Compiler = @import("compiler.zig").Compiler;
const debug = @import("debug.zig");
const OpCode = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;
const ValueType = @import("value.zig").ValueType;

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

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        const stack = std.ArrayList(Value).init(allocator);
        return Self{
            .chunk = undefined,
            .ip = undefined,
            .stack = stack,
            .stack_top = stack.items.ptr,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.stack.deinit();
        self.stack_top = undefined;
    }

    pub fn interpret(self: *Self, src: []const u8) !void {
        var chunk = Chunk.init(self.allocator);
        defer chunk.deinit();

        var compiler = Compiler.init(src, &chunk);
        compiler.compile();

        self.chunk = &chunk;
        self.ip = chunk.bytecode.items.ptr;

        return self.run();
    }

    pub fn run(self: *VM) !void {
        while (true) {
            std.debug.print("Stack: {any}\n", .{self.stack.items});
            _ = debug.disassembleInstruction(
                self.chunk,
                @intFromPtr(self.ip) - @intFromPtr(self.chunk.bytecode.items.ptr),
            );
            switch (@as(OpCode, @enumFromInt(self.readByte()))) {
                OpCode.nop => {},
                OpCode.@"const" => {
                    const constant = self.readConstant();
                    try self.push(constant);
                },
                OpCode.nil => try self.push(Value.nil),
                OpCode.true => try self.push(Value{ .bool = true }),
                OpCode.false => try self.push(Value{ .bool = false }),
                OpCode.not => try self.push(Value{ .bool = isFalsy(self.pop()) }),
                OpCode.equal => {
                    const b = self.pop();
                    const a = self.pop();
                    try self.push(Value{ .bool = a.isEqual(b) });
                },
                OpCode.greater => try self.binaryOp(.bool, struct {
                    pub fn op(a: f32, b: f32) f32 {
                        return a - b;
                    }
                }.op),
                OpCode.less => try self.binaryOp(.bool, struct {
                    pub fn op(a: f32, b: f32) f32 {
                        return a - b;
                    }
                }.op),
                OpCode.negate => {
                    if (!self.peek(0)[0].isNum()) @panic("runtime error"); // TODO Handle this better
                    try self.push(Value{ .num = -self.pop().num });
                },
                OpCode.add => try self.binaryOp(.num, struct {
                    pub fn op(a: f32, b: f32) f32 {
                        return a + b;
                    }
                }.op),
                OpCode.subtract => try self.binaryOp(.num, struct {
                    pub fn op(a: f32, b: f32) f32 {
                        return a - b;
                    }
                }.op),
                OpCode.multiply => try self.binaryOp(.num, struct {
                    pub fn op(a: f32, b: f32) f32 {
                        return a * b;
                    }
                }.op),
                OpCode.divide => try self.binaryOp(.num, struct {
                    pub fn op(a: f32, b: f32) f32 {
                        return a / b;
                    }
                }.op),
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

    fn peek(self: *Self, distance: usize) [*]Value {
        return self.stack_top - 1 - distance;
    }

    inline fn binaryOp(
        self: *Self,
        value_type: ValueType,
        comptime op: fn (a: f32, b: f32) f32,
    ) !void {
        if (!self.peek(0)[0].isNum() or !self.peek(1)[0].isNum()) @panic("Operands must be numbers.");

        const b = self.pop().num;
        const a = self.pop().num;

        switch (value_type) {
            .bool => try self.push(Value{ .bool = op(a, b) > 0 }),
            .num => try self.push(Value{ .num = op(a, b) }),
            else => unreachable,
        }
    }

    fn isFalsy(value: Value) bool {
        return value.isNil() or (value.isBool() and !value.bool);
    }
};
