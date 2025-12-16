#!/bin/bash
# Create a minimal Debian rootfs using debootstrap

set -e

SUITE="${1:-bookworm}"
ARCH="${2:-amd64}"
TARGET="${3:-/workspace/rootfs}"
MIRROR="${4:-http://deb.debian.org/debian/}"

echo "=== Creating minimal Debian rootfs ==="
echo "Suite: $SUITE"
echo "Architecture: $ARCH"
echo "Target: $TARGET"
echo "Mirror: $MIRROR"

# Create rootfs
debootstrap --variant=minbase --arch=$ARCH $SUITE $TARGET $MIRROR

# Configure basic system
echo "=== Configuring system ==="

# Set hostname
echo "debian-minimal" > $TARGET/etc/hostname

# Set root password (root:root)
chroot $TARGET bash -c 'echo "root:root" | chpasswd'

# Configure networking
cat > $TARGET/etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Copy DNS resolver
cp /etc/resolv.conf $TARGET/etc/resolv.conf

echo "=== Rootfs created successfully ==="
echo "Size: $(du -sh $TARGET | cut -f1)"
ls -la $TARGET/
