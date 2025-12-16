#!/bin/bash
# Chromium Build Script for macOS ARM64
# This script builds Chromium browser from source

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPOT_TOOLS_DIR="$SCRIPT_DIR/depot_tools"
CHROMIUM_DIR="$SCRIPT_DIR/chromium"
BUILD_DIR="out/Default"

# Add depot_tools to PATH
export PATH="$DEPOT_TOOLS_DIR:$PATH"

echo "=== Chromium Build Script ==="
echo "Script directory: $SCRIPT_DIR"
echo "Depot tools: $DEPOT_TOOLS_DIR"
echo "Chromium source: $CHROMIUM_DIR"

# Check if depot_tools exists
if [ ! -d "$DEPOT_TOOLS_DIR" ]; then
    echo "Error: depot_tools not found at $DEPOT_TOOLS_DIR"
    echo "Run: git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git"
    exit 1
fi

# Check if chromium source exists
if [ ! -d "$CHROMIUM_DIR/src" ]; then
    echo "Error: Chromium source not found at $CHROMIUM_DIR/src"
    echo "Run: mkdir chromium && cd chromium && fetch --no-history chromium"
    exit 1
fi

cd "$CHROMIUM_DIR/src"

echo ""
echo "=== Step 1: Update gclient dependencies ==="
gclient sync --jobs=8

echo ""
echo "=== Step 2: Generate build files with GN ==="
# Create args.gn for optimized build
mkdir -p "$BUILD_DIR"
cat > "$BUILD_DIR/args.gn" << 'EOF'
# Build configuration for Chromium
# Optimized for faster builds on macOS ARM64

# Release build (faster and smaller)
is_debug = false

# Component build (faster incremental builds)
is_component_build = true

# Disable expensive symbols
symbol_level = 0

# Use system Xcode
use_system_xcode = true

# Target CPU (auto-detected on ARM Mac)
# target_cpu = "arm64"

# Disable some optional features for faster build
enable_nacl = false
use_jumbo_build = true
EOF

echo "Generated build configuration:"
cat "$BUILD_DIR/args.gn"

# Generate ninja files
gn gen "$BUILD_DIR"

echo ""
echo "=== Step 3: Build Chromium ==="
echo "Starting build with autoninja..."
echo "This will take several hours depending on your machine."

# Get number of CPU cores
JOBS=$(sysctl -n hw.ncpu)
echo "Building with $JOBS parallel jobs"

# Build chrome target
autoninja -C "$BUILD_DIR" chrome

echo ""
echo "=== Build Complete! ==="
echo "Chromium.app is located at: $CHROMIUM_DIR/src/$BUILD_DIR/Chromium.app"
echo ""
echo "To run Chromium:"
echo "  open $CHROMIUM_DIR/src/$BUILD_DIR/Chromium.app"
echo "  or"
echo "  $CHROMIUM_DIR/src/$BUILD_DIR/Chromium.app/Contents/MacOS/Chromium"
