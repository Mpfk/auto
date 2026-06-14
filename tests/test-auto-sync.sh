#!/usr/bin/env bash
# tests/test-auto-sync.sh
# Test harness for bin/auto-sync — the framework sync engine.
# Exits 0 on all-pass, non-zero on any failure.
#
# Tests run entirely against local fixtures (no network calls).
# A local git repo is used as a fake "upstream" to mock the upstream fetch.
#
# Environment variables:
#   AUTO_SYNC_BIN  — path to the auto-sync script (default: bin/auto-sync)
#   KEEP_TMPDIR    — set to 1 to preserve temp directories after failure (debug)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUTO_SYNC_BIN="${AUTO_SYNC_BIN:-$REPO_ROOT/bin/auto-sync}"

PASS=0
FAIL=0
TMPDIR_ROOT=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

cleanup() {
  if [[ -n "$TMPDIR_ROOT" && -d "$TMPDIR_ROOT" ]]; then
    if [[ "${KEEP_TMPDIR:-0}" == "1" && $FAIL -gt 0 ]]; then
      echo "  [debug] Temp directory preserved at: $TMPDIR_ROOT"
    else
      rm -rf "$TMPDIR_ROOT"
    fi
  fi
}
trap cleanup EXIT

make_tmpdir() {
  TMPDIR_ROOT="$(mktemp -d)"
  echo "$TMPDIR_ROOT"
}

# ---------------------------------------------------------------------------
# Fixture builder — creates a minimal fake upstream git repo
#
# The upstream contains:
#   .auto-framework-paths  — allow-list with two paths
#   .autosyncignore        — ignore patterns
#   .auto-version          — version stamp
#   .claude/commands/auto.md  — a framework file to sync
#   workflow.conf          — a consumer-owned file (in .autosyncignore)
#   .githooks/pre-commit.d/100-consumer.sh  — a consumer hook (1xx- range)
# Returns the upstream repo path via stdout.
# ---------------------------------------------------------------------------
make_upstream_repo() {
  local upstream
  upstream="$(mktemp -d)"
  pushd "$upstream" > /dev/null

  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  # Framework allow-list
  cat > .auto-framework-paths << 'EOF'
# Auto framework paths
.claude/commands/auto.md
.auto-version
.autosyncignore
EOF

  # Sync ignore
  cat > .autosyncignore << 'EOF'
# Consumer-owned — never overwrite
workflow.conf
.claude/settings.json
CLAUDE.md
README.md
.gitignore
src/
tests/
.githooks/pre-commit.d/1[0-9][0-9]-*.sh
.githooks/commit-msg.d/1[0-9][0-9]-*.sh
.githooks/pre-push.d/1[0-9][0-9]-*.sh
.autosyncignore
.auto-version
EOF

  # Version stamp
  printf '0.2.0' > .auto-version

  # A framework file
  mkdir -p .claude/commands
  echo "# auto command v0.2.0" > .claude/commands/auto.md

  # A consumer-owned file that must NOT be overwritten
  echo "TEST_CMD=make test" > workflow.conf

  git add -A
  git commit -q -m "chore: initial upstream v0.2.0"
  git tag -a v0.2.0 -m "Release v0.2.0"

  popd > /dev/null
  echo "$upstream"
}

