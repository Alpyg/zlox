const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;

pub fn disassembleChunk(chunk: *Chunk, name: []const u8) void {
    std.debug.print("== {s} ==\n", .{name});

    var offset: u32 = 0;
    while (offset < chunk.items.len) {
        offset = disassembleInstruction(chunk, offset);
    }
}

pub fn disassembleInstruction(chunk: *Chunk, offset: u32) u32 {
    std.debug.print("{d:0>4} ", .{offset});

    const instruction: OpCode = @enumFromInt(chunk.items[offset]);
    switch (instruction) {
        OpCode.ret => {
            return simpleInstruction(@tagName(instruction), offset);
        },
        // else => {
        //     out.print("Unknown opcode {d}", .{instruction});
        //     return offset + 1;
        // },
    }
}

inline fn simpleInstruction(name: []const u8, offset: u32) u32 {
    std.debug.print("{s}\n", .{name});
    return offset + 1;
}
