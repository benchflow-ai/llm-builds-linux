# Linux Distro Building Benchmark - Implementation Plan

## Executive Summary

This benchmark tests whether LLM coding agents can build Linux distributions. Based on research, we've identified 5 difficulty tiers with 12+ concrete tasks that range from 30 minutes to 20+ hours of build time, requiring 10-500+ steps.

## Why This is Hard for Agents

1. **Long feedback loops** - Errors often only surface at boot time
2. **Cryptic error messages** - Kernel panics, missing firmware, bootloader failures
3. **Deep system knowledge required** - Package managers, bootloaders, init systems, filesystems
4. **Many moving parts** - Toolchains, kernels, userspace, boot configuration must all align
5. **Non-obvious dependencies** - glibc version must match kernel headers, etc.

## Difficulty Tiers

### Tier 1: Minimal (30 min - 1 hour, ~20 steps)
**Goal:** Build bootable system with existing tools, minimal customization

Tasks:
- [ ] **T1.1** Create minimal Alpine container with custom packages
- [ ] **T1.2** Build BusyBox + kernel initramfs (boot in QEMU)
- [ ] **T1.3** Use debootstrap to create minimal Debian rootfs

### Tier 2: Custom Spin (1-3 hours, ~50 steps)
**Goal:** Create customized distribution using established tools

Tasks:
- [ ] **T2.1** Create custom Ubuntu live ISO with live-build
- [ ] **T2.2** Create Fedora spin with kickstart + livemedia-creator
- [ ] **T2.3** Build minimal embedded Linux with Buildroot

### Tier 3: Embedded/Hardware (3-6 hours, ~100 steps)
**Goal:** Build for specific hardware with custom configuration

Tasks:
- [ ] **T3.1** Build Yocto image for QEMU ARM target
- [ ] **T3.2** Create Buildroot system with custom kernel config
- [ ] **T3.3** Build RHEL-like image with image-builder + OpenSCAP

### Tier 4: From Scratch (8-20 hours, ~200+ steps)
**Goal:** Build significant portions from source

Tasks:
- [ ] **T4.1** Build cross-toolchain + minimal system (partial LFS)
- [ ] **T4.2** Create custom Yocto layer with ML framework integration
- [ ] **T4.3** Build bootable system with custom kernel + systemd

### Tier 5: Full Distribution (20+ hours, ~500+ steps)
**Goal:** Complete distribution builds

Tasks:
- [ ] **T5.1** Full Linux From Scratch build
- [ ] **T5.2** Create production Yocto BSP for custom hardware
- [ ] **T5.3** Build ChromiumOS or similar complex distribution

## Implementation Structure

```
llm-builds-linux/
├── README.md
├── PLAN.md
├── tasks/
│   ├── tier1/
│   │   ├── t1.1-alpine-minimal/
│   │   │   ├── README.md          # Task description
│   │   │   ├── Dockerfile         # Build environment
│   │   │   ├── task.yaml          # Machine-readable spec
│   │   │   ├── solution/          # Reference solution
│   │   │   └── verify.sh          # Verification script
│   │   ├── t1.2-busybox-kernel/
│   │   └── t1.3-debootstrap/
│   ├── tier2/
│   ├── tier3/
│   ├── tier4/
│   └── tier5/
├── environments/
│   ├── base-ubuntu.Dockerfile     # Base build environment
│   ├── base-fedora.Dockerfile
│   └── base-yocto.Dockerfile
├── scripts/
│   ├── run-task.sh                # Run a task in container
│   ├── verify-build.sh            # Verify build output
│   └── benchmark.py               # Run benchmarks
└── results/
    └── .gitkeep
```

## Task Specification Format

```yaml
# task.yaml
name: "Build minimal bootable Linux with BusyBox"
id: t1.2-busybox-kernel
tier: 1
difficulty: easy

description: |
  Build a minimal bootable Linux system using the Linux kernel
  and BusyBox. The system should boot in QEMU and provide a
  functional shell.

estimated_time: "45 minutes"
estimated_steps: 25

requirements:
  - Linux kernel (latest stable)
  - BusyBox (static build)
  - initramfs creation
  - QEMU boot test

success_criteria:
  - System boots without kernel panic
  - Shell prompt appears
  - Basic commands work (ls, cat, echo)
  - Can create and read files

environment:
  base_image: "ubuntu:22.04"
  packages:
    - build-essential
    - libncurses-dev
    - flex
    - bison
    - bc
    - libelf-dev
    - libssl-dev
    - qemu-system-x86

hints:
  - Use kernel defconfig as starting point
  - BusyBox must be built with static linking
  - initramfs needs /init script with proper shebang
  - Mount proc and sys in init script

common_failures:
  - "Kernel panic - not syncing: No init found"
  - "VFS: Cannot open root device"
  - Missing /dev/console
  - Init script not executable
```

## Verification Approach

Each task has automated verification:

1. **Build verification** - Did the build complete without errors?
2. **Artifact verification** - Were expected files produced?
3. **Boot verification** - Does it boot in QEMU? (with timeout)
4. **Functional verification** - Can basic operations be performed?

## Metrics to Collect

For each agent run:
- Total time taken
- Number of steps/commands executed
- Number of errors encountered
- Number of recovery attempts
- Final success/failure
- Partial completion score (0-100%)

## Common Failure Modes to Test

Based on research, agents commonly fail at:

1. **Kernel configuration** - Missing drivers, wrong arch, no initramfs support
2. **Bootloader setup** - GRUB configuration, EFI vs BIOS
3. **Init system** - Missing /init, wrong permissions, broken scripts
4. **Package dependencies** - Version conflicts, missing libs
5. **Cross-compilation** - Wrong toolchain, architecture mismatch
6. **Filesystem issues** - Wrong format, missing /dev nodes
7. **Network in chroot** - DNS resolution, missing /etc/resolv.conf

## Phase 1 Deliverables

1. **6 working task environments** (2 per tier 1-3)
2. **Automated verification scripts**
3. **Baseline results** with at least 2 models tested
4. **Documentation** of failure modes observed

## Next Steps (Immediate)

1. Create directory structure
2. Implement T1.2 (BusyBox + kernel) as first complete task
3. Implement T2.1 (Ubuntu live-build) as second task
4. Create verification infrastructure
5. Test with Claude and document results
