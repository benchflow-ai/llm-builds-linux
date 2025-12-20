#!/bin/bash
set -e

# Buildroot Build Script
# This script builds a minimal Buildroot-based embedded Linux system for QEMU x86_64

echo "========================================="
echo "Buildroot Build Script"
echo "========================================="
echo ""

# Timing
START_TIME=$(date +%s)

# Configuration
BUILDROOT_DIR="/workspace/buildroot"
OUTPUT_DIR="/workspace/output"
BUILD_LOG="/workspace/build.log"

cd "$BUILDROOT_DIR"

# Step 1: Load default configuration for QEMU x86_64
echo "[Step 1/4] Loading qemu_x86_64_defconfig..."
make qemu_x86_64_defconfig 2>&1 | tee -a "$BUILD_LOG"

# Step 2: Show the configuration (optional, for visibility)
echo "[Step 2/4] Current configuration summary:"
echo "  Target: x86_64"
echo "  Toolchain: Buildroot internal toolchain"
echo "  Kernel: Linux kernel (from defconfig)"
echo "  Init: BusyBox"
echo "  Bootloader: Default (none/GRUB depending on config)"
echo ""

# Step 3: Build everything
echo "[Step 3/4] Starting Buildroot build..."
echo "This will take 30-60 minutes depending on system resources..."
echo "Building toolchain, kernel, rootfs, and bootloader..."
echo ""

# Run make with parallel jobs (use all cores)
NPROC=$(nproc)
echo "Using $NPROC parallel jobs"

if make -j"$NPROC" 2>&1 | tee -a "$BUILD_LOG"; then
    BUILD_STATUS="SUCCESS"
    echo ""
    echo "========================================="
    echo "BUILD SUCCESSFUL"
    echo "========================================="
else
    BUILD_STATUS="FAILED"
    echo ""
    echo "========================================="
    echo "BUILD FAILED"
    echo "========================================="
    echo "Check $BUILD_LOG for details"
    exit 1
fi

# Step 4: Show outputs
echo ""
echo "[Step 4/4] Build artifacts:"
ls -lh output/images/ 2>&1 | tee -a "$BUILD_LOG"

# Copy outputs to persistent location
mkdir -p "$OUTPUT_DIR"
cp -r output/images/* "$OUTPUT_DIR/" 2>&1 | tee -a "$BUILD_LOG"

# Calculate build time
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
BUILD_TIME_MIN=$((BUILD_TIME / 60))
BUILD_TIME_SEC=$((BUILD_TIME % 60))

echo ""
echo "========================================="
echo "Build Summary"
echo "========================================="
echo "Status: $BUILD_STATUS"
echo "Build time: ${BUILD_TIME_MIN}m ${BUILD_TIME_SEC}s"
echo "Output directory: $OUTPUT_DIR"
echo "Build log: $BUILD_LOG"
echo ""
echo "Key artifacts in $OUTPUT_DIR:"
echo "  - bzImage: Linux kernel"
echo "  - rootfs.ext2: Root filesystem"
echo "  - (possibly) grub/bootloader files"
echo ""
echo "To boot in QEMU:"
echo "  qemu-system-x86_64 -M pc -kernel bzImage -drive file=rootfs.ext2,if=virtio,format=raw -append 'root=/dev/vda console=ttyS0' -nographic"
echo ""
echo "========================================="
