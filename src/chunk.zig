const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Chunk = std.ArrayList(u8);

pub const OpCode = enum(u8) {
    ret,
};
