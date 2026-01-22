const std = @import("std");

pub const DhcpConfig = struct {
    ip_address: [4]u8,
    gateway: [4]u8,
    dns: [4]u8,
};

pub fn requestConfig() !DhcpConfig {
    // Send DHCP request and get configuration
    return DhcpConfig{
        .ip_address = [_]u8{ 192, 168, 1, 100 },
        .gateway = [_]u8{ 192, 168, 1, 1 },
        .dns = [_]u8{ 8, 8, 8, 8 },
    };
}
