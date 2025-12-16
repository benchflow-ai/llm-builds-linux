#!/bin/bash
# Build a custom Linux distro based on Linux Mint
# This script runs inside the Docker container

set -e

DISTRO_NAME="${DISTRO_NAME:-CustomMint}"
DISTRO_VERSION="${DISTRO_VERSION:-1.0}"
BUILD_DIR="/build/work"
OUTPUT_DIR="/build/output"
MINT_VERSION="${MINT_VERSION:-21.3}"
MINT_CODENAME="${MINT_CODENAME:-virginia}"
UBUNTU_CODENAME="${UBUNTU_CODENAME:-jammy}"

echo "=============================================="
echo "Building ${DISTRO_NAME} v${DISTRO_VERSION}"
echo "Based on Linux Mint ${MINT_VERSION} (${MINT_CODENAME})"
echo "=============================================="

# Create build directories
mkdir -p "${BUILD_DIR}"/{chroot,iso,scratch}
mkdir -p "${OUTPUT_DIR}"

cd "${BUILD_DIR}"

echo "[1/8] Setting up debootstrap for Ubuntu ${UBUNTU_CODENAME}..."

# Use debootstrap to create base Ubuntu system (Mint's foundation)
if [ ! -d "${BUILD_DIR}/chroot/bin" ]; then
    debootstrap --arch=amd64 "${UBUNTU_CODENAME}" "${BUILD_DIR}/chroot" http://archive.ubuntu.com/ubuntu/
fi

echo "[2/8] Configuring chroot environment..."

# Mount necessary filesystems
mount --bind /dev "${BUILD_DIR}/chroot/dev" || true
mount --bind /run "${BUILD_DIR}/chroot/run" || true
mount -t devpts devpts "${BUILD_DIR}/chroot/dev/pts" || true
mount -t proc proc "${BUILD_DIR}/chroot/proc" || true
mount -t sysfs sysfs "${BUILD_DIR}/chroot/sys" || true

# Set up resolv.conf for network access
# Remove symlink if it exists and copy actual file
rm -f "${BUILD_DIR}/chroot/etc/resolv.conf"
cp /etc/resolv.conf "${BUILD_DIR}/chroot/etc/resolv.conf"

echo "[3/8] Setting up package sources..."

# Create sources.list with Ubuntu repositories
cat > "${BUILD_DIR}/chroot/etc/apt/sources.list" << EOF
# Ubuntu base
deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME} main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME}-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ ${UBUNTU_CODENAME}-security main restricted universe multiverse
EOF

echo "[4/8] Installing base system packages..."

# Configure chroot and install packages
chroot "${BUILD_DIR}/chroot" /bin/bash << 'CHROOT_SCRIPT'
set -e
export DEBIAN_FRONTEND=noninteractive
export HOME=/root

# Update package lists
apt-get update

# Install essential packages for a bootable system
apt-get install -y \
    linux-generic \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    shim-signed \
    casper \
    discover \
    laptop-detect \
    os-prober \
    network-manager \
    net-tools \
    wireless-tools \
    wpasupplicant \
    locales \
    console-setup \
    sudo \
    systemd-sysv \
    plymouth \
    plymouth-theme-spinner

# Install minimal desktop environment (XFCE - lightweight)
apt-get install -y \
    xorg \
    xfce4 \
    xfce4-terminal \
    lightdm

# Install common utilities
apt-get install -y \
    vim \
    nano \
    htop \
    wget \
    curl \
    file

# Clean up
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

# Set locale
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Create a default user for live session
useradd -m -s /bin/bash -G sudo live || true
echo "live:live" | chpasswd
echo "live ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set hostname
echo "customlinux" > /etc/hostname

# Configure casper for live session
mkdir -p /etc/casper.conf.d
cat > /etc/casper.conf << 'CASPERCONF'
export USERNAME="live"
export USERFULLNAME="Live User"
export HOST="customlinux"
export BUILD_SYSTEM="Ubuntu"
CASPERCONF

CHROOT_SCRIPT

echo "[5/8] Creating live filesystem..."

# Unmount chroot filesystems
umount "${BUILD_DIR}/chroot/dev/pts" || true
umount "${BUILD_DIR}/chroot/dev" || true
umount "${BUILD_DIR}/chroot/run" || true
umount "${BUILD_DIR}/chroot/proc" || true
umount "${BUILD_DIR}/chroot/sys" || true

# Create squashfs filesystem
mkdir -p "${BUILD_DIR}/iso/casper"
mksquashfs "${BUILD_DIR}/chroot" "${BUILD_DIR}/iso/casper/filesystem.squashfs" \
    -comp xz -b 1M -Xdict-size 100% -noappend

# Calculate filesystem size
printf $(du -sx --block-size=1 "${BUILD_DIR}/chroot" | cut -f1) > "${BUILD_DIR}/iso/casper/filesystem.size"

echo "[6/8] Setting up boot configuration..."

# Copy kernel and initrd
cp "${BUILD_DIR}/chroot/boot/vmlinuz-"* "${BUILD_DIR}/iso/casper/vmlinuz"
cp "${BUILD_DIR}/chroot/boot/initrd.img-"* "${BUILD_DIR}/iso/casper/initrd"

