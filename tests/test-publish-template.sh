#!/usr/bin/env bash
# tests/test-publish-template.sh
# Exercises bin/publish-template: build the consumer-form template snapshot into
# a temp dir and assert the tree matches the native-distribution contract.
# Exit 0 on all-pass, non-zero on any failure.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLISH="$ROOT/bin/publish-template"

PASS=0
FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "--- Test: bin/publish-template builds a consumer-form snapshot ---"

if [[ ! -x "$PUBLISH" ]]; then
  echo "  FAIL: bin/publish-template missing or not executable"
  echo ""
  echo "Results: $PASS passed, $((FAIL + 1)) failed"
  exit 1
fi

OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

if ! "$PUBLISH" --out "$OUT/snap" >/dev/null 2>"$OUT/err"; then
  echo "  FAIL: 'publish-template --out' exited non-zero:"
  sed 's/^/    /' "$OUT/err"
  echo ""
  echo "Results: $PASS passed, $((FAIL + 1)) failed"
  exit 1
fi
SNAP="$OUT/snap"

# 1. Consumer-form pr-checks.yml references the upstream reusable workflow @v1.
PRC="$SNAP/.github/workflows/pr-checks.yml"
if [[ -f "$PRC" ]] && grep -qF 'uses: Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1' "$PRC"; then
  pass "pr-checks.yml references reusable-pr-checks.yml@v1 (remote ref)"
else
  fail "pr-checks.yml must reference Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1"
fi
if [[ -f "$PRC" ]] && grep -qE 'uses:\s*\./\.github/workflows/' "$PRC"; then
  fail "pr-checks.yml must NOT keep the local ./ ref (that breaks @v1 auto-updates)"
else
  pass "pr-checks.yml has no local ./ workflow ref"
fi

# 2. The reusable workflow is referenced upstream, never hosted in the template.
if [[ -e "$SNAP/.github/workflows/reusable-pr-checks.yml" ]]; then
  fail "template must NOT host reusable-pr-checks.yml (it is referenced @v1)"
else
  pass "reusable-pr-checks.yml is not hosted in the template"
fi

# 3. No sync-engine artefact may appear.
for gone in \
  "bin/auto-sync" \
  ".auto-framework-paths" \
  ".autosyncignore" \
  ".github/workflows/auto-sync.yml" \
  "docs/auto/template-propagation.md"; do
  if [[ -e "$SNAP/$gone" ]]; then
    fail "sync-engine artefact leaked into snapshot: $gone"
  else
    pass "absent from snapshot: $gone"
  fi
done

# 4. Maintainer-only tooling is excluded.
if [[ -e "$SNAP/bin/publish-template" ]]; then
  fail "bin/publish-template (maintainer tooling) must not ship in the template"
else
  pass "bin/publish-template excluded from snapshot"
fi

# 5. Consumer scaffolding placeholders exist; framework dev tests do not.
for keep in "bin/setup-hooks" "src/.gitkeep" "tests/.gitkeep" "workflow.conf" "CLAUDE.md"; do
  if [[ -e "$SNAP/$keep" ]]; then
    pass "present in snapshot: $keep"
  else
    fail "expected file missing from snapshot: $keep"
  fi
done
for devonly in "tests/workflow-config.sh" "tests/test-codeowners.sh" "tests/test-publish-template.sh" \
               "docs/auto/release-process.md" "docs/auto/pilot-results.md"; do
  if [[ -e "$SNAP/$devonly" ]]; then
    fail "dev-only file leaked into snapshot: $devonly"
  else
    pass "dev-only file excluded: $devonly"
  fi
done

# 6. No live sync-engine / token strings anywhere (CHANGELOG history exempt).
NEEDLES='auto-sync|AUTO_SYNC''_TOKEN|auto-framework-paths|autosyncignore'
if grep -rIlE "$NEEDLES" "$SNAP" --exclude="CHANGELOG.md" 2>/dev/null | grep -q .; then
  fail "live sync-engine/token strings present: $(grep -rIlE "$NEEDLES" "$SNAP" --exclude=CHANGELOG.md | sed "s#$SNAP/##" | tr '\n' ' ')"
else
  pass "no live sync-engine/token strings in snapshot (CHANGELOG exempt)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
