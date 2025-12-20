#!/bin/bash
# Script to configure the system inside chroot
# BROKEN: Missing critical configuration steps

set -e

CHROOT_DIR="$1"

if [ -z "$CHROOT_DIR" ]; then
    echo "Usage: $0 <chroot_directory>"
    exit 1
fi

echo "Configuring system in chroot..."

# Set hostname - this one is correct
echo "custom-distro" > "$CHROOT_DIR/etc/hostname"

# Configure network - BROKEN: incorrect interface name and syntax
cat > "$CHROOT_DIR/etc/network/interfaces" <<EOF
auto lo
iface lo inet loopback

auto eth99
iface eth99 inet dhcp
EOF

# BROKEN: Missing DNS configuration in /etc/resolv.conf

# Set root password - BROKEN: password command will fail in build context
echo "Setting root password..."
chroot "$CHROOT_DIR" passwd root

# BROKEN: Missing locale generation
# Should run: locale-gen en_US.UTF-8

# BROKEN: Missing timezone configuration
# Should set: ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Install kernel - BROKEN: package name is wrong
chroot "$CHROOT_DIR" apt-get install -y linux-image-generic-x86

echo "Chroot configuration complete"
