#!/usr/bin/env bash
# tests/test-framework-paths.sh
# Verifies .auto-framework-paths is correct and complete.
# Exits 0 on all-pass, non-zero on any failure.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ALLOW_LIST="$REPO_ROOT/.auto-framework-paths"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# ---------------------------------------------------------------------------
# 1. The file must exist
# ---------------------------------------------------------------------------
echo "--- Test: allow-list file exists ---"
if [[ ! -f "$ALLOW_LIST" ]]; then
  echo "  FAIL: .auto-framework-paths does not exist at repo root"
  FAIL=$((FAIL + 1))
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi
pass ".auto-framework-paths exists"

# ---------------------------------------------------------------------------
# 2. For every non-blank, non-comment entry, verify at least one match exists
# ---------------------------------------------------------------------------
echo ""
echo "--- Test: every listed path/glob resolves to at least one file ---"
while IFS= read -r line; do
  # Skip blank lines and comments
  [[ -z "$line" || "$line" == \#* ]] && continue

  # Entries annotated with "# (future)" or "# (added by" are not yet present
  # — skip existence check for them but still verify they are commented
  if [[ "$line" == *"# (future)"* || "$line" == *"# (added by"* ]]; then
    pass "future path skipped: $line"
    continue
  fi

  # Strip any inline comment for the actual path/glob
  path="${line%%#*}"
  path="${path%% }"   # trim trailing space

  # Use find to check for matches (handles globs and directories)
  if find "$REPO_ROOT" -path "$REPO_ROOT/$path" -maxdepth 6 2>/dev/null | grep -q .; then
    pass "exists: $path"
  else
    fail "no match found in repo for: $path"
  fi
done < "$ALLOW_LIST"

# ---------------------------------------------------------------------------
# 3. Banned paths must NOT appear in the file
# ---------------------------------------------------------------------------
echo ""
echo "--- Test: config/consumer paths absent from allow-list ---"

banned=(
  "workflow.conf"
  ".claude/settings.json"
  "src/"
  "tests/"
)

for banned_path in "${banned[@]}"; do
  # Look for any non-comment line that matches the banned path
  if grep -v '^#' "$ALLOW_LIST" | grep -qF "$banned_path"; then
    fail "banned path found in allow-list: $banned_path"
  else
    pass "absent (correct): $banned_path"
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
