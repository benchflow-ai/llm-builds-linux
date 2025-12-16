# Linux Distro Build with Debootstrap

This experiment attempted to build a bootable Linux distribution from scratch using the `debootstrap` approach.

## Overview

- **Agent:** Claude Opus 4.5
- **Outcome:** Partial success - ISO builds, UEFI testing incomplete
- **Approach:** Docker + debootstrap + squashfs + GRUB

## Files

| File | Description |
|------|-------------|
| `Dockerfile` | Build environment (Ubuntu 22.04, amd64) |
| `build.sh` | Host orchestration script |
| `build-scripts/build-mint-distro.sh` | Core 8-stage debootstrap build |
| `build-scripts/remaster-mint.sh` | Alternative remastering approach |
| `live-build-config/` | Partial live-build configuration |
| `trajectories/` | Agent session summaries and logs |

## Quick Start

```bash
# Build with Docker
BUILD_MODE=scratch ./build.sh

# Test the ISO
qemu-system-x86_64 -m 2048 -cdrom output/CustomMint-1.0-amd64.iso
```

## Key Learnings

1. Platform awareness critical (ARM vs AMD64)
2. Long-horizon tasks require context maintenance
3. QEMU on macOS has UEFI emulation limitations
