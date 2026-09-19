#!/bin/bash
# Prevents documentation files from being created in wrong locations.
# Allowed: docs/, root policy/readme/changelog files, and provider adapters.
bad_docs=$(git diff --cached --name-only --diff-filter=A \
  | grep '\.md$' \
  | grep -v '^docs/' \
  | grep -v '^README.md$' \
  | grep -v '^CLAUDE.md$' \
  | grep -v '^AGENTS.md$' \
  | grep -v '^CHANGELOG.md$' \
  | grep -v '^\.github/' \
  | grep -v '^\.claude/' \
  | grep -v '^\.agents/')
if [ -n "$bad_docs" ]; then
  echo "ERROR: Documentation files must be placed in docs/"
  echo "Found in wrong location: $bad_docs"
  exit 1
fi
