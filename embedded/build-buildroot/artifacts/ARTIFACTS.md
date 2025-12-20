# Build Artifacts

This directory contains the scripts and configurations to build a minimal embedded Linux system using Buildroot.

## Files

- `Dockerfile` - Build environment with all Buildroot dependencies
- `build.sh` - Main build orchestration script
- `docker-compose.yml` - Docker Compose configuration for easy building
- `output/` - Directory where build outputs will be placed (created during build)

## Usage

### Build with Docker Compose

```bash
docker-compose up
```

### Build Manually

```bash
# Build the image
docker build -t buildroot-builder .

# Run the build
docker run -v $(pwd)/output:/workspace/output buildroot-builder /workspace/build.sh
```

### Build Without Docker

If you have a Linux system with Buildroot dependencies installed:

```bash
# Download Buildroot
wget https://buildroot.org/downloads/buildroot-2024.02.9.tar.gz
tar -xzf buildroot-2024.02.9.tar.gz
cd buildroot-2024.02.9

# Configure for QEMU x86_64
make qemu_x86_64_defconfig

# Build (this takes 30-60 minutes)
make -j$(nproc)

# Outputs will be in output/images/
```

## What Gets Built

The `qemu_x86_64_defconfig` configuration builds:

1. **Toolchain** - Cross-compilation toolchain (GCC, binutils, etc.)
2. **Linux Kernel** - Compiled kernel (bzImage)
3. **Root Filesystem** - Minimal rootfs with BusyBox (rootfs.ext2)
4. **Bootloader** - Minimal boot support for QEMU

## Testing the Output

Once built, you can boot the system in QEMU:

```bash
cd output

qemu-system-x86_64 \
  -M pc \
  -kernel bzImage \
  -drive file=rootfs.ext2,if=virtio,format=raw \
  -append 'root=/dev/vda console=ttyS0' \
  -nographic
```

To exit QEMU: `Ctrl-A` then `X`

## Build Time

Expected build time:
- First build: 30-60 minutes (downloads and builds toolchain)
- Rebuilds: 5-15 minutes (if using ccache and incremental builds)

## Disk Space

Buildroot build requires:
- Source downloads: ~500 MB
- Build directory: 2-4 GB
- Final images: 50-100 MB
