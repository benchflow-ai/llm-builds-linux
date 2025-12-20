#!/bin/bash
set -e

echo "=== Building BusyBox and ISO (kernel already built) ==="

# Check kernel exists
if [ ! -f /output/bzImage ]; then
    echo "ERROR: bzImage not found in /output"
    exit 1
fi
echo ">>> Found existing kernel: $(ls -lh /output/bzImage | awk '{print $5}')"

# Build BusyBox
echo ">>> Cloning BusyBox from GitHub mirror..."
git clone --depth 1 https://github.com/mirror/busybox.git busybox
cd busybox

echo ">>> Configuring BusyBox (static build)..."
make defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
make oldconfig

echo ">>> Building BusyBox..."
make -j$(nproc) 2>&1 | tail -5

mkdir -p /output/initramfs
make CONFIG_PREFIX=/output/initramfs install
cd ..

# Create init script
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

# Create initramfs
echo ">>> Creating initramfs..."
find . | cpio -o -H newc 2>/dev/null | gzip > /output/initramfs.gz
cd /output

# Create ISO
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
