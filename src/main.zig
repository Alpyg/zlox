const std = @import("std");

const lib = @import("zox_lib");

const Chunk = lib.Chunk;
const OpCode = lib.OpCode;
const VM = lib.VM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var chunk = Chunk.init(allocator);
    defer chunk.deinit();

    var constant: u8 = 0;

    constant = try chunk.addConstant(1.2);
    try chunk.push(@intFromEnum(OpCode.@"const"), 1);
    try chunk.push(constant, 1);
    constant = try chunk.addConstant(3.4);
    try chunk.push(@intFromEnum(OpCode.@"const"), 1);
    try chunk.push(constant, 1);

    try chunk.push(@intFromEnum(OpCode.add), 1);

    constant = try chunk.addConstant(5.6);
    try chunk.push(@intFromEnum(OpCode.@"const"), 1);
    try chunk.push(constant, 1);

    try chunk.push(@intFromEnum(OpCode.divide), 1);
    try chunk.push(@intFromEnum(OpCode.negate), 1);

    try chunk.push(@intFromEnum(OpCode.ret), 2);

    var vm = VM.init(allocator, &chunk);
    defer vm.deinit();
    try vm.run();

    lib.debug.disassembleChunk(vm.chunk, "test chunk");

    return;
}
