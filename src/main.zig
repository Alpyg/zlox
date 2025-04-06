const std = @import("std");

const lib = @import("zox_lib");

const Chunk = lib.Chunk;
const debug = lib.debug;
const OpCode = lib.OpCode;
const VM = lib.VM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var chunk = Chunk.init(allocator);
    defer chunk.deinit();

    const constant = try chunk.addConstant(1.2);
    try chunk.push(@intFromEnum(OpCode.@"const"), 1);
    try chunk.push(constant, 1);
    try chunk.push(@intFromEnum(OpCode.ret), 1);

    var vm = VM.init(&chunk);
    try vm.run();

    lib.debug.disassembleChunk(&chunk, "test chunk");

    return;
}
