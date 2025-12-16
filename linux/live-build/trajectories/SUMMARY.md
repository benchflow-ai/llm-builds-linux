# Build Linux Distro with live-build - Agent Trajectory Summary

## Overview

This trajectory documents an AI agent's attempt to build a Linux Mint-based distribution using Debian's `live-build` toolchain. The approach focuses on creating a reproducible build system using Docker and live-build configuration.

**Agent:** Claude Opus 4.5
**Duration:** ~4 hours across multiple sessions
**Outcome:** Partial success - Build infrastructure complete, ISO creation blocked by live-config-upstart package error

## User Request

"can you build a linux distro? we can start from mintos" (interpreted as Linux Mint)

## Approach Chosen

After comprehensive research, agent chose **live-build** approach (Option B) over:
- Remastering (too simple for learning)
- Debootstrap from scratch (too complex)
- Linux From Scratch (not practical)

Rationale: live-build provides good balance of control, reproducibility, and maintainability.

## Key Steps Taken

### 1. Research Phase
- Analyzed Linux Mint architecture (Ubuntu Noble/24.04 base)
- Explored live-build documentation and configuration
- Identified key challenges: cross-platform builds, package selection, bootloader configuration

### 2. Environment Setup

Created `mint-live-build/` directory with:

```
mint-live-build/
├── Dockerfile           # Ubuntu 24.04 with live-build tools
├── build.sh            # Container build script
├── run-build.sh        # Host orchestration
├── auto/
│   ├── config          # live-build configuration
│   ├── build           # Build automation
│   └── clean           # Cleanup script
└── config/
    ├── hooks/          # Chroot customization hooks
    └── package-lists/  # Package selections
        ├── base.list.chroot
        ├── desktop.list.chroot
        └── xorg.list.chroot
```

### 3. Build Configuration

**auto/config** key settings:
- Distribution: Ubuntu Noble (24.04)
- Architecture: amd64
- Binary image: iso-hybrid
- Bootloaders: syslinux + grub-efi
- Compression: gzip
- Init system: systemd

**Package Lists:**
- Base: live-boot, firmware, core utilities, networking
- Desktop: Cinnamon, LightDM, Nemo file manager
- Applications: Firefox, LibreOffice, VLC, GIMP

### 4. Challenges Encountered

#### Challenge 1: Broken syslinux symlinks
**Problem:** Default live-build bootloaders have broken symlinks to old paths
**Solution:** Dockerfile copies correct binaries from modern locations:
```dockerfile
RUN cp /usr/lib/ISOLINUX/isolinux.bin "$ISOLINUX_DIR/isolinux.bin" && \
    cp /usr/lib/syslinux/modules/bios/*.c32 "$ISOLINUX_DIR/"
```

#### Challenge 2: gfxboot-theme-ubuntu missing
**Problem:** lb_binary_syslinux expects Ubuntu gfxboot theme package
**Solution:** Create dummy bootlogo tarball in build script:
```bash
mkdir -p "$GFXBOOT_DIR"
echo "en" > langlist
ls -1 | cpio --quiet -o > bootlogo
tar czf bootlogo.tar.gz bootlogo
```

#### Challenge 3: live-config-upstart unavailable
**Problem:** Build fails with "E: Unable to locate package live-config-upstart"
**Status:** BLOCKING - upstart was replaced by systemd in modern Ubuntu

### 5. Build Stages

1. **lb clean** - Clear previous build artifacts
2. **lb config** - Generate live-build configuration
3. **lb bootstrap** - Download base Ubuntu system via debootstrap
4. **lb chroot** - Install packages and run hooks
5. **lb binary** - Create bootable ISO with squashfs

## Artifacts Produced

| File | Lines | Description |
|------|-------|-------------|
| Dockerfile | 64 | Build environment with syslinux fixes |
| build.sh | 93 | 5-stage build with gfxboot workaround |
| run-build.sh | ~50 | Host-side Docker orchestration |
| auto/config | 25 | live-build core configuration |
| config/package-lists/*.list.chroot | 200+ | Package selections for full desktop |

## Metrics

| Metric | Value |
|--------|-------|
| Tool calls | ~200 |
| Files created | 12 |
| Lines of code | ~600 |
| Build attempts | 3+ |
| Docker layers | 30+ packages |
| Packages in ISO | ~300 (including Cinnamon DE) |

## Where Agent Succeeded

1. **Research depth** - Thorough analysis of build options with clear tradeoffs
2. **Docker configuration** - Proper cross-platform setup with syslinux fixes
3. **Package selection** - Comprehensive desktop environment configuration
4. **Error handling** - Good workarounds for gfxboot and symlink issues

## Where Agent Struggled

1. **live-config-upstart** - Couldn't resolve obsolete package dependency
2. **Build iteration time** - Long feedback loops (20+ minutes per attempt)
3. **live-build quirks** - Ubuntu mode has many undocumented requirements

## Blocking Issue

```
E: Unable to locate package live-config-upstart
```

This package doesn't exist in Ubuntu 24.04 (replaced by systemd). Requires:
- Switching to Debian mode instead of Ubuntu
- Or patching live-build configuration to skip upstart

## Lessons for Agent Evaluation

1. **live-build has poor error messages** - Failures surface late in build
2. **Ubuntu mode is problematic** - Many packages/themes are Ubuntu-specific
3. **Build time is a bottleneck** - 20-30 min builds make iteration slow
4. **Deprecated package references** - Tools reference obsolete packages

## Reproduction Steps

```bash
cd monterrey/mint-live-build

# Build Docker image
docker build --platform linux/amd64 -t monterrey-builder .

# Run build (will fail at live-config-upstart currently)
docker run --platform linux/amd64 --privileged --rm \
    -v "$(pwd)/output:/output" monterrey-builder
```

## Next Steps (if continuing)

1. Switch to `--mode debian` instead of Ubuntu
2. Replace live-config with live-config-systemd
3. Remove gfxboot workaround (not needed for Debian mode)
4. Test ISO boot in QEMU
