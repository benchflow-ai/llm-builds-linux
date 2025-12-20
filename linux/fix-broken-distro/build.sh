#!/bin/bash
# Build script for testing the debootstrap configuration
# This script will attempt to build using the broken configuration

set -e

echo "========================================"
echo "Linux Distro Build Test - Broken Config"
echo "========================================"

# Source configuration
source /workspace/debootstrap.conf

# Create target directory
mkdir -p "$TARGET_DIR"

echo ""
echo "Step 1: Running debootstrap..."
echo "Architecture: $ARCH"
echo "Suite: $SUITE"
echo "Mirror: $MIRROR"
echo "Target: $TARGET_DIR"
echo ""

# Attempt to run debootstrap with the configuration
# This will fail with the broken config
debootstrap \
    --arch="$ARCH" \
    --include="$INCLUDE_PACKAGES" \
    --exclude="$EXCLUDE_PACKAGES" \
    "$SUITE" \
    "$TARGET_DIR" \
    "$MIRROR" || {
    echo ""
    echo "ERROR: Debootstrap failed!"
    echo "Check the configuration in debootstrap.conf"
    exit 1
}

echo ""
echo "Step 2: Configuring system..."

# Copy fstab
cp /workspace/fstab "$TARGET_DIR/etc/fstab"

# Run chroot setup script
/workspace/setup-chroot.sh "$TARGET_DIR" || {
    echo ""
    echo "ERROR: Chroot setup failed!"
    echo "Check the setup-chroot.sh script"
    exit 1
}

echo ""
echo "Step 3: Installing bootloader..."

# Mount necessary filesystems for GRUB installation
mount --bind /dev "$TARGET_DIR/dev"
mount --bind /dev/pts "$TARGET_DIR/dev/pts"
mount --bind /proc "$TARGET_DIR/proc"
mount --bind /sys "$TARGET_DIR/sys"

# Copy and run GRUB config script
cp /workspace/grub-config.sh "$TARGET_DIR/tmp/"
chroot "$TARGET_DIR" /tmp/grub-config.sh || {
    echo ""
    echo "ERROR: GRUB configuration failed!"
    echo "Check the grub-config.sh script"
    # Cleanup mounts
    umount "$TARGET_DIR/sys" "$TARGET_DIR/proc" "$TARGET_DIR/dev/pts" "$TARGET_DIR/dev" 2>/dev/null || true
    exit 1
}

# Cleanup mounts
umount "$TARGET_DIR/sys" "$TARGET_DIR/proc" "$TARGET_DIR/dev/pts" "$TARGET_DIR/dev"

echo ""
echo "========================================"
echo "Build completed successfully!"
echo "========================================"
echo ""
echo "The system has been built in: $TARGET_DIR"
echo ""
echo "To validate the configuration:"
echo "  - Check /etc/fstab"
echo "  - Check /boot/grub/grub.cfg"
echo "  - Verify kernel is installed in /boot"
echo ""
