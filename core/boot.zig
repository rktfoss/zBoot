
//DO NOT USE, base to start with


```zig
// core/boot.zig
const std = @import("std");
const uefi = @import("uefi.zig");

pub fn uefi_secure_boot() !uefi.Status {
    // 1. initialize UEFI subsystems
    const bs = uefi.boot_services;
    const rt = uefi.runtime_services;

    // 2. get memory map
    const memory_map = try bs.get_memory_map();

    // 3. load kernel from ESP
    const kernel = try load_kernel_from_esp(bs);

    // 4. exit Boot Services
    try bs.exit_boot_services(memory_map);

    // 5. jump to kernel
    jump_to_kernel(kernel);

    @unreachable();
}
```
