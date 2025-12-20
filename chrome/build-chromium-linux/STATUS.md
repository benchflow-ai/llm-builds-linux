# Chromium Build Experiment - Current Status

**Date:** 2025-12-20
**Branch:** xdotli/build-chrome
**Worktree:** shanghai

## Overview

This directory contains the setup for building Chromium from source on Linux using Docker. This is a companion experiment to the successful macOS ARM64 build documented in `chrome/build-chromium/`.

## What Exists

### 1. Completed macOS ARM64 Build
Location: `/Users/lixiangyi/conductor/workspaces/llm-builds-linux/shanghai/chrome/build-chromium/`

**Status:** ✅ SUCCESS (completed 2025-12-15)

Key artifacts:
- `EXPERIMENT.yaml` - Complete experiment metadata with results
- `README.md` - Comprehensive documentation
- `artifacts/build_chromium.sh` - Build script that was used
- `trajectories/` - Agent session logs (2 sessions)
  - session1-setup-and-fetch.jsonl (10.7MB)
  - session2-build-and-monitor.jsonl (492KB)
  - SUMMARY.md

Build results:
- Source size: 35 GB
- Build output: 7.8 GB
- Build time: ~2 hours
- Compilation actions: 118,484
- Binary: chromium/src/out/Default/Chromium.app
- Cost: $42.84 (200 tool calls)

### 2. Chromium Source Checkout
Location: `/Users/lixiangyi/conductor/workspaces/llm-builds-linux/shanghai/chromium/`

**Status:** ✅ EXISTS (fetched 2025-12-15)

Contents:
- `src/` - Full Chromium source tree (35GB, ~93 top-level directories)
- `.gclient` - gclient configuration
- `.gclient_entries` - Dependency entries
- `.cipd/` - CIPD package manager cache

This source was fetched for the macOS build and can potentially be reused for the Linux build (though architecture differences may require re-sync).

### 3. depot_tools
Location: `/Users/lixiangyi/conductor/workspaces/llm-builds-linux/shanghai/depot_tools/`

**Status:** ✅ EXISTS (cloned 2025-12-15)

