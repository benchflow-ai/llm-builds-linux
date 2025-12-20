#!/bin/bash
# Test script to demonstrate iterative debugging process

set +e  # Don't exit on errors, we want to see all failures

echo "========================================"
echo "Testing Broken Configuration"
echo "========================================"
echo ""

# Test 1: Check architecture
echo "Test 1: Checking architecture in debootstrap.conf..."
ARCH=$(grep "^ARCH=" debootstrap.conf | cut -d'"' -f2)
if dpkg-architecture -L | grep -q "^$ARCH$"; then
    echo "  ✓ Architecture '$ARCH' is valid"
else
    echo "  ✗ FAIL: Architecture '$ARCH' is INVALID"
    echo "    Valid architectures: amd64, i386, arm64, armhf, etc."
fi
echo ""

# Test 2: Check for kernel package
echo "Test 2: Checking for kernel package..."
INCLUDES=$(grep "^INCLUDE_PACKAGES=" debootstrap.conf | cut -d'"' -f2)
if echo "$INCLUDES" | grep -q "linux-image"; then
    echo "  ✓ Kernel package found in INCLUDE_PACKAGES"
else
    echo "  ✗ FAIL: No kernel package in INCLUDE_PACKAGES"
    echo "    Should include: linux-image-amd64 or linux-image-generic"
fi
echo ""

# Test 3: Check fstab filesystem types
echo "Test 3: Checking fstab for valid filesystem types..."
if grep -q "ext5" fstab; then
    echo "  ✗ FAIL: Invalid filesystem type 'ext5' found"
    echo "    Valid types: ext4, ext3, ext2, xfs, btrfs"
else
    echo "  ✓ No invalid filesystem types"
fi
echo ""

# Test 4: Check for critical mount points
echo "Test 4: Checking for critical mount points in fstab..."
missing_mounts=()
grep -q "/proc" fstab || missing_mounts+=("/proc")
grep -q "/sys" fstab || missing_mounts+=("/sys")
grep -q "/dev/pts" fstab || missing_mounts+=("/dev/pts")

if [ ${#missing_mounts[@]} -eq 0 ]; then
    echo "  ✓ All critical mount points present"
else
    echo "  ✗ FAIL: Missing critical mount points: ${missing_mounts[*]}"
fi
echo ""

# Test 5: Check GRUB installation command
echo "Test 5: Checking GRUB installation command..."
if grep -q "grub-instal " grub-config.sh; then
    echo "  ✗ FAIL: Typo in command 'grub-instal' (should be 'grub-install')"
else
    echo "  ✓ GRUB command is correct"
fi
echo ""

# Test 6: Check for grub-mkconfig
echo "Test 6: Checking for grub-mkconfig command..."
if grep -q "grub-mkconfig" grub-config.sh; then
    echo "  ✓ grub-mkconfig found"
else
    echo "  ✗ FAIL: Missing grub-mkconfig command"
    echo "    Required to generate /boot/grub/grub.cfg"
fi
echo ""

# Test 7: Check kernel package name in setup script
echo "Test 7: Checking kernel package name..."
if grep -q "linux-image-generic-x86" setup-chroot.sh; then
    echo "  ✗ FAIL: Invalid package name 'linux-image-generic-x86'"
    echo "    Correct: linux-image-amd64 (Debian) or linux-image-generic (Ubuntu)"
else
    echo "  ✓ Kernel package name is valid"
fi
echo ""

# Test 8: Check for interactive commands
echo "Test 8: Checking for interactive commands..."
if grep -q "passwd root" setup-chroot.sh && ! grep -q "chpasswd" setup-chroot.sh; then
    echo "  ✗ FAIL: Interactive 'passwd' command found"
    echo "    Should use: echo 'root:password' | chpasswd"
else
    echo "  ✓ No interactive commands"
fi
echo ""

# Test 9: Check for locale generation
echo "Test 9: Checking for locale generation..."
if grep -q "locale-gen" setup-chroot.sh; then
    echo "  ✓ Locale generation configured"
else
    echo "  ✗ FAIL: Missing locale generation"
    echo "    Should configure /etc/locale.gen and run locale-gen"
fi
echo ""

# Test 10: Check for timezone configuration
echo "Test 10: Checking for timezone configuration..."
if grep -q "/usr/share/zoneinfo" setup-chroot.sh; then
    echo "  ✓ Timezone configuration found"
else
    echo "  ✗ FAIL: Missing timezone configuration"
    echo "    Should set: ln -sf /usr/share/zoneinfo/UTC /etc/localtime"
fi
echo ""

echo "========================================"
echo "Test Summary"
echo "========================================"
echo ""
echo "Run this test against the fixed configuration:"
echo "  cd /workspace/fixed && ../test-build.sh"
echo ""
