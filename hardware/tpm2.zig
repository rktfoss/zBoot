//DO NOT USE, a base to start playing with



```zig
// hardware/tpm2.zig
const std = @import("std");

pub const Tpm2 = struct {
    device: *TpmDevice,

    pub fn init() !Tpm2 {
        const device = try open_tpm_device();
        return .{ .device = device };
    }

    pub fn extend_pcr(self: *Tpm2, pcr_index: u32, data: []const u8) !void {
        const hash = std.crypto.hash.sha256.hash(data);
        try self.device.extend(pcr_index, hash);
    }

    pub fn unseal_key_with_fido2(
        self: *Tpm2,
        fido: *fido2.Fido2Client,
        key_name: []const u8,
    ) ![]u8 {
        // 1. Generate challenge
        const challenge = std.crypto.random.bytes(32);

        // 2. Sign with FIDO2
        const signature = try fido.sign_challenge(challenge);

        // 3. Unseal TPM key
        return try self.device.unseal(
            key_name,
            challenge,
            signature,
        );
    }
};
```
