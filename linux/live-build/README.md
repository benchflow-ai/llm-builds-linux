# Linux Distro Build with live-build

This experiment attempted to build a Linux Mint-based distribution using Debian's `live-build` toolchain.

## Overview

- **Agent:** Claude Opus 4.5
- **Outcome:** Partial success - Build infrastructure complete, blocked by live-config-upstart
- **Approach:** Docker + live-build + Cinnamon desktop

## Files

| Directory | Description |
|-----------|-------------|
| `mint-live-build/` | Complete live-build configuration |
| `mint-live-build/Dockerfile` | Build environment with syslinux fixes |
| `mint-live-build/config/` | Package lists and hooks |
| `trajectories/` | Agent session summaries and logs |

## Quick Start

```bash
cd mint-live-build

# Build Docker image
docker build --platform linux/amd64 -t monterrey-builder .

# Run build (currently blocked by upstart)
docker run --platform linux/amd64 --privileged --rm \
    -v "$(pwd)/output:/output" monterrey-builder
```

## Blocking Issue

```
E: Unable to locate package live-config-upstart
```

This package was replaced by systemd in modern Ubuntu. Fix requires switching to Debian mode.
