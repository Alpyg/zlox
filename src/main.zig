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

    var constant = try chunk.addConstant(1);
    try chunk.push(@intFromEnum(OpCode.@"const"), 1);
    try chunk.push(constant, 1);
    constant = try chunk.addConstant(2);
    try chunk.push(@intFromEnum(OpCode.@"const"), 2);
    try chunk.push(constant, 2);
    constant = try chunk.addConstant(3);
    try chunk.push(@intFromEnum(OpCode.@"const"), 3);
    try chunk.push(constant, 3);
    try chunk.push(@intFromEnum(OpCode.ret), 4);

    var vm = VM.init(allocator, &chunk);
    defer vm.deinit();
    try vm.run();

    return;
}
