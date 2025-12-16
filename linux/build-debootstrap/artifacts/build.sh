#!/bin/bash
# Master build script - runs on host (macOS/Linux)
# Builds custom Linux distro using Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISTRO_NAME="${DISTRO_NAME:-CustomMint}"
DISTRO_VERSION="${DISTRO_VERSION:-1.0}"
BUILD_MODE="${BUILD_MODE:-remaster}"  # 'remaster' or 'scratch'

echo "=============================================="
echo "Linux Distro Builder"
echo "Mode: ${BUILD_MODE}"
echo "Output: ${DISTRO_NAME} v${DISTRO_VERSION}"
echo "=============================================="

# Build Docker image
echo "[1/3] Building Docker build environment..."
docker build --platform linux/amd64 -t linux-distro-builder "${SCRIPT_DIR}"

# Create output directory
mkdir -p "${SCRIPT_DIR}/output"

echo "[2/3] Starting build inside Docker..."

# Run build inside Docker container
# Need privileged for mount operations and loop devices
if [ "${BUILD_MODE}" = "scratch" ]; then
    docker run --rm \
        --platform linux/amd64 \
        --privileged \
        -v "${SCRIPT_DIR}/output:/build/output" \
        -v "${SCRIPT_DIR}/build-scripts:/build/scripts:ro" \
        -e DISTRO_NAME="${DISTRO_NAME}" \
        -e DISTRO_VERSION="${DISTRO_VERSION}" \
        linux-distro-builder \
        /bin/bash /build/scripts/build-mint-distro.sh
else
    docker run --rm \
        --platform linux/amd64 \
        --privileged \
        -v "${SCRIPT_DIR}/output:/build/output" \
        -v "${SCRIPT_DIR}/build-scripts:/build/scripts:ro" \
        -e DISTRO_NAME="${DISTRO_NAME}" \
        -e DISTRO_VERSION="${DISTRO_VERSION}" \
        linux-distro-builder \
        /bin/bash /build/scripts/remaster-mint.sh
fi

echo "[3/3] Build complete!"
echo ""
echo "Output files:"
ls -la "${SCRIPT_DIR}/output/"
echo ""
echo "To test the ISO:"
echo "  qemu-system-x86_64 -m 2048 -cdrom ${SCRIPT_DIR}/output/${DISTRO_NAME}-${DISTRO_VERSION}-amd64.iso"
