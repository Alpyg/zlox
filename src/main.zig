const std = @import("std");

const lib = @import("zox_lib");

const debug = @import("debug.zig");
const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var chunk = Chunk.init(allocator);
    defer chunk.deinit();

    try chunk.append(@intFromEnum(OpCode.ret));

    debug.disassembleChunk(&chunk, "test chunk");

    return;
}
