# Build Linux Distro with Debootstrap

Build a bootable Linux distribution from scratch using `debootstrap`.

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~2 hours |
| Sessions | 2 |
| Outcome | **PARTIAL** - ISO builds, UEFI testing incomplete |
| Difficulty | Hard |

## Task

Build a custom Linux distribution based on Linux Mint, starting from "live build a linux distro" prompt.

## Results

- Created Docker-based build environment (Ubuntu 22.04, amd64)
- Developed 8-stage build pipeline using debootstrap
- Successfully solved cross-platform build (macOS ARM to Linux AMD64)
- ISO creation works, UEFI boot testing incomplete

## Files

```
artifacts/
├── Dockerfile                    # Build environment
├── build.sh                      # Host orchestration
├── build-scripts/
│   ├── build-mint-distro.sh     # Core 8-stage build (284 lines)
│   └── remaster-mint.sh         # Alternative approach
└── live-build-config/           # Partial config
trajectories/
├── SUMMARY.md                   # Detailed trajectory
└── session-build.jsonl          # Session log
```

## Quick Start

```bash
cd artifacts
BUILD_MODE=scratch ./build.sh

# Test the ISO
qemu-system-x86_64 -m 2048 -cdrom output/CustomMint-1.0-amd64.iso
```

## Key Learnings

1. **Platform awareness critical** - ARM64 vs AMD64 incompatibility caught late
2. **Long-horizon tasks are hard** - 8+ stages require context maintenance
3. **Error recovery is weak** - Build failures hard to diagnose
4. **QEMU on macOS** has UEFI emulation limitations
