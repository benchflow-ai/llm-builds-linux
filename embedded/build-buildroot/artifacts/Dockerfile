FROM ubuntu:22.04

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install Buildroot dependencies
# Based on Buildroot manual: https://buildroot.org/downloads/manual/manual.html#requirement
RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses5-dev \
    git \
    wget \
    cpio \
    unzip \
    rsync \
    bc \
    file \
    python3 \
    python3-dev \
    libssl-dev \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Create workspace
WORKDIR /workspace

# Download and extract Buildroot
# Using LTS version 2024.02.x
ARG BUILDROOT_VERSION=2024.02.9
RUN wget https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.gz \
    && tar -xzf buildroot-${BUILDROOT_VERSION}.tar.gz \
    && mv buildroot-${BUILDROOT_VERSION} buildroot \
    && rm buildroot-${BUILDROOT_VERSION}.tar.gz

WORKDIR /workspace/buildroot

# Set up for QEMU x86_64 target
# This will be configured in the build script

CMD ["/bin/bash"]
