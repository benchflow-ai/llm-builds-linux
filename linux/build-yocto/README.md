# Build Minimal Linux with Yocto/Poky

Build a minimal Linux image using the Yocto Project and Poky reference distribution.

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~4-6 hours (build time) |
| Sessions | 1 |
| Outcome | **SCAFFOLDED** - Build environment created but not executed |
| Difficulty | Hard |

## Task

Create production-ready Yocto/Poky build:
1. Set up Docker build environment
2. Configure for qemux86-64 target
3. Build core-image-minimal
4. Test with QEMU

## Status

**SCAFFOLDED ONLY** - The Docker environment and build scripts were created but the actual Yocto build was not executed. No artifacts are present in the output directory. Yocto builds typically take 2-6 hours and require 160GB+ disk space.

## Expected Results (if built)

- Complete Docker environment with 30+ dependencies
- Poky kirkstone (LTS) branch
- Optimized local.conf with shared state cache
- core-image-minimal builds successfully

## Files

```
artifacts/
├── Dockerfile    # Build environment (non-root user)
└── build.sh      # Complete build orchestration
```

## Quick Start

```bash
cd artifacts

# Full build (WARNING: Takes 2-6 hours)
./build.sh

# Test with QEMU
cd output
qemu-system-x86_64 \
  -kernel bzImage \
  -hda core-image-minimal-qemux86-64.ext4 \
  -append 'root=/dev/sda rw console=ttyS0' \
  -nographic -m 512
```

## Key Learnings

1. **Yocto is complex** - Steep learning curve but powerful
2. **Non-root required** - Yocto refuses to run as root
3. **Shared state cache** - Essential for reasonable rebuild times
4. **Long build times** - First build: 2-6 hours
5. **160GB+ disk needed** - Downloads + build artifacts
