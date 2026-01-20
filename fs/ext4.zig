//DO NOT USE, for demo only 
//ext4 with journaling

```zig
// fs/ext4.zig
const std = @import("std");
const block = @import("block.zig");

pub const Ext4 = struct {
    dev: block.BlockDevice,
    superblock: Superblock,
    journal: Journal,

    pub fn init(dev: block.BlockDevice) !Ext4 {
        // read superblock (1024 bytes from start)
        var sb_buf: [1024]u8 = undefined;
        try dev.read(1024, &sb_buf);

        const sb = parse_superblock(&sb_buf) catch |err| {
            return err;
        };

        return .{
            .dev = dev,
            .superblock = sb,
            .journal = try init_journal(dev, sb),
        };
    }

    pub fn read_file(self: *Ext4, path: []const u8) ![]u8 {
        // 1. lookup inode
        const inode = try self.lookup_inode(path);

        // 2. read data blocks
        return try self.read_inode_data(inode);
    }
};
```
