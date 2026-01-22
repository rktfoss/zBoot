const std = @import("std");

pub inline fn read(comptime T: type, address: usize) T {
    return @as(*volatile T, @ptrFromInt(address)).*;
}

pub inline fn write(comptime T: type, address: usize, value: T) void {
    @as(*volatile T, @ptrFromInt(address)).* = value;
}
