# Dockerfile for building Linux Mint-based live ISO using live-build
# Based on Ubuntu 24.04 (noble) which is the base for Linux Mint 22.x
# Must be built with --platform linux/amd64 on Apple Silicon

FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Install live-build and required tools
RUN apt-get update && apt-get install -y \
    live-build \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-common \
    syslinux-efi \
    syslinux-utils \
    genisoimage \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    shim-signed \
    mtools \
    dosfstools \
    wget \
    curl \
    gnupg \
    git \
    ca-certificates \
    apt-transport-https \
    gdisk \
    fdisk \
    librsvg2-bin \
    && rm -rf /var/lib/apt/lists/*

# Fix broken syslinux symlinks in live-build bootloaders
# The default symlinks point to old paths that don't exist in modern Ubuntu
RUN ISOLINUX_DIR="/usr/share/live/build/bootloaders/isolinux" && \
    rm -f "$ISOLINUX_DIR/isolinux.bin" "$ISOLINUX_DIR/vesamenu.c32" && \
    cp /usr/lib/ISOLINUX/isolinux.bin "$ISOLINUX_DIR/isolinux.bin" && \
    cp /usr/lib/syslinux/modules/bios/vesamenu.c32 "$ISOLINUX_DIR/vesamenu.c32" && \
    cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$ISOLINUX_DIR/ldlinux.c32" && \
    cp /usr/lib/syslinux/modules/bios/libcom32.c32 "$ISOLINUX_DIR/libcom32.c32" && \
    cp /usr/lib/syslinux/modules/bios/libutil.c32 "$ISOLINUX_DIR/libutil.c32" && \
    cp /usr/lib/ISOLINUX/isohdpfx.bin "$ISOLINUX_DIR/isohdpfx.bin"

# Create working directory
WORKDIR /build

# Copy all build files
COPY config/ /build/config/
COPY auto/ /build/auto/
COPY build.sh /build/build.sh

# Fix permissions
RUN chmod +x /build/auto/* /build/build.sh && \
    find /build/config/hooks -type f -name "*.hook.chroot" -exec chmod +x {} \; 2>/dev/null || true

# Default command - will run build script
CMD ["/bin/bash", "/build/build.sh"]
