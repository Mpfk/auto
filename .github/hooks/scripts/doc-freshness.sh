#!/bin/bash
# PostToolUse hook: reminds about docs when source files are modified.
# Receives JSON on stdin with tool use details.
# Returns JSON with systemMessage if action needed.

INPUT=$(cat)
# Extract file path from tool result if available
FILE=$(echo "$INPUT" | grep -o '"path":"[^"]*"' | head -1 | sed 's/"path":"//;s/"//')

if [ -z "$FILE" ]; then
  exit 0
fi

case "$FILE" in
  src/*|lib/*|tests/*|test/*)
    echo '{"systemMessage": "A source file was modified. Check: are there corresponding test files that should be updated? Are there docs/ files that should be refreshed?"}'
    ;;
  *.md)
    case "$FILE" in
      docs/*|README.md|.github/*) ;;
      *) echo "{\"systemMessage\": \"WARNING: Documentation files must be placed in docs/, not $FILE\"}" ;;
    esac
    ;;
esac
