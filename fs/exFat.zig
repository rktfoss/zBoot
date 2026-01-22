pub const ExFatReader = struct {
    pub fn open(path: []const u8) !ExFatReader {
        _ = path;
        return ExFatReader{};
    }

    pub fn read(self: *const ExFatReader, buffer: []u8) !usize {
        _ = self;
        _ = buffer;
        return error.NotImplemented;
    }
};
