#!/bin/bash
# Verification script for T1.2: BusyBox + Kernel minimal Linux

set -e

BUILD_DIR="${1:-.}"
TIMEOUT=60
SCORE=0
MAX_SCORE=100

echo "=== T1.2 Verification ==="
echo "Build directory: $BUILD_DIR"
echo ""

# Check for kernel
echo -n "Checking for kernel (bzImage)... "
if [ -f "$BUILD_DIR/bzImage" ]; then
    echo "FOUND"
    SCORE=$((SCORE + 20))

    # Verify it's actually a kernel
    if file "$BUILD_DIR/bzImage" | grep -q "Linux kernel"; then
        echo "  ✓ Valid Linux kernel image"
    else
        echo "  ⚠ File exists but may not be a valid kernel"
    fi
else
    echo "NOT FOUND"
    echo "  Expected: bzImage (Linux kernel)"
fi

# Check for initramfs
echo -n "Checking for initramfs... "
INITRAMFS=""
for f in initramfs.cpio.gz initramfs.cpio initrd.img initramfs.img; do
    if [ -f "$BUILD_DIR/$f" ]; then
        INITRAMFS="$BUILD_DIR/$f"
        break
    fi
done

if [ -n "$INITRAMFS" ]; then
    echo "FOUND ($INITRAMFS)"
    SCORE=$((SCORE + 20))

    # Check initramfs contents
    echo "  Checking initramfs contents..."
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"

    if [[ "$INITRAMFS" == *.gz ]]; then
        zcat "$INITRAMFS" | cpio -id 2>/dev/null || true
    else
        cpio -id < "$INITRAMFS" 2>/dev/null || true
    fi

    if [ -f "init" ] || [ -f "sbin/init" ]; then
        echo "  ✓ init script found"
    else
        echo "  ✗ No init script found in initramfs"
        SCORE=$((SCORE - 10))
    fi

    if [ -f "bin/busybox" ] || [ -f "busybox" ]; then
        echo "  ✓ BusyBox found"
        # Check if static
        BB=$(find . -name busybox -type f | head -1)
        if [ -n "$BB" ] && file "$BB" | grep -q "statically linked"; then
            echo "  ✓ BusyBox is statically linked"
        else
            echo "  ⚠ BusyBox may not be statically linked"
        fi
    else
        echo "  ✗ BusyBox not found in initramfs"
        SCORE=$((SCORE - 10))
    fi

    cd - > /dev/null
    rm -rf "$TMPDIR"
else
    echo "NOT FOUND"
    echo "  Expected: initramfs.cpio.gz or similar"
fi

# Boot test with QEMU
echo ""
echo "Running QEMU boot test (timeout: ${TIMEOUT}s)..."

if [ -f "$BUILD_DIR/bzImage" ] && [ -n "$INITRAMFS" ]; then
    BOOT_LOG=$(mktemp)

    # Run QEMU with timeout, capture output
    timeout "$TIMEOUT" qemu-system-x86_64 \
        -kernel "$BUILD_DIR/bzImage" \
        -initrd "$INITRAMFS" \
        -append "console=ttyS0 panic=1" \
        -nographic \
        -no-reboot \
        2>&1 | head -200 > "$BOOT_LOG" || true

    # Check boot progress
    echo "  Analyzing boot log..."

    if grep -q "Linux version" "$BOOT_LOG"; then
        echo "  ✓ Kernel started"
        SCORE=$((SCORE + 10))
    else
        echo "  ✗ Kernel did not start"
    fi

    if grep -q "Freeing unused kernel" "$BOOT_LOG"; then
        echo "  ✓ Kernel initialization completed"
        SCORE=$((SCORE + 10))
    fi

    if grep -q "Kernel panic" "$BOOT_LOG"; then
        echo "  ✗ Kernel panic detected"
        SCORE=$((SCORE - 20))
        echo "  Panic message:"
        grep -A2 "Kernel panic" "$BOOT_LOG" | head -5 | sed 's/^/    /'
    fi

    if grep -qE "(\/ #|~ #|# $)" "$BOOT_LOG"; then
        echo "  ✓ Shell prompt appeared"
        SCORE=$((SCORE + 20))
    else
        echo "  ⚠ Shell prompt not detected (may still work interactively)"
    fi

    # Save boot log
    cp "$BOOT_LOG" "$BUILD_DIR/boot-test.log"
    echo "  Boot log saved to: boot-test.log"

    rm "$BOOT_LOG"
else
    echo "  Skipping boot test - missing kernel or initramfs"
fi

# Final score
echo ""
echo "==========================="
echo "Final Score: $SCORE / $MAX_SCORE"
echo "==========================="

if [ $SCORE -ge 80 ]; then
    echo "Result: PASS"
    exit 0
elif [ $SCORE -ge 50 ]; then
    echo "Result: PARTIAL"
    exit 1
else
    echo "Result: FAIL"
    exit 2
fi
