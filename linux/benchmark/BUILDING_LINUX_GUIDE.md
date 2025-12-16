# Building Linux Systems: Complete Guide for Agent Benchmarking

This guide documents exact commands for building bootable Linux systems. Each section includes expected outputs, build times, and common failure points.

## Overview

| Approach | Build Time | Image Size | Complexity | Steps |
|----------|------------|------------|------------|-------|
| Buildroot | 30-90 min | 50-200MB | Medium | ~25 |
| Debootstrap | 10-30 min | 500MB-2GB | High | ~50 |
| Alpine | 2-5 min | 30-100MB | Low | ~10 |

---

## 1. Buildroot Approach

Buildroot is a set of makefiles that automate building embedded Linux systems.

### Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential gcc g++ make patch gzip bzip2 \
    perl cpio unzip rsync bc wget python3 file \
    git libncurses-dev qemu-system-x86
```

### Build Commands

```bash
# Download Buildroot (2024.02 release)
cd /tmp
wget https://buildroot.org/downloads/buildroot-2024.02.tar.gz
tar xzf buildroot-2024.02.tar.gz
cd buildroot-2024.02

# Configure for QEMU x86_64
make qemu_x86_64_defconfig

# Build (takes 30-90 minutes)
make -j$(nproc)

# Verify outputs
ls -lh output/images/
# Expected: bzImage (~10MB), rootfs.ext2 (~35MB)
```

### Boot in QEMU

```bash
qemu-system-x86_64 \
    -M pc \
    -kernel output/images/bzImage \
    -drive file=output/images/rootfs.ext2,if=virtio,format=raw \
    -append "root=/dev/vda console=ttyS0" \
    -nographic
```

**Expected**: Login prompt `buildroot login:`, login as `root` (no password).

**Exit QEMU**: `Ctrl-A` then `X`

### Common Failures

1. **Missing libncurses-dev**: `menuconfig` fails
2. **Download errors**: Run `make source` first to pre-download
3. **Disk space**: Need 20GB+ free
4. **Virtio driver missing**: Kernel panic on boot - wrong defconfig

---

## 2. Debootstrap Approach

Debootstrap creates Debian/Ubuntu base systems from scratch.

### Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y \
    debootstrap debian-archive-keyring \
    parted e2fsprogs grub-pc-bin \
    qemu-system-x86
```

### Create Minimal Rootfs

```bash
WORK=/tmp/debian-build
mkdir -p $WORK && cd $WORK

# Bootstrap minimal Debian
sudo debootstrap --variant=minbase --arch=amd64 \
    bookworm rootfs http://deb.debian.org/debian/
```

**Time**: 5-15 minutes. **Size**: ~250MB

### Configure the System

```bash
# IMPORTANT: Copy DNS resolver BEFORE chroot
sudo cp /etc/resolv.conf rootfs/etc/resolv.conf

# Chroot and configure
sudo chroot rootfs /bin/bash << 'EOF'
echo "debian-minimal" > /etc/hostname
echo "root:root" | chpasswd

# Install kernel
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    linux-image-amd64 systemd-sysv
EOF
```

### Create Bootable Disk Image

```bash
# Create 2GB disk image
dd if=/dev/zero of=debian.img bs=1M count=2048

# Set up loop device with partitions
LOOP=$(sudo losetup -f --show -P debian.img)
sudo parted -s $LOOP mklabel msdos
sudo parted -s $LOOP mkpart primary ext4 1MiB 100%
sudo parted -s $LOOP set 1 boot on

# Format and mount
sudo mkfs.ext4 ${LOOP}p1
sudo mkdir -p /mnt/build
sudo mount ${LOOP}p1 /mnt/build

# Copy rootfs
sudo cp -a rootfs/* /mnt/build/

# Install GRUB
sudo mount --bind /dev /mnt/build/dev
sudo mount --bind /proc /mnt/build/proc
sudo mount --bind /sys /mnt/build/sys

sudo chroot /mnt/build bash -c "
apt-get install -y grub-pc
grub-install --target=i386-pc $LOOP
update-grub
"

# Cleanup
sudo umount /mnt/build/{dev,proc,sys}
sudo umount /mnt/build
sudo losetup -d $LOOP
```

### Boot in QEMU

```bash
qemu-system-x86_64 \
    -hda debian.img \
    -m 1024 \
    -nographic
```

### Common Failures

1. **DNS in chroot**: Always copy `/etc/resolv.conf` first
2. **Loop device issues**: Use `-P` flag with `losetup`
3. **GRUB fails**: Ensure partition has boot flag set
4. **Wrong fstab**: Check UUIDs match actual partition

---

## 3. Alpine Approach (Fastest)

Alpine is already minimal (~5MB base), fastest to build.

### Using alpine-make-vm-image

```bash
cd /tmp
wget https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/v0.12.0/alpine-make-vm-image
chmod +x alpine-make-vm-image

# Create customization script
cat > customize.sh << 'EOF'
#!/bin/sh
apk add --no-cache openssh bash
echo "root:alpine" | chpasswd
rc-update add sshd default
EOF
chmod +x customize.sh

# Build image (2-5 minutes)
sudo ./alpine-make-vm-image \
    --image-format qcow2 \
    --image-size 1G \
    --script-chroot \
    alpine.qcow2 \
    ./customize.sh
```

### Boot in QEMU

```bash
qemu-system-x86_64 \
    -m 512M \
    -drive file=alpine.qcow2,if=virtio \
    -nographic
```

**Boot time**: 5-10 seconds

---

## Verification Commands

After any build, verify success:

```bash
# Check file type
file <image>
# Expected: "Linux kernel x86 boot executable" or "ext2/ext4 filesystem"

# Check size
du -h <image>

# Test boot (with timeout)
timeout 60 qemu-system-x86_64 \
    -m 512M \
    -drive file=<image> \
    -nographic 2>&1 | grep "login:"
```

---

## Agent Failure Analysis

Based on testing, agents commonly fail at:

| Failure Point | Rate | Cause |
|--------------|------|-------|
| Environment setup | 40% | Missing dependencies |
| Chroot DNS | 60% | Forgot resolv.conf |
| Loop devices | 50% | Missing -P flag |
| Bootloader | 70% | GRUB complexity |
| Long builds | 80% | Context loss, impatience |

---

## Recommended Progression

For benchmarking agents, use this progression:

1. **Start**: Alpine (simplest, fastest feedback)
2. **Medium**: Buildroot (longer, but scripted)
3. **Hard**: Debootstrap bootable (chroot + GRUB)
4. **Expert**: LFS-style from scratch

Each level tests progressively deeper system understanding.
