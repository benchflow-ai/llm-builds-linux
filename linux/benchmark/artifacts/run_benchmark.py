#!/usr/bin/env python3
"""
Run Linux Build Benchmarks against Claude

Usage:
    python run_benchmark.py <api_key> [task_name]

Examples:
    python run_benchmark.py sk-ant-api03-xxx alpine-minimal
    python run_benchmark.py sk-ant-api03-xxx all
"""

import sys
import os

# Parse arguments
if len(sys.argv) < 2:
    print(__doc__)
    print("Available tasks: alpine-minimal, alpine-boot-test, debug-wrong-arch, all")
    sys.exit(1)

api_key = sys.argv[1]
task_name = sys.argv[2] if len(sys.argv) > 2 else "alpine-minimal"

# Set the API key
os.environ["ANTHROPIC_API_KEY"] = api_key

# Now import and run
import anyio
from src.benchmark_runner import run_benchmark, run_all_benchmarks, BENCHMARK_TASKS

async def main():
    print(f"\n{'='*60}")
    print("Linux Build Benchmark Runner")
    print(f"{'='*60}\n")

    if task_name == "all":
        print(f"Running all {len(BENCHMARK_TASKS)} tasks...")
        traces = await run_all_benchmarks(api_key=api_key)

        print(f"\n{'='*60}")
        print("Summary")
        print(f"{'='*60}")
        for trace in traces:
            status = "PASS" if trace.success else "FAIL"
            print(f"  {trace.task_id}: {status} ({trace.total_duration_seconds}s, {trace.total_tool_calls} tool calls)")
    else:
        if task_name not in BENCHMARK_TASKS:
            print(f"Unknown task: {task_name}")
            print(f"Available: {', '.join(BENCHMARK_TASKS.keys())}")
            sys.exit(1)

        print(f"Running task: {task_name}")
        trace = await run_benchmark(task_name, api_key=api_key)

        print(f"\nResult: {'PASS' if trace.success else 'FAIL'}")
        print(f"Duration: {trace.total_duration_seconds}s")
        print(f"Tool calls: {trace.total_tool_calls}")
        print(f"Trace saved to: traces/{trace.trace_id}.json")

if __name__ == "__main__":
    anyio.run(main)
