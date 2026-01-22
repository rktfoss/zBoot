const std = @import("std");

pub const NtfsReader = struct {
    pub fn open(path: []const u8) !NtfsReader {
        _ = path;
        return NtfsReader{};
    }

    pub fn read(self: *const NtfsReader, buffer: []u8) !usize {
        _ = self;
        _ = buffer;
        return error.NotImplemented;
    }
};