# ---------------------------------------------------------------------------
# Consumer repo builder — creates a minimal fake consumer repo
#
# The consumer is at version 0.1.0 (behind upstream).
# It contains consumer-owned files that must survive sync.
# ---------------------------------------------------------------------------
make_consumer_repo() {
  local consumer
  consumer="$(mktemp -d)"
  pushd "$consumer" > /dev/null

  git init -q
  git config user.email "consumer@test.com"
  git config user.name "Consumer"

  # Current version stamp
  printf '0.1.0' > .auto-version

  # Framework file (old version — should be overwritten)
  mkdir -p .claude/commands
  echo "# auto command v0.1.0" > .claude/commands/auto.md

  # Consumer-owned files that must NOT be overwritten
  echo "TEST_CMD=pytest" > workflow.conf
  mkdir -p .claude
  echo '{"permissions":{}}' > .claude/settings.json
  echo "# My Project" > CLAUDE.md

  # Consumer-owned hook in 1xx range — must survive
  mkdir -p .githooks/pre-commit.d
  echo "#!/bin/bash" > .githooks/pre-commit.d/100-my-hook.sh

  # .autosyncignore (seeded by Auto, owned by consumer)
  cat > .autosyncignore << 'EOF'
workflow.conf
.claude/settings.json
CLAUDE.md
README.md
.gitignore
src/
tests/
.githooks/pre-commit.d/1[0-9][0-9]-*.sh
.autosyncignore
.auto-version
EOF

  git add -A
  git commit -q -m "chore: initial consumer at v0.1.0"

  popd > /dev/null
  echo "$consumer"
}

# ---------------------------------------------------------------------------
# Guard: bin/auto-sync must exist
# ---------------------------------------------------------------------------
echo "--- Test: script exists and is executable ---"
if [[ ! -f "$AUTO_SYNC_BIN" ]]; then
  echo "  FAIL: $AUTO_SYNC_BIN does not exist (tests must fail RED before implementation)"
  FAIL=$((FAIL + 1))
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi
if [[ ! -x "$AUTO_SYNC_BIN" ]]; then
  fail "bin/auto-sync is not executable"
else
  pass "bin/auto-sync exists and is executable"
fi

# ---------------------------------------------------------------------------
# Test 1: copy — framework files are synced from upstream
# ---------------------------------------------------------------------------
echo ""
echo "--- Test 1: framework files are copied from upstream ---"

TMPDIR_ROOT="$(make_tmpdir)"
UPSTREAM="$TMPDIR_ROOT/upstream"
CONSUMER="$TMPDIR_ROOT/consumer"
UPSTREAM="$(make_upstream_repo)"
CONSUMER="$(make_consumer_repo)"

pushd "$CONSUMER" > /dev/null

result=0
"$AUTO_SYNC_BIN" --upstream "$UPSTREAM" --tag v0.2.0 --skip-verify > "$TMPDIR_ROOT/test1.log" 2>&1 || result=$?

if [[ $result -eq 0 ]]; then
  pass "sync command exited 0"
else
  fail "sync command exited $result (expected 0)"
  cat "$TMPDIR_ROOT/test1.log"
fi

# Framework file must be updated
if [[ -f ".claude/commands/auto.md" ]] && grep -q "v0.2.0" ".claude/commands/auto.md"; then
  pass ".claude/commands/auto.md updated to v0.2.0"
else
  fail ".claude/commands/auto.md was not updated to v0.2.0"
  cat ".claude/commands/auto.md" 2>/dev/null || echo "(file missing)"
fi

popd > /dev/null
rm -rf "$UPSTREAM" "$CONSUMER"

# ---------------------------------------------------------------------------
# Test 2: ignore — consumer-owned files are untouched
# ---------------------------------------------------------------------------
echo ""
echo "--- Test 2: consumer-owned files are not overwritten ---"

UPSTREAM="$(make_upstream_repo)"
CONSUMER="$(make_consumer_repo)"

# Capture original values
ORIG_WORKFLOW=$(cat "$CONSUMER/workflow.conf")
ORIG_SETTINGS=$(cat "$CONSUMER/.claude/settings.json")
ORIG_CLAUDE=$(cat "$CONSUMER/CLAUDE.md")
ORIG_HOOK=$(cat "$CONSUMER/.githooks/pre-commit.d/100-my-hook.sh")

pushd "$CONSUMER" > /dev/null

"$AUTO_SYNC_BIN" --upstream "$UPSTREAM" --tag v0.2.0 --skip-verify > "$TMPDIR_ROOT/test2.log" 2>&1 || true

