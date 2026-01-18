//DO NOT USE, base to start playing from


```zig
// hardware/fido2.zig
const std = @import("std");

pub const Fido2Client = struct {
    device: *Fido2Device,

    pub fn init() !Fido2Client {
        const device = try open_fido2_device();
        return .{ .device = device };
    }

    pub fn sign_challenge(self: *Fido2Client, challenge: []const u8) ![]u8 {
        return try self.device.get_assertion(challenge);
    }
};
```
