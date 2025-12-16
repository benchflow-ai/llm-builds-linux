# Debootstrap build environment
# Provides everything needed for Debian/Ubuntu-based distro building

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install debootstrap and related tools
RUN apt-get update && apt-get install -y \
    # Core tools
    debootstrap \
    debian-archive-keyring \
    ubuntu-keyring \
    # Disk and filesystem
    parted \
    e2fsprogs \
    dosfstools \
    mtools \
    # Bootloader
    grub-pc-bin \
    grub-efi-amd64-bin \
    syslinux \
    isolinux \
    syslinux-common \
    # ISO creation
    squashfs-tools \
    xorriso \
    genisoimage \
    # QEMU for testing
    qemu-system-x86 \
    qemu-utils \
    qemu-user-static \
    # Utilities
    kmod \
    wget \
    curl \
    git \
    vim \
    less \
    tree \
    file \
    && rm -rf /var/lib/apt/lists/*

# Create workspace
WORKDIR /workspace

# Add helper scripts
COPY scripts/ /usr/local/bin/

CMD ["/bin/bash"]
