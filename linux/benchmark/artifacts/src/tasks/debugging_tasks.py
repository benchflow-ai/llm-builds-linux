"""
Debugging tasks - fixing broken builds.

These tasks provide broken configurations and ask agents to fix them.
Tests diagnostic skills, understanding of boot process, and problem-solving.
"""

from ..task import Task, Difficulty, Category, VerificationStep, VerificationType


TASK_DEBUG_KERNEL_PANIC = Task(
    id="debug-001",
    name="Fix Kernel Panic at Boot",
    description="Debug and fix a system that kernel panics immediately at boot.",
    category=Category.DEBUGGING,
    difficulty=Difficulty.MEDIUM,

    instructions="""
A Buildroot system has been built but kernel panics at boot with:
"Kernel panic - not syncing: VFS: Unable to mount root fs"

The build completed successfully but the system won't boot. Debug and fix it.

Possible causes to investigate:
1. Root filesystem type mismatch (ext2 vs ext4)
2. Missing root= kernel parameter
3. Missing filesystem driver in kernel
4. Wrong device name (vda vs sda)

You have access to:
- The build directory with all configs
- The kernel config (.config)
- The QEMU command being used

Fix the issue and verify the system boots.
""",

    expected_steps=35,
    prerequisites=["buildroot-001"],

    base_image="ubuntu:22.04",
    required_packages=[
        "qemu-system-x86", "file", "cpio", "gzip",
    ],
    required_disk_gb=5,
    required_ram_gb=2,

    verification_steps=[
        VerificationStep(
            type=VerificationType.BOOT_TEST,
            description="System boots without kernel panic",
            command="""
timeout 60 qemu-system-x86_64 \\
    -M pc \\
    -kernel output/images/bzImage \\
    -drive file=output/images/rootfs.ext2,if=virtio,format=raw \\
    -append "rootwait root=/dev/vda console=ttyS0" \\
    -nographic 2>&1 | grep -v "panic" | grep "login:"
""",
            expected_output="login:",
            timeout_seconds=90,
        ),
    ],

    success_artifacts=[],

    time_limit_minutes=45,
    expected_build_minutes=5,

    tags=["debugging", "kernel-panic", "boot"],
    reference_docs=[
        "https://wiki.archlinux.org/title/Kernel_panic",
    ],
    common_failure_points=[
        "Not checking kernel config for filesystem support",
        "Not understanding root= parameter syntax",
        "Not matching virtio device names",
    ],
)


TASK_DEBUG_MISSING_INIT = Task(
    id="debug-002",
    name="Fix Missing Init",
    description="Debug a system that fails with 'No init found' or 'Attempted to kill init!'",
    category=Category.DEBUGGING,
    difficulty=Difficulty.MEDIUM,

    instructions="""
A minimal Linux system boots but fails with:
"No working init found. Try passing init= option to kernel."
or
"Kernel panic - not syncing: Attempted to kill init!"

The rootfs exists and contains files, but init isn't working.

Possible causes:
1. /sbin/init doesn't exist or isn't executable
2. Wrong architecture (compiled for wrong arch)
3. Missing dynamic libraries
4. Init points to busybox but symlinks are broken
5. Kernel init= parameter pointing to wrong location

Debug and fix the system.
""",

    expected_steps=40,
    prerequisites=["buildroot-001"],

    base_image="ubuntu:22.04",
    required_packages=[
        "qemu-system-x86", "file", "readelf", "binutils",
    ],
    required_disk_gb=5,
    required_ram_gb=2,

    verification_steps=[
        VerificationStep(
            type=VerificationType.BOOT_TEST,
            description="Init starts successfully",
            command="""
timeout 60 qemu-system-x86_64 \\
    -M pc \\
    -kernel output/images/bzImage \\
    -drive file=output/images/rootfs.ext2,if=virtio,format=raw \\
    -append "rootwait root=/dev/vda console=ttyS0" \\
    -nographic 2>&1 | grep "login:"
""",
            expected_output="login:",
            timeout_seconds=90,
        ),
    ],

    success_artifacts=[],

    time_limit_minutes=45,
    expected_build_minutes=5,

    tags=["debugging", "init", "boot"],
    reference_docs=[],
    common_failure_points=[
        "Not checking if init is actually executable",
        "Not using file/readelf to check binary",
        "Not checking library dependencies",
    ],
)


