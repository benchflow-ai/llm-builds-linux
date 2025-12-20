# Dockerfile for building a minimal BusyBox-based Linux system
# Platform: linux/amd64
FROM --platform=linux/amd64 ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    bc \
    bison \
    flex \
    libelf-dev \
    libssl-dev \
    libncurses-dev \
    kmod \
    cpio \
    wget \
    curl \
    xz-utils \
    gzip \
    qemu-system-x86 \
    qemu-utils \
    linux-image-generic \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /build

# Default command
CMD ["/bin/bash"]