# Create GRUB configuration
mkdir -p "${BUILD_DIR}/iso/boot/grub"
cat > "${BUILD_DIR}/iso/boot/grub/grub.cfg" << EOF
set timeout=10
set default=0

menuentry "${DISTRO_NAME} Live" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}

menuentry "${DISTRO_NAME} Live (Safe Graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset quiet splash ---
    initrd /casper/initrd
}

menuentry "${DISTRO_NAME} Live (To RAM)" {
    linux /casper/vmlinuz boot=casper toram quiet splash ---
    initrd /casper/initrd
}

menuentry "Check disc for defects" {
    linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
    initrd /casper/initrd
}

menuentry "Memory test (memtest86+)" {
    linux16 /boot/memtest86+.bin
}
EOF

# Set up isolinux for legacy BIOS boot
mkdir -p "${BUILD_DIR}/iso/isolinux"
cp /usr/lib/ISOLINUX/isolinux.bin "${BUILD_DIR}/iso/isolinux/" || true
cp /usr/lib/syslinux/modules/bios/*.c32 "${BUILD_DIR}/iso/isolinux/" || true

cat > "${BUILD_DIR}/iso/isolinux/isolinux.cfg" << EOF
DEFAULT live
TIMEOUT 100
PROMPT 0

MENU TITLE ${DISTRO_NAME} Boot Menu

LABEL live
    MENU LABEL ^Start ${DISTRO_NAME}
    KERNEL /casper/vmlinuz
    APPEND initrd=/casper/initrd boot=casper quiet splash ---

LABEL live-safe
    MENU LABEL Start ${DISTRO_NAME} (^Safe Graphics)
    KERNEL /casper/vmlinuz
    APPEND initrd=/casper/initrd boot=casper nomodeset quiet splash ---

LABEL live-toram
    MENU LABEL Start ${DISTRO_NAME} (^To RAM)
    KERNEL /casper/vmlinuz
    APPEND initrd=/casper/initrd boot=casper toram quiet splash ---
EOF

echo "[7/8] Creating EFI boot support..."

# Create EFI boot image
mkdir -p "${BUILD_DIR}/iso/EFI/boot"
mkdir -p "${BUILD_DIR}/scratch"

# Copy EFI files
if [ -f "${BUILD_DIR}/chroot/usr/lib/shim/shimx64.efi.signed" ]; then
    cp "${BUILD_DIR}/chroot/usr/lib/shim/shimx64.efi.signed" "${BUILD_DIR}/iso/EFI/boot/bootx64.efi"
elif [ -f "${BUILD_DIR}/chroot/usr/lib/grub/x86_64-efi/monolithic/grubx64.efi" ]; then
    cp "${BUILD_DIR}/chroot/usr/lib/grub/x86_64-efi/monolithic/grubx64.efi" "${BUILD_DIR}/iso/EFI/boot/bootx64.efi"
fi

if [ -f "${BUILD_DIR}/chroot/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed" ]; then
    cp "${BUILD_DIR}/chroot/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed" "${BUILD_DIR}/iso/EFI/boot/grubx64.efi"
fi

# Create EFI image
dd if=/dev/zero of="${BUILD_DIR}/scratch/efiboot.img" bs=1M count=10
mkfs.vfat "${BUILD_DIR}/scratch/efiboot.img"
mkdir -p "${BUILD_DIR}/scratch/efi_mount"
mount "${BUILD_DIR}/scratch/efiboot.img" "${BUILD_DIR}/scratch/efi_mount"
mkdir -p "${BUILD_DIR}/scratch/efi_mount/EFI/boot"
cp "${BUILD_DIR}/iso/EFI/boot/"* "${BUILD_DIR}/scratch/efi_mount/EFI/boot/" || true
cp "${BUILD_DIR}/iso/boot/grub/grub.cfg" "${BUILD_DIR}/scratch/efi_mount/EFI/boot/" || true
umount "${BUILD_DIR}/scratch/efi_mount"
cp "${BUILD_DIR}/scratch/efiboot.img" "${BUILD_DIR}/iso/boot/grub/"

echo "[8/8] Building ISO image..."

# Create ISO manifest
chroot "${BUILD_DIR}/chroot" dpkg-query -W --showformat='${Package} ${Version}\n' > "${BUILD_DIR}/iso/casper/filesystem.manifest" || true

# Create the ISO
ISO_NAME="${DISTRO_NAME}-${DISTRO_VERSION}-amd64.iso"
cd "${BUILD_DIR}/iso"

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "${DISTRO_NAME}" \
    -eltorito-boot isolinux/isolinux.bin \
    -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-alt-boot \
    -e boot/grub/efiboot.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -output "${OUTPUT_DIR}/${ISO_NAME}" \
    "${BUILD_DIR}/iso"

echo "=============================================="
echo "Build complete!"
echo "ISO: ${OUTPUT_DIR}/${ISO_NAME}"
echo "Size: $(du -h ${OUTPUT_DIR}/${ISO_NAME} | cut -f1)"
echo "=============================================="

# Generate checksums
cd "${OUTPUT_DIR}"
sha256sum "${ISO_NAME}" > "${ISO_NAME}.sha256"
md5sum "${ISO_NAME}" > "${ISO_NAME}.md5"

echo "Checksums generated."
echo "Done!"
