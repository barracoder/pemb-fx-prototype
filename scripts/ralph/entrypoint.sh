#!/bin/bash
set -euo pipefail

# ── Exit codes ────────────────────────────────────────────────────
# 0 = all stories done
# 1 = max iterations reached
# 2 = build failed
# 3 = config error

# ── Validate required environment ─────────────────────────────────

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo '{"error": "ANTHROPIC_API_KEY is not set"}'
  exit 3
fi

# ── Configure git for in-container commits ────────────────────────

git config --global user.name "${GIT_USER_NAME:-Ralph Agent}"
git config --global user.email "${GIT_USER_EMAIL:-ralph@pemberton.dev}"

# ── Repo acquisition: clone mode vs bind-mount mode ───────────────

if [ -n "${REPO_URL:-}" ]; then
  echo "Clone mode: cloning $REPO_URL ..."
  # Clone into a temp dir then move contents into /workspace
  git clone --single-branch "${REPO_URL}" /tmp/repo
  cp -a /tmp/repo/. /workspace/
  rm -rf /tmp/repo
  echo "Clone complete."
elif [ -d "/workspace/.git" ]; then
  echo "Bind-mount mode: using existing /workspace repo."
else
  echo '{"error": "/workspace is empty and REPO_URL not set — nothing to work on"}'
  exit 3
fi

# Mark /workspace as safe directory
git config --global --add safe.directory /workspace

# ── Configure remote with GitHub token if available ───────────────

if [ -n "${GITHUB_TOKEN:-}" ]; then
  REMOTE_URL=$(git -C /workspace remote get-url origin 2>/dev/null || true)
  if [ -n "$REMOTE_URL" ]; then
    NEW_URL=$(echo "$REMOTE_URL" | sed -E 's|https://([^@]*@)?github\.com/|https://x-access-token:'"$GITHUB_TOKEN"'@github.com/|')
    git -C /workspace remote set-url origin "$NEW_URL"
    echo "Git remote configured with GITHUB_TOKEN."
  fi
fi

# ── Locate prd.json ───────────────────────────────────────────────

PRD_FILE="/workspace/scripts/ralph/prd.json"

if [ ! -f "$PRD_FILE" ]; then
  echo '{"error": "prd.json not found at '"$PRD_FILE"'"}'
  exit 3
fi

# ── Checkout branch ───────────────────────────────────────────────

BRANCH_NAME="${REPO_BRANCH:-$(jq -r '.branchName' "$PRD_FILE")}"

if [ -z "$BRANCH_NAME" ] || [ "$BRANCH_NAME" = "null" ]; then
  echo '{"error": "branchName not set — provide REPO_BRANCH env or set branchName in prd.json"}'
  exit 3
fi

CURRENT_BRANCH=$(git -C /workspace branch --show-current 2>/dev/null || true)

if [ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]; then
  echo "Checking out branch: $BRANCH_NAME"
  git -C /workspace checkout "$BRANCH_NAME" 2>/dev/null || git -C /workspace checkout -b "$BRANCH_NAME"
fi

# ── Export Docker environment flag ────────────────────────────────

export RALPH_DOCKER=1

# ── Hand off to ralph.sh ──────────────────────────────────────────

RALPH_SCRIPT="/workspace/scripts/ralph/ralph.sh"
if [ ! -f "$RALPH_SCRIPT" ]; then
  echo '{"error": "ralph.sh not found at '"$RALPH_SCRIPT"'"}'
  exit 3
fi

chmod +x "$RALPH_SCRIPT"
echo "Starting Ralph agent loop..."
exec "$RALPH_SCRIPT"
