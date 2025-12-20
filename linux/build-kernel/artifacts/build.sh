#!/bin/bash
# Linux Kernel Build Script
set -euo pipefail

KERNEL_VERSION="6.6.63"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"
BUILD_IMAGE="kernel-builder:latest"

GREEN='\033[0;32m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

mkdir -p "$OUTPUT_DIR"

log_info "=== Linux Kernel Build ==="
log_info "Version: $KERNEL_VERSION"

log_info "Building Docker image..."
docker build -t "$BUILD_IMAGE" -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"

log_info "Building kernel in container..."
docker run --rm -v "$OUTPUT_DIR:/output" "$BUILD_IMAGE" bash -c "
set -e
cd /kernel-build

echo 'Downloading kernel...'
wget -q https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz
tar -xf linux-${KERNEL_VERSION}.tar.xz
cd linux-${KERNEL_VERSION}

echo 'Configuring kernel...'
make defconfig
echo 'CONFIG_VIRTIO=y' >> .config
echo 'CONFIG_VIRTIO_PCI=y' >> .config
echo 'CONFIG_VIRTIO_BLK=y' >> .config
echo 'CONFIG_VIRTIO_NET=y' >> .config
echo 'CONFIG_BLK_DEV_INITRD=y' >> .config
echo 'CONFIG_RD_GZIP=y' >> .config
make olddefconfig

echo 'Building kernel (this takes 10-30 minutes)...'
make -j\$(nproc) bzImage

cp arch/x86/boot/bzImage /output/
cp .config /output/kernel.config
echo 'Kernel built successfully!'
ls -lh /output/
"

log_info "Build complete! Kernel at: $OUTPUT_DIR/bzImage"
log_info "Test with initramfs: qemu-system-x86_64 -kernel $OUTPUT_DIR/bzImage -initrd <initramfs> -nographic -append 'console=ttyS0'"
