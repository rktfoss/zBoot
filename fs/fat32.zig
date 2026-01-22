const std = @import("std");

pub const Fat32Reader = struct {
    pub fn open(path: []const u8) !Fat32Reader {
        _ = path;
        return Fat32Reader{};
    }

    pub fn read(self: *const Fat32Reader, buffer: []u8) !usize {
        _ = self;
        _ = buffer;
        return error.NotImplemented;
    }
};
