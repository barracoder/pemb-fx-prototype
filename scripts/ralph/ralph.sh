#!/bin/bash
set -e

# ── Exit codes ────────────────────────────────────────────────────
# 0 = all stories done
# 1 = max iterations reached
# 2 = build failed
# 3 = config error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
MAX_ITERATIONS="${RALPH_MAX_ITERATIONS:-10}"
SHUTTING_DOWN=0

# ── Signal handling ───────────────────────────────────────────────

cleanup() {
  SHUTTING_DOWN=1
  echo ""
  echo '{"event": "shutdown", "signal": "'"$1"'", "message": "Graceful shutdown requested"}'

  BRANCH_NAME=$(jq -r '.branchName' "$PRD_FILE" 2>/dev/null || echo "unknown")

  # Commit any staged or unstaged work
  if git -C "$REPO_ROOT" diff --quiet 2>/dev/null && git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
    echo '{"event": "shutdown", "message": "No uncommitted changes"}'
  else
    echo '{"event": "shutdown", "message": "Committing in-progress work..."}'
    git -C "$REPO_ROOT" add -A
    git -C "$REPO_ROOT" commit -m "wip: Ralph interrupted — saving in-progress work" --no-verify 2>/dev/null || true
  fi

  # Push if possible
  push_if_docker

  echo '{"event": "shutdown", "message": "Shutdown complete"}'
  exit 0
}

trap 'cleanup SIGTERM' SIGTERM
trap 'cleanup SIGINT' SIGINT

# ── Pre-flight checks ──────────────────────────────────────────────

if ! command -v claude &> /dev/null; then
  echo '{"error": "claude CLI not found"}'
  exit 3
fi

if ! command -v jq &> /dev/null; then
  echo '{"error": "jq not found"}'
  exit 3
fi

if [ ! -f "$PRD_FILE" ]; then
  echo '{"error": "No prd.json found at '"$PRD_FILE"'"}'
  exit 3
fi

echo "── Pre-flight: dotnet build ──"
if ! dotnet build "$REPO_ROOT/Pemberton.Shareclass.Hedging.Prototype/Pemberton.Shareclass.Hedging.Prototype.sln" --nologo -v q; then
  echo '{"error": "Build failed", "exit_code": 2}'
  exit 2
fi
echo "── Build passed ──"

# ── Push helper (Docker only) ────────────────────────────────────────

push_if_docker() {
  if [ "${RALPH_DOCKER:-}" = "1" ] && [ -n "${GITHUB_TOKEN:-}" ] && [ "${RALPH_NO_PUSH:-}" != "1" ]; then
    echo ""
    echo "── Pushing $BRANCH_NAME to origin ──"
    git push origin "$BRANCH_NAME" 2>/dev/null || echo '{"event": "push", "status": "failed"}'
    echo "── Push complete ──"
  fi
}

# ── Archive previous run if branch changed ──────────────────────────

BRANCH_NAME=$(jq -r '.branchName' "$PRD_FILE")

if [ -f "$LAST_BRANCH_FILE" ]; then
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE")
  if [ "$LAST_BRANCH" != "$BRANCH_NAME" ]; then
    ARCHIVE_DIR="$SCRIPT_DIR/archive/$(date +%Y-%m-%d)-$LAST_BRANCH"
    echo "Branch changed from $LAST_BRANCH to $BRANCH_NAME — archiving previous run."
    mkdir -p "$ARCHIVE_DIR"
    cp "$PRD_FILE" "$ARCHIVE_DIR/prd.json" 2>/dev/null || true
    cp "$PROGRESS_FILE" "$ARCHIVE_DIR/progress.txt" 2>/dev/null || true
  fi
fi

echo "$BRANCH_NAME" > "$LAST_BRANCH_FILE"

# ── Initialise progress.txt if missing ──────────────────────────────

if [ ! -f "$PROGRESS_FILE" ]; then
  cat > "$PROGRESS_FILE" << 'EOF'
# Ralph Progress Log
## Codebase Patterns
<!-- Reusable patterns discovered across iterations — update this section, don't append -->

---
<!-- Iteration logs below — always append, never replace -->
EOF
fi

# ── Main loop ───────────────────────────────────────────────────────

TOTAL=$(jq '.userStories | length' "$PRD_FILE")

echo ""
echo "═══════════════════════════════════════════"
echo "  Ralph — Autonomous Agent Loop"
echo "  PRD: $(jq -r '.project' "$PRD_FILE")"
echo "  Branch: $BRANCH_NAME"
echo "  Max iterations: $MAX_ITERATIONS"
echo "═══════════════════════════════════════════"
echo ""

for i in $(seq 1 $MAX_ITERATIONS); do
  [ "$SHUTTING_DOWN" -eq 1 ] && break

  REMAINING=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE")
  DONE=$((TOTAL - REMAINING))

  # Find the current story being worked on
  CURRENT_STORY=$(jq -r '[.userStories[] | select(.passes == false)][0].id // "none"' "$PRD_FILE")

  echo "── Iteration $i of $MAX_ITERATIONS  ($DONE/$TOTAL stories complete) ──"

  # Structured JSON progress line
  echo "{\"iteration\": $i, \"story\": \"$CURRENT_STORY\", \"status\": \"starting\", \"total\": $TOTAL, \"done\": $DONE}"

  OUTPUT=$(claude --dangerously-skip-permissions --print --model claude-opus-4-6 < "$SCRIPT_DIR/prompt.md" 2>&1 | tee /dev/stderr) || true

  # Recount after iteration
  REMAINING=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE")
  DONE=$((TOTAL - REMAINING))

  echo "{\"iteration\": $i, \"story\": \"$CURRENT_STORY\", \"status\": \"complete\", \"total\": $TOTAL, \"done\": $DONE}"

  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo '{"event": "finished", "message": "All stories complete", "total": '"$TOTAL"', "done": '"$TOTAL"'}'
    echo "═══════════════════════════════════════════"
    echo "  Ralph completed all stories!"
    echo "═══════════════════════════════════════════"
    push_if_docker
    exit 0
  fi

  echo ""
  echo "── Iteration $i finished. Pausing before next iteration... ──"
  sleep 2
done

echo ""
echo '{"event": "max_iterations", "iterations": '"$MAX_ITERATIONS"', "total": '"$TOTAL"', "done": '"$DONE"'}'
echo "Reached max iterations ($MAX_ITERATIONS) without completing all stories."
echo "Run again with: ./ralph.sh"
push_if_docker
exit 1
