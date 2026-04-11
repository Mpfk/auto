#!/bin/bash
# Runs the full test suite before allowing a push.
REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/workflow.conf"

# Source the shared detection helper
source "$REPO_ROOT/.githooks/lib/detect.sh"

branch=$(git rev-parse --abbrev-ref HEAD)
if ! echo "$branch" | grep -qE '^issue/'; then
  exit 0
fi

echo "Running test suite before push..."

# Call detect_test_cmd to auto-detect or use existing TEST_CMD
detect_test_cmd

# If no test command after detection, gracefully skip
if [ -z "${TEST_CMD:-}" ]; then
  echo "⚠️  No test command configured or detected. Skipping test suite."
  echo "Create package.json, pyproject.toml, go.mod, etc. or set TEST_CMD in workflow.conf"
  exit 0
fi

# Run the test command
if ! eval "$TEST_CMD" 2>&1; then
  echo ""
  echo "ERROR: Test suite failed. Fix failing tests before pushing."
  exit 1
fi
