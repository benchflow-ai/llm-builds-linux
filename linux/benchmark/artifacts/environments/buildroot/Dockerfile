# Buildroot build environment
# Provides everything needed for Buildroot-based distro building

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install Buildroot dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    patch \
    gzip \
    bzip2 \
    perl \
    cpio \
    unzip \
    rsync \
    bc \
    wget \
    curl \
    python3 \
    python3-pip \
    file \
    git \
    libncurses-dev \
    libssl-dev \
    flex \
    bison \
    # QEMU for testing
    qemu-system-x86 \
    qemu-utils \
    # Utilities
    vim \
    less \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Create workspace
WORKDIR /workspace

# Download Buildroot
ARG BUILDROOT_VERSION=2024.02
RUN wget -q https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.gz \
    && tar xzf buildroot-${BUILDROOT_VERSION}.tar.gz \
    && rm buildroot-${BUILDROOT_VERSION}.tar.gz \
    && mv buildroot-${BUILDROOT_VERSION} buildroot

# Set up default config
WORKDIR /workspace/buildroot
RUN make qemu_x86_64_defconfig

# Pre-download sources to speed up builds (optional, makes image larger)
# RUN make source

WORKDIR /workspace

# Add helper scripts
COPY scripts/ /usr/local/bin/

CMD ["/bin/bash"]
