 **About**

'zBoot' short for 'Zig Boot' is a Proposed Unix Boot Control System written in Zig, designed to be **fast, secure, and flexible** without forcing trade-offs between functionality, security and reliability. While existing bootmanager/loaders like GRUB and systemd-boot serve their purpose, what they lack is an easy to use implimentations of modern security features, hardware-aware system prep, and seamless integration with encrypted systems that we aim to provide in zBoot. While rEFInd & u-boot do a great job where the others fail, zBoot is aiming at taking the booting experience to a whole new level.

zBoot aims to provide a **better default experience** by:
- **A live environment to fall back into** In the event of a crash, you'll have a full access to all files & a network connection to search and replace corrupted files via **ghostty**. 
- **Detecting hardware** providing a complete system map & preloaded drivers to the operating systems in a 'well documented' easy to follow flow.
- **Guided user experience** Providing kernel selection, Linux &/or BSD, Guided best practice in file creation, manipulation, security & maintenance along with desktop settings-long term, could improve the entire UNIX-Like experience for coders, sysadmin & users alike. 
- **System security** zBoots main branch to be downloaded prior to operating systems, allowing an immutable fall back, with files & settings intact. Operating systemn, Kernals & desktop environments to be made down or side loadable, searchable and installable from within zBoots UI. All system operations do so in levels above zBoot with little to no access to zBoot, providing an immutable isolation layer & multiplying your security exponentially     
- **Encouraging secure partitioning** as the standard to protect user data loss in the event of system crashes.
- **Eliminating password fatigue** by leveraging cryptographically secured pysical USB keys like YubiKey below the operating system level with full drive by drive disk encryption & site by site integration, with passwords managed throughout the entire uptime, when removed the entire system is encrypted.   
- **Aiming to replace display managers** "long term goal", streamlining the boot-to-desktop process allowing kernal developers to focus on their kernals & designers to focus on designing while we take care of the less glamorous side.
- **moving towards a full featured system** "zBoot aims to grow into a fully fledged 'build your own system'", in saying that, zBoot MUST always remain available in a 'server edition' for industrial puropses & those requiring a micro loader/manager.     

For wearable screens to be useful, they need to last time! Linked to your home PC with GPU doing the heavy lifting, glasses running ghostty in zBoot could potentially be the
answer for text based comms. We may need to add include wayland for GUI support on mobile devices, "though have you tried 'Brow6el'?"

Inspired by **Andrew Kelley’s work on Zig** and **Mitchell Hashimoto’s Ghostty** zBoot seeks to modernise the boot process without sacrificing the stability we rely on.

While not claiming to be the *fastest* or *most feature-rich* , zBoot aims first & foremost to provide a solid booting experience including "server standard reliability" with the addition of **security & userbility features and seemless system prep**—without compromise.

Our goal is to make zBoot a **drop-in replacement** for traditional bootloaders while introducing opt-in features that improve security, recovery & userbility without breaking existing workflows.

- **zBoot is NOT assoiated with the creators of Zig, ziglang.org or entities betrothed within the Zig Foundation.**
  
- **"Not saying we don't want to be", just don't blame Zig if 'zBoot' breaks your system, that will be on us !**

**Manufacturers**-Our testing is restricted to the hardward we have access too. 

**Note to Manufacturers** - Testing will comence immediately post installation and continue throughout the lifetime of the machine. All code produced for your machines is yours to freely distribute without recognition for any rhyme nor reason. 

You will be provided with monthly documentation in the first year, quarterly thereafter throughout the lifetime of the machine. Due to the overheads & effort involved in conducting our testing, all machines sent in for testing become the property of the zboot foundation.  


Contact details 

**for Contributers**
buildr@zboot.org 

**for Manufacturers**
manu@zboot.org

**Contact Us**
muchlove@zboot.org

**Website & Foundation Details**
the 'todo' list


# Phase 1: Development Environment Setup


