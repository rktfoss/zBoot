//DO NOT USE, for demo only
//hot swap drive support, for server farm use



```zig
// server/hotplug.zig
pub const HotplugManager = struct {
    raid: *anytype, // Raid0/Raid1/Raid5/etc
    disks: std.ArrayList(block.BlockDevice),

    pub fn init(raid: *anytype) HotplugManager {
        return .{ .raid = raid, .disks = .{} };
    }

    pub fn add_disk(self: *HotplugManager, disk: block.BlockDevice) !void {
        // 1. Check disk health
        try disk.smart_check();

        // 2. Add to RAID
        try self.raid.add_disk(disk);

        // 3. Start rebuild (if needed)
        if (self.raid.needs_rebuild()) {
            try self.raid.rebuild();
        }
    }

    pub fn remove_disk(self: *HotplugManager, disk: block.BlockDevice) !void {
        // 1. Mark as failed
        try self.raid.mark_failed(disk);

        // 2. Remove from array
        try self.raid.remove_disk(disk);
    }
};
```
