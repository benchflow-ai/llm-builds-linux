# Minimal Linux Distro

A bootable x86_64 Linux ISO built from scratch using Docker.

## What's Inside

- **Linux Kernel** - Latest mainline kernel (defconfig)
- **BusyBox** - Static userspace with common utilities
- **ISOLINUX** - Bootloader

## Files

```
├── Dockerfile              # x86_64 Ubuntu build environment
├── build.sh                # Full build (kernel + busybox + iso)
├── build-busybox-iso.sh    # Partial build (reuses existing kernel)
└── output/
    ├── bzImage             # Compiled kernel
    ├── initramfs.gz        # Root filesystem
    └── minimal-linux.iso   # Bootable ISO (16MB)
```

## Build

```bash
# Build Docker image
docker build --platform linux/amd64 -t linux-builder .

# Full build (~25 min on ARM Mac)
docker run --platform linux/amd64 --rm -v "$(pwd)/output:/output" linux-builder

# If kernel exists, build only busybox + iso (~3 min)
docker run --platform linux/amd64 --rm \
  -v "$(pwd)/output:/output" \
  -v "$(pwd)/build-busybox-iso.sh:/build/build-busybox-iso.sh" \
  linux-builder bash /build/build-busybox-iso.sh
```

## Test

```bash
qemu-system-x86_64 -cdrom output/minimal-linux.iso -m 512
```

Boots to a shell with `ls`, `vi`, `grep`, `awk`, `sed`, `bc`, and more.
