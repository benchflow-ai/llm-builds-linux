FROM debian:bookworm

# Install debootstrap and required tools
RUN apt-get update && \
    apt-get install -y \
    debootstrap \
    qemu-utils \
    grub-pc-bin \
    grub-efi-amd64-bin \
    parted \
    dosfstools \
    e2fsprogs \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /workspace

# Copy configuration files
COPY debootstrap.conf /workspace/
COPY fstab /workspace/
COPY grub-config.sh /workspace/
COPY setup-chroot.sh /workspace/

# Copy fixed versions for reference
COPY debootstrap.conf.fixed /workspace/fixed/
COPY fstab.fixed /workspace/fixed/
COPY grub-config.sh.fixed /workspace/fixed/
COPY setup-chroot.sh.fixed /workspace/fixed/

# Make scripts executable
RUN chmod +x /workspace/*.sh /workspace/fixed/*.sh

CMD ["/bin/bash"]
