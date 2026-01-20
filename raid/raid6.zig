//DO NOT USE, for playing around with only
//raid6 dual parity


```zig
// raid/raid6.zig
pub const Raid6 = struct {
    disks: []block.BlockDevice,
    stripe_size: usize = 64 * 1024,
    parity_disks: [2]usize = .{ 0, 1 }, // P and Q parity

    pub fn init(disks: []block.BlockDevice) !Raid6 {
        if (disks.len < 4) return error.NotEnoughDisks;
        return .{ .disks = disks };
    }

    pub fn read(self: *Raid6, lba: u64, buffer: []u8) !void {
        const disk_idx = self.calculate_disk(lba);
        const stripe_lba = lba / self.stripe_size;

        // rotate parity disks
        self.parity_disks[0] = (stripe_lba % @intCast(u64, self.disks.len));
        self.parity_disks[1] = (stripe_lba + 1) % @intCast(u64, self.disks.len);

        if (disk_idx == self.parity_disks[0] || disk_idx == self.parity_disks[1]) {
            // reconstruct from other disks
            try self.reconstruct_data(lba, buffer);
        } else {
            try self.disks[disk_idx].read(lba, buffer);
        }
    }
};
