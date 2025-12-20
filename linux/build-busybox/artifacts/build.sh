#!/bin/bash
# BusyBox Linux System Build Orchestrator
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_IMAGE="busybox-builder:latest"
OUTPUT_DIR="${SCRIPT_DIR}/output"

GREEN='\033[0;32m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

mkdir -p "$OUTPUT_DIR"

log_info "=== BusyBox Linux Build ==="
log_info "Building Docker image..."
docker build --platform linux/amd64 -t "$BUILD_IMAGE" -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"

log_info "Running build inside container..."
docker run --platform linux/amd64 --rm -v "$OUTPUT_DIR:/output" "$BUILD_IMAGE" bash -c '
set -e
cd /build

echo "Downloading BusyBox..."
wget -q https://busybox.net/downloads/busybox-1.36.1.tar.bz2
tar -xf busybox-1.36.1.tar.bz2
cd busybox-1.36.1

echo "Configuring BusyBox (static build)..."
make defconfig
sed -i "s/# CONFIG_STATIC is not set/CONFIG_STATIC=y/" .config

echo "Building BusyBox..."
make -j$(nproc)

echo "Creating initramfs..."
INITRAMFS=/build/initramfs
mkdir -p $INITRAMFS/{bin,sbin,etc,proc,sys,dev,usr/{bin,sbin},tmp,root}
make CONFIG_PREFIX=$INITRAMFS install

cat > $INITRAMFS/init << "INITEOF"
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
echo ""; echo "=== BusyBox Minimal Linux ==="; echo ""
echo "Kernel: $(uname -r)"
exec /bin/sh
INITEOF
chmod +x $INITRAMFS/init

mknod -m 622 $INITRAMFS/dev/console c 5 1 2>/dev/null || true
mknod -m 666 $INITRAMFS/dev/null c 1 3 2>/dev/null || true

echo "Creating initramfs archive..."
cd $INITRAMFS
find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > /output/initramfs.cpio.gz

echo "Copying kernel..."
cp /boot/vmlinuz-* /output/vmlinuz

echo "=== Build Complete ==="
ls -lh /output/
'

log_info "Build complete! Files in: $OUTPUT_DIR"
log_info "Test with: qemu-system-x86_64 -kernel $OUTPUT_DIR/vmlinuz -initrd $OUTPUT_DIR/initramfs.cpio.gz -nographic -append 'console=ttyS0'"
