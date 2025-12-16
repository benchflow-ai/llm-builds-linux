# Linux Distro Building Benchmark Framework

A benchmark framework for evaluating AI agents on Linux distribution building tasks.

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~3 hours |
| Sessions | 2 |
| Outcome | **SUCCESS** - Created 11 tasks with verification system |
| Difficulty | Hard |

## Task

Design and implement a benchmark framework for systematically testing how far agents can go with distro building.

## Results

- Created comprehensive benchmark framework with 11 tasks
- Implemented CLI for running and evaluating tasks
- Built verification system (boot test, file check, size check)
- Successfully booted Alpine kernel/initramfs in QEMU

## Files

```
artifacts/
├── cli.py                        # Command-line interface
├── run_benchmark.py              # Benchmark runner
├── src/
│   ├── task.py                   # Task and result dataclasses
│   ├── runner.py                 # Execution and verification engine
│   └── tasks/                    # Task definitions by category
├── tasks/                        # JSON task exports
├── environments/                 # Docker environments
├── build-test/                   # Alpine kernel/initramfs for testing
└── BUILDING_LINUX_GUIDE.md       # Reference documentation
trajectories/
├── SUMMARY.md                    # Detailed trajectory
└── session-build.jsonl           # Session log
```

## Quick Start

```bash
cd artifacts

# List all tasks
python cli.py list

# Show specific task
python cli.py show buildroot-001

# Show environment setup
python cli.py env debootstrap-001

# Export tasks to JSON
python cli.py export tasks.json
```

## Tasks (11 total)

| Category | Count | Difficulty | Steps |
|----------|-------|------------|-------|
| Buildroot | 3 | Easy-Hard | 25-60 |
| Debootstrap | 4 | Easy-Hard | 20-80 |
| Debugging | 4 | Medium-Hard | 35-50 |

## Key Learnings

1. **Meta-tasks are valuable** - Building the test is harder than passing it
2. **Research compounds** - Web search + docs + practical tests = understanding
3. **Docker has limits** - Some OS-level tasks need real Linux
4. **Failure analysis** - Chroot management and bootloader installation are top failure points
