# Build environment for T2.3: Buildroot minimal embedded Linux
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Buildroot build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses-dev \
    rsync \
    cpio \
    python3 \
    python-is-python3 \
    unzip \
    bc \
    wget \
    curl \
    git \
    file \
    qemu-system-x86 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN echo '#!/bin/bash\n\
echo "=== T2.3: Build Minimal Linux with Buildroot ===" \n\
echo "" \n\
echo "Your task: Use Buildroot to create an embedded Linux system" \n\
echo "" \n\
echo "Steps:" \n\
echo "  1. wget https://buildroot.org/downloads/buildroot-2024.02.tar.gz" \n\
echo "  2. tar xf buildroot-2024.02.tar.gz && cd buildroot-2024.02" \n\
echo "  3. make qemu_x86_64_defconfig" \n\
echo "  4. make menuconfig  # Add custom packages" \n\
echo "  5. make -j$(nproc)  # Build (30-60 min)" \n\
echo "" \n\
echo "Test with:" \n\
echo "  ./board/qemu/x86_64/start-qemu.sh" \n\
echo "" \n\
echo "Output in: output/images/" \n\
' > /usr/local/bin/task-info && chmod +x /usr/local/bin/task-info

RUN echo 'task-info' >> /root/.bashrc

CMD ["/bin/bash"]
