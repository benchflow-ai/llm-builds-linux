#!/bin/bash
# Remaster Linux Mint ISO
# Downloads official Mint ISO and customizes it

set -e

DISTRO_NAME="${DISTRO_NAME:-CustomMint}"
DISTRO_VERSION="${DISTRO_VERSION:-1.0}"
BUILD_DIR="/build/work"
OUTPUT_DIR="/build/output"
MINT_ISO_URL="${MINT_ISO_URL:-https://mirrors.kernel.org/linuxmint/stable/21.3/linuxmint-21.3-cinnamon-64bit.iso}"
MINT_ISO_NAME="linuxmint-original.iso"

echo "=============================================="
echo "Remastering Linux Mint"
echo "Building: ${DISTRO_NAME} v${DISTRO_VERSION}"
echo "=============================================="

mkdir -p "${BUILD_DIR}"/{original,custom,newiso,squashfs}
mkdir -p "${OUTPUT_DIR}"
cd "${BUILD_DIR}"

# Download Mint ISO if not present
if [ ! -f "${BUILD_DIR}/${MINT_ISO_NAME}" ]; then
    echo "[1/7] Downloading Linux Mint ISO..."
    wget -O "${BUILD_DIR}/${MINT_ISO_NAME}" "${MINT_ISO_URL}" || {
        echo "Failed to download from primary mirror, trying alternative..."
        wget -O "${BUILD_DIR}/${MINT_ISO_NAME}" "https://ftp.heanet.ie/mirrors/linuxmint.com/stable/21.3/linuxmint-21.3-cinnamon-64bit.iso"
    }
else
    echo "[1/7] Using existing ISO..."
fi

echo "[2/7] Extracting ISO contents..."
# Mount and extract ISO
mkdir -p "${BUILD_DIR}/mnt"
mount -o loop "${BUILD_DIR}/${MINT_ISO_NAME}" "${BUILD_DIR}/mnt" || {
    # Try 7z extraction as fallback
    7z x -o"${BUILD_DIR}/original" "${BUILD_DIR}/${MINT_ISO_NAME}" -y
}

if mountpoint -q "${BUILD_DIR}/mnt"; then
    rsync -a "${BUILD_DIR}/mnt/" "${BUILD_DIR}/original/"
    umount "${BUILD_DIR}/mnt"
fi

echo "[3/7] Extracting squashfs filesystem..."
# Find and extract squashfs
SQUASHFS_PATH=$(find "${BUILD_DIR}/original" -name "filesystem.squashfs" 2>/dev/null | head -1)
if [ -z "${SQUASHFS_PATH}" ]; then
    echo "ERROR: Could not find filesystem.squashfs"
    exit 1
fi

unsquashfs -d "${BUILD_DIR}/squashfs" "${SQUASHFS_PATH}"

echo "[4/7] Customizing the system..."

# Mount necessary filesystems for chroot
mount --bind /dev "${BUILD_DIR}/squashfs/dev"
mount --bind /run "${BUILD_DIR}/squashfs/run"
mount -t devpts devpts "${BUILD_DIR}/squashfs/dev/pts"
mount -t proc proc "${BUILD_DIR}/squashfs/proc"
mount -t sysfs sysfs "${BUILD_DIR}/squashfs/sys"

# Copy resolv.conf
cp /etc/resolv.conf "${BUILD_DIR}/squashfs/etc/resolv.conf"

# Perform customizations inside chroot
chroot "${BUILD_DIR}/squashfs" /bin/bash << 'CUSTOMIZE'
set -e
export DEBIAN_FRONTEND=noninteractive
export HOME=/root

# Update package lists
apt-get update || true

# Example customizations - add/remove packages as needed
# Install additional packages
apt-get install -y \
    neofetch \
    htop \
    vim \
    git \
    curl \
    wget \
    tree \
    tmux || true

# Remove unwanted packages (examples)
# apt-get remove -y --purge libreoffice* || true
# apt-get remove -y --purge thunderbird* || true

# Clean up
apt-get autoremove -y || true
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

# Custom branding
echo "${DISTRO_NAME:-CustomMint}" > /etc/hostname 2>/dev/null || true

# Create custom welcome message
cat > /etc/motd << 'MOTD'
Welcome to CustomMint!
Built with love by an LLM.
MOTD

echo "Customization complete!"
CUSTOMIZE

# Unmount chroot filesystems
umount "${BUILD_DIR}/squashfs/dev/pts" || true
umount "${BUILD_DIR}/squashfs/dev" || true
umount "${BUILD_DIR}/squashfs/run" || true
umount "${BUILD_DIR}/squashfs/proc" || true
umount "${BUILD_DIR}/squashfs/sys" || true

echo "[5/7] Creating new squashfs filesystem..."
# Copy original ISO structure
rsync -a "${BUILD_DIR}/original/" "${BUILD_DIR}/newiso/"

# Remove old squashfs
rm -f "${BUILD_DIR}/newiso/casper/filesystem.squashfs"

# Create new squashfs
mksquashfs "${BUILD_DIR}/squashfs" "${BUILD_DIR}/newiso/casper/filesystem.squashfs" \
    -comp xz -b 1M -noappend

# Update filesystem size
printf $(du -sx --block-size=1 "${BUILD_DIR}/squashfs" | cut -f1) > "${BUILD_DIR}/newiso/casper/filesystem.size"

echo "[6/7] Updating boot configuration..."
# Update GRUB config with custom name
if [ -f "${BUILD_DIR}/newiso/boot/grub/grub.cfg" ]; then
    sed -i "s/Linux Mint/${DISTRO_NAME}/g" "${BUILD_DIR}/newiso/boot/grub/grub.cfg"
fi

if [ -f "${BUILD_DIR}/newiso/isolinux/isolinux.cfg" ]; then
    sed -i "s/Linux Mint/${DISTRO_NAME}/g" "${BUILD_DIR}/newiso/isolinux/isolinux.cfg"
fi

echo "[7/7] Building new ISO..."
ISO_NAME="${DISTRO_NAME}-${DISTRO_VERSION}-amd64.iso"

cd "${BUILD_DIR}/newiso"

# Build ISO with both BIOS and UEFI support
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
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -output "${OUTPUT_DIR}/${ISO_NAME}" \
    . || {
    # Fallback without EFI
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "${DISTRO_NAME}" \
        -eltorito-boot isolinux/isolinux.bin \
        -eltorito-catalog isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -output "${OUTPUT_DIR}/${ISO_NAME}" \
        .
}

echo "=============================================="
echo "Remaster complete!"
echo "ISO: ${OUTPUT_DIR}/${ISO_NAME}"
echo "Size: $(du -h ${OUTPUT_DIR}/${ISO_NAME} | cut -f1)"
echo "=============================================="

# Generate checksums
cd "${OUTPUT_DIR}"
sha256sum "${ISO_NAME}" > "${ISO_NAME}.sha256"
md5sum "${ISO_NAME}" > "${ISO_NAME}.md5"

echo "Checksums generated. Done!"
