//DO NOT USE, for playing around with only


```zig
// raid/raid5.zig
const std = @import("std");
const block = @import("block.zig");

pub const Raid5 = struct {
    disks: []block.BlockDevice,
    stripe_size: usize = 64 * 1024, // 64KB stripes
    parity_disk: usize = 0,         // Rotating parity

    pub fn init(disks: []block.BlockDevice) !Raid5 {
        if (disks.len < 3) return error.NotEnoughDisks;
        return .{ .disks = disks };
    }

    pub fn read(self: *Raid5, lba: u64, buffer: []u8) !void {
        const disk_idx = self.calculate_disk(lba);
        const stripe_lba = lba / self.stripe_size;

        // Rotate parity disk per stripe
        self.parity_disk = (stripe_lba % @intCast(usize, self.disks.len));

        if (disk_idx == self.parity_disk) {
            // Reconstruct from other disks
            try self.reconstruct_data(lba, buffer);
        } else {
            // Read directly
            try self.disks[disk_idx].read(lba, buffer);
        }
    }

    pub fn write(self: *Raid5, lba: u64, data: []const u8) !void {
        const disk_idx = self.calculate_disk(lba);
        const stripe_lba = lba / self.stripe_size;

        // Update parity
        if (disk_idx != self.parity_disk) {
            try self.update_parity(lba, data);
        }

        // Write data
        try self.disks[disk_idx].write(lba, data);
    }

    fn calculate_disk(self: *Raid5, lba: u64) usize {
        return @intCast(usize, (lba / self.stripe_size) % @intCast(u64, self.disks.len));
    }
};
