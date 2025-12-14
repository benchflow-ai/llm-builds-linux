# llm-builds-linux

Can LLM agents build Linux distros? How far can they go?

## Why this matters

Many AI hardware founders told me that Claude Code currently fails very hard at building Linux distros for them, despite doing everything else pretty decently. They need to do it on a daily basis because it's an important part of their product.

From talks with frontier lab employees, startup founders, VCs, and researchers - there's a general sense that coding agents haven't cracked these kinds of tasks yet:
- Long horizon tasks (100+ steps)
- E2E tasks with complex feedback loops
- Tasks requiring deep system-level understanding

## Task ideas

- Build a minimal bootable Linux from scratch (LFS-style)
- Create a custom Ubuntu/Fedora spin using live-build or lorax
- Build embedded Linux with Yocto/Buildroot for specific hardware
- Create a container-optimized minimal distro (like Alpine)
- Fix a broken distro build

## Tools agents would need

- debootstrap, live-build (Debian/Ubuntu)
- lorax, kickstart (Fedora/RHEL)
- Yocto Project, Buildroot (embedded)
- Docker/QEMU for testing builds

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
