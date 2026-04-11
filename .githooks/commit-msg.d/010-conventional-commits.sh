#!/bin/bash
# Rejects commit messages that don't follow Conventional Commits format.
commit_msg=$(head -1 "$1")
if ! echo "$commit_msg" | grep -qE '^(feat|fix|test|refactor|docs|chore)(\(.+\))?: .+'; then
  echo "ERROR: Commit message must follow Conventional Commits format."
  echo "  Format: type(scope): description"
  echo "  Types: feat, fix, test, refactor, docs, chore"
  echo "  Got: $commit_msg"
  exit 1
fi