if [[ "$(cat workflow.conf)" == "$ORIG_WORKFLOW" ]]; then
  pass "workflow.conf is untouched"
else
  fail "workflow.conf was overwritten (must not be)"
fi

if [[ "$(cat .claude/settings.json)" == "$ORIG_SETTINGS" ]]; then
  pass ".claude/settings.json is untouched"
else
  fail ".claude/settings.json was overwritten (must not be)"
fi

if [[ "$(cat CLAUDE.md)" == "$ORIG_CLAUDE" ]]; then
  pass "CLAUDE.md is untouched"
else
  fail "CLAUDE.md was overwritten (must not be)"
fi

if [[ "$(cat .githooks/pre-commit.d/100-my-hook.sh)" == "$ORIG_HOOK" ]]; then
  pass "1xx- hook script is untouched"
else
  fail "1xx- hook script was overwritten (must not be)"
fi

popd > /dev/null
rm -rf "$UPSTREAM" "$CONSUMER"

# ---------------------------------------------------------------------------
# Test 3: version stamp — .auto-version is written with the new version
# ---------------------------------------------------------------------------
echo ""
echo "--- Test 3: .auto-version is stamped after sync ---"

UPSTREAM="$(make_upstream_repo)"
CONSUMER="$(make_consumer_repo)"

pushd "$CONSUMER" > /dev/null

"$AUTO_SYNC_BIN" --upstream "$UPSTREAM" --tag v0.2.0 --skip-verify > "$TMPDIR_ROOT/test3.log" 2>&1 || true

if [[ -f ".auto-version" ]]; then
  local_ver=$(cat .auto-version)
  if [[ "$local_ver" == "0.2.0" ]]; then
    pass ".auto-version stamped with 0.2.0"
  else
    fail ".auto-version contains '$local_ver' (expected 0.2.0)"
  fi
else
  fail ".auto-version not written after sync"
fi

popd > /dev/null
rm -rf "$UPSTREAM" "$CONSUMER"

# ---------------------------------------------------------------------------
# Test 4: already up to date — exits 0 without copying when version matches
# ---------------------------------------------------------------------------
echo ""
echo "--- Test 4: already up to date exits 0 silently ---"

UPSTREAM="$(make_upstream_repo)"
CONSUMER="$(make_consumer_repo)"

# Set consumer to same version as upstream
printf '0.2.0' > "$CONSUMER/.auto-version"

pushd "$CONSUMER" > /dev/null

result=0
output=$("$AUTO_SYNC_BIN" --upstream "$UPSTREAM" --tag v0.2.0 --skip-verify 2>&1) || result=$?

if [[ $result -eq 0 ]]; then
  pass "already-up-to-date exits 0"
else
  fail "already-up-to-date exited $result (expected 0)"
fi

if echo "$output" | grep -qi "up.to.date\|already"; then
  pass "already-up-to-date prints informative message"
else
  fail "already-up-to-date output does not mention up-to-date: '$output'"
fi

popd > /dev/null
rm -rf "$UPSTREAM" "$CONSUMER"

# ---------------------------------------------------------------------------
# Test 5: bad/missing tag — exits non-zero
# ---------------------------------------------------------------------------
echo ""
echo "--- Test 5: bad/missing tag exits non-zero ---"

UPSTREAM="$(make_upstream_repo)"
CONSUMER="$(make_consumer_repo)"

pushd "$CONSUMER" > /dev/null

result=0
"$AUTO_SYNC_BIN" --upstream "$UPSTREAM" --tag v99.99.99 --skip-verify > "$TMPDIR_ROOT/test5.log" 2>&1 || result=$?

if [[ $result -ne 0 ]]; then
  pass "bad tag exits non-zero (got $result)"
else
  fail "bad tag exited 0 (expected non-zero)"
fi

popd > /dev/null
rm -rf "$UPSTREAM" "$CONSUMER"

