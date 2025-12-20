# Build Alpine Linux

Build a minimal Alpine Linux system with musl libc.

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~1 hour |
| Sessions | 1 |
| Outcome | **IN_PROGRESS** - Experiment setup |
| Difficulty | Medium |

## Task

Build a minimal Alpine Linux system featuring:
1. Alpine's musl-based userspace
2. OpenRC init system
3. Bootable disk image with GRUB
4. QEMU testing

## Why Alpine?

Alpine Linux uses musl libc instead of glibc, making it:
- Much smaller (~5MB base vs ~200MB for Debian)
- Different linking behavior
- BusyBox-based utilities by default
- Popular for containers and embedded systems

## Results

- Alpine 3.19 rootfs created
- 1GB bootable disk image
- GRUB bootloader installed
- OpenRC as init system

## Files

```
artifacts/
├── Dockerfile        # Alpine-based build environment
├── build.sh          # Orchestration script
└── build-scripts/    # Helper scripts
trajectories/
└── SUMMARY.md        # Build narrative
```

## Quick Start

```bash
cd artifacts

# Build Docker image
./build.sh --build-image

# Create bootable disk image
./build.sh --build-bootable

# Test with QEMU
./build.sh --test

# Or do everything
./build.sh --all
```

## Key Differences from Debian/Ubuntu

1. **Package manager**: `apk` instead of `apt`
2. **Init system**: OpenRC instead of systemd
3. **C library**: musl instead of glibc
4. **Shell**: ash (BusyBox) instead of bash by default

## Key Learnings

1. **alpine-make-rootfs** - Official tool for creating rootfs
2. **musl compatibility** - Some software needs recompilation
3. **Smaller images** - ~100MB bootable vs ~500MB+ for Debian

## Common Failure Points

1. **Missing kernel** - Need `linux-virt` package for QEMU
2. **initramfs generation** - `mkinitfs` required
3. **GRUB installation** - Different from Debian process
4. **apk caching** - Requires network during build
