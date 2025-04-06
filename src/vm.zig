const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
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

    pub fn init(chunk: *Chunk) Self {
        return Self{
            .chunk = chunk,
            .ip = chunk.bytecode.items.ptr,
        };
    }

    pub fn deinit(_: *Self) void {}

    pub fn interpret(self: *Self, chunk: *Chunk) InterpretError!void {
        self.chunk = chunk;
        self.ip = chunk.bytecode.items.ptr;

        return self.run();
    }

    pub fn run(self: *VM) InterpretError!void {
        while (true) {
            _ = debug.disassembleInstruction(
                self.chunk,
                @intFromPtr(self.ip) - @intFromPtr(self.chunk.bytecode.items.ptr),
            );
            switch (@as(OpCode, @enumFromInt(self.readByte()))) {
                OpCode.@"const" => {
                    const constant = self.readConstant();
                    std.debug.print("{any}\n", .{constant});
                    break;
                },
                OpCode.ret => {
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
};
