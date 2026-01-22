const mmio = @import("mmio.zig");

pub const UART_BASE: usize = 0x1000_0000;

pub fn init() void {
    // UART initialization logic
}

pub fn putc(c: u8) void {
    mmio.write(u8, UART_BASE, c);
}
