#!/bin/bash
# Run a task in its Docker environment
# Usage: ./scripts/run-task.sh <task-id>
# Example: ./scripts/run-task.sh t1.2-busybox-kernel

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

TASK_ID="${1:-}"

if [ -z "$TASK_ID" ]; then
    echo "Usage: $0 <task-id>"
    echo ""
    echo "Available tasks:"
    find "$ROOT_DIR/tasks" -name "task.yaml" -exec dirname {} \; | while read dir; do
        basename "$dir"
    done
    exit 1
fi

# Find task directory
TASK_DIR=""
for tier_dir in "$ROOT_DIR/tasks/tier"*; do
    if [ -d "$tier_dir/$TASK_ID" ]; then
        TASK_DIR="$tier_dir/$TASK_ID"
        break
    fi
done

if [ -z "$TASK_DIR" ]; then
    echo "Error: Task '$TASK_ID' not found"
    echo ""
    echo "Available tasks:"
    find "$ROOT_DIR/tasks" -name "task.yaml" -exec dirname {} \; | while read dir; do
        basename "$dir"
    done
    exit 1
fi

echo "=== Running Task: $TASK_ID ==="
echo "Task directory: $TASK_DIR"
echo ""

# Check for Dockerfile
if [ ! -f "$TASK_DIR/Dockerfile" ]; then
    echo "Error: No Dockerfile found in $TASK_DIR"
    exit 1
fi

# Build the Docker image
IMAGE_NAME="llm-builds-linux/$TASK_ID"
echo "Building Docker image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" "$TASK_DIR"

# Run the container
echo ""
echo "Starting container..."
echo "Type 'exit' to leave the container"
echo ""

docker run -it --privileged \
    --name "${TASK_ID}-$(date +%s)" \
    --rm \
    -v "$ROOT_DIR/results:/results" \
    "$IMAGE_NAME"
