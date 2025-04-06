const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;

pub fn disassembleChunk(chunk: *Chunk, name: []const u8) void {
    std.debug.print("== {s} ==\n", .{name});

    var offset: u32 = 0;
    while (offset < chunk.bytecode.items.len) {
        offset = disassembleInstruction(chunk, offset);
    }
}

pub fn disassembleInstruction(chunk: *Chunk, offset: u32) u32 {
    std.debug.print("{d:0>4} ", .{offset});

    if (offset > 0 and chunk.lines.items[offset] == chunk.lines.items[offset - 1]) {
        std.debug.print("   | ", .{});
    } else {
        std.debug.print("{d:>4} ", .{chunk.lines.items[offset]});
    }

    const instruction: OpCode = @enumFromInt(chunk.bytecode.items[offset]);
    switch (instruction) {
        OpCode.ret => {
            return simpleInstruction(@tagName(instruction), offset);
        },
        OpCode.@"const" => {
            return constInstruction(@tagName(instruction), chunk, offset);
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

inline fn constInstruction(name: []const u8, chunk: *Chunk, offset: u32) u32 {
    const constant = chunk.bytecode.items[offset + 1];
    std.debug.print(
        "{s:<16} {d:>4} '{any}'\n",
        .{ name, constant, chunk.constants.items[constant] },
    );
    return offset + 2;
}
