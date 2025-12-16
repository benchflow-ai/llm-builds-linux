# Build Linux Distro from Scratch - Agent Trajectory Summary

## Overview

This trajectory documents an AI agent's attempt to build a bootable Linux distribution from scratch, starting from a user request to "live build a linux distro" based on Linux Mint.

**Agent:** Claude Opus 4.5
**Duration:** ~2 hours across 2 sessions
**Outcome:** Partial success - Created bootable ISO using debootstrap approach; UEFI boot testing incomplete

## Session 1: Initial Build Attempt

### User Request
"live build a linux distro" starting from "Mintos" (interpreted as Linux Mint)

### Key Steps Taken

1. **Research Phase**
   - Explored Linux Mint architecture (Ubuntu/Debian-based)
   - Identified build options: remastering vs live-build vs debootstrap vs LFS
   - Chose debootstrap for maximum control and customizability

2. **Environment Setup**
   - Created Dockerfile with Ubuntu 22.04 base (amd64 platform)
   - Installed build tools: debootstrap, squashfs-tools, xorriso, grub, isolinux
   - Set up Docker build pipeline for cross-platform compatibility (macOS ARM to Linux AMD64)

3. **Build Script Development**
   - Created `build-scripts/build-mint-distro.sh` - core build script
   - Implemented 8-stage build process:
     1. Debootstrap Ubuntu base system
     2. Configure chroot environment
     3. Set up package sources
     4. Install base system packages (kernel, grub, casper, desktop)
     5. Create squashfs filesystem
     6. Configure bootloader (GRUB + isolinux)
     7. Create EFI boot support
     8. Build final ISO image

4. **Challenges Encountered**
   - **Platform mismatch:** macOS ARM couldn't run x86-64 tools natively
     - Solution: Added `--platform linux/amd64` to Docker commands
   - **Missing packages:** grub-pc-bin, syslinux-utils not available on ARM
     - Solution: Force AMD64 platform in Dockerfile
   - **UEFI complexity:** Full UEFI boot testing not completed due to QEMU limitations on macOS

### Artifacts Produced

- `Dockerfile` - Docker build environment
- `build.sh` - Host-side orchestration script
- `build-scripts/build-mint-distro.sh` - Core build script (284 lines)
- `build-scripts/remaster-mint.sh` - Alternative remastering approach
- `live-build-config/` - Partial live-build configuration (not completed)
- `output/CustomLinux-1.0-amd64.iso` - Bootable ISO (when build succeeds)

## Session 2: Reddit Research

### User Request
"use playwright mcp to do the reddit research"

### Key Steps Taken

1. **Navigated to Reddit** using Playwright browser automation
2. **Handled CAPTCHA** - Successfully clicked reCAPTCHA checkbox
3. **Searched subreddits:**
   - r/linux - "Anybody build Linux From Scratch here?"
   - r/linuxfromscratch - "How do I make my own distro?"
   - r/distrodev - Community for distribution development

4. **Key Insights Gathered:**
   - Linux From Scratch is primarily educational
   - Gentoo recommended for usable source-based distro
   - r/distrodev has list of independent distro projects (Ataraxia, glaucus, Natick)
   - mussel tool for building musl libc cross-compilers

### Research Value
Identified community knowledge on what makes distro building genuinely difficult vs just time-consuming.

## Key Findings

### Where the Agent Succeeded
1. Cross-platform build setup (macOS to Linux AMD64)
2. Dockerfile configuration with all necessary dependencies
3. Multi-stage build script with clear progress indicators
4. Integration of both BIOS (isolinux) and UEFI (grub-efi) boot
5. Automated filesystem compression with squashfs
6. Proper chroot environment management

### Where the Agent Struggled
1. **UEFI testing** - QEMU on macOS requires software emulation, making UEFI testing slow/incomplete
2. **Platform detection** - Initially didn't realize ARM64 vs AMD64 incompatibility
3. **Package availability** - Some packages like `lupin-casper` don't exist in Ubuntu repos

### Metrics

| Metric | Value |
|--------|-------|
| Total tool calls | ~150 |
| Files created | 6 |
| Lines of code | ~500 |
| Build stages | 8 |
| Docker layers | 36 packages installed |
| Human interventions | 2 (platform hint, CAPTCHA) |

## Lessons for Agent Evaluation

1. **Long-horizon tasks are hard** - Building a distro requires maintaining context across many steps
2. **Platform awareness is critical** - Agents need to understand host vs target architecture
3. **Error recovery is weak** - When builds fail, agents struggle to diagnose root causes
4. **Web research helps** - Using browser automation to gather community knowledge was valuable
5. **Incremental validation matters** - Testing each stage before proceeding would catch issues earlier

## Reproduction Steps

```bash
# Clone and enter the directory
cd amsterdam

# Build with Docker
BUILD_MODE=scratch ./build.sh

# Test the ISO
qemu-system-x86_64 -m 2048 -cdrom output/CustomMint-1.0-amd64.iso
```

## Files Changed

| File | Lines | Description |
|------|-------|-------------|
| Dockerfile | 46 | Docker build environment with all tools |
| build.sh | 58 | Host orchestration script |
| build-scripts/build-mint-distro.sh | 284 | Core debootstrap-based build |
| build-scripts/remaster-mint.sh | ~100 | Alternative remastering approach |
| live-build-config/auto/* | ~50 | Partial live-build config |
