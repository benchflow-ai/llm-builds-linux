"""
Benchmark Runner using Claude Agent SDK

Runs Linux build tasks against Claude and collects traces.
"""

import anyio
import json
import os
import time
from datetime import datetime
from dataclasses import dataclass, field, asdict
from typing import Optional
from pathlib import Path

from claude_agent_sdk import (
    query,
    ClaudeAgentOptions,
    ClaudeSDKClient,
    HookMatcher,
    AssistantMessage,
    UserMessage,
    TextBlock,
    ToolUseBlock,
    ToolResultBlock,
)


@dataclass
class ToolCall:
    """Record of a single tool invocation."""
    tool_name: str
    tool_input: dict
    tool_output: Optional[str] = None
    duration_seconds: float = 0.0
    timestamp: str = ""
    success: bool = True
    error: Optional[str] = None


@dataclass
class AgentTrace:
    """Complete trace of an agent's execution."""
    trace_id: str
    task_id: str
    task_prompt: str
    model: str
    timestamp: str

    # Results
    success: bool = False
    total_duration_seconds: float = 0.0
    total_tool_calls: int = 0
    total_tokens_in: int = 0
    total_tokens_out: int = 0

    # Detailed records
    tool_calls: list = field(default_factory=list)
    messages: list = field(default_factory=list)
    errors: list = field(default_factory=list)

    # Final state
    final_output: str = ""
    artifacts_produced: list = field(default_factory=list)

    def to_dict(self):
        return asdict(self)

    def to_json(self, indent=2):
        return json.dumps(self.to_dict(), indent=indent, default=str)