1. **Simple Project Structure - will evolve**
   ```
   boot-manager/
   ├── src/
   │   ├── main.zig
   │   ├── hardware/
   │   ├── drivers/
   │   ├── network/
   │   ├── bluetooth/
   │   ├── ui/
   │   └── auth/
   ├── build.zig
   ├── config/
   │   └── default.cfg
   └── docs/
   ```

2. **Create build.zig**


**Phase 2: Core System Implementation**

1. **Implement Basic Boot Manager Structure**
   - Create `src/main.zig` with the core framework
   - Implement the basic menu system
   - Add YubiKey authentication stubs

2. **Hardware Detection Layer**
   - Implement PCI bus enumeration (`src/hardware/pci.zig`)
   - Add USB controller detection (`src/hardware/usb.zig`)
   - Create storage device detection (`src/hardware/storage.zig`)

3. **Driver Management System**
   - Create driver loading framework (`src/drivers/manager.zig`)
   - Implement basic driver interface
   - Add driver dependency resolution

## Phase 3: Network Stack Implementation**

1. **Network Interface Detection**


2. **DHCP Client**


3. **Static IP Configuration**


## Phase 4: Bluetooth Support

1. **Bluetooth Controller Initialization**
 

2. **Device Management**


## Phase 5: User Interface with Ghostty

1. **Ghostty Integration**


2. **Menu System**


## Phase 6: Kernel Loading and Handoff

1. **Kernel Image Loading**
 

2. **Hardware State Preparation**
 

3. **Control Transfer**


## Phase 7: Testing and Debugging

1. **Unit Testing**


2. **Integration Testing**
   - Test in QEMU with virtual hardware
   - Test with real hardware in a safe environment

3. **Debugging Tools**
   - Add serial console output
   - Implement logging system
   - Add crash recovery

## Phase 8: Deployment

1. **Build for Target Platform**
 

2. **Create Bootable Image**
   - Combine with GRUB or other bootloader
   - Create ISO or disk image

3. **Installation**
   - Install to boot partition
   - Configure bootloader to use it

## Development Tips

1. **Incremental Development**
   - Start with basic menu system
   - Add hardware detection incrementally
   - Implement one subsystem at a time

2. **Use Existing Libraries**
   - Consider using `ziglyph` for terminal UI
   - Look for Zig network stack implementations
   - Use existing Bluetooth libraries if available

3. **Hardware Access**
   - Use `/dev/mem` for direct hardware access on Linux
   - Implement proper memory-mapped I/O
   - Handle different architectures (x86, ARM, RISC-V "Lets make it easy for new designers to test & build" )

4. **Security Considerations**
   - Verify all driver signatures
   - Implement secure boot if needed
   - Protect YubiKey authentication

5. **Performance Optimization**
   - Minimize memory usage
   - Optimize critical paths
   - Consider parallel initialization whenever possible


## Implementation Timeline "Ambitious Version"

| Week  | Focus Area                             |
| ----- | -------------------------------------- |
| 1-2   | Core framework, basic UI, YubiKey auth |
| 3-4   | Hardware detection (PCI, USB, storage) |
| 5-6   | Driver management system               |
| 7-8   | Network stack implementation           |
| 9-10  | Bluetooth support                      |
| 11-12 | Kernel loading and handoff             |
| 13-14 | Testing and debugging                  |
| 15-16 | Optimization and deployment            |


## Implimentation Timeline "Most Likely"

| Months| Focus Area                             |
| ----- | -------------------------------------- |
| 1-2   | Core framework, basic UI, YubiKey auth |
| 3-4   | Hardware detection (PCI, USB, storage) |
| 5-6   | Driver management system               |
| 7-8   | Network stack implementation           |
| 9-10  | Bluetooth support                      |
| 11-12 | Kernel loading and handoff             |
| 13-14 | Testing and debugging                  |
| 15-16 | Optimization and deployment            |

All rights Reserved yata yata yata, "DO WHAT EVER YOU WANT WITH IT" The best software is always free.

**muchLove**
brawijaya
zboot.org 