TASK_DEBUG_NETWORK_FAILURE = Task(
    id="debug-003",
    name="Fix Network Not Working",
    description="Debug a system where network interface exists but networking doesn't work.",
    category=Category.DEBUGGING,
    difficulty=Difficulty.HARD,

    instructions="""
A Linux system boots successfully but networking doesn't work.

Symptoms:
- Network interface (eth0) shows up in `ip link`
- No IP address is assigned
- Cannot ping anything
- DHCP doesn't seem to work

Debug and fix networking. Possible issues:
1. DHCP client not installed or not running
2. Network driver loaded but not configured
3. udev rules not creating device correctly
4. systemd-networkd or other network manager not configured
5. DNS resolver not configured
6. Firewall/iptables blocking

The fix should result in the system getting an IP and being able to reach the network.
""",

    expected_steps=50,
    prerequisites=["buildroot-002"],

    base_image="ubuntu:22.04",
    required_packages=[
        "qemu-system-x86", "tcpdump",
    ],
    required_disk_gb=5,
    required_ram_gb=2,

    verification_steps=[
        VerificationStep(
            type=VerificationType.COMMAND_OUTPUT,
            description="System has IP address",
            command="""
# Boot system and check for IP
timeout 90 qemu-system-x86_64 \\
    -M pc \\
    -kernel output/images/bzImage \\
    -drive file=output/images/rootfs.ext2,if=virtio,format=raw \\
    -append "rootwait root=/dev/vda console=ttyS0" \\
    -net nic,model=virtio -net user \\
    -nographic 2>&1
""",
            expected_output="10.0.2",
            timeout_seconds=120,
        ),
    ],

    success_artifacts=[],

    time_limit_minutes=60,
    expected_build_minutes=10,

    tags=["debugging", "networking", "dhcp"],
    reference_docs=[],
    common_failure_points=[
        "Not checking if DHCP client is present",
        "Not understanding QEMU user networking",
        "Not checking DNS configuration",
    ],
)


TASK_DEBUG_BUILD_FAILURE = Task(
    id="debug-004",
    name="Fix Buildroot Build Failure",
    description="Debug and fix a Buildroot configuration that fails to build.",
    category=Category.DEBUGGING,
    difficulty=Difficulty.HARD,

    instructions="""
A Buildroot configuration fails during the build with cryptic errors.

The configuration has been modified to add some packages, but now the build fails.
Error messages mention missing dependencies or configuration conflicts.

Your task:
1. Analyze the build error
2. Identify the root cause
3. Fix the configuration
4. Complete the build successfully

Common build failure causes:
- Package dependencies not met
- Conflicting options selected
- Missing host tools
- Circular dependencies
- Invalid configuration combinations

The build should complete and produce bootable images.
""",

    expected_steps=45,
    prerequisites=["buildroot-001"],

    base_image="ubuntu:22.04",
    required_packages=[
        "build-essential", "gcc", "g++", "make", "patch", "gzip", "bzip2",
        "perl", "cpio", "unzip", "rsync", "bc", "wget", "python3", "file",
        "git", "libncurses-dev"
    ],
    required_disk_gb=15,
    required_ram_gb=4,

    verification_steps=[
        VerificationStep(
            type=VerificationType.FILE_CHECK,
            description="Build produces images",
            expected_files=[
                "output/images/bzImage",
                "output/images/rootfs.ext2",
            ],
        ),
    ],

    success_artifacts=[
        "output/images/bzImage",
        "output/images/rootfs.ext2",
    ],

    time_limit_minutes=90,
    expected_build_minutes=45,

    tags=["debugging", "buildroot", "build-failure"],
    reference_docs=[
        "https://buildroot.org/downloads/manual/manual.html#_troubleshooting",
    ],
    common_failure_points=[
        "Not reading full error message",
        "Not understanding dependency graph",
        "Trying to fix symptoms instead of root cause",
    ],
)


DEBUGGING_TASKS = [
    TASK_DEBUG_KERNEL_PANIC,
    TASK_DEBUG_MISSING_INIT,
    TASK_DEBUG_NETWORK_FAILURE,
    TASK_DEBUG_BUILD_FAILURE,
]
