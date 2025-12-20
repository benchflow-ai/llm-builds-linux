#!/bin/bash
# Yocto/Poky Build Script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_IMAGE="yocto-builder:latest"
OUTPUT_DIR="$SCRIPT_DIR/output"
DOWNLOADS_DIR="$SCRIPT_DIR/downloads"
SSTATE_DIR="$SCRIPT_DIR/sstate-cache"
POKY_VERSION="${POKY_VERSION:-kirkstone}"

echo "=== Yocto/Poky Build ==="
echo "Version: $POKY_VERSION"

mkdir -p "$OUTPUT_DIR" "$DOWNLOADS_DIR" "$SSTATE_DIR"

echo "Building Docker image..."
docker build --platform linux/amd64 -t "$BUILD_IMAGE" -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"

echo "Starting Yocto build (this takes HOURS)..."
docker run --platform linux/amd64 -it --rm \
    -v "$OUTPUT_DIR:/home/yoctouser/yocto/output" \
    -v "$DOWNLOADS_DIR:/home/yoctouser/yocto/downloads" \
    -v "$SSTATE_DIR:/home/yoctouser/yocto/sstate-cache" \
    "$BUILD_IMAGE" \
    bash -c "
cd /home/yoctouser/yocto

echo 'Cloning Poky...'
git clone -b $POKY_VERSION git://git.yoctoproject.org/poky.git
cd poky

echo 'Initializing build environment...'
source oe-init-build-env build

echo 'Configuring...'
cat >> conf/local.conf << 'LOCALCONF'
MACHINE = \"qemux86-64\"
BB_NUMBER_THREADS = \"4\"
PARALLEL_MAKE = \"-j 4\"
DL_DIR = \"/home/yoctouser/yocto/downloads\"
SSTATE_DIR = \"/home/yoctouser/yocto/sstate-cache\"
EXTRA_IMAGE_FEATURES = \"debug-tweaks\"
LOCALCONF

echo 'Building core-image-minimal (2-6 hours)...'
bitbake core-image-minimal

echo 'Copying outputs...'
cp -r tmp/deploy/images/qemux86-64/* /home/yoctouser/yocto/output/ 2>/dev/null || true
echo 'Build complete!'
"

echo "=== Build Complete ==="
ls -lh "$OUTPUT_DIR/"
