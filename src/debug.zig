const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;

pub fn disassembleChunk(chunk: *Chunk, name: []const u8) void {
    std.debug.print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.bytecode.items.len) {
        offset = disassembleInstruction(chunk, offset);
    }
}

pub fn disassembleInstruction(chunk: *Chunk, offset: usize) usize {
    std.debug.print("{d:0>4} ", .{offset});

    if (offset > 0 and chunk.lines.items[offset] == chunk.lines.items[offset - 1]) {
        std.debug.print("   | ", .{});
    } else {
        std.debug.print("{d:>4} ", .{chunk.lines.items[offset]});
    }

    const instruction: OpCode = @enumFromInt(chunk.bytecode.items[offset]);
    switch (instruction) {
        OpCode.@"const" => return constInstruction(@tagName(instruction), chunk, offset),
        OpCode.nop,
        OpCode.negate,
        OpCode.add,
        OpCode.subtract,
        OpCode.multiply,
        OpCode.divide,
        OpCode.ret,
        => return simpleInstruction(@tagName(instruction), offset),
    }
}

inline fn simpleInstruction(name: []const u8, offset: usize) usize {
    std.debug.print("{s}\n", .{name});
    return offset + 1;
}

inline fn constInstruction(name: []const u8, chunk: *Chunk, offset: usize) usize {
    const constant = chunk.bytecode.items[offset + 1];
    std.debug.print(
        "{s:<16} {d:>4} '{any}'\n",
        .{ name, constant, chunk.constants.items[constant] },
    );
    return offset + 2;
}
