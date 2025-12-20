# Dockerfile for Building Chromium on Linux
# Based on official Chromium build instructions for Ubuntu
# Reference: https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md
#
# This creates a containerized build environment for Chromium on Linux (Ubuntu 22.04)
#
# IMPORTANT: Building Chromium requires:
# - 100GB+ disk space (35GB source + 65GB build artifacts for full debug build)
# - 16GB+ RAM (32GB recommended)
# - Multi-hour build time (2-8 hours depending on hardware)

FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    lsb-release \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for building (Chromium build scripts prefer this)
RUN useradd -m -s /bin/bash chromium-builder && \
    echo 'chromium-builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER chromium-builder
WORKDIR /home/chromium-builder

# Clone depot_tools (required for Chromium build system)
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

# Add depot_tools to PATH
ENV PATH="/home/chromium-builder/depot_tools:${PATH}"

# Fetch Chromium source code (this will take 30+ minutes and download ~35GB)
# Using --no-history to skip git history and save space/time
# NOTE: This layer is commented out by default because it's massive
# Uncomment to bake the source into the image, or run this step at runtime
# RUN mkdir chromium && cd chromium && fetch --no-history chromium

# The following will be run when the source is available:
# After fetching, install build dependencies with:
# cd chromium/src && ./build/install-build-deps.sh --no-prompt
#
# This script installs all required packages including:
# - Build tools: gcc, g++, ninja-build, gn
# - Libraries: libgtk-3-dev, libglib2.0-dev, libnss3-dev, libatk1.0-dev
# - X11 dependencies: libx11-dev, libxcomposite-dev, libxdamage-dev
# - Audio: libasound2-dev, libpulse-dev
# - Graphics: libgl1-mesa-dev, libglu1-mesa-dev
# - And many more (200+ packages)

# Set up build configuration
# Create a script that will configure the build
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "=== Chromium Linux Build Setup ==="\n\
\n\
# Check if source exists\n\
if [ ! -d "/home/chromium-builder/chromium/src" ]; then\n\
    echo "ERROR: Chromium source not found."\n\
    echo "Please run: mkdir chromium && cd chromium && fetch --no-history chromium"\n\
    exit 1\n\
fi\n\
\n\
cd /home/chromium-builder/chromium/src\n\
\n\
# Install build dependencies\n\
echo "Installing build dependencies (this requires sudo and takes 10+ minutes)..."\n\
sudo ./build/install-build-deps.sh --no-prompt\n\
\n\
# Run gclient sync to fetch all dependencies\n\
echo "Running gclient sync..."\n\
gclient sync --jobs=8\n\
\n\
# Create optimized build configuration\n\
echo "Creating build configuration..."\n\
mkdir -p out/Default\n\
cat > out/Default/args.gn << EOF\n\
# Chromium build configuration for Linux\n\
# Optimized for faster builds\n\
\n\
# Release build (no debug symbols)\n\
is_debug = false\n\
\n\
# Component build (faster incremental builds, but slower runtime)\n\
is_component_build = true\n\
\n\
# Disable symbols (saves significant disk space and build time)\n\
symbol_level = 0\n\
\n\
# Use system libraries where possible\n\
use_sysroot = true\n\
\n\
# Enable Clang (recommended)\n\
is_clang = true\n\
\n\
# Disable NaCl (not needed for basic builds)\n\
enable_nacl = false\n\
\n\
# Use jumbo builds for faster compilation\n\
use_jumbo_build = true\n\
\n\
# Treat warnings as non-fatal\n\
treat_warnings_as_errors = false\n\
EOF\n\
\n\
echo "Build configuration:"\n\
cat out/Default/args.gn\n\
\n\
# Generate build files\n\
echo "Generating build files with GN..."\n\
gn gen out/Default\n\
\n\
echo ""\n\
echo "=== Setup Complete ==="\n\
echo "To build Chromium, run:"\n\
echo "  autoninja -C out/Default chrome"\n\
echo ""\n\
echo "Build time: 2-8 hours depending on hardware"\n\
echo "Output: chromium/src/out/Default/chrome"\n\
' > /home/chromium-builder/setup-build.sh && \
chmod +x /home/chromium-builder/setup-build.sh

# Default command
CMD ["/bin/bash"]

# Build instructions:
#
# 1. Build the Docker image:
#    docker build -t chromium-builder .
#
# 2. Run the container with sufficient resources:
#    docker run -it --rm \
#      -v $(pwd)/chromium:/home/chromium-builder/chromium \
#      --memory="16g" \
#      --cpus="8" \
#      chromium-builder
#
# 3. Inside the container, fetch the source (first time only):
#    mkdir chromium && cd chromium
#    fetch --no-history chromium
#    cd ..
#
# 4. Run the setup script:
#    ./setup-build.sh
#
# 5. Build Chromium:
#    cd chromium/src
#    autoninja -C out/Default chrome
#
# 6. The built binary will be at:
#    chromium/src/out/Default/chrome
#
# Tips:
# - Mount a volume for chromium/ directory to persist the source and build
# - Allocate at least 16GB RAM (32GB recommended)
# - Allocate at least 100GB disk space
# - Build time varies from 2 hours (64-core workstation) to 8+ hours (8-core laptop)
# - Component builds are faster but create many .so files
# - For faster builds, increase parallel jobs: autoninja -j 16 -C out/Default chrome
