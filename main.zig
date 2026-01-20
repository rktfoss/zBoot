//DO NOT USE, for veiwing only, messed with lines bellow 376 & 1017 "filesystems" to fix Note to self: always double check copying files over!!!

```zig
const std = @import("std");
const mem = std.mem;
const os = std.os;
const json = std.json;
const crypto = std.crypto;
const fs = std.fs;
const time = std.time;

// import our generated assets
const config = @import("config");
const fonts = @import("fonts");
const keys = @import("keys");
const hw_config = @import("hw_config");
const fs_images = @import("fs_images");
const net_config = @import("net_config");
const themes = @import("themes");

// import core modules
const boot = @import("core/boot.zig");
const panic = @import("core/panic.zig");
const alloc = @import("core/alloc.zig");

// import hardware modules
const tpm2 = @import("hardware/tpm2.zig");
const uart = @import("hardware/uart.zig");
const mmio = @import("hardware/mmio.zig");
const acpi = @import("hardware/acpi.zig");
const pci = @import("hardware/pci.zig");

// import filesystem modules
const fat32 = @import("fs/fat32.zig");
const btrfs = @import("fs/btrfs.zig");
const exfat = @import("fs/exfat.zig");
const ext4 = @import("fs/ext4.zig");
const ntfs = @import("fs/ntfs.zig");
const zfs = @import("fs/zfs.zig");

// import crypto modules
const sha256 = @import("crypto/sha256.zig");
const rsa = @import("crypto/rsa.zig");
const ed25519 = @import("crypto/ed25519.zig");

// import network modules
const quic = @import("net/quic.zig");
const dhcp = @import("net/dhcp.zig");
const tftp = @import("net/tftp.zig");
const http = @import("net/http.zig");
const pxe = @import("net/pxe.zig");

// import user interface modules
const ghostty = @import("terminal/ghostty.zig");
const tui = @import("zsets/ui.zig");

// global allocator
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// global state
var boot_config: BootConfig = undefined;
var current_selection: usize = 0;
var network_initialized: bool = false;
var secure_boot_enabled: bool = false;
var tpm_available: bool = false;

pub fn main() !void {
    // initialize the system
    initSystem();

    // set up panic handler
    panic.setHandler(customPanicHandler);

    // initialize hardware
    initHardware();

    // load configuration
    boot_config = loadConfiguration() catch |err| {
        panic.panic("Failed to load configuration", .{err});
    };

    // initialize filesystem
    initFilesystem();

    // initialize network if needed
    if (boot_config.network.dhcp_enabled ||
    boot_config.network.http_boot) {
        network_initialized = initNetwork();
    }

    // initialize user interface
    initUI();

    // check security requirements
    checkSecurityRequirements();

    // main bootloader loop
    runBootloader();
}

fn initSystem() void {
    // initialize memory allocator
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // set up memory protection if available
    #ifdef HAS_MPU
        mmio.setupMemoryProtection();
    #endif

    // initialize console
    uart.init(115200); // Standard baud rate
    std.debug.print("ZigBoot initializing...\n", .{});

    // initialize random number generator
    crypto.random.setup();

    // initialize time
    time.init();
}

fn initHardware() void {
    // detect hardware platform
    const platform = hw_config.detectPlatform();

    // initialize platform-specific hardware
    switch (platform) {
        .x86 => {
            mmio.initX86();
            acpi.init();
            pci.init();
            tpm_available = tpm2.init();
        },
        .arm => {
            mmio.initARM();
            // ARM-specific initialization
        },
        .riscv => {
            mmio.initRISCV();
            // RISC-V-specific initialization
        },
        else => {
            std.debug.print("Unknown platform detected\n", .{});
        },
    }

    // initialize common hardware
    uart.init(115200);
}

fn loadConfiguration() !BootConfig {
    // parse the embedded configuration
    const config_data = config.getDefaultConfig();
    var config = try parseBootConfig(config_data);

    // try to load configuration from disk if available
    if (fs.exists("zigboot/config.json")) {
        const disk_config = try fs.readFileAlloc(allocator, "zigboot/config.json", 4096);
        defer allocator.free(disk_config);

        const disk_boot_config = try
        parseBootConfig(disk_config);
        // merge configurations (disk config takes precedence)
        config = mergeConfigs(config, disk_boot_config);
    }

    // apply hardware-specific overrides
    applyHardwareConfig(&config);

    // validate configuration
    if (!validateConfig(&config)) {
        return error.ConfigurationError;
    }

    return config;
}

fn parseBootConfig(data: []const u8) !BootConfig {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // parse JSON configuration
    const json_value = try json.parseFromSlice(
        json.Value,
        allocator,
        data,
        .{ .allow_trailing_commas = true },
    );

    // extract configuration values
    var config = BootConfig{
        .boot = .{
            .timeout = json_value.Object.get("boot").?.Object.get("timeout").?.Number orelse 5,
            .default_entry = json_value.Object.get("boot").?.Object.get("default_entry").?.Strijson_value.Object.get("boot").?.Objec.get("default_entry").?.String orelse "ZigOS",
            .entries = std.ArrayList(BootEntry).init(allocator),
            .pxe_enabled = json_value.Object.get("boot").?.Object.get("pxe_enabled").?.Bool orelse false,
            .http_boot = json_value.Object.get("boot").?.Object.get("http_boot").?.Bool orelse false,
        },
        .security = .{
            .secure_boot = json_value.Object.get("security").?.Object.get("secure_boot").?.Bojson_value.Object.get("security").?.Objct.get("secure_boot").?.Bool orelse true,
            .tpm_required = json_value.Object.get("security").?.Object.get("tpm_required").?.Bjson_value.Object.get("security").?.Obect.get("tpm_required").?.Bool orelse false,
            .measure_boot = json_value.Object.get("security").?.Object.get("measure_boot").?.Bjson_value.Object.get("security").?.Obect.get("measure_boot").?.Bool orelse false,
        },
        .network = .{
            .dhcp_enabled = json_value.Object.get("network").?.Object.get("dhcp_enabled").?.Bojson_value.Object.get("network").?.Objct.get("dhcp_enabled").?.Bool orelse true,
            .timeout = json_value.Object.get("network").?.Object.get("timeout").?.Number orelse 5,
            .http_boot = json_value.Object.get("network").?.Object.get("http_boot").?.Bool orelse false,
            .pxe_server = json_value.Object.get("network").?.Object.get("pxe_server").?.Strijson_value.Object.get("network").?.Objec.get("pxe_server").?.String orelse "",
        },
        .debug = .{
            .serial_output = json_value.Object.get("debug").?.Object.get("serial_output").?.Boojson_value.Object.get("debug").?.Objet.get("serial_output").?.Bool orelse true,
            .recovery_mode = json_value.Object.get("debug").?.Object.get("recovery_mode").?.Boojson_value.Object.get("debug").?.Objet.get("recovery_mode").?.Bool orelse false,
        },
    };

    // parse boot entries
    if (json_value.Object.get("boot").?.Object.get("entries")) |entries| {
        for (entries.Array) |entry| {
            const name = entry.Object.get("name").?.String orelse "Unknown";
            const path = entry.Object.get("path").?.String orelse "";
            const args = entry.Object.get("args").?.String orelse "";
            const initrd = entry.Object.get("initrd").?.String orelse "";
            const local = entry.Object.get("local").?.Bool orelse true;
            const pxe = entry.Object.get("pxe").?.Bool orelse false;
            const http = entry.Object.get("http").?.Bool orelse false;

            try config.boot.entries.append(.{
                .name = name,
                .path = path,
                .args = args,
                .initrd = initrd,
                .local = local,
                .pxe = pxe,
                .http = http,
            });
        }
    }

    return config;
}

fn mergeConfigs(base: BootConfig, override: BootConfig)
BootConfig {
    // create a new config with override values where specified
    return .{
        .boot = .{
            .timeout = override.boot.timeout,
            .default_entry = if (override.boot.default_entry.len> 0)
                override.boot.default_entry
            else
                base.boot.default_entry,
            .entries = if (override.boot.entries.items.len > 0)
                override.boot.entries
            else
                base.boot.entries,
            .pxe_enabled = override.boot.pxe_enabled,
            .http_boot = override.boot.http_boot,
        },
        .security = override.security,
        .network = override.network,
        .debug = override.debug,
    };
}

fn applyHardwareConfig(config: *BootConfig) void {
    // get hardware-specific configuration
    const hw = hw_config.getConfig();

    // apply platform-specific defaults
    switch (hw.platform) {
        .x86 => {
            if (config.boot.timeout == 0) {
                config.boot.timeout = 3;
            }
            config.security.tpm_required = tpm_available;
        },
        .arm => {
            if (config.boot.timeout == 0) {
                config.boot.timeout = 5;
            }
            config.security.tpm_required = false;
        },
        .riscv => {
            if (config.boot.timeout == 0) {
                config.boot.timeout = 4;
            }
            config.security.tpm_required = false;
        },
        else => {},
    }
}

fn validateConfig(config: *BootConfig) bool {
    // validate boot entries
    if (config.boot.entries.items.len == 0) {
        std.debug.print("No boot entries configured\n", .{});
        return false;
    }

    // validate default entry exists
    var found_default = false;
    for (config.boot.entries.items) |entry| {
        if (std.mem.eql(u8, entry.name,
        config.boot.default_entry)) {
            found_default = true;
            break;
        }
    }

    if (!found_default) {
        std.debug.print("Default boot entry not found\n", .{});
        return false;
    }

    // validate security settings
    if (config.security.tpm_required && !tpm_available) {
        std.debug.print("TPM required but not available\n", .{});
        return false;
    }

    // validate network settings
    if (config.boot.pxe_enabled && !config.network.dhcp_enabled)
{
        std.debug.print("PXE enabled but DHCP disabled\n", .{});
        return false;
    }

    return true;
}

fn checkSecurityRequirements() void {
    secure_boot_enabled = boot_config.security.secure_boot;

    if (boot_config.security.measure_boot && tpm_available) {
        tpm2.measureBoot();
    }

    if (boot_config.security.tpm_required && !tpm_available) {
        panic.panic("TPM required but not available", .{});
    }
}

fn initFilesystem() void {
    // initialize filesystem drivers
    fat32.init();
    btrfs.init();
    exfat.init();
    ext4.init();
    ntfs.init();
    zfs.init();

    // mount filesystem images
    const fs_data = fs_images.getImage();
    if (!zfs.mount(fs_data)) {
        std.debug.print("Failed to mount ZFS image\n", .{});
    }

    // try to mount disk filesystems
    #ifdef X86
        if (!fat32.mountDisk(0)) {
            std.debug.print("Failed to mount FAT32 disk\n", .{});
        }
        if (!exfat.mountDisk(0)) {
            std.debug.print("Failed to mount exFAT disk\n", .{});
        }
        if (!btrfs.mountDisk(0)) {
            std.debug.print("Failed to mount btrfs disk\n", .{});
        }
        if (!ntfs.mountDisk(0)) {
            std.debug.print("Failed to mount NTFS disk\n", .{});
        }
        if (!ext4.mountDisk(1)) {
            std.debug.print("Failed to mount ext4 disk\n", .{});
        }
    #endif
}

fn initNetwork() bool {
    // initialize network stack
    if (!dhcp.init()) {
        std.debug.print("DHCP initialization failed\n", .{});
        return false;
    }

    // initialize network protocols
    quic.init();
    tftp.init();
    http.init();

    // initialize PXE if enabled
    if (boot_config.boot.pxe_enabled) {
        if (!pxe.init()) {
            std.debug.print("PXE initialization failed\n", .{});
            return false;
        }
    }

    return true;
}

fn initUI() void {
    // initialize terminal
    ghostty.init();

    // load fonts
    const font_data = fonts.getFonts();
    if (!ghostty.loadFonts(font_data)) {
        std.debug.print("Font loading failed\n", .{});
    }

    // load themes
    const theme_data = themes.getThemes();
    if (!tui.loadThemes(theme_data)) {
        std.debug.print("Theme loading failed\n", .{});
    }

    // initialize TUI
    tui.init();

    // set up UI components
    setupUI();
}

fn setupUI() void {
    // create main window
    tui.createWindow(.{
        .title = "ZigBoot",
        .x = 0,
        .y = 0,
        .width = 80,
        .height = 24,
    });

    // create boot menu
    tui.createList(.{
        .id = "boot_menu",
        .x = 2,
        .y = 2,
        .width = 76,
        .height = 18,
        .items = &boot_config.boot.entries.items,
        .selected = 0,
    });

    // create status bar
    tui.createStatusBar(.{
        .id = "status",
        .y = 22,
        .text = "Use arrow keys to select, Enter to boot, 'c' forcommand line",
    });

    // create help bar
    tui.createHelpBar(.{
        .id = "help",
        .y = 23,
        .text = "F1: Help  F2: Config  F3: Network  F10: Reboot",
    });
}

fn runBootloader() !void {
    // display boot menu
    displayBootMenu();

    // Wait for user input or timeout
    const selection = waitForSelection(boot_config.boot.timeout) catch |err| {
        panic.panic("Failed to get user selection", .{err});
    };

    // boot the selected entry
    bootSelectedEntry(selection);
}

fn displayBootMenu() void {
    // clear screen
    tui.clear();

    // display header
    tui.printAt(2, 0, "ZigBoot v1.0 - Boot Menu", .{});

    // display boot entries
    for (boot_config.boot.entries.items, 0..) |entry, i| {
        const prefix = if (std.mem.eql(u8, entry.name, boot_config.boot.default_entry)) "* " else "  ";
        tui.printAt(2, i + 2, "{s}{d}. {s}", .{prefix, i + 1, entry.name});
    }

    // display instructions
    tui.printAt(2, 20, "Use arrow keys to select, Enter to boot, 'c' for command line", .{});
}

fn waitForSelection(timeout: u32) !usize {
    const start_time = time.timestamp();
    current_selection = 0;

    // find default entry index
    var default_index: usize = 0;
    for (boot_config.boot.entries.items, 0..) |entry, i| {
        if (std.mem.eql(u8, entry.name,
    boot_config.boot.default_entry)) {
            default_index = i;
            break;
        }
    }

    current_selection = default_index;
    updateSelectionDisplay(current_selection);

    while (true) {
        // check for timeout
        const current_time = time.timestamp();
        if (current_time - start_time >= timeout * 1000) {
            return current_selection;
        }

        // check for input
        if (tui.hasInput()) {
            const key = tui.getKey();

            switch (key) {
                .up => {
                    if (current_selection > 0) {
                        current_selection -= 1;

updateSelectionDisplay(current_selection);
                    }
                },
                .down => {
                    if (current_selection < boot_config.boot.entries.items.len - 1) {
                        current_selection += 1;

updateSelectionDisplay(current_selection);
                    }
                },
                .enter => {
                    return current_selection;
                },
                .c => {
                    // enter command line mode
                    return commandLineMode();
                },
                .f1 => {
                    showHelp();
                },
                .f2 => {
                    showConfig();
                },
                .f3 => {
                    showNetworkStatus();
                },
                .f10 => {
                    rebootSystem();
                },
                else => {},
            }
        }

        // small delay to prevent CPU hogging
        time.sleep(100); // 100ms
    }
}

fn updateSelectionDisplay(selection: usize) void {
    // clear previous selection
    for (boot_config.boot.entries.items, 0..) |_, i| {
        tui.printAt(2, i + 2, "  ", .{});
    }

    // show new selection
    tui.printAt(2, selection + 2, "> ", .{});
}

fn commandLineMode() !usize {
    tui.printAt(0, 22, "ZigBoot> ", .{});

    var input = std.ArrayList(u8).init(allocator);
    defer input.deinit();

    while (true) {
        const key = tui.getKey();

        switch (key) {
            .enter => {
                // process command
                const cmd = mem.dupe(u8, allocator, input.items);
                const result = processCommand(cmd);
                allocator.free(cmd);

                if (result == .boot) {
                    // return to boot menu with last selection
                    return current_selection;
                } else if (result == .reboot) {
                    rebootSystem();
                } else if (result == .shutdown) {
                    shutdownSystem();
                } else if (result == .recovery) {
                    enterRecoveryMode();
                }

                // clear input and show prompt again
                input.items = std.ArrayList(u8).init(allocator);
                tui.printAt(0, 22, "ZigBoot> ", .{});
            },
            .backspace => {
                if (input.items.len > 0) {
                    input.pop();
                    tui.printAt(9 + input.items.len, 22, " \b", .{});
                }
            },
            .char => |c| {
                try input.append(c);
                tui.printAt(9 + input.items.len - 1, 22, "{c}", .{c});
            },
            else => {},
        }
    }
}

fn processCommand(cmd: []const u8) CommandResult {
    // parse command
    const parts = std.mem.splitSequence(u8, cmd, " ");
    if (parts.len == 0) return .unknown;

    const command = parts[0];

    if (std.mem.eql(u8, command, "boot")) {
        if (parts.len < 2) {
            tui.printAt(0, 23, "Usage: boot <entry>", .{});
            return .unknown;
        }

        // find entry by name or number
        const entry = parts[1];
        if (std.mem.isDigit(entry[0])) {
            // numeric selection
            const num = std.fmt.parseInt(usize, entry, 10) catch |err| {
                tui.printAt(0, 23, "Invalid entry number: {s}", .{err});
                return .unknown;
            };

            if (num >= 1 && num <=boot_config.boot.entries.items.len) {
                current_selection = num - 1;
                return .boot;
            } else {
                tui.printAt(0, 23, "Invalid entry number", .{});
                return .unknown;
            }
        } else {
            // name selection
            for (boot_config.boot.entries.items, 0..) |e, i| {
                if (std.mem.eql(u8, e.name, entry)) {
                    current_selection = i;
                    return .boot;
                }
            }

            tui.printAt(0, 23, "Entry not found: {s}", .{entry});
            return .unknown;
        }
    } else if (std.mem.eql(u8, command, "reboot")) {
        return .reboot;
    } else if (std.mem.eql(u8, command, "shutdown")) {
        return .shutdown;
    } else if (std.mem.eql(u8, command, "recovery")) {
        return .recovery;
    } else if (std.mem.eql(u8, command, "help")) {
        tui.printAt(0, 23, "Available commands: boot, reboot, shutdown, recovery, help", .{});
        return .unknown;
    } else if (std.mem.eql(u8, command, "network")) {
        if (parts.len < 2) {
            tui.printAt(0, 23, "Usage: network <command>", .{});
            return .unknown;
        }

        const subcmd = parts[1];
        if (std.mem.eql(u8, subcmd, "dhcp")) {
            if (!network_initialized) {
                network_initialized = initNetwork();
                if (network_initialized) {
                    tui.printAt(0, 23, "Network initialized", .{});
                } else {
                    tui.printAt(0, 23, "Network initialization failed", .{});
                }
            } else {
                tui.printAt(0, 23, "Network already initialized", .{});
            }
        } else if (std.mem.eql(u8, subcmd, "status")) {
            showNetworkStatus();
        } else {
            tui.printAt(0, 23, "Unknown network command: {s}", .{subcmd});
        }
        return .unknown;
    } else {
        tui.printAt(0, 23, "Unknown command: {s}", .{command});
        return .unknown;
    }
}

fn showHelp() void {
    tui.clear();
    tui.printAt(2, 0, "ZigBoot Help", .{});
    tui.printAt(2, 2, "Arrow keys: Navigate boot menu", .{});
    tui.printAt(2, 3, "Enter: Boot selected entry", .{});
    tui.printAt(2, 4, "c: Command line mode", .{});
    tui.printAt(2, 5, "F1: This help", .{});
    tui.printAt(2, 6, "F2: Show configuration", .{});
    tui.printAt(2, 7, "F3: Network status", .{});
    tui.printAt(2, 8, "F10: Reboot", .{});
    tui.printAt(2, 10, "Press any key to continue...", .{});
    tui.getKey();
    displayBootMenu();
}

fn showConfig() void {
    tui.clear();
    tui.printAt(2, 0, "ZigBoot Configuration", .{});
    tui.printAt(2, 2, "Boot Timeout: {d} seconds", .{boot_config.boot.timeout});
    tui.printAt(2, 3, "Default Entry: {s}", .{boot_config.boot.default_entry});
    tui.printAt(2, 4, "Secure Boot: {s}", .{if (boot_config.security.secure_boot) "Enabled" else "Disabled"});
    tui.printAt(2, 5, "TPM Required: {s}", .{if (boot_config.security.tpm_required) "Yes" else "No"});
    tui.printAt(2, 6, "DHCP Enabled: {s}", .{if (boot_config.network.dhcp_enabled) "Yes" else "No"});
    tui.printAt(2, 7, "PXE Enabled: {s}", .{if (boot_config.boot.pxe_enabled) "Yes" else "No"});
    tui.printAt(2, 8, "HTTP Boot: {s}", .{if (boot_config.boot.http_boot) "Yes" else "No"});
    tui.printAt(2, 10, "Press any key to continue...", .{});
    tui.getKey();
    displayBootMenu();
}

fn showNetworkStatus() void {
    tui.clear();
    tui.printAt(2, 0, "Network Status", .{});

    if (!network_initialized) {
        tui.printAt(2, 2, "Network not initialized", .{});
    } else {
        const ip = dhcp.getIP();
        const mask = dhcp.getNetmask();
        const gateway = dhcp.getGateway();
        const dns = dhcp.getDNS();

        tui.printAt(2, 2, "IP Address: {s}", .{ip});
        tui.printAt(2, 3, "Netmask: {s}", .{mask});
        tui.printAt(2, 4, "Gateway: {s}", .{gateway});
        tui.printAt(2, 5, "DNS: {s}", .{dns});
        tui.printAt(2, 7, "Network protocols:", .{});
        tui.printAt(4, 8, "DHCP: {s}", .{if (dhcp.isActive()) "Active" else "Inactive"});
        tui.printAt(4, 9, "TFTP: {s}", .{if (tftp.isActive()) "Active" else "Inactive"});
        tui.printAt(4, 10, "HTTP: {s}", .{if (http.isActive()) "Active" else "Inactive"});
        tui.printAt(4, 11, "QUIC: {s}", .{if (quic.isActive()) "Active" else "Inactive"});
        tui.printAt(4, 12, "PXE: {s}", .{if (pxe.isActive()) "Active" else "Inactive"});
    }

    tui.printAt(2, 14, "Press any key to continue...", .{});
    tui.getKey();
    displayBootMenu();
}

fn bootSelectedEntry(selection: usize) !void {
    const entry = boot_config.boot.entries.items[selection];

    // display boot message
    tui.clear();
    tui.printAt(2, 0, "Booting {s}...", .{entry.name});

    // verify boot image
    if (!verifyBootImage(entry)) {
        panic.panic("Boot image verification failed", .{});
    }

    // load kernel and initrd
    var kernel: []const u8 = undefined;
    var initrd: ?[]const u8 = null;

    if (entry.local) {
        kernel = loadLocalKernel(entry.path) catch |err| {
            panic.panic("Failed to load kernel", .{err});
        };

        if (entry.initrd.len > 0) {
            initrd = loadLocalInitrd(entry.initrd) catch |err| {
                panic.panic("Failed to load initrd", .{err});
            };
        }
    } else if (entry.pxe) {
        kernel = loadPXEKernel(entry.path) catch |err| {
            panic.panic("Failed to load PXE kernel", .{err});
        };

        if (entry.initrd.len > 0) {
            initrd = loadPXEInitrd(entry.initrd) catch |err| {
                panic.panic("Failed to load PXE initrd", .{err});
            };
        }
    } else if (entry.http) {
        kernel = loadHTTPKernel(entry.path) catch |err| {
            panic.panic("Failed to load HTTP kernel", .{err});
        };

        if (entry.initrd.len > 0) {
            initrd = loadHTTPInitrd(entry.initrd) catch |err| {
                panic.panic("Failed to load HTTP initrd",
.{err});
            };
        }
    } else {
        panic.panic("Unknown boot source", .{});
    }

    // Prepare boot parameters
    const boot_params = BootParams{
        .kernel = kernel,
        .kernel_args = entry.args,
        .initrd = initrd,
        .secure_boot = boot_config.security.secure_boot,
    };

    // hand off to boot protocol
    boot.bootKernel(boot_params) catch |err| {
        panic.panic("Boot failed", .{err});
    };
}

fn verifyBootImage(entry: BootEntry) bool {
    // for local files
    if (entry.local) {
        // verify signature if secure boot is enabled
        if (boot_config.security.secure_boot) {
            const kernel = fs.readFile(entry.path) catch |err| {
                std.debug.print("Failed to read kernel: {s}\n", .{err});
                return false;
            };
            defer allocator.free(kernel);

            const signature = fs.readFile(entry.path ++ ".sig") catch |err| {
                std.debug.print("Failed to read signature: {s}\n", .{err});
                return false;
            };
            defer allocator.free(signature);

            // get public key
            const pub_key = keys.getRsaPublicKey();

            // verify signature
            if (!rsa.verify(kernel, signature, pub_key)) {
                std.debug.print("Signature verification failed\n", .{});
                return false;
            }
        }

        return true;
    }
    // for network files, verification happens during download
    return true;
}

fn loadLocalKernel(path: []const u8) ![]const u8 {
    return fs.readFile(path) catch |err| {
        return error.KernelLoadError;
    };
}

fn loadLocalInitrd(path: []const u8) ![]const u8 {
    return fs.readFile(path) catch |err| {
        return error.InitrdLoadError;
    };
}

fn loadPXEKernel(path: []const u8) ![]const u8 {
    if (!network_initialized) {
        network_initialized = initNetwork();
        if (!network_initialized) {
            return error.NetworkNotInitialized;
        }
    }

    return pxe.loadFile(path) catch |err| {
        return error.PXELoadError;
    };
}

fn loadPXEInitrd(path: []const u8) ![]const u8 {
    if (!network_initialized) {
        network_initialized = initNetwork();
        if (!network_initialized) {
            return error.NetworkNotInitialized;
        }
    }

    return pxe.loadFile(path) catch |err| {
        return error.PXELoadError;
    };
}

fn loadHTTPKernel(path: []const u8) ![]const u8 {
    if (!network_initialized) {
        network_initialized = initNetwork();
        if (!network_initialized) {
            return error.NetworkNotInitialized;
        }
    }

    return http.get(path) catch |err| {
        return error.HTTPLoadError;
    };
}

fn loadHTTPInitrd(path: []const u8) ![]const u8 {
    if (!network_initialized) {
        network_initialized = initNetwork();
        if (!network_initialized) {
            return error.NetworkNotInitialized;
        }
    }

    return http.get(path) catch |err| {
        return error.HTTPLoadError;
    };
}

fn enterRecoveryMode() !void {
    tui.clear();
    tui.printAt(2, 0, "Recovery Mode", .{});
    tui.printAt(2, 2, "1. Reset configuration to defaults", .{});
    tui.printAt(2, 3, "2. Verify filesystem integrity", .{});
    tui.printAt(2, 4, "3. Network diagnostics", .{});
    tui.printAt(2, 5, "4. Memory test", .{});
    tui.printAt(2, 6, "5. Return to boot menu", .{});
    tui.printAt(2, 8, "Select an option: ", .{});

    while (true) {
        const key = tui.getKey();
        if (key == .char) |c| {
            switch (c) {
                '1' => {
                    resetConfig();
                    tui.printAt(2, 10, "Configuration reset.
Rebooting...", .{});
                    time.sleep(2000);
                    rebootSystem();
                },
                '2' => {
                    verifyFilesystem();
                },
                '3' => {
                    networkDiagnostics();
                },
                '4' => {
                    memoryTest();
                },
                '5' => {
                    displayBootMenu();
                    return;
                },
                else => {},
            }
        }
    }
}

fn resetConfig() void {
    // reset to default configuration
    boot_config = loadConfiguration() catch |err| {
        panic.panic("Failed to reset configuration", .{err});
    };
}

fn verifyFilesystem() void {
    tui.clear();
    tui.printAt(2, 0, "Filesystem Verification", .{});

    // verify ZFS image
    if (zfs.verify()) {
        tui.printAt(2, 2, "ZFS image: OK", .{});
    } else {
        tui.printAt(2, 2, "ZFS image: CORRUPT", .{});
    }

    // verify disk filesystems
    #ifdef X86
        if (fat32.verify(0)) {
            tui.printAt(2, 3, "FAT32 disk: OK", .{});
        } else {
            tui.printAt(2, 3, "FAT32 disk: CORRUPT", .{});
        }
        if (exfat.verify(0)) {
            tui.printAt(2, 3, "exFAT disk: OK", .{});
        } else {
            tui.printAt(2, 3, "exFAT disk: CORRUPT", .{});
        }
        if (btrfs.verify(0)) {
            tui.printAt(2, 3, "btrfs disk: OK", .{});
        } else {
            tui.printAt(2, 3, "btrfs disk: CORRUPT", .{});
        }
        if (NTFS.verify(0)) {
            tui.printAt(2, 3, "NTFS disk: OK", .{});
        } else {
            tui.printAt(2, 3, "NTFS disk: CORRUPT", .{});
        }

        if (ext4.verify(1)) {
            tui.printAt(2, 4, "ext4 disk: OK", .{});
        } else {
            tui.printAt(2, 4, "ext4 disk: CORRUPT", .{});
        }
    #endif

    tui.printAt(2, 6, "Press any key to continue...", .{});
    tui.getKey();
    enterRecoveryMode();
}

fn networkDiagnostics() void {
    tui.clear();
    tui.printAt(2, 0, "Network Diagnostics", .{});

    if (!network_initialized) {
        tui.printAt(2, 2, "Network not initialized", .{});
        tui.printAt(2, 4, "Press any key to continue...", .{});
        tui.getKey();
        enterRecoveryMode();
        return;
    }

    // test DHCP
    tui.printAt(2, 2, "Testing DHCP...", .{});
    if (dhcp.test()) {
        tui.printAt(2, 2, "DHCP: OK", .{});
    } else {
        tui.printAt(2, 2, "DHCP: FAILED", .{});
    }

    // test TFTP
    tui.printAt(2, 3, "Testing TFTP...", .{});
    if (tftp.test()) {
        tui.printAt(2, 3, "TFTP: OK", .{});
    } else {
        tui.printAt(2, 3, "TFTP: FAILED", .{});
    }

    // test HTTP
    tui.printAt(2, 4, "Testing HTTP...", .{});
    if (http.test()) {
        tui.printAt(2, 4, "HTTP: OK", .{});
    } else {
        tui.printAt(2, 4, "HTTP: FAILED", .{});
    }

    tui.printAt(2, 6, "Press any key to continue...", .{});
    tui.getKey();
    enterRecoveryMode();
}

fn memoryTest() void {
    tui.clear();
    tui.printAt(2, 0, "Memory Test", .{});
    tui.printAt(2, 2, "Running memory test...", .{});

    const result = mmio.testMemory();
    if (result) {
        tui.printAt(2, 3, "Memory test: PASSED", .{});
    } else {
        tui.printAt(2, 3, "Memory test: FAILED", .{});
    }

    tui.printAt(2, 5, "Press any key to continue...", .{});
    tui.getKey();
    enterRecoveryMode();
}

fn rebootSystem() !void {
    // platform-specific reboot
    #ifdef X86
        mmio.rebootX86();
    #elseif ARM
        mmio.rebootARM();
    #elseif RISCV
        mmio.rebootRISCV();
    #else
        panic.panic("Reboot not supported on this platform", .{});
    #endif
}

fn shutdownSystem() !void {
    // platform-specific shutdown
    #ifdef X86
        mmio.shutdownX86();
    #elseif ARM
        mmio.shutdownARM();
    #elseif RISCV
        mmio.shutdownRISCV();
    #else
        panic.panic("Shutdown not supported on this platform", .{});
    #endif
}

fn customPanicHandler(message: []const u8, context: anytype)
noret {
    // display panic message
    tui.clear();
    tui.printAt(2, 0, "*** ZIGBOOT PANIC ***", .{});
    tui.printAt(2, 2, "Message: {s}", .{message});

    // display context if available
    if (context) |ctx| {
        tui.printAt(2, 3, "Context: {any}", .{ctx});
    }

    // display stack trace if available
    #ifdef DEBUG
        tui.printAt(2, 5, "Stack trace:", .{});
        // platform-specific stack trace
        #ifdef X86
            mmio.printStackTraceX86();
        #elseif ARM
            mmio.printStackTraceARM();
        #elseif RISCV
            mmio.printStackTraceRISCV();
        #endif
    #endif

    // show recovery options
    tui.printAt(2, 10, "Press R to reboot or any other key for recovery shell", .{});

    const key = tui.getKey();
    if (key == .char) |c| {
        if (c == 'R' or c == 'r') {
            rebootSystem();
        } else {
            recoveryShell();
        }
    } else {
        recoveryShell();
    }
}

fn recoveryShell() !void {
    tui.clear();
    tui.printAt(2, 0, "Recovery Shell", .{});
    tui.printAt(2, 2, "Type 'help' for available commands", .{});

    while (true) {
        tui.printAt(2, 4, "> ", .{});

        var input = std.ArrayList(u8).init(allocator);
        defer input.deinit();

        while (true) {
            const key = tui.getKey();

            switch (key) {
                .enter => {
                    const cmd = mem.dupe(u8, allocator, input.items);
                    processRecoveryCommand(cmd);
                    allocator.free(cmd);
                    break;
                },
                .backspace => {
                    if (input.items.len > 0) {
                        input.pop();
                        tui.printAt(4 + input.items.len, 4, " \b", .{});
                    }
                },
                .char => |c| {
                    try input.append(c);
                    tui.printAt(4 + input.items.len - 1, 4, "{c}", .{c});
                },
                else => {},
            }
        }
    }
}

fn processRecoveryCommand(cmd: []const u8) void {
    const parts = std.mem.splitSequence(u8, cmd, " ");
    if (parts.len == 0) return;

    const command = parts[0];

    if (std.mem.eql(u8, command, "help")) {
        tui.printAt(2, 6, "Available commands:", .{});
        tui.printAt(2, 7, "  help       - Show this help", .{});
        tui.printAt(2, 8, "  reboot     - Reboot the system", .{});
        tui.printAt(2, 9, "  shutdown   - Shutdown the system", .{});
        tui.printAt(2, 10, "  config     - Show configuration", .{});
        tui.printAt(2, 11, "  network    - Network diagnostics", .{});
        tui.printAt(2, 12, "  memory     - Memory test", .{});
        tui.printAt(2, 13, "  fs         - Filesystem verification", .{});
    } else if (std.mem.eql(u8, command, "reboot")) {
        rebootSystem();
    } else if (std.mem.eql(u8, command, "shutdown")) {
        shutdownSystem();
    } else if (std.mem.eql(u8, command, "config")) {
        showConfig();
    } else if (std.mem.eql(u8, command, "network")) {
        networkDiagnostics();
    } else if (std.mem.eql(u8, command, "memory")) {
        memoryTest();
    } else if (std.mem.eql(u8, command, "fs")) {
        verifyFilesystem();
    } else {
        tui.printAt(2, 6, "Unknown command: {s}", .{command});
    }
}

// data structures
const BootEntry = struct {
    name: []const u8,
    path: []const u8,
    args: []const u8,
    initrd: []const u8,
    local: bool,
    pxe: bool,
    http: bool,
};

const BootConfig = struct {
    boot: struct {
        timeout: u32,
        default_entry: []const u8,
        entries: std.ArrayList(BootEntry),
        pxe_enabled: bool,
        http_boot: bool,
    },
    security: struct {
        secure_boot: bool,
        tpm_required: bool,
        measure_boot: bool,
    },
    network: struct {
        dhcp_enabled: bool,
        timeout: u32,
        http_boot: bool,
        pxe_server: []const u8,
    },
    debug: struct {
        serial_output: bool,
        recovery_mode: bool,
    },
};

const BootParams = struct {
    kernel: []const u8,
    kernel_args: []const u8,
    initrd: ?[]const u8,
    secure_boot: bool,
};

const CommandResult = enum {
    unknown,
    boot,
    reboot,
    shutdown,
    recovery,
};

// error types
const Error = error{
    ConfigurationError,
    KernelLoadError,
    InitrdLoadError,
    NetworkNotInitialized,
    PXELoadError,
    HTTPLoadError,
    BootError,
};
```
