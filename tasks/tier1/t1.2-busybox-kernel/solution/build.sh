#!/bin/bash
# Reference solution for T1.2: BusyBox + Kernel minimal Linux
# This script builds a minimal bootable Linux system

set -e

KERNEL_VERSION="6.6.67"
BUSYBOX_VERSION="1.36.1"
BUILD_DIR="/build"
JOBS=$(nproc)

echo "=== Building Minimal Linux ==="
echo "Kernel: $KERNEL_VERSION"
echo "BusyBox: $BUSYBOX_VERSION"
echo "Parallel jobs: $JOBS"
echo ""

cd "$BUILD_DIR"

# Step 1: Download sources
echo "[1/6] Downloading sources..."
if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
    wget -q "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"
fi
if [ ! -f "busybox-${BUSYBOX_VERSION}.tar.bz2" ]; then
    wget -q "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
fi

# Step 2: Build kernel
echo "[2/6] Building Linux kernel..."
if [ ! -d "linux-${KERNEL_VERSION}" ]; then
    tar xf "linux-${KERNEL_VERSION}.tar.xz"
fi
cd "linux-${KERNEL_VERSION}"
make defconfig
# Enable initramfs support (should be on by default)
./scripts/config --enable CONFIG_BLK_DEV_INITRD
./scripts/config --enable CONFIG_RD_GZIP
make -j"$JOBS" bzImage
cp arch/x86/boot/bzImage "$BUILD_DIR/"
cd "$BUILD_DIR"
echo "  Kernel built: bzImage"

# Step 3: Build BusyBox (static)
echo "[3/6] Building BusyBox (static)..."
if [ ! -d "busybox-${BUSYBOX_VERSION}" ]; then
    tar xf "busybox-${BUSYBOX_VERSION}.tar.bz2"
fi
cd "busybox-${BUSYBOX_VERSION}"
make defconfig
# Enable static build
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
make -j"$JOBS"
make install
cd "$BUILD_DIR"
echo "  BusyBox built"

# Step 4: Create initramfs structure
echo "[4/6] Creating initramfs structure..."
INITRAMFS_DIR="$BUILD_DIR/initramfs"
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/{bin,sbin,etc,proc,sys,dev,tmp,root}

# Copy BusyBox
cp -a "busybox-${BUSYBOX_VERSION}/_install/"* "$INITRAMFS_DIR/"

# Step 5: Create init script
echo "[5/6] Creating init script..."
cat > "$INITRAMFS_DIR/init" << 'INIT_EOF'
#!/bin/busybox sh

# Mount essential filesystems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Create necessary device nodes if devtmpfs didn't
[ -e /dev/console ] || mknod /dev/console c 5 1
[ -e /dev/null ] || mknod /dev/null c 1 3
[ -e /dev/tty ] || mknod /dev/tty c 5 0

# Set hostname
hostname minimal-linux

# Display welcome message
echo ""
echo "============================================"
echo "  Minimal Linux with BusyBox"
echo "  Built for llm-builds-linux benchmark"
echo "============================================"
echo ""
echo "Type 'poweroff' or press Ctrl-A X to exit QEMU"
echo ""

# Start shell
exec /bin/sh
INIT_EOF

chmod +x "$INITRAMFS_DIR/init"

# Step 6: Create initramfs archive
echo "[6/6] Creating initramfs archive..."
cd "$INITRAMFS_DIR"
find . | cpio -o -H newc 2>/dev/null | gzip > "$BUILD_DIR/initramfs.cpio.gz"
cd "$BUILD_DIR"
echo "  Created: initramfs.cpio.gz"

# Create boot script
cat > "$BUILD_DIR/boot.sh" << 'BOOT_EOF'
#!/bin/bash
# Boot the minimal Linux in QEMU
# Exit with: Ctrl-A X

qemu-system-x86_64 \
    -kernel bzImage \
    -initrd initramfs.cpio.gz \
    -append "console=ttyS0 quiet" \
    -nographic \
    -m 256M
BOOT_EOF
chmod +x "$BUILD_DIR/boot.sh"

echo ""
echo "=== Build Complete ==="
echo ""
echo "Files created:"
ls -lh "$BUILD_DIR/bzImage" "$BUILD_DIR/initramfs.cpio.gz" "$BUILD_DIR/boot.sh"
echo ""
echo "To boot: ./boot.sh"
echo "To exit QEMU: Ctrl-A X"
