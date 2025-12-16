"""
Buildroot-based benchmark tasks.

Buildroot is simpler than Yocto but still requires understanding of:
- Cross-compilation toolchains
- Kernel configuration
- Root filesystem generation
- Bootloader setup
"""

from ..task import Task, Difficulty, Category, VerificationStep, VerificationType


TASK_BUILDROOT_MINIMAL = Task(
    id="buildroot-001",
    name="Buildroot Minimal QEMU System",
    description="Build a minimal bootable Linux system using Buildroot that boots in QEMU x86_64.",
    category=Category.TOOL_ASSISTED,
    difficulty=Difficulty.EASY,

    instructions="""
Build a minimal Linux system using Buildroot that can boot in QEMU.

Requirements:
1. Clone the Buildroot repository (use latest stable release)
2. Configure for qemu_x86_64_defconfig
3. Build the system (this will take 15-30 minutes)
4. Boot the resulting image in QEMU and verify you get a shell prompt
5. The system should respond to basic commands (ls, cat, echo)

Success criteria:
- Kernel boots without panic
- Init system starts
- You can log in and run commands
- Output image exists at output/images/

Hints:
- Use `make qemu_x86_64_defconfig` to start with a known-good config
- Build with `make` (optionally `make -j$(nproc)` for parallel build)
- QEMU command is documented in board/qemu/x86_64/readme.txt
""",

    expected_steps=25,
    prerequisites=[],

    base_image="ubuntu:22.04",
    required_packages=[
        "build-essential", "gcc", "g++", "make", "patch", "gzip", "bzip2",
        "perl", "cpio", "unzip", "rsync", "bc", "wget", "python3", "file",
        "qemu-system-x86", "git", "libncurses-dev"
    ],
    required_disk_gb=15,
    required_ram_gb=4,

    verification_steps=[
        VerificationStep(
            type=VerificationType.FILE_CHECK,
            description="Check that kernel image exists",
            expected_files=["output/images/bzImage"],
        ),
        VerificationStep(
            type=VerificationType.FILE_CHECK,
            description="Check that root filesystem exists",
            expected_files=["output/images/rootfs.ext2"],
        ),
        VerificationStep(
            type=VerificationType.SIZE_CHECK,
            description="Root filesystem should be reasonable size",
            expected_files=["output/images/rootfs.ext2"],
            min_size_mb=5,
            max_size_mb=500,
        ),
        VerificationStep(
            type=VerificationType.BOOT_TEST,
            description="System boots in QEMU and reaches login prompt",
            command="""
timeout 60 qemu-system-x86_64 \\
    -M pc \\
    -kernel output/images/bzImage \\
    -drive file=output/images/rootfs.ext2,if=virtio,format=raw \\
    -append "rootwait root=/dev/vda console=ttyS0" \\
    -net nic,model=virtio -net user \\
    -nographic 2>&1 | grep -E "(login:|#|\\$)"
""",
            expected_output="login:",
            timeout_seconds=120,
        ),
    ],

    success_artifacts=[
        "output/images/bzImage",
        "output/images/rootfs.ext2",
    ],

    time_limit_minutes=60,
    expected_build_minutes=30,

    tags=["buildroot", "qemu", "minimal", "x86_64"],
    reference_docs=[
        "https://buildroot.org/downloads/manual/manual.html",
        "https://buildroot.org/downloads/manual/manual.html#_qemu",
    ],
    common_failure_points=[
        "Missing build dependencies (ncurses-dev, etc.)",
        "Incorrect QEMU command syntax",
        "Not waiting long enough for build to complete",
        "Kernel config issues with virtio drivers",
    ],
)


