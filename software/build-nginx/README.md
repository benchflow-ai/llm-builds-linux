# Build Nginx from Source with Custom Modules

Build Nginx with third-party modules (headers-more and RTMP).

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~1 hour |
| Sessions | 1 |
| Outcome | **SCAFFOLDED** - Build scripts created but not executed |
| Difficulty | Medium |

## Task

Build Nginx from source with custom modules:
1. headers-more-nginx-module (HTTP header manipulation)
2. nginx-rtmp-module (RTMP/HLS streaming)

## Status

**SCAFFOLDED ONLY** - The build environment and scripts were created but the actual nginx compilation was not executed. No artifacts are present in the output directory.

## Files

```
artifacts/
├── Dockerfile    # Build environment
└── build.sh      # Build script
```

## Quick Start

```bash
cd artifacts
docker build -t nginx-builder .
docker run --rm -v $(pwd)/output:/output nginx-builder
./output/sbin/nginx -V  # Shows compiled modules
```

## Key Learnings

1. Third-party modules via --add-module flag
2. Modules must match nginx version
3. Dependencies: PCRE, zlib, OpenSSL
