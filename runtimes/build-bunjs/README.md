# Building Bun from Source

Can an AI agent build Bun (the JavaScript/TypeScript runtime) from source?

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~1 hour |
| Sessions | 1 |
| Outcome | **PARTIAL (0.6)** - Environment setup complete, build progressed 205/632 steps (32%) before Zig compiler issues |
| Difficulty | Hard |

## Task

Build the Bun JavaScript runtime from source. Bun is written in Zig and powered by JavaScriptCore (WebKit's JS engine). This is a complex build task because:

1. **Multiple languages**: Zig, C++, TypeScript, Rust, and Go
2. **Heavy dependencies**: LLVM 19, WebKit/JSC, BoringSSL, lolhtml, numerous system libraries
3. **Bootstrapping problem**: Building Bun requires an existing Bun binary
4. **Large codebase**: ~10GB for repo + build artifacts
5. **Long build times**: Debug builds take ~6 minutes for Zig compilation alone

## Results Summary

### What Succeeded

- Docker environment setup with all dependencies (LLVM 19, Rust, Go, Ruby, CMake, Ninja)
- Repository clone and Bun bootstrapping
- CMake configuration completed successfully
- Downloaded and configured 20+ dependency libraries (lolhtml, brotli, zstd, highway, etc.)
- JavaScript module bundling completed (1780kb, 136 modules)
- C/C++ compilation of ~200+ source files before failure
- All Rust dependencies (lolhtml) compiled successfully
- All C dependencies (zstd, sqlite, boringssl, c-ares, libarchive) compiled
- Build progressed to step 205/632 (~32% complete)

### Where It Failed

1. **Cargo.lock version issue** (resolved): Initial failure due to Rust version too old for Cargo.lock v4 format
2. **Zig compilation failure**: The Zig compiler (`zig build-obj`) terminated unexpectedly when targeting `aarch64-linux-gnu.2.26` with `-mcpu cortex_a35`
3. **Root cause**: CPU architecture detection issues in Docker ARM64 emulation environment

## Build Requirements

### System Dependencies

**Linux (Ubuntu/Debian)**:
```bash
sudo apt install curl wget lsb-release software-properties-common \
  cmake git golang libtool ninja-build pkg-config ruby-full xz-utils

# MUST install Rust via rustup (not apt) for Cargo.lock v4 support
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```

**LLVM 19** (required to match WebKit):
```bash
wget https://apt.llvm.org/llvm.sh -O - | sudo bash -s -- 19 all
```

### Key Requirements

- ~10GB disk space
- Bun already installed (bootstrapping)
- LLVM 19 specifically (must match WebKit version)
- Rust 1.78+ (for Cargo.lock version 4 support)
- Zig (auto-installed by build scripts)

## Challenges Discovered

1. **Rust version sensitivity**: Ubuntu 24.04's default Rust 1.75 is too old. Cargo.lock v4 format requires Rust 1.78+
2. **CPU architecture detection**: Zig's `-mcpu native` fails in Docker emulation environments
3. **Massive dependency tree**: 20+ external libraries must be fetched and built
4. **Build parallelism**: 632 build steps with complex interdependencies
5. **Memory requirements**: Zig compilation is memory-intensive, may OOM in constrained environments

## Files

```
artifacts/
├── Dockerfile        # Build environment (Ubuntu 24.04 + LLVM 19 + Rust via rustup)
├── build.sh          # Orchestration script with timeout handling
trajectories/
├── SUMMARY.md
└── session-build.jsonl
```

## Quick Start

```bash
# Build the Docker image (~10 min)
docker build -t bun-build -f artifacts/Dockerfile .

# Run the build (will progress ~32% before Zig issues on emulated ARM64)
docker run --rm bun-build
```

## Key Learnings for Agent Evaluation

1. **Dependency version mismatches are common** - Agents need to diagnose and fix version issues (e.g., Cargo.lock v4 requiring newer Rust)
2. **Build environment matters** - Docker emulation may cause architecture-specific failures
3. **Partial progress is valuable** - Reaching 32% of a 632-step build demonstrates significant capability
4. **Bootstrapping is a real blocker** - You literally cannot build Bun without Bun
5. **Multi-language builds are complex** - Zig, C++, Rust, and TypeScript all compile in parallel with interdependencies

## Recommended Improvements for Future Attempts

1. Use native hardware (not Docker emulation) for ARM64 builds
2. Try x86_64 build instead of ARM64
3. Pre-download WebKit/JSC to avoid network delays
4. Consider using Bun's official devcontainer configuration

## References

- [Bun Contributing Guide](https://bun.sh/docs/project/contributing)
- [Bun GitHub Repository](https://github.com/oven-sh/bun)
