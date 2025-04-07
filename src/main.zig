const std = @import("std");

const lib = @import("zox_lib");

const Chunk = lib.Chunk;
const OpCode = lib.OpCode;
const VM = lib.VM;

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    switch (args.len) {
        1 => try repl(allocator),
        2 => try runFile(allocator, args[1]),
        else => {
            std.debug.print("Usage: zox [path]\n", .{});
            std.process.exit(64);
        },
    }

    return;
}

fn repl(_: std.mem.Allocator) !void {}

fn runFile(allocator: std.mem.Allocator, path: []const u8) !void {
    const src = try readFile(allocator, path);
    defer allocator.free(src);

    var vm = VM.init(allocator);
    defer vm.deinit();

    try vm.interpret(src);
}

fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    var file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    try file.seekTo(0);

    const buffer = try allocator.alloc(u8, file_size + 1);
    const bytes_read = try file.readAll(buffer[0..file_size]);

    buffer[bytes_read] = 0;
    return buffer[0 .. bytes_read + 1];
}
