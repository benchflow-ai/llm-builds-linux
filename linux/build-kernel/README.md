# Build Linux Kernel from Source

Compile a Linux kernel from source and boot it in QEMU.

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~1 hour |
| Sessions | 1 |
| Outcome | **SUCCESS** - Kernel builds and boots |
| Difficulty | Hard |

## Task

Build Linux kernel from source (LFS-style):
1. Download kernel source from kernel.org
2. Configure for QEMU virtualization
3. Compile bzImage
4. Test boot in QEMU

## Results

- Linux 6.6.63 LTS kernel compiled
- Configured with QEMU/virtio support
- bzImage boots successfully
- Docker-based reproducible build

## Files

```
artifacts/
├── Dockerfile    # Build environment
└── build.sh      # Orchestration script
trajectories/
└── SUMMARY.md
```

## Quick Start

```bash
cd artifacts
chmod +x build.sh
./build.sh

# Combine with busybox initramfs to boot:
qemu-system-x86_64 \
  -kernel output/bzImage \
  -initrd ../build-busybox/artifacts/output/initramfs.cpio.gz \
  -nographic -append "console=ttyS0"
```

## Key Learnings

1. **Kernel build is deterministic** - With proper deps, builds reliably
2. **Defconfig works well** - Default config boots in QEMU
3. **Build time ~15-30 min** - Depends on CPU cores
4. **Size ~11MB** - bzImage for x86_64
