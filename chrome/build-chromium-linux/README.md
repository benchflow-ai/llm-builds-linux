# Build Chromium on Linux - Experiment

This experiment tests whether an LLM agent can successfully set up and execute a complete Chromium browser build on Linux using Docker.

## Difficulty: EXTREME

**Why this is extreme:**
- **100GB+ disk space required** (35GB source + 65GB build artifacts for debug build, ~43GB for optimized build)
- **Multi-hour build time** (2-8 hours depending on hardware)
- **200+ dependencies** to install and manage
- **Complex build system** (depot_tools, GN, Ninja)
- **Long feedback loops** (errors may not surface until hours into the build)
- **100+ step process** from initial setup to final binary

## Task Description

Build the Chromium browser from source on Linux (Ubuntu 22.04) in a Docker container, producing a working `chrome` binary.

## System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| Disk Space | 100GB | 150GB |
| RAM | 16GB | 32GB |
| CPU Cores | 4 | 8+ |
| Build Time | 8 hours (4-core) | 2 hours (16-core) |

## Architecture

```
chrome/build-chromium-linux/
├── Dockerfile           # Ubuntu 22.04 with build tools
├── build.sh            # Orchestration script
├── README.md           # This file
├── EXPERIMENT.yaml     # Experiment metadata
├── artifacts/          # Build scripts and configs
├── trajectories/       # Agent session logs
└── chromium/           # Source code (gitignored, 35GB+)
    └── src/
        └── out/Default/
            └── chrome  # Final binary
```

## Quick Start

```bash
# Check system resources
./build.sh check

# Run complete build (2-8 hours)
./build.sh all

# Or run step-by-step:
./build.sh image   # Build Docker image
./build.sh fetch   # Download Chromium source (30-60 min)
./build.sh setup   # Install dependencies and configure
./build.sh build   # Compile Chromium (2-8 hours)
```

## Build Process

