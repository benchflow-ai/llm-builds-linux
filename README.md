# llm-builds-linux

Can LLM agents build Linux distros? How far can they go?

## Quick Start

```bash
# List available tasks
./scripts/benchmark.py --list

# Run a specific task
./scripts/run-task.sh t1.2-busybox-kernel

# Run benchmark for a tier
./scripts/benchmark.py --tier 1 --model "claude-3.5-sonnet"
```

## Why This Matters

Many AI hardware founders told me that Claude Code currently fails very hard at building Linux distros for them, despite doing everything else pretty decently. They need to do it on a daily basis because it's an important part of their product.

Building Linux distributions is a great benchmark because it requires:
- **Long horizon tasks** (100+ steps)
- **Deep system knowledge** (kernels, bootloaders, package managers, init systems)
- **Cryptic error handling** (errors often only surface at boot time)
- **Complex feedback loops** (build → test → debug → rebuild)

## Task Tiers

### Tier 1: Minimal (~30-60 min, ~20 steps)
| Task | Description | Status |
|------|-------------|--------|
| t1.2-busybox-kernel | Build bootable Linux with BusyBox + kernel | Ready |
| t1.3-debootstrap | Create Debian rootfs with debootstrap | Ready |

### Tier 2: Custom Spin (~1-3 hours, ~50 steps)
| Task | Description | Status |
|------|-------------|--------|
| t2.1-ubuntu-livebuild | Create custom Ubuntu live ISO | Ready |
| t2.3-buildroot-minimal | Build embedded Linux with Buildroot | Ready |

### Tier 3-5: Advanced (Coming Soon)
- Yocto Project builds
- Custom BSP for hardware
- Full Linux From Scratch
- ChromiumOS-style builds

## Project Structure

```
llm-builds-linux/
├── README.md
├── PLAN.md                    # Detailed implementation plan
├── tasks/
│   ├── tier1/
│   │   ├── t1.2-busybox-kernel/
│   │   │   ├── README.md      # Human-readable task description
│   │   │   ├── task.yaml      # Machine-readable specification
│   │   │   ├── Dockerfile     # Build environment
│   │   │   ├── verify.sh      # Verification script
│   │   │   └── solution/      # Reference solution
│   │   └── t1.3-debootstrap/
│   ├── tier2/
│   │   ├── t2.1-ubuntu-livebuild/
│   │   └── t2.3-buildroot-minimal/
│   ├── tier3/
│   ├── tier4/
│   └── tier5/
├── scripts/
│   ├── run-task.sh            # Run a task interactively
│   └── benchmark.py           # Run benchmarks, collect metrics
└── results/                   # Benchmark results
```

## Task Specification Format

Each task has a `task.yaml` with:

```yaml
name: "Build minimal bootable Linux with BusyBox"
id: t1.2-busybox-kernel
tier: 1
difficulty: easy

estimated_time: "45-60 minutes"
estimated_steps: 25

success_criteria:
  - kernel_compiles: "Kernel compiles without errors"
  - boots_without_panic: "System boots without kernel panic"
  - shell_appears: "Shell prompt appears"

common_failures:
  - error: "Kernel panic - not syncing: No init found"
    cause: "Missing /init or not executable"
    fix: "Ensure /init exists and has +x permission"
```

## Running Tasks

### Interactive Mode

```bash
# Start task environment
./scripts/run-task.sh t1.2-busybox-kernel

# Inside container, follow the task README
# Build kernel, BusyBox, create initramfs
# Test with QEMU
```

### Verification

Each task includes a verification script:

```bash
./verify.sh /path/to/build

# Output:
# === T1.2 Verification ===
# Checking for kernel (bzImage)... FOUND
# Checking for initramfs... FOUND
# Running QEMU boot test...
#   ✓ Kernel started
#   ✓ Shell prompt appeared
# Final Score: 80 / 100
# Result: PASS
```

## Metrics Collected

For each benchmark run:
- Total time taken
- Number of steps/commands executed
- Number of errors encountered
- Recovery attempts
- Final success/failure
- Partial completion score (0-100%)

## Common Failure Modes

Based on research, agents commonly fail at:

1. **Kernel configuration** - Missing drivers, wrong arch, no initramfs support
2. **Bootloader setup** - GRUB config, EFI vs BIOS
3. **Init system** - Missing /init, wrong permissions, broken scripts
4. **Package dependencies** - Version conflicts, missing libs
5. **Cross-compilation** - Wrong toolchain, architecture mismatch
6. **Filesystem issues** - Wrong format, missing /dev nodes

## Contributing

### Adding a New Task

1. Create task directory: `tasks/tierN/task-id/`
2. Add `README.md` with human instructions
3. Add `task.yaml` with machine-readable spec
4. Add `Dockerfile` for build environment
5. Add `verify.sh` for automated verification
6. Optionally add `solution/` with reference implementation

### Running Benchmarks

```bash
# Run all tier 1 tasks
./scripts/benchmark.py --tier 1 --model "model-name"

# Results saved to results/benchmark-YYYYMMDD-HHMMSS.json
```

---

## Background

I've been talking to a lot of people in the AI space - researchers at frontier labs, startup founders building AI hardware, VCs evaluating AI companies. One thing kept coming up: current coding agents are surprisingly bad at certain categories of tasks, even when they excel at others.

The Linux distro building problem came from AI hardware founders who deal with this daily. They use Claude Code for most of their coding work and it does well, but when it comes to building custom Linux images for their hardware, it falls apart. This isn't a niche use case for them - it's core to shipping their product.

What makes this interesting as a benchmark is that it naturally requires long-horizon planning (easily 100+ steps), deep system understanding (kernel, bootloaders, package managers, init systems), and dealing with long feedback loops where errors are cryptic and often don't surface until boot time. You can't fake your way through it.

---

## Broader Vision

This project is part of a larger effort to find hard tasks for coding agents. The full notes are in [this Google Doc](https://docs.google.com/document/d/1B1wgmJ1K4CZNMg7VWtUs-QsPAfCJ1mq7ggKO-lAby3U/edit).

Some related ideas we're exploring:
- 100 tasks that take agents 100 steps to solve (coding mostly)
- Can agents build Chrome (and can they do follow up tasks)
- Can agents build their own bun / rust cargo / openshift / kubernetes etc.
- Given any repo / open-source repo and relevant keys / env vars, how far can agents go
- Can agents build their own mobile OS
- Inspection on which model is good at what (e.g. some models better at python, others at design)

Related work: [LLM Speedrunner](https://github.com/facebookresearch/llm-speedrunner) - a benchmark that lets AI build entire models.

## License

MIT
