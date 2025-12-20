# Build BusyBox Minimal Linux System

Build a minimal bootable Linux system using BusyBox as the userspace and init.

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~0.5 hours |
| Sessions | 1 |
| Outcome | **SUCCESS** - Minimal system boots in QEMU |
| Difficulty | Medium |

## Task

Create a minimal bootable Linux system using:
1. BusyBox compiled statically as the userspace
2. A simple init script
3. An initramfs containing the minimal root filesystem
4. Pre-built Linux kernel

## Results

- BusyBox 1.36.1 compiled statically with all standard utilities
- Minimal initramfs (~2MB compressed) with essential directories
- Custom init script mounting proc, sys, devtmpfs
- Boots successfully in QEMU with interactive shell

## Files

```
artifacts/
├── Dockerfile              # Ubuntu 22.04 build environment
└── build.sh                # Main orchestration script
trajectories/
└── SUMMARY.md              # Build narrative
```

## Quick Start

```bash
cd artifacts

# Build everything
chmod +x build.sh
./build.sh

# Test with QEMU
qemu-system-x86_64 \
  -kernel output/vmlinuz \
  -initrd output/initramfs.cpio.gz \
  -nographic \
  -append "console=ttyS0"

# Press Ctrl-A then X to exit QEMU
```

## Key Learnings

1. **Static linking essential** - BusyBox must be statically linked for initramfs
2. **Init script critical** - Must mount proc/sys/dev before anything works
3. **Device nodes needed** - /dev/console and /dev/null must exist for shell
4. **Minimal size achievable** - Complete userspace in ~2MB compressed
