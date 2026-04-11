#!/bin/bash
# Prevents direct commits to the main branch.
REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/workflow.conf"

branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" = "$MAIN_BRANCH" ]; then
  echo "ERROR: Direct commits to $MAIN_BRANCH are forbidden."
  echo "Create an issue and work on a feature branch: issue/{issue-id}"
  exit 1
fi