### Phase 1: Environment Setup (10 minutes)
1. Build Docker image with Ubuntu 22.04
2. Install basic tools (git, curl, python3)
3. Clone depot_tools (Google's build toolchain)

### Phase 2: Source Checkout (30-60 minutes)
4. Run `fetch --no-history chromium` (~35GB download)
5. Sync dependencies with `gclient sync`

### Phase 3: Dependency Installation (10-20 minutes)
6. Run `build/install-build-deps.sh` (installs 200+ packages)
7. Install libraries: GTK3, NSS, X11, ALSA, Mesa GL, etc.

### Phase 4: Build Configuration (2 minutes)
8. Create `out/Default/args.gn` with optimized settings:
   - `is_debug = false` (release build, smaller size)
   - `is_component_build = true` (faster incremental builds)
   - `symbol_level = 0` (no debug symbols, saves space and time)
   - `enable_nacl = false` (skip NaCl, not needed)
   - `use_jumbo_build = true` (combine files for faster compilation)
9. Generate build files with `gn gen out/Default`

### Phase 5: Compilation (2-8 hours)
10. Run `autoninja -C out/Default chrome`
11. Compile ~118,000 build actions
12. Link final binary

### Phase 6: Verification
13. Check that `out/Default/chrome` exists and is executable
14. Measure build output size

## Success Criteria

- [ ] Docker image builds successfully
- [ ] Chromium source fetches completely (~35GB)
- [ ] Build dependencies install without errors (200+ packages)
- [ ] Build configuration generates valid Ninja files
- [ ] Compilation completes without fatal errors
- [ ] Final binary exists at `chromium/src/out/Default/chrome`
- [ ] Binary is executable (can verify with `file` command)

## Expected Output

```
Chromium source:     ~35 GB
Build artifacts:     ~8-65 GB (8GB for component build, 65GB for debug)
Final binary:        out/Default/chrome
Build actions:       ~118,000
```

## Common Failure Modes

### Resource Exhaustion
- **Disk full:** Chromium requires 100GB+. Clean up old files or add storage.
- **OOM (Out of Memory):** Build crashes with "killed" messages. Add more RAM or reduce parallel jobs.

### Dependency Issues
- **install-build-deps.sh fails:** Usually network issues or package repo problems. Retry.
- **Missing libraries:** Some Ubuntu versions lack certain packages. Check error logs.

### Build Errors
- **Compilation errors:** Usually due to environment issues or corrupted source. Try `git clean` and re-sync.
- **Linker errors:** Often memory-related. Use component build or add swap space.

### Docker Issues
- **Container crashes:** Increase Docker resource limits (memory, CPU, disk).
- **Permission errors:** Ensure the non-root user has correct permissions.

## Optimization Options

### Faster Builds (Trade-offs)
```gn
is_component_build = true    # Faster builds, slower runtime
symbol_level = 0             # No debug symbols
enable_nacl = false          # Skip Native Client
use_jumbo_build = true       # Combine compilation units
```

### Smaller Builds (Trade-offs)
```gn
is_debug = false             # Release mode (smaller)
is_component_build = false   # Static build (fewer files, slower builds)
symbol_level = 0             # No symbols
remove_webcore_debug_symbols = true
```

### Debug Builds (Full features)
```gn
is_debug = true              # Debug mode
symbol_level = 2             # Full symbols
is_component_build = true    # Component build
```

## Agent Challenges

Building Chromium tests several agent capabilities:

1. **Long-horizon planning:** 100+ steps from start to finish
2. **Resource management:** Must check disk space, RAM, CPU before starting
3. **Error recovery:** Builds can fail hours in; agent must diagnose and fix
4. **Progress monitoring:** Build takes hours; agent must track progress
5. **System understanding:** Must understand build systems, dependencies, compilation
6. **Documentation reading:** Must parse and follow complex official docs
7. **Environment setup:** Docker, build tools, dependency management
8. **Debugging:** Cryptic build errors require systematic diagnosis

## Metrics to Track

| Metric | Expected Value |
|--------|---------------|
| Agent sessions | 1-3 |
| Human interventions | 0-2 |
| Total duration | 4-10 hours |
| Active duration | 1-2 hours |
| Tool calls | 50-150 |
| Build success | true/false |
| Source size | ~35 GB |
| Build size | ~8-65 GB |
| Compilation actions | ~118,000 |

## References

### Official Documentation
- [Chromium Linux Build Instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md)
- [Chromium GN Build Configuration](https://www.chromium.org/developers/gn-build-configuration/)
- [Chromium depot_tools](https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html)

### Related Experiments
- `chrome/build-chromium/` - macOS ARM64 build (completed successfully)

## Notes

- This is primarily a test of agent capability, not a practical way to build Chromium
- Production Chromium builds use distributed compilation (Goma) for much faster builds
- The official Chromium team uses 64-core+ machines for development
- Component builds are faster but create many shared libraries
- Full debug builds can exceed 100GB of disk space

## Current Status

**Status:** Not yet attempted

This experiment directory contains:
- ✅ Dockerfile (ready)
- ✅ build.sh script (ready)
- ✅ README.md documentation (ready)
- ⬜ EXPERIMENT.yaml (pending - will be created after attempt)
- ⬜ Chromium source (not fetched - too large for repo)
- ⬜ Build artifacts (not generated)

## Next Steps

1. Review system requirements
2. Ensure 100GB+ disk space available
3. Run `./build.sh check` to verify resources
4. Run `./build.sh all` to start build (or step-by-step)
5. Monitor build progress (2-8 hours)
6. Document results in EXPERIMENT.yaml

---

**Realistic Expectations:** This is an EXTREME difficulty task. Even experienced developers encounter issues building Chromium. Success is not guaranteed, and the process will take multiple hours. The primary value is testing agent capabilities on long-horizon, complex build tasks.
