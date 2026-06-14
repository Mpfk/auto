#!/usr/bin/env bash
# tests/test-autosyncignore.sh
# Verifies .autosyncignore exists, has correct content, and does not
# accidentally list framework-owned paths from .auto-framework-paths.
# Exits 0 on all-pass, non-zero on any failure.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IGNORE_FILE="$REPO_ROOT/.autosyncignore"
ALLOW_LIST="$REPO_ROOT/.auto-framework-paths"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# ---------------------------------------------------------------------------
# 1. The file must exist
# ---------------------------------------------------------------------------
echo "--- Test: .autosyncignore exists ---"
if [[ ! -f "$IGNORE_FILE" ]]; then
  echo "  FAIL: .autosyncignore does not exist at repo root"
  FAIL=$((FAIL + 1))
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi
pass ".autosyncignore exists"

# ---------------------------------------------------------------------------
# 2. Required consumer-config entries must be present
# ---------------------------------------------------------------------------
echo ""
echo "--- Test: required consumer-config entries present ---"

required_entries=(
  "workflow.conf"
  ".claude/settings.json"
  "CLAUDE.md"
  "README.md"
  ".gitignore"
)

for entry in "${required_entries[@]}"; do
  if grep -qF "$entry" "$IGNORE_FILE"; then
    pass "entry present: $entry"
  else
    fail "entry missing: $entry"
  fi
done

# ---------------------------------------------------------------------------
# 3. Consumer source and test directories must be present
# ---------------------------------------------------------------------------
echo ""
echo "--- Test: consumer src/ and tests/ directories present ---"

for dir in "src/" "tests/"; do
  if grep -qF "$dir" "$IGNORE_FILE"; then
    pass "entry present: $dir"
  else
    fail "entry missing: $dir"
  fi
done

# ---------------------------------------------------------------------------
# 4. Consumer hook extension pattern (100-range) must be present
# ---------------------------------------------------------------------------
echo ""
echo "--- Test: consumer hook extension patterns present ---"

# Look for the 1[0-9][0-9]-*.sh pattern in one or more hook subdirectories
hook_pattern_found=0
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  stripped="${line%%#*}"
  stripped="${stripped%% }"
  # Match any line that references the 100-range hook glob
  if [[ "$stripped" == *"1[0-9][0-9]-*.sh"* || "$stripped" == *"1[[:digit:]][[:digit:]]-*.sh"* ]]; then
    hook_pattern_found=1
    break
  fi
done < "$IGNORE_FILE"

if [[ $hook_pattern_found -eq 1 ]]; then
  pass "consumer hook extension pattern found (1[0-9][0-9]-*.sh)"
else
  fail "consumer hook extension pattern missing — expected 1[0-9][0-9]-*.sh in .githooks/**/"
fi

# Check all three dispatcher dirs are covered
for hook_dir in "pre-commit.d" "commit-msg.d" "pre-push.d"; do
  if grep -qF "$hook_dir" "$IGNORE_FILE"; then
    pass "hook dir covered: .githooks/$hook_dir/"
  else
    fail "hook dir not covered: .githooks/$hook_dir/ — add a 1[0-9][0-9]-*.sh pattern"
  fi
done

# ---------------------------------------------------------------------------
# 5. The ignore file itself must be listed (so sync never overwrites it)
# ---------------------------------------------------------------------------
echo ""
echo "--- Test: .autosyncignore lists itself ---"
if grep -qF ".autosyncignore" "$IGNORE_FILE"; then
  pass ".autosyncignore lists itself"
else
  fail ".autosyncignore does not list itself — sync would overwrite it"
fi

# ---------------------------------------------------------------------------
# 6. Framework paths from .auto-framework-paths must NOT appear in the ignore
#    file (no accidental overlap — framework paths must be overwritten by sync)
# ---------------------------------------------------------------------------
echo ""
echo "--- Test: no framework paths accidentally appear in ignore file ---"

if [[ ! -f "$ALLOW_LIST" ]]; then
  fail ".auto-framework-paths not found — cannot check for overlap"
else
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    # Skip future/annotated entries
    [[ "$line" == *"# (future)"* || "$line" == *"# (added by"* ]] && continue

    # Strip inline comment
    path="${line%%#*}"
    path="${path%% }"

    # Skip .autosyncignore itself — it's listed in both files by design
    # (.auto-framework-paths marks it as framework-owned; the ignore file lists
    # itself so the sync engine knows not to re-seed it once it exists.
    # The sync engine handles this special case explicitly.)
    [[ "$path" == ".autosyncignore" ]] && continue

    # Use exact-line matching (anchored) so that e.g. ".githooks/pre-commit"
    # does not false-positive match ".githooks/pre-commit.d/..." lines.
    if grep -qxF "$path" "$IGNORE_FILE"; then
      fail "framework path found in ignore file (overlap!): $path"
    else
      pass "no overlap: $path"
    fi
  done < "$ALLOW_LIST"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
