const std = @import("std");

pub const ZfsReader = struct {
    pub fn open(path: []const u8) !ZfsReader {
        _ = path;
        return ZfsReader{};
    }

    pub fn read(self: *const ZfsReader, buffer: []u8) !usize {
        _ = self;
        _ = buffer;
        return error.NotImplemented;
    }
};
