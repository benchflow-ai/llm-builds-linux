# Dockerfile for building Alpine Linux rootfs
# Uses alpine-make-rootfs for proper Alpine setup
FROM --platform=linux/amd64 alpine:3.19

# Install build tools
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    git \
    e2fsprogs \
    parted \
    dosfstools \
    squashfs-tools \
    xorriso \
    grub \
    grub-bios \
    grub-efi \
    syslinux \
    cpio \
    gzip \
    xz \
    linux-virt \
    qemu-system-x86_64 \
    qemu-img \
    mkinitfs \
    busybox-static \
    util-linux

# Download alpine-make-rootfs
RUN wget -q https://raw.githubusercontent.com/alpinelinux/alpine-make-rootfs/master/alpine-make-rootfs \
    -O /usr/local/bin/alpine-make-rootfs && \
    chmod +x /usr/local/bin/alpine-make-rootfs

# Create working directory
WORKDIR /build

# Copy build scripts
COPY build-scripts/ /build/scripts/

# Set execution permissions
RUN chmod +x /build/scripts/*.sh 2>/dev/null || true

CMD ["/bin/bash"]