Contains: 264 items (Google's build toolchain for Chromium)

### 4. Linux Build Experiment (NEW)
Location: `/Users/lixiangyi/conductor/workspaces/llm-builds-linux/shanghai/chrome/build-chromium-linux/`

**Status:** 🆕 SETUP READY (created 2025-12-20)

Files created:
- ✅ `Dockerfile` - Ubuntu 22.04 with Chromium build environment
- ✅ `build.sh` - Orchestration script for Docker-based build
- ✅ `README.md` - Comprehensive experiment documentation
- ✅ `EXPERIMENT.yaml` - Experiment metadata (status: not_started)
- ✅ `.gitignore` - Ignore build artifacts and source
- ✅ `STATUS.md` - This file

Directories:
- `artifacts/` - Empty, ready for build artifacts
- `trajectories/` - Empty, ready for agent session logs
- `chromium/` - Will be created during build (gitignored)

## Repository Structure

```
shanghai/ (worktree)
├── .git
├── .gitignore (gitignores chromium/ and depot_tools/)
├── chrome/
│   ├── build-chromium/          # macOS ARM64 (COMPLETED)
│   │   ├── EXPERIMENT.yaml      # Results documented
│   │   ├── README.md
│   │   ├── artifacts/
│   │   │   └── build_chromium.sh
│   │   └── trajectories/
│   │       ├── session1-setup-and-fetch.jsonl
│   │       ├── session2-build-and-monitor.jsonl
│   │       └── SUMMARY.md
│   └── build-chromium-linux/    # Linux x86_64 (NEW)
│       ├── Dockerfile
│       ├── build.sh
│       ├── README.md
│       ├── EXPERIMENT.yaml
│       ├── STATUS.md
│       ├── .gitignore
│       ├── artifacts/
│       └── trajectories/
├── chromium/                     # Shared source (35GB, gitignored)
│   ├── src/
│   └── .gclient
└── depot_tools/                  # Shared toolchain (gitignored)
```

## Next Steps

### Option 1: Test Docker Build (Recommended)
Since the macOS build is complete and working, the next step would be to test if the Docker-based Linux build works:

1. Verify system has 100GB+ free space
2. Run `./build.sh check` to verify resources
3. Run `./build.sh image` to build Docker image
4. Run `./build.sh fetch` to get Chromium source in container
5. Run `./build.sh setup` to install dependencies
6. Run `./build.sh build` to compile (2-8 hours)

### Option 2: Document Without Building
If resources are limited, document the current state and mark as "setup complete, not attempted":

1. Update EXPERIMENT.yaml with setup details
2. Create trajectory SUMMARY.md documenting preparation
3. Note that macOS build provides sufficient validation
4. Mark as baseline for future testing

### Option 3: Reuse Existing Source
The existing chromium/ source could potentially be reused:

1. Check if source is compatible with Linux build
2. Run gclient sync for Linux dependencies
3. Build in Docker container with mounted source
4. This would save 30-60 minutes of source fetch time

## Resource Requirements

Current disk usage:
- chromium/src/: ~35 GB
- depot_tools/: ~264 items (~200 MB)
- chrome/build-chromium/: ~30 MB (docs and scripts)
- chrome/build-chromium-linux/: <1 MB (just setup files)

For Linux build attempt:
- Docker image: ~2-5 GB
- Build artifacts: 8-65 GB (depending on configuration)
- Total additional: ~10-70 GB

## Realistic Expectations

### Difficulty Level: EXTREME

This is one of the hardest build tasks for an LLM agent:

**Why it's extreme:**
1. **100+ steps** from setup to completion
2. **Multi-hour feedback loops** (errors surface late)
3. **Massive resource requirements** (100GB disk, 16GB RAM)
4. **Complex toolchain** (depot_tools, GN, Ninja, 200+ packages)
5. **Long build time** (2-8 hours, agent must monitor)
6. **Cryptic error messages** requiring deep system knowledge

**Success factors from macOS build:**
- ✅ Agent successfully navigated 100+ step process
- ✅ Managed background processes for long operations
- ✅ Recovered state between sessions
- ✅ Monitored build progress and detected completion
- ⚠️ Required human intervention for Xcode installation

**Additional Linux challenges:**
- Docker adds complexity layer
- Resource limits within container
- Container networking for source fetch
- Volume mounts for persistence
- Different package manager (apt vs Homebrew)

**Likely outcome:**
- Setup (Dockerfile, build.sh): ✅ Agent can handle
- Source fetch: ✅ Agent can handle (if resources available)
- Dependency install: ⚠️ May hit Docker permission or package issues
- Build configuration: ✅ Agent can handle
- Compilation: ⚠️ May hit resource limits or timeout issues
- Overall success rate: 60-80% (based on macOS experience)

## Learnings from macOS Build

From the completed macOS experiment:

**What worked well:**
- Systematic approach with todo tracking
- Background processes for long-running operations
- State recovery between sessions
- Progress monitoring strategies
- Following official documentation

**What didn't work:**
- Didn't verify Xcode installation upfront (critical blocker)
- Didn't estimate disk space needs initially
- Didn't check macOS SDK compatibility early

**Apply to Linux:**
- ✅ Check disk space upfront (build.sh check command)
- ✅ Document resource requirements clearly (README)
- ✅ Verify Docker is running before starting (build.sh)
- ✅ Break into phases with clear validation
- ⚠️ Still need: Build time estimation, resource monitoring, failure recovery

## Metrics to Track

If build is attempted:

| Metric | Target |
|--------|--------|
| Docker image build time | 5-10 minutes |
| Source fetch time | 30-60 minutes |
| Dependency install time | 10-20 minutes |
| Build configuration time | 2-5 minutes |
| Compilation time | 2-8 hours |
| Total elapsed time | 3-9 hours |
| Agent sessions | 1-3 |
| Human interventions | 0-2 |
| Tool calls | 50-150 |
| Success | true/false |

## Conclusion

**Current State:** Ready for testing
**Recommendation:** Proceed with caution
**Prerequisites:** 100GB disk, 16GB RAM, Docker installed
**Expected duration:** 4-10 hours total
**Success probability:** 60-80% (based on macOS experience)

The experiment setup is complete and ready for an agent to attempt the build. The macOS build success provides confidence that an agent can handle the complexity, but the Docker layer and resource constraints add uncertainty.

---

**Note:** This is primarily a benchmark/evaluation task, not a practical way to build Chromium. The value is in testing agent capabilities on extreme-difficulty, long-horizon build tasks.
