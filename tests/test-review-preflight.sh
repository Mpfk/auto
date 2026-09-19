#!/usr/bin/env bash
# Exercise deterministic review preflight success and failure paths.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFLIGHT="$ROOT/bin/auto-review-preflight"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q -b main
git -C "$REPO" config user.name "Auto Test"
git -C "$REPO" config user.email "auto@example.invalid"

mkdir -p "$REPO/src" "$REPO/tests"
printf '%s\n' 'TEST_CMD="bash tests/pass.sh"' 'SRC_DIRS="src/ lib/"' 'TEST_DIRS="tests/ test/"' 'MAIN_BRANCH="main"' > "$REPO/workflow.conf"
printf '%s\n' '# Auto fixture' > "$REPO/README.md"
git -C "$REPO" add .
git -C "$REPO" commit -q -m "chore: initialize fixture"

git -C "$REPO" switch -q -c issue/1
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$REPO/tests/pass.sh"
chmod +x "$REPO/tests/pass.sh"
git -C "$REPO" add tests/pass.sh
git -C "$REPO" commit -q -m "test(core): add behavior coverage"
printf '%s\n' 'implemented=true' > "$REPO/src/feature.sh"
git -C "$REPO" add src/feature.sh
git -C "$REPO" commit -q -m "feat(core): implement behavior"
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

if [[ ! -x "$PREFLIGHT" ]]; then
  fail "bin/auto-review-preflight is missing or not executable"
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi

run_ok() {
  local label="$1"; shift
  if (cd "$REPO" && "$PREFLIGHT" "$@") >"$TMP/out" 2>"$TMP/err"; then
    pass "$label"
  else
    fail "$label: $(tr '\n' ' ' < "$TMP/err")"
  fi
}

run_fail() {
  local label="$1" needle="$2"; shift 2
  if (cd "$REPO" && "$PREFLIGHT" "$@") >"$TMP/out" 2>"$TMP/err"; then
    fail "$label unexpectedly passed"
  elif grep -qiF "$needle" "$TMP/out" "$TMP/err"; then
    pass "$label"
  else
    fail "$label did not mention '$needle'"
  fi
}

run_ok "valid current-head review passes" \
  --base main --head HEAD --expected-head "$HEAD_SHA" --ci-status success --provider codex-native --native-status completed
grep -qF 'Provider: `codex-native`' "$TMP/out" && pass "native provider is recorded" || fail "native provider is not recorded"
grep -qF "Reviewed head SHA: \`$HEAD_SHA\`" "$TMP/out" && pass "reviewed head is recorded" || fail "reviewed head is not recorded"

run_fail "stale head fails" "stale" \
  --base main --expected-head 0000000000000000000000000000000000000000 --ci-status success
run_fail "failed CI fails" "CI" \
  --base main --expected-head "$HEAD_SHA" --ci-status failure

printf '%s\n' 'P1|open|https://example.invalid/finding/1' > "$TMP/findings"
run_fail "unresolved P1 finding fails" "P1" \
  --base main --expected-head "$HEAD_SHA" --ci-status success --provider codex-native --native-status completed --findings-file "$TMP/findings"

run_ok "native timeout with completed local fallback passes" \
  --base main --expected-head "$HEAD_SHA" --ci-status success --provider codex-native --native-status timeout --local-review-pass
grep -qF 'Provider: `codex-local`' "$TMP/out" && pass "fallback is normalized to codex-local" || fail "fallback provider was not normalized"

git -C "$REPO" switch -q main
git -C "$REPO" switch -q -c issue/2
mkdir -p "$REPO/src"
printf '%s\n' 'untested=true' > "$REPO/src/untested.sh"
git -C "$REPO" add src/untested.sh
git -C "$REPO" commit -q -m "feat(core): add untested behavior"
UNT_HEAD="$(git -C "$REPO" rev-parse HEAD)"
run_fail "TDD ordering violation fails" "TDD" \
  --base main --expected-head "$UNT_HEAD" --ci-status success

# Reviewing a ref that is not checked out must not run the current worktree's
# workflow.conf and tests while certifying another SHA.
git -C "$REPO" switch -q main
git -C "$REPO" switch -q -c issue/not-checked-out
mkdir -p "$REPO/src"
printf '%s\n' 'broken=true' > "$REPO/src/broken.sh"
git -C "$REPO" add src/broken.sh
git -C "$REPO" commit -q -m "feat(core): add broken behavior"
OTHER_HEAD="$(git -C "$REPO" rev-parse HEAD)"
git -C "$REPO" switch -q main
run_fail "non-checked-out reviewed ref fails" "worktree" \
  --base main --head issue/not-checked-out --expected-head "$OTHER_HEAD" --ci-status success

# Project-specific source and test roots must drive TDD ordering checks.
mkdir -p "$REPO/app" "$REPO/spec"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$REPO/spec/pass.sh"
chmod +x "$REPO/spec/pass.sh"
printf '%s\n' 'TEST_CMD="bash spec/pass.sh"' 'SRC_DIRS="app/"' 'TEST_DIRS="spec/"' 'MAIN_BRANCH="main"' > "$REPO/workflow.conf"
git -C "$REPO" add workflow.conf spec/pass.sh
git -C "$REPO" commit -q -m "chore: configure custom project roots"

git -C "$REPO" switch -q -c issue/custom-roots
printf '%s\n' 'untested=true' > "$REPO/app/untested.sh"
git -C "$REPO" add app/untested.sh
git -C "$REPO" commit -q -m "feat(core): add untested custom-root behavior"
CUSTOM_HEAD="$(git -C "$REPO" rev-parse HEAD)"
run_fail "configured source directories enforce TDD" "TDD" \
  --base main --expected-head "$CUSTOM_HEAD" --ci-status success

# A test and its implementation in one commit is not Red-Green ordering.
git -C "$REPO" switch -q main
git -C "$REPO" switch -q -c issue/combined-red-green
mkdir -p "$REPO/app" "$REPO/spec"
printf '%s\n' '# combined test' > "$REPO/spec/combined.sh"
printf '%s\n' 'implemented=true' > "$REPO/app/combined.sh"
git -C "$REPO" add spec/combined.sh app/combined.sh
git -C "$REPO" commit -q -m "feat(core): combine test and implementation"
COMBINED_HEAD="$(git -C "$REPO" rev-parse HEAD)"
run_fail "combined test and source commit fails TDD" "TDD" \
  --base main --expected-head "$COMBINED_HEAD" --ci-status success

printf '%s\n' '# misplaced' > "$REPO/NOTES.md"
git -C "$REPO" add NOTES.md
git -C "$REPO" commit -q -m "docs: add misplaced notes"
DOC_HEAD="$(git -C "$REPO" rev-parse HEAD)"
run_fail "misplaced documentation fails" "documentation" \
  --base main --expected-head "$DOC_HEAD" --ci-status success

git -C "$REPO" commit --allow-empty -q -m "not conventional"
BAD_HEAD="$(git -C "$REPO" rev-parse HEAD)"
run_fail "non-conventional commit fails" "Conventional" \
  --base main --expected-head "$BAD_HEAD" --ci-status success

sed -i.bak 's#^TEST_CMD=.*#TEST_CMD="false"#' "$REPO/workflow.conf"
rm -f "$REPO/workflow.conf.bak"
run_fail "failed configured tests fail" "test suite" \
  --base main --expected-head "$BAD_HEAD" --ci-status success

echo
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
