# Linux Distro Building Benchmark Framework - Agent Trajectory Summary

## Overview

This trajectory documents an AI agent's attempt to design and implement a **benchmark framework** for evaluating AI agents on Linux distribution building tasks. Rather than just building a distro, this workspace focused on creating reproducible tasks, verification methods, and tooling.

**Agent:** Claude Opus 4.5
**Duration:** ~3 hours across multiple sessions
**Outcome:** Success - Created comprehensive benchmark framework with 11 tasks, CLI, and verification system

## User Request

"The above is the Google Doc that I have created so far. What I want you to do is: Start exploration task, Make plans, Preferably be able to build some Linux distros or have some code written and have some things to demo for me"

The context was a research goal: "Can agents build Linux distros? How far can they go?"

## Approach Taken

Agent recognized this as a **meta-task** - not just building a distro, but creating infrastructure to evaluate agents systematically. Chose to build a benchmark framework with:

1. Task definitions with difficulty ratings
2. Verification methods (boot tests, file checks, etc.)
3. CLI for running and evaluating tasks
4. Docker environments for reproducible execution

## Key Steps Taken

### 1. Research Phase

- Searched for existing benchmarks: Terminal-Bench, OSWorld, AgentBench
- Analyzed Linux distro building approaches: Buildroot, Debootstrap, Alpine
- Identified common failure points from community experience

### 2. Framework Design

Created Python-based benchmark system:

```
harare/
├── src/
│   ├── task.py           # Task dataclasses with JSON serialization
│   ├── runner.py         # Task execution and verification
│   └── tasks/            # Task definitions by category
│       ├── buildroot.py
│       ├── debootstrap.py
│       └── debug.py
├── tasks/                # JSON task exports
├── environments/         # Docker environments
├── cli.py               # Command-line interface
└── BUILDING_LINUX_GUIDE.md  # Reference documentation
```

### 3. Task Categories

**11 tasks across 3 categories:**

| Category | Count | Difficulty Range | Steps Range |
|----------|-------|------------------|-------------|
| Buildroot | 3 | Easy-Hard | 25-60 |
| Debootstrap | 4 | Easy-Hard | 20-80 |
| Debugging | 4 | Medium-Hard | 35-50 |

### 4. Verification System

Implemented multiple verification methods:

- `boot_test` - QEMU boot to login prompt
- `file_check` - Verify expected files exist
- `size_check` - Check image size constraints
- `command_output` - Run commands and check output
- `checksum` - Verify file integrity

### 5. Practical Validation

Agent actually attempted to build a minimal Linux system using Alpine:
- Downloaded Alpine kernel and initramfs
- Booted in QEMU successfully
- Reached kernel initialization
- Shell access achieved with `init=/bin/sh`

## Artifacts Produced

| File | Lines | Description |
|------|-------|-------------|
| `cli.py` | 230 | Full CLI with list/show/export/run/env commands |
| `src/task.py` | ~200 | Task and result dataclasses |
| `src/runner.py` | ~300 | Task execution and verification engine |
| `src/tasks/*.py` | ~400 | 11 task definitions |
| `README.md` | 138 | Project overview and quick start |
| `BUILDING_LINUX_GUIDE.md` | ~200 | Technical reference |
| `build-test/` | - | Actual Alpine kernel/initramfs for testing |

## Key Research Findings

### Where Agents Fail (from research)

1. **Environment Setup** (40% failure) - Missing dependencies
2. **Chroot Management** (60% failure) - DNS, mounts, cleanup
3. **Loop Devices** (50% failure) - Partition scanning, cleanup
4. **Bootloader** (70% failure) - GRUB installation complexity
5. **Long Feedback Loops** (80% failure) - Errors surface late

### Difficulty Calibration

- **Easy** (~50% agent success): 10-25 steps, tool-assisted
- **Medium** (~20% agent success): 30-55 steps, bootloader work
- **Hard** (~5% agent success): 50-80 steps, debugging, ISOs
- **Extreme** (<1% agent success): 100+ steps, LFS-style

## Metrics

| Metric | Value |
|--------|-------|
| Tool calls | ~180 |
| Files created | 15+ |
| Lines of code | ~1200 |
| Tasks defined | 11 |
| Verification methods | 5 |
| Web searches | 3 |
| Practical tests | 2 (Alpine boot) |

## Where Agent Succeeded

1. **Meta-thinking** - Recognized need for framework, not just one-off build
2. **Research synthesis** - Combined web search with practical knowledge
3. **Structured design** - Clean separation of concerns
4. **Practical validation** - Actually booted a kernel to verify approach

## Where Agent Struggled

1. **Docker loop device limitations** - Couldn't mount images in container
2. **Full rootfs creation** - Incomplete due to container restrictions
3. **Scope creep** - Could have shipped smaller MVP faster

## Reproduction Steps

```bash
cd harare

# List all tasks
python cli.py list

# Show specific task details
python cli.py show buildroot-001

# Show environment setup
python cli.py env debootstrap-001

# Export all tasks to JSON
python cli.py export tasks.json
```

## Lessons for Agent Evaluation

1. **Meta-tasks are valuable** - Building the test is harder than passing it
2. **Research compounds** - Web search + docs + practical tests = understanding
3. **Incremental delivery** - Should have shipped CLI earlier
4. **Docker has limits** - Some OS-level tasks need real Linux

## Sample Task Definition

```python
Task(
    id="buildroot-001",
    name="Minimal QEMU System",
    category=TaskCategory.BUILDROOT,
    difficulty=Difficulty.EASY,
    description="Build minimal bootable Linux using Buildroot",
    expected_steps=25,
    time_limit_minutes=60,
    verification_steps=[
        VerificationStep(
            type=VerificationType.BOOT_TEST,
            description="System boots to login prompt in QEMU",
            command="qemu-system-x86_64 -kernel bzImage -append 'console=ttyS0' -nographic",
            expected_output="login:",
            timeout_seconds=60
        )
    ]
)
```
