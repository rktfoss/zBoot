const std = @import("std");

pub fn hash(data: []const u8, out: *[32]u8) void {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hasher.update(data);
    hasher.final(out);
}
