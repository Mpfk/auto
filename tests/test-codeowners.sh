#!/usr/bin/env bash
# tests/test-codeowners.sh — verify .github/CODEOWNERS exists and is valid
# RED: fails until .github/CODEOWNERS is created.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CODEOWNERS="$REPO_ROOT/.github/CODEOWNERS"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; ((PASS++)) || true; }
fail() { echo "FAIL: $1"; ((FAIL++)) || true; }

# ── 1. File exists ────────────────────────────────────────────────────────────
if [[ -f "$CODEOWNERS" ]]; then
  pass "CODEOWNERS file exists at .github/CODEOWNERS"
else
  fail "CODEOWNERS file missing at .github/CODEOWNERS"
fi

# ── 2. .github/ pattern with at least one owner ───────────────────────────────
if grep -qE '^/\.github/\s+@\S+' "$CODEOWNERS" 2>/dev/null; then
  pass ".github/ pattern present with at least one owner"
else
  fail ".github/ pattern missing or has no owner"
fi

# ── 3. .githooks/ pattern with at least one owner ────────────────────────────
if grep -qE '^/\.githooks/\s+@\S+' "$CODEOWNERS" 2>/dev/null; then
  pass ".githooks/ pattern present with at least one owner"
else
  fail ".githooks/ pattern missing or has no owner"
fi

# ── 4. Basic syntax check: every non-blank, non-comment line is pattern + owner
SYNTAX_OK=true
while IFS= read -r line; do
  # Skip blank lines and comment lines
  [[ -z "$line" || "$line" == \#* ]] && continue
  # Must have at least two fields: pattern and one @owner or email
  fields=($line)
  if [[ ${#fields[@]} -lt 2 ]]; then
    fail "Syntax error — line has no owner: '$line'"
    SYNTAX_OK=false
  fi
done < "$CODEOWNERS" 2>/dev/null || true

if $SYNTAX_OK; then
  pass "CODEOWNERS syntax valid (every rule has pattern + owner)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
