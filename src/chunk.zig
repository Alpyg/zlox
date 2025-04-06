const std = @import("std");
const Allocator = std.mem.Allocator;

const Value = @import("value.zig").Value;

pub const OpCode = enum(u8) {
    @"const",
    negate,
    add,
    subtract,
    multiply,
    divide,
    ret,
};

pub const Chunk = struct {
    const Self = @This();

    bytecode: std.ArrayList(u8),
    constants: std.ArrayList(Value),
    lines: std.ArrayList(usize),

    pub fn init(allocator: Allocator) Self {
        return Self{
            .bytecode = std.ArrayList(u8).init(allocator),
            .constants = std.ArrayList(Value).init(allocator),
            .lines = std.ArrayList(usize).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.bytecode.deinit();
        self.constants.deinit();
        self.lines.deinit();
    }

    pub fn push(self: *Self, byte: u8, line: usize) !void {
        try self.lines.append(line);
        return try self.bytecode.append(byte);
    }

    pub fn addConstant(self: *Self, value: Value) !u8 {
        try self.constants.append(value);
        return @truncate(self.constants.items.len - 1);
    }
};
