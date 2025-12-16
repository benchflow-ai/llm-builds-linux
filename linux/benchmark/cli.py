#!/usr/bin/env python3
"""
CLI for llm-builds-linux benchmark.

Usage:
    python cli.py list                    # List all tasks
    python cli.py show <task_id>          # Show task details
    python cli.py export tasks.json       # Export tasks to JSON
    python cli.py run <task_id>           # Run verification for a task
"""

import argparse
import json
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent))

from src.task import Task
from src.runner import (
    list_all_tasks,
    get_task_by_id,
    export_tasks_json,
    print_task_summary,
    TaskRunner,
    RunnerConfig,
)


def cmd_list(args):
    """List all available tasks."""
    if args.json:
        tasks = list_all_tasks()
        data = [{"id": t.id, "name": t.name, "difficulty": t.difficulty.value} for t in tasks]
        print(json.dumps(data, indent=2))
    else:
        print_task_summary()


def cmd_show(args):
    """Show details for a specific task."""
    task = get_task_by_id(args.task_id)

    if not task:
        print(f"Task not found: {args.task_id}")
        print("\nAvailable tasks:")
        for t in list_all_tasks():
            print(f"  - {t.id}")
        sys.exit(1)

    if args.json:
        print(task.to_json())
    else:
        print(f"\n{'='*60}")
        print(f"Task: {task.name}")
        print(f"{'='*60}")
        print(f"\nID: {task.id}")
        print(f"Category: {task.category.value}")
        print(f"Difficulty: {task.difficulty.value}")
        print(f"\nDescription:\n{task.description}")
        print(f"\nInstructions:\n{task.instructions}")
        print(f"\nExpected Steps: {task.expected_steps}")
        print(f"Time Limit: {task.time_limit_minutes} minutes")
        print(f"\nBase Image: {task.base_image}")
        print(f"Required Packages: {', '.join(task.required_packages[:5])}...")
        print(f"Required Disk: {task.required_disk_gb} GB")
        print(f"Required RAM: {task.required_ram_gb} GB")

        print(f"\nVerification Steps ({len(task.verification_steps)}):")
        for i, step in enumerate(task.verification_steps, 1):
            print(f"  {i}. [{step.type.value}] {step.description}")

        print(f"\nSuccess Artifacts:")
        for artifact in task.success_artifacts:
            print(f"  - {artifact}")

        if task.common_failure_points:
            print(f"\nCommon Failure Points:")
            for point in task.common_failure_points:
                print(f"  - {point}")

        if task.reference_docs:
            print(f"\nReference Docs:")
            for doc in task.reference_docs:
                print(f"  - {doc}")

        print()


def cmd_export(args):
    """Export tasks to JSON file."""
    output_path = Path(args.output)
    export_tasks_json(output_path)
    print(f"Exported {len(list_all_tasks())} tasks to {output_path}")


def cmd_run(args):
    """Run verification for a completed task."""
    task = get_task_by_id(args.task_id)

    if not task:
        print(f"Task not found: {args.task_id}")
        sys.exit(1)

    print(f"\n{'='*60}")
    print(f"Evaluating: {task.name}")
    print(f"{'='*60}\n")

    config = RunnerConfig(
        docker_enabled=not args.local,
        qemu_enabled=not args.no_qemu,
        verbose=args.verbose,
    )

    runner = TaskRunner(config)

    result = runner.evaluate_task(
        task=task,
        agent_id=args.agent or "manual",
        model_name=args.model or "unknown",
    )

    print(f"\n{'='*60}")
    print("RESULTS")
    print(f"{'='*60}\n")

    print(f"Success: {'YES' if result.success else 'NO'}")
    print(f"Partial Score: {result.partial_score:.2%}")
    print(f"Duration: {result.duration_seconds:.1f}s")

    print(f"\nVerification Results:")
    for v in result.verification_results:
        status = "PASS" if v["passed"] else "FAIL"
        print(f"  [{status}] {v['description']}")
        if v.get("details"):
            print(f"         {v['details']}")

    if result.errors:
        print(f"\nErrors:")
        for error in result.errors:
            print(f"  - {error}")

    print(f"\nArtifacts Produced:")
    for artifact in result.artifacts_produced:
        print(f"  - {artifact}")

    if args.json:
        print(f"\n{'='*60}")
        print("JSON Output:")
        print(json.dumps(result.to_dict(), indent=2))


def cmd_env(args):
    """Show environment setup instructions."""
    task = get_task_by_id(args.task_id)

    if not task:
        print(f"Task not found: {args.task_id}")
        sys.exit(1)

    print(f"\n{'='*60}")
    print(f"Environment Setup: {task.name}")
    print(f"{'='*60}\n")

    print("# Docker setup command:")
    packages = " ".join(task.required_packages)
    print(f"""
docker run -it --rm \\
    -v $(pwd):/workspace \\
    --name llm-builds-{task.id} \\
    {task.base_image} \\
    bash -c "apt-get update && apt-get install -y {packages} && bash"
""")

    print("\n# Or install packages locally:")
    print(f"sudo apt-get update && sudo apt-get install -y {packages}")
    print()


def main():
    parser = argparse.ArgumentParser(
        description="llm-builds-linux benchmark CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # list command
    list_parser = subparsers.add_parser("list", help="List all available tasks")
    list_parser.add_argument("--json", action="store_true", help="Output as JSON")
    list_parser.set_defaults(func=cmd_list)

    # show command
    show_parser = subparsers.add_parser("show", help="Show task details")
    show_parser.add_argument("task_id", help="Task ID to show")
    show_parser.add_argument("--json", action="store_true", help="Output as JSON")
    show_parser.set_defaults(func=cmd_show)

    # export command
    export_parser = subparsers.add_parser("export", help="Export tasks to JSON")
    export_parser.add_argument("output", help="Output file path")
    export_parser.set_defaults(func=cmd_export)

    # run command
    run_parser = subparsers.add_parser("run", help="Run verification for a task")
    run_parser.add_argument("task_id", help="Task ID to evaluate")
    run_parser.add_argument("--agent", help="Agent ID")
    run_parser.add_argument("--model", help="Model name")
    run_parser.add_argument("--local", action="store_true", help="Run locally without Docker")
    run_parser.add_argument("--no-qemu", action="store_true", help="Skip QEMU boot tests")
    run_parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    run_parser.add_argument("--json", action="store_true", help="Also output JSON")
    run_parser.set_defaults(func=cmd_run)

    # env command
    env_parser = subparsers.add_parser("env", help="Show environment setup")
    env_parser.add_argument("task_id", help="Task ID")
    env_parser.set_defaults(func=cmd_env)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    args.func(args)


if __name__ == "__main__":
    main()
