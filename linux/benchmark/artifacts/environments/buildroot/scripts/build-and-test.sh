#!/bin/bash
# Build Buildroot and test boot in QEMU

set -e

cd /workspace/buildroot

echo "=== Starting Buildroot build ==="
echo "Configuration: $(cat .config | grep BR2_DEFCONFIG)"

# Build
time make -j$(nproc)

echo ""
echo "=== Build complete ==="
echo "Output images:"
ls -lh output/images/

echo ""
echo "=== Testing boot in QEMU ==="

# Boot test with timeout
timeout 60 qemu-system-x86_64 \
    -M pc \
    -kernel output/images/bzImage \
    -drive file=output/images/rootfs.ext2,if=virtio,format=raw \
    -append "rootwait root=/dev/vda console=ttyS0" \
    -net nic,model=virtio -net user \
    -nographic 2>&1 | head -100

echo ""
echo "=== Boot test complete ==="
