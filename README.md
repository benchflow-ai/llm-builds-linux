# llm-builds-linux

Can LLM agents build Linux distros? How far can they go?

## Quick Start

```bash
# List all available benchmark tasks
python cli.py list

# Show details for a specific task
python cli.py show buildroot-001

# Export all tasks to JSON
python cli.py export tasks.json
```

## Why This Matters

Many AI hardware founders told me that Claude Code currently fails very hard at building Linux distros for them, despite doing everything else pretty decently. They need to do it on a daily basis because it's an important part of their product.

From talks with frontier lab employees, startup founders, VCs, and researchers - there's a general sense that coding agents haven't cracked these kinds of tasks yet:
- Long horizon tasks (100+ steps)
- E2E tasks with complex feedback loops
- Tasks requiring deep system-level understanding

## Current Tasks (11 total)

### Tool-Assisted (Buildroot)
| Task ID | Name | Difficulty | Steps |
|---------|------|------------|-------|
| buildroot-001 | Minimal QEMU System | Easy | 25 |
| buildroot-002 | Networking Support | Medium | 40 |
| buildroot-003 | Custom Package | Hard | 60 |

### Tool-Assisted (Debootstrap)
| Task ID | Name | Difficulty | Steps |
|---------|------|------------|-------|
| debootstrap-001 | Minimal Debian Rootfs | Easy | 20 |
| debootstrap-002 | Bootable Disk Image | Medium | 50 |
| debootstrap-003 | Debian Live ISO | Hard | 80 |
| debootstrap-004 | Ubuntu Minimal Server | Medium | 55 |

### Debugging
| Task ID | Name | Difficulty | Steps |
|---------|------|------------|-------|
| debug-001 | Fix Kernel Panic | Medium | 35 |
| debug-002 | Fix Missing Init | Medium | 40 |
| debug-003 | Fix Network Failure | Hard | 50 |
| debug-004 | Fix Build Failure | Hard | 45 |

## Project Structure

```
harare/
├── src/
│   ├── task.py          # Task and result dataclasses
│   ├── runner.py        # Task runner and verifier
│   └── tasks/           # Task definitions (Python)
├── tasks/               # Task definitions (JSON)
├── environments/        # Docker environments
│   ├── buildroot/
│   └── debootstrap/
├── cli.py              # Command-line interface
├── BUILDING_LINUX_GUIDE.md   # Detailed build guides
└── TASK_SPECIFICATION.md     # Full specification docs
```

## Key Documentation

- **[BUILDING_LINUX_GUIDE.md](./BUILDING_LINUX_GUIDE.md)** - Complete guide to building Linux systems with Buildroot, Debootstrap, and Alpine. Includes exact commands, expected outputs, build times, and common failure points.

- **[TASK_SPECIFICATION.md](./TASK_SPECIFICATION.md)** - Full specification format for benchmark tasks, including JSON schema, verification methods, and scoring algorithms.

## Verification Methods

Tasks use multiple verification methods:
- **boot_test** - Boot in QEMU and check for login prompt
- **file_check** - Verify expected files exist
- **size_check** - Check image size constraints
- **command_output** - Run commands and check output
- **checksum** - Verify file integrity

## Difficulty Levels

- **Easy** (~50% agent success): 10-25 steps, tool-assisted builds
- **Medium** (~20% agent success): 30-55 steps, bootloader/config work
- **Hard** (~5% agent success): 50-80 steps, debugging, ISOs
- **Extreme** (<1% agent success): 100+ steps, LFS-style

## Where Agents Fail

Research identified these common failure points:

1. **Environment Setup** (40% failure) - Missing dependencies
2. **Chroot Management** (60% failure) - DNS, mounts, cleanup
3. **Loop Devices** (50% failure) - Partition scanning, cleanup
4. **Bootloader** (70% failure) - GRUB installation complexity
5. **Long Feedback Loops** (80% failure) - Build errors surface late

## Plan

**Phase 1:** Create hard tasks around Linux distro building

Success criteria:
- At least a dozen environments / tasks
- Tested how far different models can go

**Phase 2:** TBD

---

## How this came about

I've been talking to a lot of people in the AI space - researchers at frontier labs, startup founders building AI hardware, VCs evaluating AI companies. One thing kept coming up: current coding agents are surprisingly bad at certain categories of tasks, even when they excel at others.

The Linux distro building problem came from AI hardware founders who deal with this daily. They use Claude Code for most of their coding work and it does well, but when it comes to building custom Linux images for their hardware, it falls apart. This isn't a niche use case for them - it's core to shipping their product.

What makes this interesting as a benchmark is that it naturally requires long-horizon planning (easily 100+ steps), deep system understanding (kernel, bootloaders, package managers, init systems), and dealing with long feedback loops where errors are cryptic and often don't surface until boot time. You can't fake your way through it.

I'm starting this project to systematically test how far different LLM agents can actually go with these tasks. The goal is to build a set of reproducible environments and tasks, run different models through them, and document where they succeed and fail.

---

## Broader vision

This project is part of a larger effort to find hard tasks for coding agents. The full notes are in [this Google Doc](https://docs.google.com/document/d/1B1wgmJ1K4CZNMg7VWtUs-QsPAfCJ1mq7ggKO-lAby3U/edit).

Some related ideas we're exploring:
- 100 tasks that take agents 100 steps to solve (coding mostly)
- Can agents build Chrome (and can they do follow up tasks)
- Can agents build their own bun / rust cargo / openshift / kubernetes etc.
- Given any repo / open-source repo and relevant keys / env vars, how far can agents go
- Can agents build their own mobile OS
- Inspection on which model is good at what (e.g. some models better at python, others at design)

Related work: [LLM Speedrunner](https://github.com/facebookresearch/llm-speedrunner) - a benchmark that lets AI build entire models.
