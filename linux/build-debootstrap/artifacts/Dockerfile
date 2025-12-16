# Linux Mint distro builder
# Force AMD64 platform for x86-specific tools
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential build tools
RUN apt-get update && apt-get install -y \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    dosfstools \
    isolinux \
    syslinux-utils \
    wget \
    curl \
    git \
    rsync \
    cpio \
    genisoimage \
    live-build \
    debian-archive-keyring \
    ubuntu-keyring \
    gnupg \
    gpg \
    apt-transport-https \
    ca-certificates \
    p7zip-full \
    binutils \
    zstd \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /build

# Copy build scripts
COPY build-scripts/ /build/scripts/
RUN chmod +x /build/scripts/*.sh 2>/dev/null || true

CMD ["/bin/bash"]
