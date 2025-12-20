#!/bin/bash
# Build Bun from source
# This script is meant to be run inside the Docker container

set -e

echo "=========================================="
echo "Building Bun from Source"
echo "=========================================="

cd /build/bun

# Verify prerequisites
echo ""
echo "Checking prerequisites..."
echo "- Bun version: $(bun --version)"
echo "- Clang version: $(clang-19 --version | head -1)"
echo "- CMake version: $(cmake --version | head -1)"
echo "- Ninja version: $(ninja --version)"
echo "- Go version: $(go version)"
echo "- Rust version: $(rustc --version)"

echo ""
echo "Disk space:"
df -h /build

echo ""
echo "=========================================="
echo "Starting build process..."
echo "=========================================="

# Run the build
# This will:
# 1. Clone submodules
# 2. Download/install Zig (automatically)
# 3. Build dependencies
# 4. Compile Bun

echo ""
echo "Running: bun run build"
echo "This will take a while..."
echo ""

# Set timeout for very long builds (2 hours)
timeout 7200 bun run build || {
    exit_code=$?
    if [ $exit_code -eq 124 ]; then
        echo "ERROR: Build timed out after 2 hours"
        exit 1
    fi
    echo "ERROR: Build failed with exit code $exit_code"
    exit $exit_code
}

echo ""
echo "=========================================="
echo "Build completed!"
echo "=========================================="

# Verify the build
if [ -f "./build/debug/bun-debug" ]; then
    echo ""
    echo "Debug binary created successfully!"
    echo "Version: $(./build/debug/bun-debug --version)"
    echo "Size: $(ls -lh ./build/debug/bun-debug | awk '{print $5}')"
    echo ""
    echo "Running quick sanity test..."
    ./build/debug/bun-debug --print "console.log('Hello from Bun debug build!')"
    exit 0
else
    echo ""
    echo "ERROR: Debug binary not found at ./build/debug/bun-debug"
    echo ""
    echo "Contents of ./build directory:"
    ls -la ./build/ || echo "(directory doesn't exist)"
    exit 1
fi
