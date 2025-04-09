const std = @import("std");

pub const ValueType = enum {
    nil,
    bool,
    num,
};

pub const Value = union(ValueType) {
    const Self = @This();

    nil,
    bool: bool,
    num: f32,

    pub inline fn makeBool(value: bool) Self {
        return Self{
            .bool = value,
        };
    }

    pub inline fn isEqual(self: *const Self, value: Value) bool {
        if (std.mem.eql(u8, @tagName(self.*), @tagName(value))) return false;

        return switch (self.*) {
            .nil => true,
            .bool => self.bool == value.bool,
            .num => self.num == value.num,
        };
    }

    pub inline fn isBool(self: *const Self) bool {
        switch (self.*) {
            ValueType.bool => return true,
            else => return false,
        }
    }

    pub inline fn isNum(self: *const Self) bool {
        switch (self.*) {
            ValueType.num => return true,
            else => return false,
        }
    }

    pub inline fn isNil(self: *const Self) bool {
        switch (self.*) {
            ValueType.nil => return true,
            else => return false,
        }
    }
};