class BenchmarkRunner:
    """Runs benchmark tasks against Claude and collects traces."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = "claude-sonnet-4-20250514",
        working_dir: Optional[str] = None,
        trace_dir: str = "traces",
    ):
        self.api_key = api_key or os.environ.get("ANTHROPIC_API_KEY")
        self.model = model
        self.working_dir = working_dir or os.getcwd()
        self.trace_dir = Path(trace_dir)
        self.trace_dir.mkdir(exist_ok=True)

        # Current trace being collected
        self._current_trace: Optional[AgentTrace] = None
        self._tool_start_time: Optional[float] = None

    async def _pre_tool_hook(self, input_data, tool_use_id, context):
        """Hook called before each tool use."""
        tool_name = input_data.tool_name
        tool_input = input_data.tool_input

        self._tool_start_time = time.time()

        # Log the tool call
        print(f"  → {tool_name}: {self._summarize_input(tool_name, tool_input)}")

        return {}  # Don't modify anything

    async def _post_tool_hook(self, input_data, tool_use_id, context):
        """Hook called after each tool use."""
        tool_name = input_data.tool_name
        tool_input = input_data.tool_input
        tool_output = input_data.tool_response

        duration = time.time() - self._tool_start_time if self._tool_start_time else 0

        # Record the tool call
        if self._current_trace:
            call = ToolCall(
                tool_name=tool_name,
                tool_input=tool_input,
                tool_output=str(tool_output)[:5000],  # Truncate long outputs
                duration_seconds=round(duration, 2),
                timestamp=datetime.now().isoformat(),
                success="error" not in str(tool_output).lower(),
            )
            self._current_trace.tool_calls.append(asdict(call))
            self._current_trace.total_tool_calls += 1

        return {}

    def _summarize_input(self, tool_name: str, tool_input: dict) -> str:
        """Create a short summary of tool input."""
        if tool_name == "Bash":
            cmd = tool_input.get("command", "")
            return cmd[:80] + "..." if len(cmd) > 80 else cmd
        elif tool_name == "Read":
            return tool_input.get("file_path", "")
        elif tool_name == "Write":
            return f"{tool_input.get('file_path', '')} ({len(tool_input.get('content', ''))} chars)"
        elif tool_name == "Edit":
            return tool_input.get("file_path", "")
        else:
            return str(tool_input)[:60]

    async def run_task(
        self,
        task_id: str,
        prompt: str,
        timeout_seconds: int = 600,
        max_turns: int = 50,
    ) -> AgentTrace:
        """
        Run a benchmark task and collect the trace.

        Args:
            task_id: Unique identifier for this task
            prompt: The task prompt to give Claude
            timeout_seconds: Maximum time allowed
            max_turns: Maximum conversation turns

        Returns:
            AgentTrace with complete execution history
        """
        trace_id = f"{task_id}-{datetime.now().strftime('%Y%m%d-%H%M%S')}"

        self._current_trace = AgentTrace(
            trace_id=trace_id,
            task_id=task_id,
            task_prompt=prompt,
            model=self.model,
            timestamp=datetime.now().isoformat(),
        )

        print(f"\n{'='*60}")
        print(f"Running task: {task_id}")
        print(f"Trace ID: {trace_id}")
        print(f"{'='*60}\n")

        start_time = time.time()

        try:
            options = ClaudeAgentOptions(
                model=self.model,
                system_prompt=self._get_system_prompt(),
                max_turns=max_turns,
                allowed_tools=["Bash", "Read", "Write", "Edit", "Glob", "Grep"],
                permission_mode="acceptEdits",  # Auto-accept for benchmarking
                cwd=self.working_dir,
                hooks={
                    "PreToolUse": [
                        HookMatcher(matcher="*", hooks=[self._pre_tool_hook]),
                    ],
                    "PostToolUse": [
                        HookMatcher(matcher="*", hooks=[self._post_tool_hook]),
                    ],
                },
            )

            # Set API key in environment if provided
            if self.api_key:
                os.environ["ANTHROPIC_API_KEY"] = self.api_key

            # Run the agent
            messages = []
            async for message in query(prompt=prompt, options=options):
                messages.append(self._serialize_message(message))

                # Print assistant text responses
                if isinstance(message, AssistantMessage):
                    for block in message.content:
                        if isinstance(block, TextBlock):
                            print(f"\nClaude: {block.text[:500]}...")

            self._current_trace.messages = messages
            self._current_trace.success = True
            self._current_trace.final_output = self._extract_final_output(messages)

        except Exception as e:
            self._current_trace.success = False
            self._current_trace.errors.append({
                "type": type(e).__name__,
                "message": str(e),
                "timestamp": datetime.now().isoformat(),
            })
            print(f"\nError: {e}")

        finally:
            self._current_trace.total_duration_seconds = round(time.time() - start_time, 2)

        # Save the trace
        trace_path = self.trace_dir / f"{trace_id}.json"
        with open(trace_path, "w") as f:
            f.write(self._current_trace.to_json())

        print(f"\n{'='*60}")
        print(f"Task completed: {'SUCCESS' if self._current_trace.success else 'FAILED'}")
        print(f"Duration: {self._current_trace.total_duration_seconds}s")
        print(f"Tool calls: {self._current_trace.total_tool_calls}")
        print(f"Trace saved: {trace_path}")
        print(f"{'='*60}\n")

        return self._current_trace

    def _get_system_prompt(self) -> str:
        """System prompt for benchmark tasks."""
        return """You are an expert Linux systems engineer being evaluated on your ability to build Linux systems.

Your task is to complete the given Linux build challenge. You should:
1. Understand what is being asked
2. Execute the necessary commands to build/configure the system
3. Verify your work actually succeeded (check file existence, run tests, etc.)
4. Report clearly whether you succeeded or failed

Be methodical and verify each step. If something fails, debug and retry.
You have access to Docker for building Linux systems.

IMPORTANT: Actually execute commands and verify results. Don't just describe what you would do."""

    def _serialize_message(self, message) -> dict:
        """Convert SDK message to serializable dict."""
        if isinstance(message, AssistantMessage):
            content = []
            for block in message.content:
                if isinstance(block, TextBlock):
                    content.append({"type": "text", "text": block.text})
                elif isinstance(block, ToolUseBlock):
                    content.append({
                        "type": "tool_use",
                        "name": block.name,
                        "input": block.input,
                    })
            return {"role": "assistant", "content": content}
        elif isinstance(message, UserMessage):
            return {"role": "user", "content": str(message.content)}
        else:
            return {"role": "unknown", "content": str(message)}

    def _extract_final_output(self, messages: list) -> str:
        """Extract final text output from messages."""
        for msg in reversed(messages):
            if msg.get("role") == "assistant":
                for block in msg.get("content", []):
                    if block.get("type") == "text":
                        return block.get("text", "")[:2000]
        return ""


