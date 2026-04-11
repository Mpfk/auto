#!/bin/bash
# Enforces TDD: source-only commits require prior test commits on the branch.
REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/workflow.conf"

branch=$(git rev-parse --abbrev-ref HEAD)
# Only enforce on issue branches
if ! echo "$branch" | grep -qE '^issue/'; then
  exit 0
fi

# Build grep pattern from SRC_DIRS
src_pattern=$(echo "$SRC_DIRS" | tr ' ' '\n' | sed 's|/$||' | paste -sd'|' -)
test_pattern=$(echo "$TEST_DIRS" | tr ' ' '\n' | sed 's|/$||' | paste -sd'|' -)

# Check if this commit includes source changes
staged_src=$(git diff --cached --name-only | grep -E "^($src_pattern)/")
if [ -z "$staged_src" ]; then
  exit 0  # No source changes, nothing to enforce
fi

# Check if this commit also includes test changes (GREEN/REFACTOR phase)
staged_tests=$(git diff --cached --name-only | grep -E "^($test_pattern)/")
if [ -n "$staged_tests" ]; then
  exit 0  # Tests and source together is fine
fi

# Source-only commit: verify that test commits already exist on this branch
# Handle fresh repo where main has no commits yet
if git rev-parse "$MAIN_BRANCH" >/dev/null 2>&1; then
  test_commits=$(git log "$MAIN_BRANCH"..HEAD --oneline -- $TEST_DIRS)
else
  test_commits=$(git log --oneline -- $TEST_DIRS)
fi

if [ -z "$test_commits" ]; then
  echo "ERROR: TDD violation — no test commits found on this branch."
  echo "You must commit failing tests (RED phase) before implementation (GREEN phase)."
  echo "Staged source files: $staged_src"
  exit 1
fi
