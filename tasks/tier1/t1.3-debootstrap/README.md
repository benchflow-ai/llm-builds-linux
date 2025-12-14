# Task T1.3: Create Minimal Debian Rootfs with Debootstrap

## Objective

Use `debootstrap` to create a minimal Debian root filesystem that can:
- Be chrooted into and used interactively
- Optionally boot in QEMU with a kernel

## Difficulty

- **Tier:** 1 (Minimal)
- **Estimated Time:** 30-45 minutes
- **Estimated Steps:** ~15 commands

## Requirements

Your rootfs must:
1. Use debootstrap to create minimal Debian system
2. Be functional when chrooted
3. Have working package management (apt)
4. Include basic networking configuration

## Success Criteria

- [ ] Debootstrap completes without errors
- [ ] Can chroot into the filesystem
- [ ] Basic commands work (ls, cat, apt)
- [ ] Can install new packages with apt
- [ ] Network DNS resolution works (optional)

## Getting Started

```bash
# Enter the build environment
docker build -t debootstrap-env .
docker run -it --privileged debootstrap-env

# Create minimal Debian rootfs
debootstrap --arch=amd64 bookworm /rootfs http://deb.debian.org/debian
```

## Hints (use only if stuck)

<details>
<summary>Hint 1: Basic debootstrap command</summary>

```bash
debootstrap --arch=amd64 --variant=minbase bookworm /rootfs http://deb.debian.org/debian
```

`minbase` creates an even smaller system.

</details>

<details>
<summary>Hint 2: Chroot setup</summary>

Before chrooting, mount necessary filesystems:
```bash
mount -t proc /proc /rootfs/proc
mount -t sysfs /sys /rootfs/sys
mount --bind /dev /rootfs/dev
mount --bind /dev/pts /rootfs/dev/pts
```

</details>

<details>
<summary>Hint 3: Network in chroot</summary>

Copy DNS configuration:
```bash
cp /etc/resolv.conf /rootfs/etc/resolv.conf
```

</details>

<details>
<summary>Hint 4: Clean chroot exit</summary>

After exiting chroot, unmount:
```bash
umount /rootfs/dev/pts
umount /rootfs/dev
umount /rootfs/sys
umount /rootfs/proc
```

</details>

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Release file not found` | Wrong mirror or suite name | Verify suite name (bookworm, jammy) |
| `Cannot install into target` | Permission issues | Run with sudo or as root |
| `DNS not working in chroot` | Missing resolv.conf | Copy /etc/resolv.conf into rootfs |

## Verification

```bash
./verify.sh /rootfs
```

## Reference

- [Debootstrap - Debian Wiki](https://wiki.debian.org/Debootstrap)
- [Debian Releases](https://www.debian.org/releases/)