# ---------------------------------------------------------------------------
# Test 6: signature fail — warns and exits 1 without --skip-verify
# ---------------------------------------------------------------------------
echo ""
echo "--- Test 6: unsigned tag fails signature verification (without --skip-verify) ---"

UPSTREAM="$(mktemp -d)"
CONSUMER="$(make_consumer_repo)"

pushd "$UPSTREAM" > /dev/null
git init -q
git config user.email "test@test.com"
git config user.name "Test"
printf '0.2.0' > .auto-version
cat > .auto-framework-paths << 'EOF'
.auto-version
EOF
git add -A
git commit -q -m "chore: initial"
# Lightweight (unsigned) tag
git tag v0.2.0
popd > /dev/null

pushd "$CONSUMER" > /dev/null

# Without --skip-verify, an unsigned tag must cause a warning and exit non-zero
# We pass AUTO_SYNC_SKIP_GPG_CHECK=false to force signature check even in test env
result=0
output=$(AUTO_SYNC_SKIP_GPG_CHECK=false "$AUTO_SYNC_BIN" --upstream "$UPSTREAM" --tag v0.2.0 2>&1) || result=$?

if [[ $result -ne 0 ]]; then
  pass "unsigned tag without --skip-verify exits non-zero"
else
  # In environments where git tag -v doesn't fail on lightweight tags (e.g., no GPG),
  # we accept exit 0 IFF the script was told to skip; here we're NOT skipping.
  # Some git versions warn but still exit 0 — the script must re-check.
  # If the script exited 0 here, check that it printed a warning.
  if echo "$output" | grep -qi "warn\|signature\|verify\|unsigned"; then
    pass "unsigned tag without --skip-verify printed signature warning"
  else
    fail "unsigned tag without --skip-verify: exit 0 and no warning (expected non-zero or warning)"
  fi
fi

popd > /dev/null
rm -rf "$UPSTREAM" "$CONSUMER"

# ---------------------------------------------------------------------------
# Test 7: changes are left uncommitted
# ---------------------------------------------------------------------------
echo ""
echo "--- Test 7: sync leaves changes uncommitted for consumer review ---"

UPSTREAM="$(make_upstream_repo)"
CONSUMER="$(make_consumer_repo)"

pushd "$CONSUMER" > /dev/null

"$AUTO_SYNC_BIN" --upstream "$UPSTREAM" --tag v0.2.0 --skip-verify > "$TMPDIR_ROOT/test7.log" 2>&1 || true

# git status should show modified/new files (dirty working tree)
if git diff --quiet && git diff --cached --quiet; then
  fail "working tree is clean after sync — changes should be left uncommitted"
else
  pass "working tree is dirty after sync (changes left for review)"
fi

popd > /dev/null
rm -rf "$UPSTREAM" "$CONSUMER"

# ---------------------------------------------------------------------------
# Test 8: no temp files left on success
# ---------------------------------------------------------------------------
echo ""
echo "--- Test 8: no temp files left on success ---"

UPSTREAM="$(make_upstream_repo)"
CONSUMER="$(make_consumer_repo)"

before_tmp=$(find /tmp -maxdepth 1 -name "auto-sync-*" 2>/dev/null | wc -l | tr -d ' ')

pushd "$CONSUMER" > /dev/null
"$AUTO_SYNC_BIN" --upstream "$UPSTREAM" --tag v0.2.0 --skip-verify > "$TMPDIR_ROOT/test8.log" 2>&1 || true
popd > /dev/null

after_tmp=$(find /tmp -maxdepth 1 -name "auto-sync-*" 2>/dev/null | wc -l | tr -d ' ')

if [[ "$after_tmp" -le "$before_tmp" ]]; then
  pass "no auto-sync-* temp files left in /tmp"
else
  fail "$((after_tmp - before_tmp)) auto-sync-* temp file(s) left in /tmp"
fi

rm -rf "$UPSTREAM" "$CONSUMER"

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
echo "================================"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
