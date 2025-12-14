# Task T2.1: Create Custom Ubuntu Live ISO with live-build

## Objective

Create a custom Ubuntu live ISO using the `live-build` tool. The ISO should:
- Boot into a graphical or text environment
- Include custom packages of your choice
- Be customized with a specific theme/branding

## Difficulty

- **Tier:** 2 (Custom Spin)
- **Estimated Time:** 1-2 hours
- **Estimated Steps:** ~50 commands

## Requirements

Your custom ISO must:
1. Use live-build to create a Debian/Ubuntu-based live system
2. Include at least 5 custom packages beyond minimal
3. Boot successfully in QEMU
4. Have some form of customization (welcome message, custom script, etc.)

## Success Criteria

- [ ] `lb config` completes without errors
- [ ] `lb build` completes without errors
- [ ] ISO file is generated
- [ ] ISO boots in QEMU
- [ ] Custom packages are installed
- [ ] Customization is visible (welcome message, etc.)

## Getting Started

```bash
# Enter the build environment
docker build -t ubuntu-livebuild-env .
docker run -it --privileged ubuntu-livebuild-env

# Initialize live-build config
lb config

# Build the ISO
lb build
```

## Hints (use only if stuck)

<details>
<summary>Hint 1: Basic configuration</summary>

```bash
lb config \
    --distribution jammy \
    --archive-areas "main universe" \
    --apt-recommends false
```

</details>

<details>
<summary>Hint 2: Adding packages</summary>

Create `config/package-lists/custom.list.chroot`:
```
vim
htop
curl
git
tmux
```

</details>

<details>
<summary>Hint 3: Adding customization scripts</summary>

Create `config/hooks/live/9999-welcome.hook.chroot`:
```bash
#!/bin/bash
echo "Welcome to Custom Linux!" > /etc/motd
```
Make it executable: `chmod +x config/hooks/live/9999-welcome.hook.chroot`

</details>

<details>
<summary>Hint 4: Testing with QEMU</summary>

```bash
qemu-system-x86_64 \
    -cdrom live-image-amd64.hybrid.iso \
    -m 2G \
    -enable-kvm
```

Without KVM (slower):
```bash
qemu-system-x86_64 \
    -cdrom live-image-amd64.hybrid.iso \
    -m 2G \
    -cpu qemu64
```

</details>

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `lb build` fails at bootstrap | Network/mirror issues | Use `--mirror-bootstrap` with working mirror |
| Package not found | Wrong archive area | Add `universe` or `multiverse` to archive-areas |
| Build hangs | Low memory/disk | Ensure 8GB+ disk space, 4GB+ RAM |
| ISO won't boot | Missing bootloader | Check `--bootloaders` config |

## Verification

Run the verification script to check your build:

```bash
./verify.sh
```

## Customization Ideas

- **Minimal server**: No GUI, just essential CLI tools
- **Developer workstation**: vim, git, docker, nodejs, python
- **Security distro**: nmap, wireshark, aircrack-ng (educational)
- **Kiosk mode**: Auto-login, single application

## Reference

- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/html/live-manual/)
- [Ubuntu Live Build](https://help.ubuntu.com/community/LiveCDCustomization)
- [lb_config man page](https://manpages.debian.org/testing/live-build/lb_config.1.en.html)
