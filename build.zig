//DO NOT USE Just a start 

```zig
const std = @import("std");
const Builder = std.build.Builder;
const BuildMode = std.build.Mode;
const InstallMode = std.build.InstallMode;
const OptimizationMode = std.builtin.OptimizeMode;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create executable
    const exe = b.addExecutable(.{
        .name = "zigboot",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add all source files
    exe.addPackage(.{
        .name = "core",
        .path = "src/core",
    });
    exe.addPackage(.{
        .name = "hardware",
        .path = "src/hardware",
    });
    exe.addPackage(.{
        .name = "net",
        .path = "src/net",
    });
    exe.addPackage(.{
        .name = "fs",
        .path = "src/fs",
    });
    exe.addPackage(.{
        .name = "crypto",
        .path = "src/crypto",
    });
    exe.addPackage(.{
        .name = "configs",
        .path = "src/configs",
    });
    exe.addPackage(.{
        .name = "user",
        .path = "src/user",
    });
    exe.addPackage(.{
        .name = "terminal",
        .path = "src/terminal",
    });
    exe.addPackage(.{
        .name = "zsets",
        .path = "src/zsets",
    });
    exe.addPackage(.{
        .name = "block",
        .path = "src/block",
    });
    exe.addPackage(.{
        .name = "raid",
        .path = "src/raid",
    });
    exe.addPackage(.{
        .name = "server",
        .path = "src/server",
    });

    // Add dependencies if needed
    // exe.linkLibC();
    // exe.linkSystemLibrary("m"); 
    // For math functions if needed

    // Set build options based on mode
    if (b.args) |args| {
        if (args.containsSlice(u8, "-Drelease")) {
            exe.setBuildMode(.Release);
            exe.setTarget(.{ .cpu_arch = target.cpu_arch, .os_tag = target.os_tag });
            exe.setOptimize(OptimizationMode.ReleaseFast);
        } else if (args.containsSlice(u8, "-Ddebug")) {
            exe.setBuildMode(.Debug);
            exe.setOptimize(OptimizationMode.Debug);
        } else {
            exe.setBuildMode(.Dev);
            exe.setOptimize(OptimizationMode.Debug);
        }
    }

    // Install step
    const install = b.addInstallArtifact(exe);
    if (b.args) |args| {
        if (args.containsSlice(u8, "-Dinstall")) {
            install.setDestination(.{ .dir = "zigboot" });
        }
    }

    // Test step
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    tests.addPackage(.{ .name = "core", .path = "src/core" });
    // Add other packages as needed for tests

    // Run step
    const run_cmd = exe.addRunArtifact();
    run_cmd.step.dependOn(b.getInstallStep());

    // Add custom build steps if needed
    // For example, generating config files or other build-time operations

    // Set default step
    const run_step = b.step("run", "Run the bootloader");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests.step);

    const install_step = b.step("install", "Install the bootloader");
    install_step.dependOn(&install.step);

    // Default build step
    const build_step = b.step("build", "Build the bootloader");
    build_step.dependOn(&exe.step);

    // Set default step based on arguments
    if (b.args) |args| {
        if (args.containsSlice(u8, "run")) {
            b.default_step = run_step;
        } else if (args.containsSlice(u8, "test")) {
            b.default_step = test_step;
        } else if (args.containsSlice(u8, "install")) {
            b.default_step = install_step;
        } else {
            b.default_step = build_step;
        }
    } else {
        b.default_step = build_step;
    }
}
```
