# Contributing Experiments

This guide explains how AI agents (and humans) should structure and report experiments in this repository.

## For AI Agents: Quick Reference

When completing an experiment, create these files:

```
<category>/<experiment-name>/
├── README.md           # Human-readable overview
├── EXPERIMENT.yaml     # Machine-readable metadata
├── artifacts/          # All code, scripts, configs you created
└── trajectories/
    ├── SUMMARY.md      # Narrative of what you did
    └── session-*.jsonl # Sanitized session logs
```

## Directory Structure

### Top-Level Categories

Experiments are organized by category:

```
llm-builds-linux/
├── linux/              # Linux distribution experiments
│   ├── build-debootstrap/
│   ├── build-livebuild/
│   └── benchmark/
├── chrome/             # Chromium experiments (future)
└── [other-category]/   # Future categories
```

### Experiment Naming

Use lowercase, hyphenated names that describe what was built or tested:

- `build-debootstrap` - Building with debootstrap
- `build-livebuild` - Building with live-build
- `benchmark` - Benchmark framework
- `build-chromium` - Building Chromium (future)

## Required Files

### 1. README.md

Human-readable overview with key metrics table.

```markdown
# [Experiment Name]

[One-line description]

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | ~X hours |
| Sessions | N |
| Outcome | **SUCCESS/PARTIAL/FAILED** - [brief description] |
| Difficulty | Easy/Medium/Hard/Extreme |

## Task

[What was asked/attempted]

## Results

- [Bullet point achievements]
- [What worked]
- [What didn't work]

## Files

\`\`\`
artifacts/
├── [file]    # [description]
└── [dir]/    # [description]
trajectories/
├── SUMMARY.md
└── session-*.jsonl
\`\`\`

## Quick Start

\`\`\`bash
# Commands to reproduce or use the artifacts
\`\`\`

## Key Learnings

1. **[Learning]** - [explanation]
2. **[Learning]** - [explanation]
```

### 2. EXPERIMENT.yaml

Machine-readable metadata for analysis and filtering.

```yaml
name: "Human Readable Name"
id: experiment-id
category: build  # build | benchmark | debug | research
status: success  # success | partial | failed | in-progress

agent:
  model: claude-opus-4-5  # or claude-sonnet-4, etc.
  sessions: 2
  total_duration_hours: 3
  active_duration_hours: 2

task:
  description: "What the experiment aimed to do"
  initial_prompt: "The exact first user message"
  difficulty: hard  # easy | medium | hard | extreme
  estimated_steps: 80

results:
  success: true  # or false
  partial_score: 0.7  # 0.0 to 1.0
  artifacts:
    - "key_file_1.py"
    - "key_file_2.sh"
  key_metrics:
    # Custom metrics relevant to this experiment
    build_stages: 8
    iso_created: true

# Optional but encouraged
cost:
  total_usd: 15.50
  input_tokens: 50000
  output_tokens: 200000

human_intervention:
  count: 2
  critical: false  # true if couldn't proceed without it
  details:
    - "Platform hint (ARM64 vs AMD64)"
    - "CAPTCHA during web research"

findings:
  successes:
    - "What worked well"
  failures:
    - "What didn't work"
  lessons:
    - "Key learnings for future experiments"

references:
  pr_url: "https://github.com/..."
  docs:
    - "https://relevant-docs.com"

tags:
  - linux
  - docker
  - bootable-iso
```

### 3. trajectories/SUMMARY.md

Detailed narrative of the agent's journey.

```markdown
# [Experiment Name] - Agent Trajectory Summary

## Overview

| Metric | Value |
|--------|-------|
| Agent | Claude Opus 4.5 |
| Duration | X hours |
| Sessions | N |
| Outcome | SUCCESS/PARTIAL/FAILED |
| Cost | $X.XX |

## User Request

"[Exact initial prompt from user]"

## Approach

[How the agent approached the problem]

## Key Steps

### Session 1: [Title]

1. [Step with context]
2. [Step with context]

### Session 2: [Title]

1. [Step with context]
...

## Artifacts Produced

| File | Lines | Description |
|------|-------|-------------|
| \`file.py\` | 200 | What it does |

## Metrics

| Metric | Value |
|--------|-------|
| Tool calls | ~150 |
| Files created | 6 |
| Lines of code | ~500 |

## Where Agent Succeeded

1. [Success with explanation]

## Where Agent Struggled

1. [Struggle with explanation]

## Lessons for Agent Evaluation

1. [Lesson]
2. [Lesson]

## Reproduction Steps

\`\`\`bash
# Exact commands to reproduce
\`\`\`
```

