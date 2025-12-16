#!/bin/bash
# Convenience script to build Monterrey Linux ISO using Docker
# Run this from the mint-live-build directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="monterrey-builder"
CONTAINER_NAME="monterrey-build-$$"
OUTPUT_DIR="$SCRIPT_DIR/output"

echo "============================================"
echo "Monterrey Linux Build Launcher"
echo "============================================"
echo ""

# Check Docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    echo "Please install Docker Desktop for Mac from https://docker.com"
    exit 1
fi

# Check Docker daemon is running
if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running"
    echo "Please start Docker Desktop"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Building Docker image (amd64 architecture for x86_64 ISO)..."
echo "NOTE: On Apple Silicon, this uses QEMU emulation and will be slower"
docker build --platform linux/amd64 -t "$IMAGE_NAME" "$SCRIPT_DIR"

echo ""
echo "Starting build container..."
echo "This will take 30-60 minutes depending on network speed"
echo ""

# Run the build with appropriate settings
# - Privileged mode needed for loop devices and mounts
# - Large shared memory for squashfs operations
docker run \
    --rm \
    --privileged \
    --platform linux/amd64 \
    --name "$CONTAINER_NAME" \
    -v "$SCRIPT_DIR/config:/build/config:ro" \
    -v "$SCRIPT_DIR/auto:/build/auto:ro" \
    -v "$SCRIPT_DIR/build.sh:/build/build.sh:ro" \
    -v "$OUTPUT_DIR:/output" \
    --shm-size=2g \
    "$IMAGE_NAME"

echo ""
echo "============================================"
echo "Build process complete!"
echo "============================================"
echo ""

# Check for output
if ls "$OUTPUT_DIR"/*.iso 1> /dev/null 2>&1; then
    echo "ISO file(s) created in: $OUTPUT_DIR/"
    ls -lh "$OUTPUT_DIR"/*.iso
    echo ""
    echo "To test with QEMU (if installed):"
    echo "  qemu-system-x86_64 -m 4G -cdrom $OUTPUT_DIR/monterrey-linux-*.iso -boot d"
else
    echo "WARNING: No ISO file found in output directory"
    echo "Check the build output above for errors"
fi
