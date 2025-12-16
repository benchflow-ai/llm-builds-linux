"""
Task definition for Linux distro building benchmarks.

Tasks are defined as dataclasses with clear success criteria and verification methods.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional
import json


class Difficulty(Enum):
    """Task difficulty levels based on expected agent performance."""
    EASY = "easy"           # ~50% of agents should pass
    MEDIUM = "medium"       # ~20% of agents should pass
    HARD = "hard"           # ~5% of agents should pass
    EXTREME = "extreme"     # <1% of agents should pass


class Category(Enum):
    """Categories of Linux distro building tasks."""
    FROM_SCRATCH = "from_scratch"       # LFS-style, minimal tooling
    TOOL_ASSISTED = "tool_assisted"     # Buildroot, Yocto, debootstrap
    MODIFICATION = "modification"        # Customize existing distro
    DEBUGGING = "debugging"              # Fix broken builds
    CONFIGURATION = "configuration"      # Add packages/features


class VerificationType(Enum):
    """How to verify task success."""
    BOOT_TEST = "boot_test"             # Must boot in QEMU/VM
    FILE_CHECK = "file_check"           # Check for specific files
    CHECKSUM = "checksum"               # Verify artifact checksums
    COMMAND_OUTPUT = "command_output"   # Run command, check output
    SIZE_CHECK = "size_check"           # Verify image size constraints


@dataclass
class VerificationStep:
    """A single verification step."""
    type: VerificationType
    description: str
    command: Optional[str] = None       # Command to run
    expected_output: Optional[str] = None
    expected_files: list[str] = field(default_factory=list)
    max_size_mb: Optional[int] = None
    min_size_mb: Optional[int] = None
    timeout_seconds: int = 300


@dataclass
class Task:
    """
    A Linux distro building benchmark task.

    Tasks define what an agent needs to accomplish, how to verify success,
    and metadata for evaluation.
    """
    id: str
    name: str
    description: str
    category: Category
    difficulty: Difficulty

    # Task details
    instructions: str                    # What the agent should do
    expected_steps: int                  # Approximate steps to complete
    prerequisites: list[str] = field(default_factory=list)

    # Environment
    base_image: str = "ubuntu:22.04"    # Docker base for environment
    required_packages: list[str] = field(default_factory=list)
    required_disk_gb: int = 20
    required_ram_gb: int = 4

    # Verification
    verification_steps: list[VerificationStep] = field(default_factory=list)
    success_artifacts: list[str] = field(default_factory=list)  # Files that should exist

    # Timing
    time_limit_minutes: int = 120
    expected_build_minutes: int = 30

    # Metadata
    tags: list[str] = field(default_factory=list)
    reference_docs: list[str] = field(default_factory=list)
    common_failure_points: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization."""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "category": self.category.value,
            "difficulty": self.difficulty.value,
            "instructions": self.instructions,
            "expected_steps": self.expected_steps,
            "prerequisites": self.prerequisites,
            "base_image": self.base_image,
            "required_packages": self.required_packages,
            "required_disk_gb": self.required_disk_gb,
            "required_ram_gb": self.required_ram_gb,
            "verification_steps": [
                {
                    "type": v.type.value,
                    "description": v.description,
                    "command": v.command,
                    "expected_output": v.expected_output,
                    "expected_files": v.expected_files,
                    "max_size_mb": v.max_size_mb,
                    "min_size_mb": v.min_size_mb,
                    "timeout_seconds": v.timeout_seconds,
                }
                for v in self.verification_steps
            ],
            "success_artifacts": self.success_artifacts,
            "time_limit_minutes": self.time_limit_minutes,
            "expected_build_minutes": self.expected_build_minutes,
            "tags": self.tags,
            "reference_docs": self.reference_docs,
            "common_failure_points": self.common_failure_points,
        }

    def to_json(self, indent: int = 2) -> str:
        """Convert to JSON string."""
        return json.dumps(self.to_dict(), indent=indent)

    @classmethod
    def from_dict(cls, data: dict) -> "Task":
        """Create Task from dictionary."""
        verification_steps = [
            VerificationStep(
                type=VerificationType(v["type"]),
                description=v["description"],
                command=v.get("command"),
                expected_output=v.get("expected_output"),
                expected_files=v.get("expected_files", []),
                max_size_mb=v.get("max_size_mb"),
                min_size_mb=v.get("min_size_mb"),
                timeout_seconds=v.get("timeout_seconds", 300),
            )
            for v in data.get("verification_steps", [])
        ]

        return cls(
            id=data["id"],
            name=data["name"],
            description=data["description"],
            category=Category(data["category"]),
            difficulty=Difficulty(data["difficulty"]),
            instructions=data["instructions"],
            expected_steps=data["expected_steps"],
            prerequisites=data.get("prerequisites", []),
            base_image=data.get("base_image", "ubuntu:22.04"),
            required_packages=data.get("required_packages", []),
            required_disk_gb=data.get("required_disk_gb", 20),
            required_ram_gb=data.get("required_ram_gb", 4),
            verification_steps=verification_steps,
            success_artifacts=data.get("success_artifacts", []),
            time_limit_minutes=data.get("time_limit_minutes", 120),
            expected_build_minutes=data.get("expected_build_minutes", 30),
            tags=data.get("tags", []),
            reference_docs=data.get("reference_docs", []),
            common_failure_points=data.get("common_failure_points", []),
        )


@dataclass
class TaskResult:
    """Result of running a task."""
    task_id: str
    agent_id: str
    model_name: str

    # Outcome
    success: bool
    steps_completed: int
    total_steps_attempted: int

    # Timing
    start_time: str
    end_time: str
    duration_seconds: float

    # Verification results
    verification_results: list[dict] = field(default_factory=list)

    # Artifacts
    artifacts_produced: list[str] = field(default_factory=list)
    logs_path: Optional[str] = None

    # Error tracking
    errors: list[str] = field(default_factory=list)
    failure_point: Optional[str] = None

    # Partial credit
    partial_score: float = 0.0  # 0.0 to 1.0

    def to_dict(self) -> dict:
        return {
            "task_id": self.task_id,
            "agent_id": self.agent_id,
            "model_name": self.model_name,
            "success": self.success,
            "steps_completed": self.steps_completed,
            "total_steps_attempted": self.total_steps_attempted,
            "start_time": self.start_time,
            "end_time": self.end_time,
            "duration_seconds": self.duration_seconds,
            "verification_results": self.verification_results,
            "artifacts_produced": self.artifacts_produced,
            "logs_path": self.logs_path,
            "errors": self.errors,
            "failure_point": self.failure_point,
            "partial_score": self.partial_score,
        }
