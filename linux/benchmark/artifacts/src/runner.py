"""
Task runner for executing and evaluating Linux distro building benchmarks.

This module handles:
- Setting up Docker environments for tasks
- Running verification steps
- Collecting results and metrics
"""

import subprocess
import json
import time
import os
from datetime import datetime
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from .task import (
    Task,
    TaskResult,
    VerificationStep,
    VerificationType,
)


@dataclass
class RunnerConfig:
    """Configuration for the task runner."""
    docker_enabled: bool = True
    qemu_enabled: bool = True
    work_dir: Path = field(default_factory=lambda: Path("/tmp/llm-builds-linux"))
    timeout_multiplier: float = 1.0  # Multiply all timeouts by this factor
    verbose: bool = True
    save_logs: bool = True
    log_dir: Path = field(default_factory=lambda: Path("/tmp/llm-builds-linux/logs"))


class TaskRunner:
    """Runs and evaluates Linux distro building tasks."""

    def __init__(self, config: Optional[RunnerConfig] = None):
        self.config = config or RunnerConfig()
        self.config.work_dir.mkdir(parents=True, exist_ok=True)
        self.config.log_dir.mkdir(parents=True, exist_ok=True)

    def setup_environment(self, task: Task) -> str:
        """
        Set up Docker environment for a task.
        Returns the container ID.
        """
        if not self.config.docker_enabled:
            return "local"

        # Build Docker command
        packages = " ".join(task.required_packages)
        dockerfile_content = f"""
FROM {task.base_image}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y {packages} && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
"""

        # Write Dockerfile
        dockerfile_path = self.config.work_dir / f"Dockerfile.{task.id}"
        dockerfile_path.write_text(dockerfile_content)

        # Build image
        image_name = f"llm-builds-linux-{task.id}:latest"
        result = subprocess.run(
            ["docker", "build", "-t", image_name, "-f", str(dockerfile_path), "."],
            cwd=self.config.work_dir,
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(f"Failed to build Docker image: {result.stderr}")

        # Start container
        result = subprocess.run(
            [
                "docker", "run", "-d",
                "--name", f"llm-builds-{task.id}-{int(time.time())}",
                "-v", f"{self.config.work_dir}:/workspace",
                image_name,
                "sleep", "infinity"
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            raise RuntimeError(f"Failed to start container: {result.stderr}")

        return result.stdout.strip()

    def run_verification(
        self, step: VerificationStep, container_id: str
    ) -> dict:
        """
        Run a single verification step.
        Returns a dict with results.
        """
        result = {
            "type": step.type.value,
            "description": step.description,
            "passed": False,
            "details": "",
            "error": None,
            "duration_seconds": 0,
        }

        start_time = time.time()

        try:
            if step.type == VerificationType.FILE_CHECK:
                result = self._verify_files(step, container_id, result)

            elif step.type == VerificationType.SIZE_CHECK:
                result = self._verify_size(step, container_id, result)

            elif step.type == VerificationType.COMMAND_OUTPUT:
                result = self._verify_command(step, container_id, result)

            elif step.type == VerificationType.BOOT_TEST:
                result = self._verify_boot(step, container_id, result)

            elif step.type == VerificationType.CHECKSUM:
                result = self._verify_checksum(step, container_id, result)

        except Exception as e:
            result["error"] = str(e)
            result["passed"] = False

        result["duration_seconds"] = time.time() - start_time
        return result

    def _verify_files(
        self, step: VerificationStep, container_id: str, result: dict
    ) -> dict:
        """Check that expected files exist."""
        missing_files = []

        for file_path in step.expected_files:
            if container_id == "local":
                exists = Path(file_path).exists()
            else:
                check_result = subprocess.run(
                    ["docker", "exec", container_id, "test", "-f", file_path],
                    capture_output=True,
                )
                exists = check_result.returncode == 0

            if not exists:
                missing_files.append(file_path)

        result["passed"] = len(missing_files) == 0
        if missing_files:
            result["details"] = f"Missing files: {missing_files}"
        else:
            result["details"] = f"All {len(step.expected_files)} files found"

        return result

    def _verify_size(
        self, step: VerificationStep, container_id: str, result: dict
    ) -> dict:
        """Verify file size constraints."""
        for file_path in step.expected_files:
            if container_id == "local":
                size_bytes = Path(file_path).stat().st_size
            else:
                size_result = subprocess.run(
                    ["docker", "exec", container_id, "stat", "-c", "%s", file_path],
                    capture_output=True,
                    text=True,
                )
                if size_result.returncode != 0:
                    result["details"] = f"File not found: {file_path}"
                    return result
                size_bytes = int(size_result.stdout.strip())

            size_mb = size_bytes / (1024 * 1024)

            if step.min_size_mb and size_mb < step.min_size_mb:
                result["details"] = f"{file_path}: {size_mb:.1f}MB < min {step.min_size_mb}MB"
                return result

            if step.max_size_mb and size_mb > step.max_size_mb:
                result["details"] = f"{file_path}: {size_mb:.1f}MB > max {step.max_size_mb}MB"
                return result

        result["passed"] = True
        result["details"] = f"Size constraints satisfied"
        return result

    def _verify_command(
        self, step: VerificationStep, container_id: str, result: dict
    ) -> dict:
        """Run command and check output."""
        timeout = int(step.timeout_seconds * self.config.timeout_multiplier)

        if container_id == "local":
            cmd_result = subprocess.run(
                step.command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
        else:
            cmd_result = subprocess.run(
                ["docker", "exec", container_id, "bash", "-c", step.command],
                capture_output=True,
                text=True,
                timeout=timeout,
            )

        output = cmd_result.stdout + cmd_result.stderr

        if step.expected_output:
            result["passed"] = step.expected_output in output
            result["details"] = f"Output {'contains' if result['passed'] else 'missing'} expected string"
        else:
            result["passed"] = cmd_result.returncode == 0
            result["details"] = f"Command returned {cmd_result.returncode}"

        return result

    def _verify_boot(
        self, step: VerificationStep, container_id: str, result: dict
    ) -> dict:
        """Test that system boots in QEMU."""
        if not self.config.qemu_enabled:
            result["details"] = "QEMU verification disabled"
            result["passed"] = True  # Skip but don't fail
            return result

        timeout = int(step.timeout_seconds * self.config.timeout_multiplier)

        # Run QEMU with timeout
        try:
            if container_id == "local":
                qemu_result = subprocess.run(
                    step.command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=timeout,
                )
            else:
                qemu_result = subprocess.run(
                    ["docker", "exec", container_id, "bash", "-c", step.command],
                    capture_output=True,
                    text=True,
                    timeout=timeout,
                )

            output = qemu_result.stdout + qemu_result.stderr

            # Check for expected boot indicators
            if step.expected_output and step.expected_output in output:
                result["passed"] = True
                result["details"] = f"Boot successful: found '{step.expected_output}'"
            else:
                result["passed"] = False
                result["details"] = f"Boot indicator not found in output"

        except subprocess.TimeoutExpired:
            result["passed"] = False
            result["details"] = f"Boot timed out after {timeout}s"

        return result

    def _verify_checksum(
        self, step: VerificationStep, container_id: str, result: dict
    ) -> dict:
        """Verify file checksum."""
        for file_path in step.expected_files:
            if container_id == "local":
                hash_result = subprocess.run(
                    ["sha256sum", file_path],
                    capture_output=True,
                    text=True,
                )
            else:
                hash_result = subprocess.run(
                    ["docker", "exec", container_id, "sha256sum", file_path],
                    capture_output=True,
                    text=True,
                )

            if hash_result.returncode != 0:
                result["details"] = f"Failed to hash {file_path}"
                return result

            actual_hash = hash_result.stdout.split()[0]

            if step.expected_output and actual_hash != step.expected_output:
                result["details"] = f"Checksum mismatch: {actual_hash[:16]}... != {step.expected_output[:16]}..."
                return result

        result["passed"] = True
        result["details"] = "Checksum verified"
        return result

    def cleanup(self, container_id: str):
        """Clean up Docker container."""
        if container_id != "local" and self.config.docker_enabled:
            subprocess.run(["docker", "rm", "-f", container_id], capture_output=True)

    def evaluate_task(
        self,
        task: Task,
        agent_id: str,
        model_name: str,
    ) -> TaskResult:
        """
        Evaluate a completed task.

        This assumes the agent has already attempted the task.
        We just run verification steps.
        """
        start_time = datetime.now().isoformat()
        start_ts = time.time()

        verification_results = []
        errors = []
        success = True

        for step in task.verification_steps:
            result = self.run_verification(step, "local")
            verification_results.append(result)

            if not result["passed"]:
                success = False
                if result.get("error"):
                    errors.append(result["error"])

        end_time = datetime.now().isoformat()
        duration = time.time() - start_ts

        # Calculate partial score
        passed_count = sum(1 for v in verification_results if v["passed"])
        total_count = len(verification_results)
        partial_score = passed_count / total_count if total_count > 0 else 0.0

        # Check for artifacts
        artifacts_produced = []
        for artifact in task.success_artifacts:
            if Path(artifact).exists():
                artifacts_produced.append(artifact)

        return TaskResult(
            task_id=task.id,
            agent_id=agent_id,
            model_name=model_name,
            success=success,
            steps_completed=passed_count,
            total_steps_attempted=total_count,
            start_time=start_time,
            end_time=end_time,
            duration_seconds=duration,
            verification_results=verification_results,
            artifacts_produced=artifacts_produced,
            errors=errors,
            partial_score=partial_score,
        )


def list_all_tasks() -> list[Task]:
    """List all available tasks."""
    from .tasks import ALL_TASKS
    return ALL_TASKS


def get_task_by_id(task_id: str) -> Optional[Task]:
    """Get a task by its ID."""
    for task in list_all_tasks():
        if task.id == task_id:
            return task
    return None


def export_tasks_json(output_path: Path):
    """Export all tasks to JSON file."""
    tasks = list_all_tasks()
    tasks_data = [task.to_dict() for task in tasks]

    with open(output_path, "w") as f:
        json.dump(tasks_data, f, indent=2)


def print_task_summary():
    """Print a summary of all available tasks."""
    tasks = list_all_tasks()

    print(f"\n{'='*60}")
    print("Linux Distro Building Benchmark Tasks")
    print(f"{'='*60}\n")

    by_category = {}
    for task in tasks:
        cat = task.category.value
        if cat not in by_category:
            by_category[cat] = []
        by_category[cat].append(task)

    for category, category_tasks in by_category.items():
        print(f"\n## {category.upper().replace('_', ' ')}")
        print("-" * 40)

        for task in category_tasks:
            print(f"\n  [{task.id}] {task.name}")
            print(f"    Difficulty: {task.difficulty.value}")
            print(f"    Expected steps: {task.expected_steps}")
            print(f"    Time limit: {task.time_limit_minutes} min")

    print(f"\n{'='*60}")
    print(f"Total: {len(tasks)} tasks")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    print_task_summary()
