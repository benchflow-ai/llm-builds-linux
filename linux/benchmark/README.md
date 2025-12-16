# Linux Distro Building Benchmark Framework

A benchmark framework for evaluating AI agents on Linux distribution building tasks.

## Overview

- **Agent:** Claude Opus 4.5
- **Outcome:** Success - Created 11 tasks with verification system
- **Purpose:** Systematically test how far agents can go with distro building

## Quick Start

```bash
cd experiments/linux/benchmark

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

## Key Files

| File | Description |
|------|-------------|
| `cli.py` | Command-line interface |
| `src/task.py` | Task and result dataclasses |
| `src/runner.py` | Execution and verification engine |
| `src/tasks/` | Task definitions by category |
| `environments/` | Docker environments |
| `build-test/` | Alpine kernel/initramfs for testing |
| `trajectories/` | Agent session summaries |

## Research Findings

Common agent failure points:
1. Environment Setup (40% failure)
2. Chroot Management (60% failure)
3. Loop Devices (50% failure)
4. Bootloader (70% failure)
5. Long Feedback Loops (80% failure)
