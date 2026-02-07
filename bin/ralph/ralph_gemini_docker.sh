#!/bin/bash
# ralph_gemini_docker.sh
# Docker wrapper for Gemini CLI - runs iterations in isolated container
# Usage: ./ralph_gemini_docker.sh <iterations>

set -e

# Configuration
IMAGE_NAME="ralph-gemini:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE_PATH="$SCRIPT_DIR/Dockerfile.ralph-gemini"
BUILD_CONTEXT="$SCRIPT_DIR"
DEFAULT_MODEL="gemini-3-flash-preview"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}$1${NC}"
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker Desktop and try again."
    fi
}

# Check if Gemini credentials exist
check_gemini_auth() {
    if [ ! -d "$HOME/.gemini" ]; then
        error "Gemini CLI not authenticated. Please run 'gemini' on host first to authenticate via browser."
    fi
}

# Check if image exists, build if not
ensure_image() {
    if [ ! -f "$DOCKERFILE_PATH" ]; then
        error "Dockerfile not found at: $DOCKERFILE_PATH"
    fi

    if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        info "Building $IMAGE_NAME Docker image (one-time setup)..."
        info "This may take 2-5 minutes..."

        if ! docker build \
            --build-arg USER_ID="$(id -u)" \
            --build-arg GROUP_ID="$(id -g)" \
            -t "$IMAGE_NAME" \
            -f "$DOCKERFILE_PATH" \
            "$BUILD_CONTEXT/" 2>&1; then
            error "Failed to build Docker image"
        fi

        info "✓ Image built successfully"
    else
        info "✓ Using existing $IMAGE_NAME image"
    fi
}

# Validate parameters
if [ -z "$1" ]; then
    echo "Usage: $0 <iterations> [model]"
    echo ""
    echo "Run Gemini CLI iterations in Docker sandbox with automatic PRD task processing."
    echo ""
    echo "Arguments:"
    echo "  iterations    Number of iterations to run (positive integer)"
    echo "  model         Optional model name (default: $DEFAULT_MODEL)"
    echo ""
    echo "Examples:"
    echo "  $0 5                      # Run 5 iterations with default model"
    echo "  $0 1 gemini-2.5-pro      # Run 1 iteration with specific model"
    echo ""
    echo "Features:"
    echo "  - Isolated Docker sandbox"
    echo "  - Uses your Google AI Pro subscription"
    echo "  - Git push blocked (no SSH keys in container)"
    echo "  - Automatic image build on first run"
    echo "  - Git commits use your identity"
    echo "  - File edits persist to host"
    echo ""
    echo "Prerequisites:"
    echo "  1. Run 'gemini' on host to authenticate with Google account"
    echo "  2. Docker Desktop must be running"
    exit 1
fi

# Validate iteration count
if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 1 ]; then
    error "Iterations must be a positive integer, got: $1"
fi

ITERATIONS=$1
MODEL="${2:-$DEFAULT_MODEL}"

# Check prerequisites
info "Checking prerequisites..."
check_docker
check_gemini_auth

# Verify we're in a project directory
if [ ! -f ".agents/plans/prd.json" ] || [ ! -f ".agents/plans/progress.txt" ]; then
    error "Must be run from project root with .agents/plans/prd.json and progress.txt"
fi

# Get git config for commit attribution
GIT_NAME=$(git config user.name 2>/dev/null || echo "Gemini Docker")
GIT_EMAIL=$(git config user.email 2>/dev/null || echo "gemini@localhost")

info "Git commits will be attributed to: $GIT_NAME <$GIT_EMAIL>"
info "Using model: $MODEL"

# Ensure image exists (build if needed)
ensure_image

# Verify Gemini CLI is available in image
info "Verifying Gemini CLI installation..."
if ! docker run --rm "$IMAGE_NAME" gemini --version >/dev/null 2>&1; then
    error "Gemini CLI not found in Docker image. Try rebuilding: docker rmi $IMAGE_NAME"
fi

info "Starting $ITERATIONS iteration(s) in Docker sandbox..."
info "Press Ctrl+C to abort"
echo ""

# Docker run configuration
DOCKER_ARGS=(
    --rm
    --user "$(id -u):$(id -g)"
    -v "$PWD:/workspace:rw"
    -v "$HOME/.gemini:/home/gemini/.gemini:rw"
    -v "$HOME/.agents:/home/gemini/.agents:ro"
    -v "$HOME/.gitconfig:/home/gemini/.gitconfig:ro"
    -w /workspace
    -e "GIT_AUTHOR_NAME=$GIT_NAME"
    -e "GIT_AUTHOR_EMAIL=$GIT_EMAIL"
    -e "GIT_COMMITTER_NAME=$GIT_NAME"
    -e "GIT_COMMITTER_EMAIL=$GIT_EMAIL"
)

# PRD prompt template
PROMPT=".agents/plans/prd.json .agents/plans/progress.txt
1. Decide which task to work on next.
This should be the one YOU decide has the highest priority,
- not necessarily the first in the list.
3. One task is one PRD item. Work ONLY on that PRD item.
2. Check any feedback loops, such as types and tests.
3. Append your progress to the progress.txt file.
4. Append in the pdr.json file the work that was done.
5. Make a git commit of that task.
ONLY WORK ON A SINGLE TASK.
CRITICAL: At the end of EVERY TASK, you must output your status:
- Output <promise>COMPLETE</promise> if the PRD is fully complete
- Output <promise>CONTINUE</promise> if any work remains

The loop depends on receiving one of these tags. Never end a response without one. "

# Iteration loop
for ((i=1; i<=$ITERATIONS; i++)); do
    echo "=== Iteration $i of $ITERATIONS ==="

    # Run docker and capture output (show in real-time if tty available)
    if [ -t 1 ]; then
        # Interactive mode - show output in real-time
        result=$(docker run "${DOCKER_ARGS[@]}" \
            "$IMAGE_NAME" \
            gemini -y -m "$MODEL" --include-directories .agents/plans --sandbox false -p "$PROMPT" 2>&1 | tee /dev/tty)
    else
        # Non-interactive mode - just capture output
        result=$(docker run "${DOCKER_ARGS[@]}" \
            "$IMAGE_NAME" \
            gemini -y -m "$MODEL" --include-directories .agents/plans --sandbox false -p "$PROMPT" 2>&1)
        echo "$result"
    fi

    if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
        echo ""
        info "✓ PRD complete, exiting early."
        exit 0
    fi

    echo "=== Completed iteration $i ==="
    echo ""
done

echo ""
info "✓ All $ITERATIONS iterations completed."
info "Review changes with: git log --oneline -$ITERATIONS"
info "Review and push manually when ready: git push"
