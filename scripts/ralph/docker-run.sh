#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Source .env if present ───────────────────────────────────────────

if [ -f "$REPO_ROOT/.env" ]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

IMAGE_NAME="ralph-base:latest"
PRD_PATH=""
REPO_URL=""
MAX_ITERATIONS=""
NO_PUSH=""
REBUILD_BASE=""

# ── Usage ────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run the Ralph autonomous agent in a Docker container.

Modes:
  Local (default)   Bind-mounts the current repo into the container.
  Clone (--repo-url) Clones a remote repo inside the container (SaaS path).

Options:
  --prd <path>            Path to PRD json file (default: scripts/ralph/prd.json)
  --repo-url <url>        Clone this repo instead of mounting local (SaaS mode)
  --max-iterations <n>    Maximum Ralph iterations (default: 10)
  --no-push               Do not push results branch on completion
  --rebuild-base          Force rebuild of the base image before running
  --help                  Show this help message

Environment variables:
  ANTHROPIC_API_KEY     (required) API key for Claude
  GITHUB_TOKEN          (optional) GitHub token for pushing results

Examples:
  # Local mode — bind-mount repo, run with defaults
  ./scripts/ralph/docker-run.sh

  # Local mode — custom PRD, limited iterations
  ./scripts/ralph/docker-run.sh --prd scripts/ralph/tasks/my-feature.json --max-iterations 5

  # Clone mode — validates SaaS execution path
  ./scripts/ralph/docker-run.sh --repo-url https://github.com/org/repo.git --no-push

  # Rebuild base image (after bumping SDK/Node/Claude versions)
  ./scripts/ralph/docker-run.sh --rebuild-base
EOF
  exit 0
}

# ── Parse arguments ──────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prd)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --prd requires a file path"
        exit 1
      fi
      PRD_PATH="$2"
      shift 2
      ;;
    --repo-url)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --repo-url requires a URL"
        exit 1
      fi
      REPO_URL="$2"
      shift 2
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations requires a numeric argument"
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --no-push)
      NO_PUSH="1"
      shift
      ;;
    --rebuild-base)
      REBUILD_BASE="1"
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Error: Unknown option '$1'"
      echo "Run with --help for usage information."
      exit 1
      ;;
  esac
done

# ── Validate environment ────────────────────────────────────────────

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "Error: ANTHROPIC_API_KEY is not set."
  echo "Export it before running: export ANTHROPIC_API_KEY=sk-..."
  exit 1
fi

# ── Resolve PRD path ────────────────────────────────────────────────

if [ -z "$PRD_PATH" ]; then
  PRD_PATH="$SCRIPT_DIR/prd.json"
fi

# Make absolute if relative
if [[ "$PRD_PATH" != /* ]]; then
  PRD_PATH="$(cd "$(dirname "$PRD_PATH")" && pwd)/$(basename "$PRD_PATH")"
fi

if [ ! -f "$PRD_PATH" ]; then
  echo "Error: PRD file not found at $PRD_PATH"
  exit 1
fi

BRANCH_NAME=$(jq -r '.branchName' "$PRD_PATH")
PROJECT_NAME=$(jq -r '.project' "$PRD_PATH")

# ── Build base image if needed ──────────────────────────────────────

if [ -n "$REBUILD_BASE" ] || ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
  echo "Building base image: $IMAGE_NAME ..."
  "$SCRIPT_DIR/build-base.sh"
  echo ""
fi

# ── Banner ───────────────────────────────────────────────────────────

MODE="local (bind-mount)"
if [ -n "$REPO_URL" ]; then
  MODE="clone ($REPO_URL)"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  Ralph Docker Runner"
echo "  Project: $PROJECT_NAME"
echo "  Branch:  $BRANCH_NAME"
echo "  Mode:    $MODE"
echo "═══════════════════════════════════════════"
echo ""

# ── Assemble docker run arguments ────────────────────────────────────

DOCKER_ARGS=(
  run --rm
  --name ralph-runner
  -e "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
)

if [ -n "${GITHUB_TOKEN:-}" ]; then
  DOCKER_ARGS+=(-e "GITHUB_TOKEN=$GITHUB_TOKEN")
fi

if [ -n "$NO_PUSH" ]; then
  DOCKER_ARGS+=(-e "RALPH_NO_PUSH=1")
fi

if [ -n "$MAX_ITERATIONS" ]; then
  DOCKER_ARGS+=(-e "RALPH_MAX_ITERATIONS=$MAX_ITERATIONS")
fi

if [ -n "$REPO_URL" ]; then
  # Clone mode: pass repo URL, mount prd.json into the expected location
  DOCKER_ARGS+=(-e "REPO_URL=$REPO_URL")
  DOCKER_ARGS+=(-v "$PRD_PATH:/workspace/scripts/ralph/prd.json:ro")
else
  # Local mode: bind-mount the entire repo
  DOCKER_ARGS+=(-v "$REPO_ROOT:/workspace")
fi

# Mount progress.txt for crash recovery (both modes)
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
touch "$PROGRESS_FILE"
DOCKER_ARGS+=(-v "$PROGRESS_FILE:/workspace/scripts/ralph/progress.txt")

DOCKER_ARGS+=("$IMAGE_NAME")

# ── Run container ────────────────────────────────────────────────────

echo "Starting Ralph container..."
echo ""

EXIT_CODE=0
docker "${DOCKER_ARGS[@]}" || EXIT_CODE=$?

# ── Summary banner ───────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════"
case "$EXIT_CODE" in
  0) echo "  Ralph finished successfully (all stories done)" ;;
  1) echo "  Ralph reached max iterations" ;;
  2) echo "  Ralph exited: build failed" ;;
  3) echo "  Ralph exited: configuration error" ;;
  *) echo "  Ralph exited with code $EXIT_CODE" ;;
esac
echo "  Branch:  $BRANCH_NAME"
echo "  Mode:    $MODE"

# Show stories completed from prd.json
if [ -f "$PRD_PATH" ]; then
  TOTAL=$(jq '.userStories | length' "$PRD_PATH")
  DONE=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_PATH")
  echo "  Stories: $DONE/$TOTAL complete"
fi

echo "═══════════════════════════════════════════"
echo ""

exit $EXIT_CODE
