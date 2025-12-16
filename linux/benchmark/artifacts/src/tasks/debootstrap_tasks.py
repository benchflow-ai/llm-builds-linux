"""
Debootstrap-based benchmark tasks.

Debootstrap is the Debian/Ubuntu way of creating minimal systems.
These tasks test understanding of:
- Debian packaging
- Chroot environments
- Bootloader configuration
- systemd/init setup
"""

from ..task import Task, Difficulty, Category, VerificationStep, VerificationType


TASK_DEBOOTSTRAP_MINIMAL = Task(
    id="debootstrap-001",
    name="Minimal Debian Rootfs",
    description="Create a minimal Debian rootfs using debootstrap.",
    category=Category.TOOL_ASSISTED,
    difficulty=Difficulty.EASY,

    instructions="""
Create a minimal Debian root filesystem using debootstrap.

Requirements:
1. Use debootstrap to create a minimal Debian bookworm rootfs
2. Set up basic configuration:
   - Root password
   - /etc/fstab
   - Hostname
3. Verify the rootfs is functional by chrooting into it

Success criteria:
- Rootfs directory structure is complete
- Can chroot and run commands
- Basic system files exist (/etc/passwd, /etc/fstab, etc.)

Commands to start:
```
sudo debootstrap --arch=amd64 bookworm ./rootfs http://deb.debian.org/debian
```
""",

    expected_steps=20,
    prerequisites=[],

    base_image="ubuntu:22.04",
    required_packages=[
        "debootstrap", "debian-archive-keyring", "qemu-user-static",
    ],
    required_disk_gb=10,
    required_ram_gb=2,

    verification_steps=[
        VerificationStep(
            type=VerificationType.FILE_CHECK,
            description="Basic rootfs structure exists",
            expected_files=[
                "rootfs/bin/bash",
                "rootfs/etc/passwd",
                "rootfs/etc/debian_version",
            ],
        ),
        VerificationStep(
            type=VerificationType.COMMAND_OUTPUT,
            description="Can chroot and run commands",
            command="sudo chroot rootfs /bin/bash -c 'cat /etc/debian_version'",
            expected_output="12",
            timeout_seconds=30,
        ),
    ],

    success_artifacts=[
        "rootfs/",
    ],

    time_limit_minutes=30,
    expected_build_minutes=15,

    tags=["debootstrap", "debian", "rootfs", "minimal"],
    reference_docs=[
        "https://wiki.debian.org/Debootstrap",
    ],
    common_failure_points=[
        "Missing debian-archive-keyring",
        "Network issues downloading packages",
        "Permission issues (need root)",
    ],
)


TASK_DEBOOTSTRAP_BOOTABLE = Task(
    id="debootstrap-002",
    name="Bootable Debian Disk Image",
    description="Create a bootable Debian disk image from debootstrap that boots in QEMU.",
    category=Category.TOOL_ASSISTED,
    difficulty=Difficulty.MEDIUM,

    instructions="""
Create a bootable Debian disk image from a debootstrap rootfs.

Requirements:
1. Create a disk image file (e.g., 2GB)
2. Partition it (one partition for root is fine)
3. Format with ext4
4. Mount and debootstrap into it
5. Install kernel and bootloader (GRUB or extlinux)
6. Set up /etc/fstab
7. Configure networking (optional but nice)
8. Boot in QEMU

This is significantly harder than just creating a rootfs because you need:
- Disk partitioning
- Bootloader installation
- Kernel installation
- Proper /etc/fstab
- Understanding of boot process

Success criteria:
- Disk image boots to login prompt in QEMU
- Can log in as root
""",

    expected_steps=50,
    prerequisites=["debootstrap-001"],

    base_image="ubuntu:22.04",
    required_packages=[
        "debootstrap", "debian-archive-keyring", "qemu-system-x86",
        "parted", "e2fsprogs", "grub-pc-bin", "grub-efi-amd64-bin",
        "dosfstools", "mtools", "kmod",
    ],
    required_disk_gb=15,
    required_ram_gb=4,

    verification_steps=[
        VerificationStep(
            type=VerificationType.FILE_CHECK,
            description="Disk image exists",
            expected_files=["debian.img"],
        ),
        VerificationStep(
            type=VerificationType.SIZE_CHECK,
            description="Disk image is reasonable size",
            expected_files=["debian.img"],
            min_size_mb=500,
            max_size_mb=4000,
        ),
        VerificationStep(
            type=VerificationType.BOOT_TEST,
            description="Image boots in QEMU",
            command="""
timeout 90 qemu-system-x86_64 \\
    -m 1024 \\
    -drive file=debian.img,format=raw \\
    -nographic 2>&1 | grep -E "login:"
""",
            expected_output="login:",
            timeout_seconds=120,
        ),
    ],

    success_artifacts=[
        "debian.img",
    ],

    time_limit_minutes=90,
    expected_build_minutes=45,

    tags=["debootstrap", "debian", "bootable", "disk-image", "grub"],
    reference_docs=[
        "https://wiki.debian.org/Debootstrap",
        "https://www.gnu.org/software/grub/manual/grub/grub.html",
    ],
    common_failure_points=[
        "Bootloader not installed correctly",
        "Kernel not installed or wrong version",
        "Incorrect /etc/fstab UUIDs",
        "Missing initramfs",
        "GRUB config pointing to wrong device",
    ],
)


