# Task T1.2: Build Minimal Bootable Linux with BusyBox

## Objective

Build a minimal bootable Linux system from scratch using:
- Linux kernel (compiled from source)
- BusyBox (static build)
- Custom initramfs

The system must boot in QEMU and provide a functional shell.

## Difficulty

- **Tier:** 1 (Minimal)
- **Estimated Time:** 45-60 minutes
- **Estimated Steps:** ~25 commands

## Requirements

Your build must:
1. Compile the Linux kernel from source
2. Build BusyBox with static linking
3. Create a proper initramfs with init script
4. Boot successfully in QEMU
5. Provide working shell with basic commands

## Success Criteria

- [ ] Kernel compiles without errors
- [ ] BusyBox builds as static binary
- [ ] System boots without kernel panic
- [ ] Shell prompt appears (can be simple `/ #`)
- [ ] Basic commands work: `ls`, `cat`, `echo`, `mount`
- [ ] Can create and read files

## Getting Started

```bash
# Enter the build environment
docker build -t busybox-kernel-env .
docker run -it --privileged busybox-kernel-env

# You now have all tools needed to:
# 1. Download and compile Linux kernel
# 2. Download and compile BusyBox
# 3. Create initramfs
# 4. Test boot with QEMU
```

## Hints (use only if stuck)

<details>
<summary>Hint 1: Kernel configuration</summary>

Use `make defconfig` for a working default config, then enable:
- `CONFIG_BLK_DEV_INITRD=y` (initramfs support)
- Keep it simple - defconfig works for QEMU

</details>

<details>
<summary>Hint 2: BusyBox static linking</summary>

In BusyBox menuconfig:
- Settings → Build static binary (no shared libs) → Enable

</details>

<details>
<summary>Hint 3: Init script requirements</summary>

Your `/init` script must:
- Start with `#!/bin/busybox sh`
- Mount proc: `mount -t proc none /proc`
- Mount sys: `mount -t sysfs none /sys`
- Mount devtmpfs: `mount -t devtmpfs none /dev`
- End with `exec /bin/sh`

</details>

<details>
<summary>Hint 4: QEMU boot command</summary>

```bash
qemu-system-x86_64 \
  -kernel bzImage \
  -initrd initramfs.cpio.gz \
  -append "console=ttyS0" \
  -nographic
```

Press `Ctrl-A X` to exit QEMU.

</details>

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Kernel panic - not syncing: No init found` | Missing or non-executable /init | Ensure init exists and has `chmod +x` |
| `Failed to execute /init` | Wrong shebang or not static | Use `#!/bin/busybox sh`, build busybox static |
| `/bin/sh: not found` | Missing busybox symlinks | Create symlinks or use busybox directly |
| No output at all | Wrong console setting | Add `console=ttyS0` to kernel cmdline |

## Verification

Run the verification script to check your build:

```bash
./verify.sh /path/to/your/build
```

## Reference

- [Minimal Linux Live](https://github.com/ivandavidov/minimal)
- [Linux From Scratch - Kernel](https://www.linuxfromscratch.org/lfs/view/stable/chapter10/kernel.html)
- [BusyBox](https://busybox.net/)
