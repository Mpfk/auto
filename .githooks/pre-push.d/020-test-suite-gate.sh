#!/bin/bash
# Runs the full test suite before allowing a push.
REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/workflow.conf"

branch=$(git rev-parse --abbrev-ref HEAD)
if ! echo "$branch" | grep -qE '^issue/'; then
  exit 0
fi

echo "Running test suite before push..."
if ! eval "$TEST_CMD" 2>&1; then
  echo ""
  echo "ERROR: Test suite failed. Fix failing tests before pushing."
  exit 1
fi
