const std = @import("std");

pub fn panic(message: []const u8, stack_trace: ?*std.builtin.StackTrace) noreturn {
    std.debug.print("KERNEL PANIC: {s}\n", .{message});
    if (stack_trace) |st| {
        std.debug.dumpStackTrace(st.*);
    }
    while (true) {}
}
