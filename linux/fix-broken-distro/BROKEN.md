# Broken Configuration Issues

This document lists all the deliberate errors introduced into the Linux distribution build configuration. The goal is to test whether an LLM agent can identify and fix these issues.

## 1. Architecture Issues

### File: `debootstrap.conf`
- **Issue**: Architecture is set to `i368` instead of valid architecture
- **Correct values**: `i386`, `amd64`, `arm64`, `armhf`, etc.
- **Impact**: Debootstrap will fail immediately as it cannot find packages for invalid architecture
- **Difficulty**: Easy - debootstrap will error clearly

## 2. Missing Critical Packages

### File: `debootstrap.conf`
- **Issue**: No Linux kernel package in INCLUDE_PACKAGES
- **Missing**: `linux-image-amd64` or `linux-image-generic` or similar
- **Impact**: System will be created but cannot boot without a kernel
- **Difficulty**: Medium - build succeeds but system won't boot

## 3. Filesystem Type Error

### File: `fstab`
- **Issue**: Root filesystem type is `ext5` which doesn't exist
- **Correct**: `ext4`, `ext3`, `ext2`, `xfs`, `btrfs`, etc.
- **Impact**: System will fail to mount root filesystem during boot
- **Difficulty**: Easy - well-documented error

## 4. Missing Critical Mount Points

### File: `fstab`
- **Issue**: Missing `/proc`, `/sys`, and `/dev/pts` entries
- **Required entries**:
  ```
  proc    /proc    proc    defaults    0    0
  sysfs   /sys     sysfs   defaults    0    0
  devpts  /dev/pts devpts  gid=5,mode=620    0    0
  ```
- **Impact**: System will have non-functional /proc, /sys, and pseudo-terminals
- **Difficulty**: Medium - system may partially boot but be unusable

## 5. Invalid Swap Device

### File: `fstab`
- **Issue**: Swap device `/dev/sda99` is unlikely to exist
- **Impact**: Boot warnings/errors, no swap space
- **Difficulty**: Easy - can be commented out or fixed

## 6. GRUB Installation Typo

### File: `grub-config.sh`
- **Issue**: Command is `grub-instal` instead of `grub-install`
- **Impact**: Script will fail with "command not found"
- **Difficulty**: Easy - clear error message

## 7. Wrong GRUB Device

### File: `grub-config.sh`
- **Issue**: Installing to `/dev/sdc` which may not exist
- **Should be**: `/dev/sda` or `/dev/vda` (for VM)
- **Impact**: GRUB may fail to install or install to wrong device
- **Difficulty**: Medium - depends on build environment

## 8. Missing GRUB Configuration Generation

### File: `grub-config.sh`
- **Issue**: No `grub-mkconfig` command to generate grub.cfg
- **Required**: `grub-mkconfig -o /boot/grub/grub.cfg`
- **Impact**: No boot menu, system cannot boot
- **Difficulty**: Medium - GRUB will be installed but won't boot

## 9. Missing GRUB Environment Block

### File: `grub-config.sh`
- **Issue**: No grubenv creation
- **Required**: `grub-editenv /boot/grub/grubenv create`
- **Impact**: GRUB may fail or have issues saving state
- **Difficulty**: Hard - may work but cause subtle issues

## 10. Missing Kernel Boot Parameters

### File: `grub-config.sh`
- **Issue**: No default kernel parameters configured
- **Required**: Set `root=UUID=xxx ro quiet` or similar
- **Impact**: Kernel may not find root filesystem
- **Difficulty**: Medium - related to fstab and GRUB config

## 11. Invalid Network Interface

### File: `setup-chroot.sh`
- **Issue**: Network interface named `eth99` which won't exist
- **Should be**: `eth0`, `enp0s3`, or use predictable names
- **Impact**: No network connectivity after boot
- **Difficulty**: Easy - but requires understanding modern network naming

## 12. Wrong Kernel Package Name

### File: `setup-chroot.sh`
- **Issue**: Package `linux-image-generic-x86` doesn't exist in Debian
- **Correct**: `linux-image-amd64` for Debian or `linux-image-generic` for Ubuntu
- **Impact**: apt-get will fail to install kernel
- **Difficulty**: Easy - package manager will error

## 13. Interactive Password Command

### File: `setup-chroot.sh`
- **Issue**: `passwd root` command requires interactive input
- **Should use**: `echo "root:password" | chpasswd` or similar
- **Impact**: Build will hang waiting for input
- **Difficulty**: Medium - needs non-interactive alternative

## 14. Missing Locale Generation

### File: `setup-chroot.sh`
- **Issue**: No locale generation configured
- **Required**: Configure `/etc/locale.gen` and run `locale-gen`
- **Impact**: System warnings, potential issues with character encoding
- **Difficulty**: Medium - system may work but with warnings

## 15. Missing Timezone Configuration

### File: `setup-chroot.sh`
- **Issue**: No timezone set
- **Required**: `ln -sf /usr/share/zoneinfo/UTC /etc/localtime`
- **Impact**: Wrong system time, log timestamps
- **Difficulty**: Easy - well-documented

## 16. Missing DNS Configuration

### File: `setup-chroot.sh`
- **Issue**: No `/etc/resolv.conf` created
- **Required**: Configure nameservers
- **Impact**: No DNS resolution, cannot download packages or access internet
- **Difficulty**: Easy - obvious when networking fails

## Summary Statistics

- **Total Issues**: 16
- **Easy to fix**: 7 (typos, obvious errors)
- **Medium difficulty**: 7 (missing configurations, wrong parameters)
- **Hard to fix**: 2 (subtle issues that might work partially)

## Expected Agent Behavior

A successful debugging agent should:
1. Read and understand all configuration files
2. Identify issues through static analysis before running builds
3. Run the build and observe error messages
4. Fix errors iteratively
5. Verify fixes don't introduce new problems
6. Test the final system boots correctly

## Success Criteria

- All 16 issues identified
- All issues fixed correctly
- Final system can complete debootstrap
- System configuration is valid
- Documentation of debugging process