TASK_BUILDROOT_NETWORKING = Task(
    id="buildroot-002",
    name="Buildroot with Networking",
    description="Build a Buildroot system with working networking that can ping external hosts.",
    category=Category.TOOL_ASSISTED,
    difficulty=Difficulty.MEDIUM,

    instructions="""
Build a Buildroot system with networking support.

Requirements:
1. Start from qemu_x86_64_defconfig
2. Enable networking support in the kernel
3. Include network tools (ip, ping, wget or curl)
4. Configure DHCP or static networking
5. Boot in QEMU with user-mode networking
6. Successfully ping an external host or download a file

Success criteria:
- System boots
- Network interface comes up
- Can resolve DNS
- Can reach external network (ping 8.8.8.8 or similar)

This tests the agent's ability to:
- Navigate Buildroot's menuconfig
- Understand kernel networking options
- Configure userspace networking tools
- Debug network issues in QEMU
""",

    expected_steps=40,
    prerequisites=["buildroot-001"],

    base_image="ubuntu:22.04",
    required_packages=[
        "build-essential", "gcc", "g++", "make", "patch", "gzip", "bzip2",
        "perl", "cpio", "unzip", "rsync", "bc", "wget", "python3", "file",
        "qemu-system-x86", "git", "libncurses-dev"
    ],
    required_disk_gb=15,
    required_ram_gb=4,

    verification_steps=[
        VerificationStep(
            type=VerificationType.FILE_CHECK,
            description="Check images exist",
            expected_files=["output/images/bzImage", "output/images/rootfs.ext2"],
        ),
        VerificationStep(
            type=VerificationType.BOOT_TEST,
            description="System boots and network interface exists",
            command="""
timeout 60 qemu-system-x86_64 \\
    -M pc \\
    -kernel output/images/bzImage \\
    -drive file=output/images/rootfs.ext2,if=virtio,format=raw \\
    -append "rootwait root=/dev/vda console=ttyS0" \\
    -net nic,model=virtio -net user \\
    -nographic 2>&1 | grep -E "eth0|enp0s"
""",
            expected_output="eth0",
            timeout_seconds=120,
        ),
    ],

    success_artifacts=[
        "output/images/bzImage",
        "output/images/rootfs.ext2",
    ],

    time_limit_minutes=90,
    expected_build_minutes=45,

    tags=["buildroot", "networking", "qemu", "intermediate"],
    reference_docs=[
        "https://buildroot.org/downloads/manual/manual.html",
    ],
    common_failure_points=[
        "Virtio network driver not enabled in kernel",
        "Network tools not included in rootfs",
        "DHCP client not configured",
        "DNS resolution not working",
    ],
)


TASK_BUILDROOT_CUSTOM_PACKAGE = Task(
    id="buildroot-003",
    name="Buildroot Custom Package",
    description="Add a custom package to Buildroot and include it in the build.",
    category=Category.TOOL_ASSISTED,
    difficulty=Difficulty.HARD,

    instructions="""
Create and integrate a custom package into Buildroot.

Requirements:
1. Start from a working qemu_x86_64 Buildroot setup
2. Create a custom package that:
   - Downloads a simple C program source (can be hello world)
   - Compiles it using the Buildroot toolchain
   - Installs it to /usr/bin in the target
3. The package should follow Buildroot conventions:
   - Create package/mypackage/mypackage.mk
   - Create package/mypackage/Config.in
   - Register in package/Config.in
4. Enable the package and rebuild
5. Boot and verify the binary works

This tests:
- Understanding Buildroot's package infrastructure
- Cross-compilation concepts
- Makefile syntax for Buildroot
- Integration with existing build system
""",

    expected_steps=60,
    prerequisites=["buildroot-001"],

    base_image="ubuntu:22.04",
    required_packages=[
        "build-essential", "gcc", "g++", "make", "patch", "gzip", "bzip2",
        "perl", "cpio", "unzip", "rsync", "bc", "wget", "python3", "file",
        "qemu-system-x86", "git", "libncurses-dev"
    ],
    required_disk_gb=15,
    required_ram_gb=4,

    verification_steps=[
        VerificationStep(
            type=VerificationType.FILE_CHECK,
            description="Custom package files exist",
            expected_files=[
                "package/mypackage/mypackage.mk",
                "package/mypackage/Config.in",
            ],
        ),
        VerificationStep(
            type=VerificationType.BOOT_TEST,
            description="Custom binary runs in booted system",
            command="""
timeout 60 qemu-system-x86_64 \\
    -M pc \\
    -kernel output/images/bzImage \\
    -drive file=output/images/rootfs.ext2,if=virtio,format=raw \\
    -append "rootwait root=/dev/vda console=ttyS0" \\
    -nographic 2>&1 | grep -i "hello"
""",
            expected_output="hello",
            timeout_seconds=120,
        ),
    ],

    success_artifacts=[
        "output/images/bzImage",
        "output/images/rootfs.ext2",
        "package/mypackage/mypackage.mk",
    ],

    time_limit_minutes=120,
    expected_build_minutes=45,

    tags=["buildroot", "custom-package", "advanced"],
    reference_docs=[
        "https://buildroot.org/downloads/manual/manual.html#adding-packages",
    ],
    common_failure_points=[
        "Incorrect Makefile syntax",
        "Cross-compilation issues",
        "Package not registered in Config.in",
        "Incorrect installation paths",
    ],
)


BUILDROOT_TASKS = [
    TASK_BUILDROOT_MINIMAL,
    TASK_BUILDROOT_NETWORKING,
    TASK_BUILDROOT_CUSTOM_PACKAGE,
]
