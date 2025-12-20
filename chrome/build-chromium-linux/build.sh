#!/bin/bash
# Build Chromium on Linux using Docker
# This script orchestrates the complete Chromium build process in a containerized environment
#
# Requirements:
# - Docker installed and running
# - 100GB+ available disk space
# - 16GB+ RAM (32GB recommended)
# - Multi-core CPU (more cores = faster build)
#
# Estimated time:
# - Source checkout: 30-60 minutes
# - Dependency installation: 10-20 minutes
# - Chromium build: 2-8 hours (depending on hardware)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHROMIUM_DIR="${SCRIPT_DIR}/chromium"
IMAGE_NAME="chromium-builder:latest"

echo "=== Chromium Linux Build Script ==="
echo "Script directory: $SCRIPT_DIR"
echo "Chromium directory: $CHROMIUM_DIR"
echo ""

# Function to check system resources
check_resources() {
    echo "=== Checking System Resources ==="

    # Check available disk space
    AVAILABLE_SPACE=$(df -BG "$SCRIPT_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    echo "Available disk space: ${AVAILABLE_SPACE}GB"

    if [ "$AVAILABLE_SPACE" -lt 100 ]; then
        echo "WARNING: Less than 100GB available. Chromium build requires 100GB+."
        echo "Continue anyway? (y/n)"
        read -r response
        if [ "$response" != "y" ]; then
            echo "Exiting."
            exit 1
        fi
    fi

    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        echo "ERROR: Docker is not running. Please start Docker and try again."
        exit 1
    fi

    echo "System resources check: OK"
    echo ""
}

# Function to build the Docker image
build_docker_image() {
    echo "=== Building Docker Image ==="

    if docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        echo "Docker image '$IMAGE_NAME' already exists."
        echo "Rebuild? (y/n)"
        read -r response
        if [ "$response" != "y" ]; then
            echo "Using existing image."
            return
        fi
    fi

    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    echo "Docker image built successfully."
    echo ""
}

# Function to fetch Chromium source
fetch_chromium_source() {
    echo "=== Fetching Chromium Source ==="

    if [ -d "$CHROMIUM_DIR/src" ]; then
        echo "Chromium source already exists at $CHROMIUM_DIR/src"
        echo "Re-fetch? This will delete the existing source. (y/n)"
        read -r response
        if [ "$response" != "y" ]; then
            echo "Using existing source."
            return
        fi
        rm -rf "$CHROMIUM_DIR"
    fi

    mkdir -p "$CHROMIUM_DIR"

    echo "Fetching Chromium source (this will take 30-60 minutes and download ~35GB)..."
    echo "Running in Docker container..."

    docker run -it --rm \
        -v "$CHROMIUM_DIR:/home/chromium-builder/chromium" \
        "$IMAGE_NAME" \
        bash -c "cd chromium && fetch --no-history chromium"

    echo "Source fetch complete."
    echo ""
}

# Function to setup build environment
setup_build_environment() {
    echo "=== Setting Up Build Environment ==="

    if [ ! -d "$CHROMIUM_DIR/src" ]; then
        echo "ERROR: Chromium source not found. Run fetch_chromium_source first."
        exit 1
    fi

    echo "Installing build dependencies and configuring build..."
    echo "This will take 10-20 minutes..."

    docker run -it --rm \
        -v "$CHROMIUM_DIR:/home/chromium-builder/chromium" \
        "$IMAGE_NAME" \
        /home/chromium-builder/setup-build.sh

    echo "Build environment setup complete."
    echo ""
}

# Function to build Chromium
build_chromium() {
    echo "=== Building Chromium ==="

    if [ ! -f "$CHROMIUM_DIR/src/out/Default/args.gn" ]; then
        echo "ERROR: Build not configured. Run setup_build_environment first."
        exit 1
    fi

    # Get CPU count for optimal parallelization
    CPU_COUNT=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "8")
    echo "Building with $CPU_COUNT parallel jobs..."
    echo ""
    echo "This will take 2-8 hours depending on your hardware."
    echo "You can monitor progress in the output below."
    echo ""
    echo "Starting build at $(date)"
    echo ""

    # Run the build with resource limits
    docker run -it --rm \
        -v "$CHROMIUM_DIR:/home/chromium-builder/chromium" \
        --memory="16g" \
        --cpus="$CPU_COUNT" \
        "$IMAGE_NAME" \
        bash -c "cd chromium/src && autoninja -C out/Default chrome"

    BUILD_EXIT_CODE=$?

    echo ""
    echo "Build finished at $(date)"
    echo ""

    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        echo "=== BUILD SUCCESSFUL ==="
        echo ""
        echo "Chromium binary location:"
        echo "  $CHROMIUM_DIR/src/out/Default/chrome"
        echo ""
        echo "To run Chromium:"
        echo "  $CHROMIUM_DIR/src/out/Default/chrome"
        echo ""

        # Get build output size
        if [ -d "$CHROMIUM_DIR/src/out/Default" ]; then
            BUILD_SIZE=$(du -sh "$CHROMIUM_DIR/src/out/Default" | cut -f1)
            echo "Build output size: $BUILD_SIZE"
        fi
    else
        echo "=== BUILD FAILED ==="
        echo "Exit code: $BUILD_EXIT_CODE"
        echo ""
        echo "Check the output above for error messages."
        echo "Common issues:"
        echo "  - Insufficient disk space"
        echo "  - Insufficient memory (need 16GB+)"
        echo "  - Network issues during dependency fetch"
        echo ""
        exit $BUILD_EXIT_CODE
    fi
}

# Function to show usage
usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  check       - Check system resources"
    echo "  image       - Build Docker image"
    echo "  fetch       - Fetch Chromium source code"
    echo "  setup       - Setup build environment"
    echo "  build       - Build Chromium"
    echo "  all         - Run all steps (check, image, fetch, setup, build)"
    echo "  clean       - Remove Chromium source and build artifacts"
    echo ""
    echo "Examples:"
    echo "  $0 all      - Complete build from scratch"
    echo "  $0 build    - Build with existing source and setup"
    echo ""
}

# Function to clean up
clean() {
    echo "=== Cleaning Up ==="
    echo "This will remove:"
    echo "  - Chromium source (~35GB)"
    echo "  - Build artifacts (~8-65GB)"
    echo ""
    echo "Are you sure? (yes/no)"
    read -r response
    if [ "$response" = "yes" ]; then
        rm -rf "$CHROMIUM_DIR"
        echo "Cleanup complete."
    else
        echo "Cleanup cancelled."
    fi
}

# Main script logic
case "${1:-all}" in
    check)
        check_resources
        ;;
    image)
        build_docker_image
        ;;
    fetch)
        check_resources
        build_docker_image
        fetch_chromium_source
        ;;
    setup)
        check_resources
        build_docker_image
        setup_build_environment
        ;;
    build)
        check_resources
        build_chromium
        ;;
    all)
        check_resources
        build_docker_image
        fetch_chromium_source
        setup_build_environment
        build_chromium
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        usage
        exit 1
        ;;
esac

echo ""
echo "=== Done ==="
