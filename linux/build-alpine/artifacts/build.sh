#!/bin/bash
# Orchestration script for building Alpine Linux system
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="alpine-builder"
CONTAINER_NAME="alpine-build"
OUTPUT_DIR="${SCRIPT_DIR}/output"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --build-image     Build the Docker image"
    echo "  --build-rootfs    Create Alpine rootfs"
    echo "  --build-bootable  Create bootable disk image"
    echo "  --test            Test with QEMU"
    echo "  --clean           Clean build artifacts"
    echo "  --all             Build everything and test"
    echo "  -h, --help        Show this help"
}

build_image() {
    echo "=== Building Docker image ==="
    docker build --platform linux/amd64 -t "${IMAGE_NAME}" "${SCRIPT_DIR}"
}

build_rootfs() {
    echo "=== Building Alpine rootfs ==="
    mkdir -p "${OUTPUT_DIR}"

    docker run --rm --privileged --platform linux/amd64 \
        -v "${OUTPUT_DIR}:/output" \
        --name "${CONTAINER_NAME}" \
        "${IMAGE_NAME}" \
        /bin/bash -c "
            set -e
            cd /build

            echo '=== Creating Alpine rootfs ==='

            # Use alpine-make-rootfs
            alpine-make-rootfs \
                --branch v3.19 \
                --packages 'alpine-base openrc' \
                --timezone UTC \
                /output/rootfs

            echo '=== Rootfs created ==='
            du -sh /output/rootfs
            ls -la /output/rootfs
        "
}

build_bootable() {
    echo "=== Building bootable image ==="
    mkdir -p "${OUTPUT_DIR}"

    docker run --rm --privileged --platform linux/amd64 \
        -v "${OUTPUT_DIR}:/output" \
        --name "${CONTAINER_NAME}" \
        "${IMAGE_NAME}" \
        /bin/bash -c '
            set -e
            cd /build

            # Create disk image (1GB)
            echo "=== Creating disk image ==="
            dd if=/dev/zero of=/output/alpine.img bs=1M count=1024

            # Create partition table and partitions
            echo "=== Creating partitions ==="
            parted -s /output/alpine.img mklabel msdos
            parted -s /output/alpine.img mkpart primary ext4 1MiB 100%
            parted -s /output/alpine.img set 1 boot on

            # Setup loop device
            LOOPDEV=$(losetup --find --show /output/alpine.img)
            echo "Loop device: $LOOPDEV"

            # Calculate partition offset (2048 sectors * 512 bytes)
            OFFSET=$((2048 * 512))

            # Setup partition as separate loop device
            PART1=$(losetup --find --show --offset $OFFSET /output/alpine.img)
            echo "Partition device: $PART1"

            # Verify partition device exists
            [ -b "$PART1" ] || { echo "Partition not found"; losetup -d "$LOOPDEV"; exit 1; }

            # Format partition
            echo "=== Formatting partition ==="
            mkfs.ext4 -F "$PART1"

            # Mount and populate
            echo "=== Populating filesystem ==="
            mkdir -p /mnt/alpine
            mount "$PART1" /mnt/alpine

            # Create minimal rootfs using alpine-make-rootfs
            alpine-make-rootfs \
                --branch v3.19 \
                --packages "alpine-base linux-virt grub grub-bios openrc" \
                --timezone UTC \
                /mnt/alpine

            # Install GRUB
            echo "=== Installing GRUB ==="
            grub-install --target=i386-pc --boot-directory=/mnt/alpine/boot "$LOOPDEV"

            # Find kernel version
            KERNEL_VERSION=$(ls /mnt/alpine/lib/modules/ | head -1)

            # Create GRUB config
            cat > /mnt/alpine/boot/grub/grub.cfg << EOF
set timeout=3
set default=0

menuentry "Alpine Linux" {
    linux /boot/vmlinuz-virt root=/dev/sda1 rw quiet
    initrd /boot/initramfs-virt
}
EOF

            # Generate initramfs
            chroot /mnt/alpine /bin/sh -c "mkinitfs -o /boot/initramfs-virt $KERNEL_VERSION" || true

            # Cleanup
            echo "=== Cleanup ==="
            umount /mnt/alpine
            losetup -d "$PART1"
            losetup -d "$LOOPDEV"

            # Also create standalone kernel/initramfs for direct QEMU boot
            echo "=== Extracting kernel ==="
            LOOPDEV=$(losetup --find --show /output/alpine.img)
            OFFSET=$((2048 * 512))
            PART1=$(losetup --find --show --offset $OFFSET /output/alpine.img)
            mkdir -p /mnt/alpine
            mount "$PART1" /mnt/alpine
            cp /mnt/alpine/boot/vmlinuz-virt /output/vmlinuz 2>/dev/null || true
            cp /mnt/alpine/boot/initramfs-virt /output/initramfs 2>/dev/null || true
            umount /mnt/alpine
            losetup -d "$PART1"
            losetup -d "$LOOPDEV"

            echo "=== Build complete ==="
            ls -lah /output/
        '
}

test_qemu() {
    echo "=== Testing with QEMU ==="

    if [ -f "${OUTPUT_DIR}/alpine.img" ]; then
        echo "Booting disk image... (Press Ctrl+A, X to exit)"
        qemu-system-x86_64 \
            -drive file="${OUTPUT_DIR}/alpine.img",format=raw \
            -m 512M \
            -nographic \
            -enable-kvm 2>/dev/null || \
        qemu-system-x86_64 \
            -drive file="${OUTPUT_DIR}/alpine.img",format=raw \
            -m 512M \
            -nographic
    elif [ -f "${OUTPUT_DIR}/vmlinuz" ]; then
        echo "Booting kernel directly... (Press Ctrl+A, X to exit)"
        qemu-system-x86_64 \
            -kernel "${OUTPUT_DIR}/vmlinuz" \
            -initrd "${OUTPUT_DIR}/initramfs" \
            -append "console=ttyS0" \
            -m 512M \
            -nographic
    else
        echo "Error: No bootable artifacts found. Run --build-bootable first."
        exit 1
    fi
}

clean() {
    echo "=== Cleaning ==="
    rm -rf "${OUTPUT_DIR}"
    docker rmi "${IMAGE_NAME}" 2>/dev/null || true
    echo "Done"
}

case "${1:-}" in
    --build-image)
        build_image
        ;;
    --build-rootfs)
        build_rootfs
        ;;
    --build-bootable)
        build_bootable
        ;;
    --test)
        test_qemu
        ;;
    --clean)
        clean
        ;;
    --all)
        build_image
        build_bootable
        test_qemu
        ;;
    -h|--help|"")
        usage
        ;;
    *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
esac
