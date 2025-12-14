# Task T2.3: Build Minimal Embedded Linux with Buildroot

## Objective

Use Buildroot to create a minimal embedded Linux system. This is a more
structured approach to building embedded systems, commonly used by
hardware companies.

## Difficulty

- **Tier:** 2 (Custom Spin)
- **Estimated Time:** 1-3 hours (mostly build time)
- **Estimated Steps:** ~30 commands

## Requirements

Your Buildroot image must:
1. Configure Buildroot for x86_64 QEMU target
2. Build successfully without errors
3. Boot in QEMU and provide a shell
4. Include at least 2-3 custom packages

## Success Criteria

- [ ] Buildroot downloads and extracts
- [ ] Configuration completes (menuconfig or defconfig)
- [ ] Build completes without errors
- [ ] Output images are generated
- [ ] System boots in QEMU
- [ ] Custom packages are present

## Getting Started

```bash
# Enter the build environment
docker build -t buildroot-env .
docker run -it --privileged buildroot-env

# Download and extract Buildroot
wget https://buildroot.org/downloads/buildroot-2024.02.tar.gz
tar xf buildroot-2024.02.tar.gz
cd buildroot-2024.02

# Configure for QEMU x86_64
make qemu_x86_64_defconfig
make menuconfig  # Optional: customize

# Build (takes 30-60 minutes)
make -j$(nproc)
```

## Hints (use only if stuck)

<details>
<summary>Hint 1: Quick QEMU config</summary>

Start with a known-good defconfig:
```bash
make qemu_x86_64_defconfig
```

This pre-configures everything for QEMU testing.

</details>

<details>
<summary>Hint 2: Adding packages</summary>

In menuconfig:
- Target packages → ...
- Navigate to find packages
- Press `Y` to select

Or edit `.config` directly:
```
BR2_PACKAGE_HTOP=y
BR2_PACKAGE_VIM=y
```

Then run `make` again.

</details>

<details>
<summary>Hint 3: Speeding up builds</summary>

Enable ccache:
- Build options → Enable compiler cache → Enable

Use parallel jobs:
```bash
make -j$(nproc)
```

</details>

<details>
<summary>Hint 4: Testing the build</summary>

Buildroot provides a test script:
```bash
./board/qemu/x86_64/start-qemu.sh
```

Or manually:
```bash
qemu-system-x86_64 \
    -M pc \
    -kernel output/images/bzImage \
    -drive file=output/images/rootfs.ext2,if=virtio,format=raw \
    -append "rootwait root=/dev/vda console=ttyS0" \
    -nographic
```

</details>

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Download fails | Network/mirror issues | Retry or use different mirror |
| Build fails at package X | Missing host dependency | Install missing package on host |
| "recipe for target failed" | Parallel build race | Try `make -j1` for that package |
| No output images | Build incomplete | Check for errors, run `make` again |

## Verification

```bash
./verify.sh
```

## Key Files After Build

```
output/
├── images/
│   ├── bzImage          # Linux kernel
│   ├── rootfs.ext2      # Root filesystem
│   └── rootfs.tar       # Rootfs as tarball
├── build/               # Build directories for each package
└── target/              # The actual rootfs contents
```

## Reference

- [Buildroot Manual](https://buildroot.org/downloads/manual/manual.html)
- [Buildroot Training](https://bootlin.com/doc/training/buildroot/)
- [QEMU Boards in Buildroot](https://github.com/buildroot/buildroot/tree/master/board/qemu)
