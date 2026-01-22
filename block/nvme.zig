const std = @import("std");

pub const NvmeDevice = struct {
    pub fn readSector(dev: *NvmeDevice, sector: u64, buf: []u8) !void {
        _ = dev;
        _ = sector;
        _ = buf;
        return error.Unimplemented;
    }
};