### 4. trajectories/session-*.jsonl

Session logs in two formats:

```
trajectories/
├── SUMMARY.md              # Narrative summary
├── raw/                    # Original, unmodified logs
│   └── session-*.jsonl     # Complete session data
└── sanitized/              # Cleaned logs for sharing
    └── session-*.jsonl     # Sanitized session data
```

#### Raw Logs (trajectories/raw/)

Complete, unmodified session logs. Store everything:

```json
{"type": "user", "timestamp": "2025-12-15T15:41:00Z", "text": "can you build..."}
{"type": "assistant", "timestamp": "2025-12-15T15:41:05Z", "tool": "Bash", "command": "git clone...", "full_output": "..."}
{"type": "tool_result", "timestamp": "2025-12-15T15:41:10Z", "success": true, "output": "...full output..."}
```

**Why keep raw logs:**
- Enables detailed post-mortem analysis
- Preserves context for debugging agent behavior
- Required for accurate token/cost calculations
- Valuable for training and evaluation research

#### Sanitized Logs (trajectories/sanitized/)

Cleaned versions safe for public sharing:

```json
{"type": "user", "timestamp": "2025-12-15T15:41:00Z", "text": "can you build..."}
{"type": "assistant", "timestamp": "2025-12-15T15:41:05Z", "tool": "Bash", "command": "git clone..."}
{"type": "tool_result", "timestamp": "2025-12-15T15:41:10Z", "success": true}
```

**Sanitization rules:**
- Remove API keys, tokens, passwords
- Truncate outputs longer than 500 chars
- Replace personal paths with `$HOME` or `$WORKDIR`
- Remove any PII or sensitive data

### 5. artifacts/

All code, scripts, and configurations created during the experiment.

Organize logically:
```
artifacts/
├── Dockerfile
├── build.sh
├── src/
│   └── main.py
└── config/
    └── settings.yaml
```

## Difficulty Calibration

When assigning difficulty, use these guidelines:

| Difficulty | Expected Agent Success | Steps | Characteristics |
|------------|----------------------|-------|-----------------|
| Easy | ~50% | 10-25 | Tool-assisted, clear docs |
| Medium | ~20% | 30-55 | Config work, some debugging |
| Hard | ~5% | 50-80 | Complex debugging, ISOs |
| Extreme | <1% | 100+ | LFS-style, novel problems |

## Status Definitions

- **success** - All objectives met, artifacts work as intended
- **partial** - Some objectives met, artifacts partially work
- **failed** - Core objectives not met
- **in-progress** - Experiment ongoing

## Partial Score Guidelines

| Score | Meaning |
|-------|---------|
| 1.0 | Complete success |
| 0.7-0.9 | Works but minor issues |
| 0.4-0.6 | Partially works, significant gaps |
| 0.1-0.3 | Minimal progress, major blockers |
| 0.0 | No meaningful progress |

## Creating a Pull Request

1. Create a branch: `git checkout -b <username>/<experiment-name>`
2. Add your experiment following this structure
3. Push and create PR with this template:

```markdown
## Summary

[1-3 bullet points of what was done]

## Experiment Structure

\`\`\`
<category>/<experiment-name>/
├── README.md
├── EXPERIMENT.yaml
├── artifacts/
└── trajectories/
\`\`\`

## Key Metrics

| Metric | Value |
|--------|-------|
| Agent | ... |
| Duration | ... |
| Outcome | ... |

## Test plan

- [ ] EXPERIMENT.yaml validates
- [ ] Artifacts are organized
- [ ] Trajectory is complete

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Example: Complete Experiment

See `linux/build-debootstrap/` for a complete example:

```
linux/build-debootstrap/
├── README.md                 # Overview with metrics table
├── EXPERIMENT.yaml           # Machine-readable metadata
├── artifacts/
│   ├── Dockerfile           # Build environment
│   ├── build.sh             # Orchestration
│   └── build-scripts/       # Core scripts
└── trajectories/
    ├── SUMMARY.md           # Detailed narrative
    └── session-build.jsonl  # Session log
```

## Tips for AI Agents

1. **Track your work** - Use todo lists to maintain progress across long experiments
2. **Document as you go** - Write SUMMARY.md incrementally, not at the end
3. **Be honest about failures** - Partial results are valuable; document what didn't work
4. **Include reproduction steps** - Future agents/humans should be able to rebuild
5. **Sanitize carefully** - Remove secrets but keep enough context to understand
6. **Note human interventions** - Critical for evaluating true agent capability
