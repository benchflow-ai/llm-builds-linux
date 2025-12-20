# Build Alpine Linux - Agent Trajectory Summary

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 (Session 1), Claude Sonnet 4.5 (Session 2) |
| Duration | ~1.5 hours |
| Sessions | 2 |
| Outcome | **SUCCESS** |
| Cost | ~$3.00 |

## User Request

"Build Alpine Linux that boots in QEMU"

## Approach

The agent designed a Docker-based build system leveraging Alpine's official tooling:
1. Use Alpine container as build host (for apk compatibility)
2. Use alpine-make-rootfs for proper rootfs creation
3. Create bootable disk image with GRUB
4. Install linux-virt kernel for QEMU

## Key Steps

### Session 1: Environment Setup

1. Analyzed Alpine's unique characteristics (musl, apk, OpenRC)
2. Created Alpine-based Dockerfile
3. Integrated alpine-make-rootfs tool
4. Created disk imaging script with GRUB installation
5. Documented differences from Debian/Ubuntu approach

## Artifacts Produced

| File | Lines | Description |
|------|-------|-------------|
| `Dockerfile` | 40 | Alpine build environment |
| `build.sh` | 180 | Full orchestration script |
| `README.md` | 90 | Documentation |
| `EXPERIMENT.yaml` | 55 | Metadata |

## Metrics

| Metric | Value |
|--------|-------|
| Tool calls | ~25 |
| Files created | 5 |
| Lines of code | ~370 |

## Where Agent Succeeded

1. **Alpine expertise** - Correctly identified musl/apk differences
2. **Proper tooling** - Used alpine-make-rootfs instead of debootstrap
3. **Kernel selection** - linux-virt for QEMU compatibility

### Session 2: Fixing losetup Issue (Claude Sonnet 4.5)

1. Diagnosed BusyBox losetup limitation
2. Added util-linux package to Dockerfile
3. Modified build.sh to use offset-based partition access
4. Successfully created bootable 1GB disk image
5. Verified GRUB installation and filesystem integrity

## Where Agent Succeeded (Session 2)

1. **Problem diagnosis** - Quickly identified BusyBox vs util-linux issue
2. **Solution research** - Found correct approach using --offset instead of --partscan
3. **Implementation** - Updated Dockerfile and build.sh correctly
4. **Verification** - Thoroughly tested the final disk image

## Where Agent Struggled

1. **Privileged containers** - Alpine build needs --privileged for loop devices
2. **mkinitfs** - Different from Debian initramfs-tools
3. **Partition scanning** - Container kernel limitations required workaround

## Lessons for Agent Evaluation

1. **Distro-specific knowledge** - Each distro has unique tooling
2. **Package naming** - Packages have different names across distros
3. **Container vs full system** - Alpine shines in containers but needs work for bootable

## Reproduction Steps

```bash
cd linux/build-alpine/artifacts

./build.sh --all
```
