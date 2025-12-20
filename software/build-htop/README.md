# Build htop from Source

Build htop process viewer from source in a Docker environment.

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~0.5 hours |
| Sessions | 1 |
| Outcome | **SUCCESS** - htop builds and runs |
| Difficulty | Easy |

## Task

Build htop from source:
1. Clone from GitHub
2. Install dependencies (ncurses)
3. Run autotools build (autogen, configure, make)
4. Verify binary works

## Files

```
artifacts/
├── Dockerfile    # Build environment
└── build.sh      # Build script
```

## Quick Start

```bash
cd artifacts
docker build -t htop-builder .
mkdir -p output
docker run --rm -v $(pwd)/output:/output htop-builder
./output/htop --version
```

## Key Learnings

1. Autotools workflow is standard: autogen.sh, configure, make
2. ncurses-dev is the main dependency
3. Build is straightforward with proper deps
