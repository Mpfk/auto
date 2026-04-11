#!/bin/bash
# Auto-appends GitHub Issue reference to commits on issue branches if not already present.
branch=$(git rev-parse --abbrev-ref HEAD)
if echo "$branch" | grep -qE '^issue/'; then
  issue_number=$(echo "$branch" | sed 's|^issue/||')
  commit_body=$(cat "$1")
  if ! echo "$commit_body" | grep -qF "#$issue_number"; then
    echo "" >> "$1"
    echo "Closes #$issue_number" >> "$1"
  fi
fi