# Predefined benchmark tasks
BENCHMARK_TASKS = {
    "alpine-minimal": {
        "id": "alpine-minimal",
        "prompt": """Build a minimal bootable Linux system using Alpine Linux in Docker.

Requirements:
1. Use Docker with Alpine 3.19 base image
2. Build an x86_64 kernel (use --platform linux/amd64 if needed)
3. Create kernel (vmlinuz) and initramfs files
4. Verify the kernel is x86_64 architecture using the 'file' command
5. Save the artifacts to the current directory

Success criteria:
- vmlinuz file exists and is a valid x86_64 Linux kernel
- initramfs file exists
- Both files are non-empty

Start by running Docker commands to build the system.""",
        "timeout": 300,
        "verification": ["file_exists:vmlinuz", "file_exists:initramfs"],
    },

    "alpine-boot-test": {
        "id": "alpine-boot-test",
        "prompt": """Build a minimal Alpine Linux system and verify it boots in QEMU.

Requirements:
1. Build x86_64 kernel and initramfs using Alpine in Docker
2. Install QEMU if not present (brew install qemu on macOS)
3. Boot the kernel in QEMU with: qemu-system-x86_64 -kernel <kernel> -initrd <initramfs> -m 512M -nographic -append "console=ttyS0"
4. Capture boot output showing successful kernel initialization
5. Kill QEMU after 10-15 seconds

Success criteria:
- Kernel boots (look for "Linux version" in output)
- Init runs (look for "Alpine Init" or similar)
- No kernel panic

This is a complete end-to-end test.""",
        "timeout": 600,
        "verification": ["boot_test"],
    },

    "debug-wrong-arch": {
        "id": "debug-wrong-arch",
        "prompt": """Debug challenge: A user built a Linux kernel but QEMU won't boot it.

The kernel is at: build-test/vmlinuz (if it exists)
The user is on an Apple Silicon Mac running QEMU x86_64.

Your task:
1. Check if build-test/vmlinuz exists
2. If it exists, check its architecture with 'file' command
3. Diagnose why it won't boot in QEMU x86_64
4. Fix the issue by rebuilding with correct architecture
5. Verify the fix

This tests debugging skills for cross-architecture issues.""",
        "timeout": 300,
        "verification": ["correct_diagnosis", "fix_applied"],
    },
}


async def run_benchmark(
    task_name: str,
    api_key: Optional[str] = None,
    working_dir: Optional[str] = None,
) -> AgentTrace:
    """
    Run a single benchmark task.

    Args:
        task_name: Name of task from BENCHMARK_TASKS
        api_key: Anthropic API key (or set ANTHROPIC_API_KEY env var)
        working_dir: Directory to run in

    Returns:
        AgentTrace with results
    """
    if task_name not in BENCHMARK_TASKS:
        raise ValueError(f"Unknown task: {task_name}. Available: {list(BENCHMARK_TASKS.keys())}")

    task = BENCHMARK_TASKS[task_name]

    runner = BenchmarkRunner(
        api_key=api_key,
        working_dir=working_dir,
    )

    return await runner.run_task(
        task_id=task["id"],
        prompt=task["prompt"],
        timeout_seconds=task.get("timeout", 600),
    )


async def run_all_benchmarks(
    api_key: Optional[str] = None,
    working_dir: Optional[str] = None,
) -> list[AgentTrace]:
    """Run all benchmark tasks and return traces."""
    results = []
    for task_name in BENCHMARK_TASKS:
        trace = await run_benchmark(task_name, api_key, working_dir)
        results.append(trace)
    return results


# CLI interface
if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python benchmark_runner.py <task_name|all>")
        print(f"Available tasks: {', '.join(BENCHMARK_TASKS.keys())}")
        sys.exit(1)

    task_arg = sys.argv[1]
    api_key = os.environ.get("CLAUDE_API_KEY") or os.environ.get("ANTHROPIC_API_KEY")

    if not api_key:
        print("Error: Set CLAUDE_API_KEY or ANTHROPIC_API_KEY environment variable")
        sys.exit(1)

    if task_arg == "all":
        anyio.run(run_all_benchmarks, api_key)
    else:
        anyio.run(run_benchmark, task_arg, api_key)
