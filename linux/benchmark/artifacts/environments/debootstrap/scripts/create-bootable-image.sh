#!/bin/bash
# Create a bootable disk image from a rootfs

set -e

ROOTFS="${1:-/workspace/rootfs}"
OUTPUT="${2:-/workspace/debian.img}"
SIZE_MB="${3:-2048}"

echo "=== Creating bootable disk image ==="
echo "Rootfs: $ROOTFS"
echo "Output: $OUTPUT"
echo "Size: ${SIZE_MB}MB"

# Check rootfs exists
if [ ! -d "$ROOTFS" ]; then
    echo "Error: Rootfs not found at $ROOTFS"
    exit 1
fi

# Create disk image
dd if=/dev/zero of=$OUTPUT bs=1M count=$SIZE_MB

# Set up loop device
LOOP_DEV=$(losetup -f --show -P $OUTPUT)
echo "Loop device: $LOOP_DEV"

cleanup() {
    echo "Cleaning up..."
    umount /mnt/build/{dev,proc,sys} 2>/dev/null || true
    umount /mnt/build 2>/dev/null || true
    losetup -d $LOOP_DEV 2>/dev/null || true
}
trap cleanup EXIT

# Create partition table
parted -s $LOOP_DEV mklabel msdos
parted -s $LOOP_DEV mkpart primary ext4 1MiB 100%
parted -s $LOOP_DEV set 1 boot on

# Re-read partition table
partprobe $LOOP_DEV
sleep 1

# Format partition
mkfs.ext4 ${LOOP_DEV}p1

# Mount and copy rootfs
mkdir -p /mnt/build
mount ${LOOP_DEV}p1 /mnt/build
cp -a $ROOTFS/* /mnt/build/

# Install kernel if not present
if [ ! -f /mnt/build/boot/vmlinuz-* ]; then
    echo "Installing kernel..."
    mount --bind /dev /mnt/build/dev
    mount --bind /proc /mnt/build/proc
    mount --bind /sys /mnt/build/sys

    chroot /mnt/build apt-get update
    chroot /mnt/build apt-get install -y --no-install-recommends linux-image-amd64 systemd-sysv

    umount /mnt/build/{dev,proc,sys}
fi

# Install GRUB
echo "Installing GRUB..."
mount --bind /dev /mnt/build/dev
mount --bind /proc /mnt/build/proc
mount --bind /sys /mnt/build/sys

chroot /mnt/build apt-get install -y grub-pc
chroot /mnt/build grub-install --target=i386-pc $LOOP_DEV
chroot /mnt/build update-grub

# Create fstab
ROOT_UUID=$(blkid -s UUID -o value ${LOOP_DEV}p1)
echo "UUID=$ROOT_UUID / ext4 errors=remount-ro 0 1" > /mnt/build/etc/fstab

echo "=== Disk image created successfully ==="
echo "Size: $(du -h $OUTPUT | cut -f1)"
echo ""
echo "Boot with:"
echo "  qemu-system-x86_64 -hda $OUTPUT -m 1024 -nographic -append 'console=ttyS0'"
