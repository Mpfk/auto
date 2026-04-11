#!/bin/bash
# Prevents documentation files from being created in wrong locations.
# Allowed: docs/, README.md (root), .github/
bad_docs=$(git diff --cached --name-only --diff-filter=A \
  | grep '\.md$' \
  | grep -v '^docs/' \
  | grep -v '^README.md$' \
  | grep -v '^\.github/')
if [ -n "$bad_docs" ]; then
  echo "ERROR: Documentation files must be placed in docs/"
  echo "Found in wrong location: $bad_docs"
  exit 1
fi
