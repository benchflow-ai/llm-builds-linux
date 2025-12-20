#!/bin/bash
set -e

echo "=== Building Minimal Linux Distro ==="

# 1. Build Linux Kernel (minimal config for faster build)
echo ">>> Cloning Linux kernel..."
git clone --depth 1 https://github.com/torvalds/linux.git
cd linux

echo ">>> Configuring kernel (minimal x86_64)..."
make defconfig
# Enable initramfs support
scripts/config --enable CONFIG_BLK_DEV_INITRD
scripts/config --enable CONFIG_RD_GZIP
scripts/config --enable CONFIG_RD_BZIP2
scripts/config --enable CONFIG_RD_LZMA
scripts/config --enable CONFIG_RD_XZ
scripts/config --enable CONFIG_RD_LZO
scripts/config --enable CONFIG_RD_LZ4
scripts/config --enable CONFIG_RD_ZSTD
make olddefconfig

echo ">>> Building kernel (this takes a while)..."
make -j$(nproc) bzImage 2>&1 | tail -20

mkdir -p /output
cp arch/x86/boot/bzImage /output/
cd ..

# 2. Build BusyBox
echo ">>> Cloning BusyBox..."
git clone --depth 1 https://github.com/mirror/busybox.git busybox
cd busybox

echo ">>> Configuring BusyBox (static build)..."
make defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
make oldconfig

echo ">>> Building BusyBox..."
make -j$(nproc) 2>&1 | tail -10

mkdir -p /output/initramfs
make CONFIG_PREFIX=/output/initramfs install
cd ..

# 3. Create init script
echo ">>> Creating init script..."
cd /output/initramfs
cat > init << 'INITEOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

echo "Welcome to Minimal Linux!"
echo "Type 'poweroff' to shutdown."
echo ""

exec /bin/sh
INITEOF
chmod +x init
mkdir -p proc sys dev

# 4. Create initramfs
echo ">>> Creating initramfs..."
find . | cpio -o -H newc 2>/dev/null | gzip > /output/initramfs.gz
cd /output

# 5. Create ISO with ISOLINUX
echo ">>> Creating bootable ISO..."
mkdir -p iso/boot/isolinux

cp /usr/lib/ISOLINUX/isolinux.bin iso/boot/isolinux/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 iso/boot/isolinux/
cp bzImage iso/boot/
cp initramfs.gz iso/boot/

cat > iso/boot/isolinux/isolinux.cfg << 'CFGEOF'
DEFAULT linux
LABEL linux
    KERNEL /boot/bzImage
    APPEND initrd=/boot/initramfs.gz
CFGEOF

xorriso -as mkisofs \
    -o /output/minimal-linux.iso \
    -b boot/isolinux/isolinux.bin \
    -c boot/isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    iso/

echo ""
echo "=== BUILD COMPLETE ==="
ls -lh /output/minimal-linux.iso
echo "ISO ready at /output/minimal-linux.iso"
