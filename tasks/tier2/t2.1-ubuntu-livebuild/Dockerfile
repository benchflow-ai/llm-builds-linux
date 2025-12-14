# Build environment for T2.1: Ubuntu Live ISO with live-build
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install live-build and dependencies
RUN apt-get update && apt-get install -y \
    live-build \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-common \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    shim-signed \
    mtools \
    dosfstools \
    qemu-system-x86 \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /build

# Create a helper script
RUN echo '#!/bin/bash\n\
echo "=== T2.1: Create Custom Ubuntu Live ISO ===" \n\
echo "" \n\
echo "Your task: Create a custom live ISO using live-build" \n\
echo "" \n\
echo "Basic workflow:" \n\
echo "  1. lb config [options]    # Configure the build" \n\
echo "  2. lb build               # Build the ISO" \n\
echo "" \n\
echo "Key configuration options:" \n\
echo "  --distribution jammy      # Ubuntu 22.04" \n\
echo "  --archive-areas \"main universe\"" \n\
echo "  --apt-recommends false    # Smaller image" \n\
echo "" \n\
echo "Add packages: config/package-lists/custom.list.chroot" \n\
echo "Add scripts: config/hooks/live/*.hook.chroot" \n\
echo "" \n\
echo "Test ISO:" \n\
echo "  qemu-system-x86_64 -cdrom *.iso -m 2G" \n\
' > /usr/local/bin/task-info && chmod +x /usr/local/bin/task-info

RUN echo 'task-info' >> /root/.bashrc

CMD ["/bin/bash"]
