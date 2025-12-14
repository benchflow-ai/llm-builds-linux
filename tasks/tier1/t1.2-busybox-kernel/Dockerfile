# Build environment for T1.2: BusyBox + Kernel minimal Linux
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses-dev \
    flex \
    bison \
    bc \
    libelf-dev \
    libssl-dev \
    wget \
    curl \
    cpio \
    gzip \
    qemu-system-x86 \
    file \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /build

# Create a helper script with useful information
RUN echo '#!/bin/bash\n\
echo "=== T1.2: Build Minimal Bootable Linux ===" \n\
echo "" \n\
echo "Your task: Build a minimal Linux that boots in QEMU" \n\
echo "" \n\
echo "Components needed:" \n\
echo "  1. Linux kernel (compile from source)" \n\
echo "  2. BusyBox (static binary)" \n\
echo "  3. initramfs (with init script)" \n\
echo "" \n\
echo "Useful URLs:" \n\
echo "  Kernel: https://cdn.kernel.org/pub/linux/kernel/v6.x/" \n\
echo "  BusyBox: https://busybox.net/downloads/" \n\
echo "" \n\
echo "To test your build:" \n\
echo "  qemu-system-x86_64 -kernel bzImage -initrd initramfs.cpio.gz \\\\" \n\
echo "    -append \"console=ttyS0\" -nographic" \n\
echo "" \n\
echo "Exit QEMU: Ctrl-A X" \n\
' > /usr/local/bin/task-info && chmod +x /usr/local/bin/task-info

# Display task info on shell start
RUN echo 'task-info' >> /root/.bashrc

CMD ["/bin/bash"]