TASK_DEBOOTSTRAP_LIVECD = Task(
    id="debootstrap-003",
    name="Debian Live ISO",
    description="Create a bootable Debian Live ISO with debootstrap.",
    category=Category.TOOL_ASSISTED,
    difficulty=Difficulty.HARD,

    instructions="""
Create a bootable Debian Live ISO using debootstrap.

A Live ISO boots entirely from the ISO without touching disk. This requires:
1. Create base rootfs with debootstrap
2. Install kernel and live-boot packages
3. Create squashfs of the rootfs
4. Set up isolinux or GRUB for ISO boot
5. Create the ISO with proper boot structure
6. Test boot in QEMU

Key packages needed in rootfs:
- linux-image-amd64
- live-boot
- systemd-sysv

ISO structure:
/live/
  filesystem.squashfs
  vmlinuz
  initrd.img
/isolinux/ or /boot/grub/
  boot config

Success criteria:
- ISO file is created
- Boots in QEMU with: qemu-system-x86_64 -cdrom live.iso -m 1024
- Reaches a shell prompt
""",

    expected_steps=80,
    prerequisites=["debootstrap-001", "debootstrap-002"],

    base_image="ubuntu:22.04",
    required_packages=[
        "debootstrap", "debian-archive-keyring", "qemu-system-x86",
        "squashfs-tools", "xorriso", "isolinux", "syslinux-common",
        "grub-pc-bin", "grub-efi-amd64-bin", "mtools",
    ],
    required_disk_gb=20,
    required_ram_gb=4,

    verification_steps=[
        VerificationStep(
            type=VerificationType.FILE_CHECK,
            description="ISO file exists",
            expected_files=["live.iso"],
        ),
        VerificationStep(
            type=VerificationType.SIZE_CHECK,
            description="ISO is reasonable size",
            expected_files=["live.iso"],
            min_size_mb=200,
            max_size_mb=2000,
        ),
        VerificationStep(
            type=VerificationType.BOOT_TEST,
            description="ISO boots in QEMU",
            command="""
timeout 120 qemu-system-x86_64 \\
    -m 1024 \\
    -cdrom live.iso \\
    -nographic 2>&1 | grep -E "(login:|root@|#)"
""",
            expected_output="login:",
            timeout_seconds=180,
        ),
    ],

    success_artifacts=[
        "live.iso",
    ],

    time_limit_minutes=120,
    expected_build_minutes=60,

    tags=["debootstrap", "debian", "livecd", "iso", "squashfs"],
    reference_docs=[
        "https://wiki.debian.org/Debootstrap",
        "https://wiki.debian.org/DebianLive",
        "https://manpages.debian.org/live-boot",
    ],
    common_failure_points=[
        "Missing live-boot package",
        "Incorrect isolinux/GRUB configuration",
        "Squashfs not created correctly",
        "Initramfs doesn't include live-boot hooks",
        "ISO boot structure incorrect",
    ],
)


TASK_UBUNTU_MINIMAL = Task(
    id="debootstrap-004",
    name="Ubuntu Minimal Server",
    description="Create a minimal Ubuntu server installation using debootstrap.",
    category=Category.TOOL_ASSISTED,
    difficulty=Difficulty.MEDIUM,

    instructions="""
Create a minimal Ubuntu 22.04 server installation.

Requirements:
1. Use debootstrap to create Ubuntu jammy rootfs
2. Install minimal server packages:
   - systemd
   - openssh-server
   - network-manager or systemd-networkd
3. Create a bootable disk image
4. Configure:
   - Root password or SSH key
   - Networking (DHCP)
   - Hostname
5. Boot and verify SSH works

Success criteria:
- System boots
- SSH service is running
- Can log in via SSH (in QEMU with port forwarding)
""",

    expected_steps=55,
    prerequisites=["debootstrap-002"],

    base_image="ubuntu:22.04",
    required_packages=[
        "debootstrap", "ubuntu-keyring", "qemu-system-x86",
        "parted", "e2fsprogs", "grub-pc-bin",
    ],
    required_disk_gb=15,
    required_ram_gb=4,

    verification_steps=[
        VerificationStep(
            type=VerificationType.FILE_CHECK,
            description="Disk image exists",
            expected_files=["ubuntu.img"],
        ),
        VerificationStep(
            type=VerificationType.BOOT_TEST,
            description="System boots and SSH is running",
            command="""
timeout 90 qemu-system-x86_64 \\
    -m 1024 \\
    -drive file=ubuntu.img,format=raw \\
    -nographic 2>&1 | grep -E "Started.*SSH|login:"
""",
            expected_output="login:",
            timeout_seconds=120,
        ),
    ],

    success_artifacts=[
        "ubuntu.img",
    ],

    time_limit_minutes=90,
    expected_build_minutes=45,

    tags=["debootstrap", "ubuntu", "server", "ssh"],
    reference_docs=[
        "https://wiki.debian.org/Debootstrap",
        "https://help.ubuntu.com/community/Installation/MinimalCD",
    ],
    common_failure_points=[
        "Wrong keyring for Ubuntu",
        "Missing systemd-networkd config",
        "SSH not enabled/started",
        "Wrong kernel for Ubuntu",
    ],
)


DEBOOTSTRAP_TASKS = [
    TASK_DEBOOTSTRAP_MINIMAL,
    TASK_DEBOOTSTRAP_BOOTABLE,
    TASK_DEBOOTSTRAP_LIVECD,
    TASK_UBUNTU_MINIMAL,
]
