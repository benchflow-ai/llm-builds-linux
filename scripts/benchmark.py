#!/usr/bin/env python3
"""
Linux Distro Building Benchmark Runner

This script runs benchmark tasks and collects metrics on agent performance.
"""

import argparse
import json
import os
import subprocess
import sys
import time
import yaml
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict


@dataclass
class TaskResult:
    task_id: str
    task_name: str
    tier: int
    start_time: str
    end_time: str
    duration_seconds: float
    success: bool
    score: int
    max_score: int
    errors: List[str]
    notes: str


@dataclass
class BenchmarkRun:
    run_id: str
    model: str
    timestamp: str
    tasks: List[TaskResult]
    total_score: int
    max_total_score: int


def find_tasks(root_dir: Path) -> List[Path]:
    """Find all task directories with task.yaml files."""
    tasks = []
    for tier_dir in sorted(root_dir.glob("tasks/tier*")):
        for task_dir in sorted(tier_dir.iterdir()):
            if (task_dir / "task.yaml").exists():
                tasks.append(task_dir)
    return tasks


def load_task_spec(task_dir: Path) -> dict:
    """Load task specification from task.yaml."""
    with open(task_dir / "task.yaml") as f:
        return yaml.safe_load(f)


def list_tasks(root_dir: Path):
    """List all available tasks."""
    tasks = find_tasks(root_dir)

    print("Available Tasks")
    print("=" * 60)

    current_tier = None
    for task_dir in tasks:
        spec = load_task_spec(task_dir)
        tier = spec.get("tier", 0)

        if tier != current_tier:
            current_tier = tier
            print(f"\nTier {tier}: {'Minimal' if tier == 1 else 'Custom Spin' if tier == 2 else 'Advanced'}")
            print("-" * 40)

        task_id = task_dir.name
        name = spec.get("name", "Unknown")
        difficulty = spec.get("difficulty", "unknown")
        est_time = spec.get("estimated_time", "unknown")

        print(f"  {task_id}")
        print(f"    {name}")
        print(f"    Difficulty: {difficulty}, Time: {est_time}")


def run_task_interactive(task_dir: Path) -> TaskResult:
    """Run a task interactively and collect results."""
    spec = load_task_spec(task_dir)
    task_id = task_dir.name

    print(f"\n{'=' * 60}")
    print(f"Task: {spec.get('name', task_id)}")
    print(f"Tier: {spec.get('tier', 'unknown')}")
    print(f"Estimated Time: {spec.get('estimated_time', 'unknown')}")
    print(f"{'=' * 60}\n")

    start_time = datetime.now()

    # This would be where we hook into an LLM agent
    # For now, we just run the container interactively
    print("Starting task environment...")
    print("(In automated mode, this would run an LLM agent)")
    print()

    # Build and run Docker container
    image_name = f"llm-builds-linux/{task_id}"

    try:
        subprocess.run(
            ["docker", "build", "-t", image_name, str(task_dir)],
            check=True,
            capture_output=True
        )
    except subprocess.CalledProcessError as e:
        print(f"Error building Docker image: {e.stderr.decode()}")
        return TaskResult(
            task_id=task_id,
            task_name=spec.get("name", "Unknown"),
            tier=spec.get("tier", 0),
            start_time=start_time.isoformat(),
            end_time=datetime.now().isoformat(),
            duration_seconds=0,
            success=False,
            score=0,
            max_score=100,
            errors=["Docker build failed"],
            notes=""
        )

    # Run interactively
    try:
        subprocess.run(
            ["docker", "run", "-it", "--privileged", "--rm", image_name],
            check=True
        )
    except subprocess.CalledProcessError:
        pass  # User exited

    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()

    # Prompt for results (manual for now)
    print("\n" + "=" * 60)
    print("Task completed. Please enter results:")

    success = input("Did the task succeed? (y/n): ").lower().startswith("y")
    score = int(input("Score (0-100): ") or "0")
    notes = input("Notes: ")

    return TaskResult(
        task_id=task_id,
        task_name=spec.get("name", "Unknown"),
        tier=spec.get("tier", 0),
        start_time=start_time.isoformat(),
        end_time=end_time.isoformat(),
        duration_seconds=duration,
        success=success,
        score=score,
        max_score=100,
        errors=[],
        notes=notes
    )


def save_results(run: BenchmarkRun, output_dir: Path):
    """Save benchmark results to JSON file."""
    output_dir.mkdir(parents=True, exist_ok=True)

    filename = f"benchmark-{run.run_id}.json"
    filepath = output_dir / filename

    with open(filepath, "w") as f:
        json.dump(asdict(run), f, indent=2)

    print(f"\nResults saved to: {filepath}")


def main():
    parser = argparse.ArgumentParser(description="Linux Distro Building Benchmark")
    parser.add_argument("--list", action="store_true", help="List available tasks")
    parser.add_argument("--task", type=str, help="Run a specific task")
    parser.add_argument("--tier", type=int, help="Run all tasks in a tier")
    parser.add_argument("--model", type=str, default="manual", help="Model being tested")
    parser.add_argument("--output", type=str, default="results", help="Output directory")

    args = parser.parse_args()

    # Find root directory
    script_dir = Path(__file__).parent
    root_dir = script_dir.parent

    if args.list:
        list_tasks(root_dir)
        return

    if args.task:
        # Find and run specific task
        task_dir = None
        for tier_dir in root_dir.glob("tasks/tier*"):
            candidate = tier_dir / args.task
            if candidate.exists():
                task_dir = candidate
                break

        if not task_dir:
            print(f"Error: Task '{args.task}' not found")
            sys.exit(1)

        result = run_task_interactive(task_dir)

        run = BenchmarkRun(
            run_id=datetime.now().strftime("%Y%m%d-%H%M%S"),
            model=args.model,
            timestamp=datetime.now().isoformat(),
            tasks=[result],
            total_score=result.score,
            max_total_score=result.max_score
        )

        save_results(run, root_dir / args.output)

    elif args.tier:
        # Run all tasks in a tier
        tasks = find_tasks(root_dir)
        tier_tasks = [t for t in tasks if load_task_spec(t).get("tier") == args.tier]

        if not tier_tasks:
            print(f"Error: No tasks found for tier {args.tier}")
            sys.exit(1)

        results = []
        for task_dir in tier_tasks:
            result = run_task_interactive(task_dir)
            results.append(result)

        run = BenchmarkRun(
            run_id=datetime.now().strftime("%Y%m%d-%H%M%S"),
            model=args.model,
            timestamp=datetime.now().isoformat(),
            tasks=results,
            total_score=sum(r.score for r in results),
            max_total_score=sum(r.max_score for r in results)
        )

        save_results(run, root_dir / args.output)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
