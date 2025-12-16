#!/bin/bash
# Build script for Monterrey Linux (Linux Mint-based distribution)
# This script runs inside the Docker container

set -e

echo "============================================"
echo "Monterrey Linux Build System"
echo "Based on Ubuntu 24.04 (Noble) + Linux Mint"
echo "============================================"
echo ""

BUILD_DIR="/build"
OUTPUT_DIR="/output"

cd "$BUILD_DIR"

# Make auto scripts executable
chmod +x auto/* 2>/dev/null || true

# Make hook scripts executable
find config/hooks -type f -name "*.hook.chroot" -exec chmod +x {} \; 2>/dev/null || true

echo "[1/5] Cleaning previous build artifacts..."
lb clean --purge 2>/dev/null || true
rm -rf .build binary* chroot* *.iso *.log 2>/dev/null || true

echo "[2/5] Configuring live-build..."
lb config

echo "[3/5] Starting bootstrap phase..."
echo "      This will download the base Ubuntu system..."
lb bootstrap

echo "[4/5] Starting chroot phase..."
echo "      This will install packages and run hooks..."
lb chroot

# Create dummy gfxboot-theme-ubuntu in chroot to satisfy lb_binary_syslinux
# This is needed because Ubuntu mode tries to extract this non-existent package
# The tarball must contain a 'bootlogo' file which is a cpio archive
echo "      Creating gfxboot workaround..."
GFXBOOT_DIR="chroot/usr/share/gfxboot-theme-ubuntu"
mkdir -p "$GFXBOOT_DIR"
cd "$GFXBOOT_DIR"

# Create empty bootlogo cpio archive with minimal required files
mkdir -p bootlogo_contents
cd bootlogo_contents
# Create minimal langlist file (required by the gfxboot processing code)
echo "en" > langlist
# Create bootlogo cpio archive
ls -1 | cpio --quiet -o > ../bootlogo
cd ..
rm -rf bootlogo_contents

# Create tarball containing the bootlogo
tar czf bootlogo.tar.gz bootlogo
rm bootlogo
cd "$BUILD_DIR"

echo "[5/5] Starting binary phase..."
echo "      This will create the bootable ISO..."
lb binary

echo ""
echo "============================================"
echo "Build completed!"
echo "============================================"

# Find and report the ISO
ISO_FILE=$(find . -maxdepth 1 -name "*.iso" -type f | head -1)

if [ -n "$ISO_FILE" ]; then
    ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
    echo "ISO created: $ISO_FILE ($ISO_SIZE)"

    # Copy to output directory if it exists
    if [ -d "$OUTPUT_DIR" ]; then
        cp "$ISO_FILE" "$OUTPUT_DIR/"
        echo "ISO copied to: $OUTPUT_DIR/"
    fi
else
    echo "WARNING: No ISO file found!"
    echo "Check build.log for errors"
    exit 1
fi

echo ""
echo "To test the ISO:"
echo "  qemu-system-x86_64 -m 4G -cdrom $ISO_FILE -boot d"
echo ""
