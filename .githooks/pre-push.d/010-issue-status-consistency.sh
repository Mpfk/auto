#!/bin/bash
# Verifies GitHub Issue exists and status is at least 'in-progress' before pushing.
branch=$(git rev-parse --abbrev-ref HEAD)
if ! echo "$branch" | grep -qE '^issue/'; then
  exit 0
fi

issue_number=$(echo "$branch" | sed 's|^issue/||')

# Check if gh CLI is available
if ! command -v gh &>/dev/null; then
  echo "WARNING: gh CLI not found — skipping issue status check."
  exit 0
fi

# Fetch issue labels
labels=$(gh issue view "$issue_number" --json labels --jq '.labels[].name' 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "ERROR: GitHub Issue #$issue_number not found."
  echo "Every branch must have a corresponding GitHub Issue."
  exit 1
fi

if echo "$labels" | grep -qE '^status/(in-progress|review|done)$'; then
  exit 0
elif echo "$labels" | grep -qE '^status/(draft|researching|planning|ready)$'; then
  status=$(echo "$labels" | grep -oE '^status/[a-z-]+$' | head -1)
  echo "ERROR: Issue #$issue_number is still in '$status'."
  echo "Work must reach 'status/in-progress' before pushing."
  exit 1
elif echo "$labels" | grep -q '^status/blocked$'; then
  echo "ERROR: Issue #$issue_number is blocked. Resolve the blocker before pushing."
  exit 1
else
  echo "WARNING: No status label found on Issue #$issue_number."
  exit 0
fi
