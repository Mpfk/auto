#!/usr/bin/env bash
# Static assertions over the GitHub Actions workflow YAML for issue #81:
# Reduce Actions run fan-out from issue-automation triggers without weakening
# any core feature (status-guard invariant, Gate-1 comment command,
# CI->issue-status gate, branch protection).
#
# Exit 1 if any assertion fails, exit 0 if all pass.

set -u

# Resolve repo root relative to this script so the test runs from any cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WF="$ROOT/.github/workflows"

FAILED=0
pass() { echo "✅ $1"; }
fail() { echo "❌ $1"; FAILED=1; }

# --- 1. issue-state-guard: types no longer include 'edited', still labeled+unlabeled ---
GUARD="$WF/issue-state-guard.yml"
if [ ! -f "$GUARD" ]; then
  fail "issue-state-guard.yml missing"
else
  types_line="$(grep -E '^\s*types:' "$GUARD" | head -n1)"
  if echo "$types_line" | grep -q 'edited'; then
    fail "issue-state-guard.yml still lists 'edited' in types: ($types_line)"
  else
    pass "issue-state-guard.yml types: does not contain 'edited'"
  fi
  if echo "$types_line" | grep -q 'labeled' && echo "$types_line" | grep -q 'unlabeled'; then
    pass "issue-state-guard.yml types: still contains labeled and unlabeled"
  else
    fail "issue-state-guard.yml types: must still contain labeled and unlabeled ($types_line)"
  fi

  # --- 2. concurrency block with cancel-in-progress: true ---
  if grep -qE '^\s*concurrency:' "$GUARD"; then
    pass "issue-state-guard.yml has a concurrency: block"
  else
    fail "issue-state-guard.yml missing concurrency: block"
  fi
  if grep -qE 'cancel-in-progress:\s*true' "$GUARD"; then
    pass "issue-state-guard.yml has cancel-in-progress: true"
  else
    fail "issue-state-guard.yml missing cancel-in-progress: true"
  fi
fi

# --- 3. issue-native-automation: comment-commands gated on /auto prefix ---
NATIVE="$WF/issue-native-automation.yml"
if [ ! -f "$NATIVE" ]; then
  fail "issue-native-automation.yml missing"
elif grep -qF "startsWith(github.event.comment.body, '/auto ')" "$NATIVE"; then
  pass "issue-native-automation.yml comment-commands gated on '/auto ' prefix"
else
  fail "issue-native-automation.yml comment-commands missing startsWith('/auto ') guard"
fi

# --- 4. pr-checks.yml exists with jobs test:, check-commits:, policy: ---
PRC="$WF/pr-checks.yml"
REUSABLE_PRC="$WF/reusable-pr-checks.yml"
# The real CI logic lives in a reusable workflow (on: workflow_call) so consumer
# repos can reference it as `uses: Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1`
# and receive updates for free via the default GITHUB_TOKEN. pr-checks.yml is a
# thin caller that keeps the "PR Checks" status name (ci-issue-gate depends on it).
if [ ! -f "$REUSABLE_PRC" ]; then
  fail "reusable-pr-checks.yml missing (CI logic must live in a reusable workflow)"
else
  if grep -qE '^\s*workflow_call:' "$REUSABLE_PRC"; then
    pass "reusable-pr-checks.yml is reusable (on: workflow_call)"
  else
    fail "reusable-pr-checks.yml must declare 'on: workflow_call'"
  fi
  for job in test check-commits policy; do
    if grep -qE "^  ${job}:" "$REUSABLE_PRC"; then
      pass "reusable-pr-checks.yml defines job '${job}'"
    else
      fail "reusable-pr-checks.yml missing job '${job}'"
    fi
  done
fi
if [ ! -f "$PRC" ]; then
  fail "pr-checks.yml missing"
else
  if grep -qE 'uses:\s*\./\.github/workflows/reusable-pr-checks\.yml' "$PRC"; then
    pass "pr-checks.yml is a thin caller of reusable-pr-checks.yml"
  else
    fail "pr-checks.yml must call the reusable workflow (uses: ./.github/workflows/reusable-pr-checks.yml)"
  fi
  if grep -qE '^\s*name:\s*PR Checks' "$PRC"; then
    pass "pr-checks.yml keeps the 'PR Checks' status name"
  else
    fail "pr-checks.yml must keep 'name: PR Checks' so ci-issue-gate's workflow_run still matches"
  fi
fi

# --- 5. old workflow files removed ---
for old in test-suite.yml conventional-commits.yml workflow-policy.yml; do
  if [ -e "$WF/$old" ]; then
    fail "$old should be removed but still exists"
  else
    pass "$old removed"
  fi
done

# --- 6. ci-issue-gate references merged workflow, no dangling old names ---
GATE="$WF/ci-issue-gate.yml"
if [ ! -f "$GATE" ]; then
  fail "ci-issue-gate.yml missing"
else
  wf_line="$(grep -E '^\s*workflows:' "$GATE" | head -n1)"
  if echo "$wf_line" | grep -qF '"PR Checks"'; then
    pass "ci-issue-gate.yml references \"PR Checks\""
  else
    fail "ci-issue-gate.yml must reference \"PR Checks\" ($wf_line)"
  fi
  for old in '"Test Suite"' '"Conventional Commits Check"' '"Workflow Policy"'; do
    if echo "$wf_line" | grep -qF "$old"; then
      fail "ci-issue-gate.yml still references $old"
    else
      pass "ci-issue-gate.yml does not reference $old"
    fi
  done
fi

# --- 7. pr-issue-sync.yml: opened/reopened/synchronize sets status by PR draft state (#125) ---
# A draft PR maps to status/in-progress; a ready (non-draft) PR maps to status/review,
# keeping the sync workflow consistent with the policy job in pr-checks.yml which fails
# a ready PR whose linked issue is not status/review.
SYNC="$WF/pr-issue-sync.yml"
if [ ! -f "$SYNC" ]; then
  fail "pr-issue-sync.yml missing"
else
  if grep -qF "setStatus(pr.draft ? 'status/in-progress' : 'status/review')" "$SYNC"; then
    pass "pr-issue-sync.yml opened/reopened/synchronize honors pr.draft (in-progress vs review)"
  else
    fail "pr-issue-sync.yml must set status by pr.draft: draft->in-progress, ready->review"
  fi
  # The unconditional in-progress set must be gone.
  if grep -qE "setStatus\('status/in-progress'\);" "$SYNC"; then
    fail "pr-issue-sync.yml still unconditionally sets status/in-progress on open"
  else
    pass "pr-issue-sync.yml no longer unconditionally sets status/in-progress on open"
  fi
fi

# --- 8. setup-hooks bootstrap: worktree/clone hook activation (#127) ---
# Fresh worktrees inherit the shared .git/config, which previously held an
# absolute core.hooksPath pointing at the empty .git/hooks. A committed,
# idempotent bin/setup-hooks gives every worktree/clone a canonical activation
# command that sets the RELATIVE path (.githooks) so hooks resolve per-worktree.
SETUP_HOOKS="$ROOT/bin/setup-hooks"
if [ ! -f "$SETUP_HOOKS" ]; then
  fail "bin/setup-hooks missing (worktrees have no canonical hook activation)"
else
  pass "bin/setup-hooks exists"
  if [ -x "$SETUP_HOOKS" ]; then
    pass "bin/setup-hooks is executable"
  else
    fail "bin/setup-hooks must be executable"
  fi
  # Must set the RELATIVE path so it resolves correctly inside every worktree.
  if grep -qE 'core\.hooksPath[[:space:]]+\.githooks' "$SETUP_HOOKS"; then
    pass "bin/setup-hooks sets relative core.hooksPath .githooks"
  else
    fail "bin/setup-hooks must run: git config core.hooksPath .githooks"
  fi
fi

# --- 9. CLAUDE.md documents worktree hook activation via bin/setup-hooks (#127) ---
CLAUDEMD="$ROOT/CLAUDE.md"
if [ ! -f "$CLAUDEMD" ]; then
  fail "CLAUDE.md missing"
elif grep -qF "bin/setup-hooks" "$CLAUDEMD"; then
  pass "CLAUDE.md references bin/setup-hooks for worktree/clone activation"
else
  fail "CLAUDE.md must document bin/setup-hooks for worktree/clone hook activation"
fi

# --- 10. release-process.md documents the native @v1 tag-move release model (#141) ---
# Releasing moves the floating major tag (v1) so @v1 consumers of the reusable
# workflow receive the update for free — no sync engine, no cron, no token.
RELEASE_DOC="$ROOT/docs/auto/release-process.md"
if [ ! -f "$RELEASE_DOC" ]; then
  fail "docs/auto/release-process.md missing"
else
  if grep -qiE 'major tag|floating' "$RELEASE_DOC" && grep -qF '@v1' "$RELEASE_DOC"; then
    pass "release-process.md documents moving the major (@v1) tag so consumers receive updates"
  else
    fail "release-process.md must document moving the floating major tag (v1) so @v1 consumers receive the release"
  fi
fi

# --- 11. every workflow file is valid YAML; run: block scalars are never broken
#         by an under-indented continuation line (#135). The auto-sync.yml PR-body
#         was a multi-line double-quoted string inside a `run: |` block whose
#         continuation lines sat at column 0, terminating the block scalar and
#         making GitHub reject the whole workflow (0s "workflow file issue" run,
#         workflow_dispatch 422, schedule never firing). Guard the defect class:
#         (a) structural — no column-0, non-blank, non-comment line may appear
#             between a `run: |`/`run: >` block opener and the next dedented YAML
#             key in any workflow file; and
#         (b) semantic — if a YAML loader is available, every workflow file must
#             parse (skipped cleanly when no loader is present).
for wf_file in "$WF"/*.yml; do
  [ -e "$wf_file" ] || continue
  wf_name="$(basename "$wf_file")"

  # (a) Structural scan: find column-0 shell text inside run: block scalars.
  bad_line="$(awk '
    # Detect the start of a block-scalar run: step, capturing its indent.
    /^[[:space:]]*run:[[:space:]]*[|>]/ {
      in_block = 1
      match($0, /^[[:space:]]*/)
      block_indent = RLENGTH
      next
    }
    in_block {
      # Blank lines stay inside the block scalar.
      if ($0 ~ /^[[:space:]]*$/) next
      # A line indented MORE than the run: key is block content — OK.
      match($0, /^[[:space:]]*/)
      this_indent = RLENGTH
      if (this_indent > block_indent) next
      # A dedented line ends the block. If it sits at column 0 and is not a
      # comment, it is the smoking gun: shell text that escaped the scalar.
      if (this_indent == 0 && $0 !~ /^#/) {
        print NR ": " $0
      }
      in_block = 0
    }
  ' "$wf_file")"
  if [ -n "$bad_line" ]; then
    fail "$wf_name has column-0 line(s) inside a run: block scalar (broken continuation): $bad_line"
  else
    pass "$wf_name: no under-indented continuation inside run: block scalars"
  fi

  # (b) Semantic scan: load the YAML if a loader is available.
  if command -v ruby >/dev/null 2>&1; then
    if ruby -ryaml -e "YAML.load_file(ARGV[0])" "$wf_file" >/dev/null 2>&1; then
      pass "$wf_name: parses as valid YAML"
    else
      fail "$wf_name: is not valid YAML (GitHub will reject the workflow)"
    fi
  fi
done

# --- 12. Custom sync engine fully removed (#141) ---
# Distribution is now native-GitHub-only: "Use this template" for instantiation
# (snapshot) + reusable workflows referenced @v1 for CI updates. The bespoke
# token-based sync engine (bin/auto-sync, weekly auto-sync.yml cron,
# AUTO_SYNC_TOKEN PAT, .auto-framework-paths / .autosyncignore ownership
# contracts) must be gone entirely.
for gone in \
  "$ROOT/bin/auto-sync" \
  "$WF/auto-sync.yml" \
  "$ROOT/.auto-framework-paths" \
  "$ROOT/.autosyncignore" \
  "$ROOT/docs/auto/template-propagation.md"; do
  if [ -e "$gone" ]; then
    fail "sync-engine artefact should be removed but still exists: ${gone#$ROOT/}"
  else
    pass "removed: ${gone#$ROOT/}"
  fi
done

# --- 13. No AUTO_SYNC_TOKEN reference survives anywhere (#141) ---
# No token setup is the whole point — a consumer must never wire up a PAT.
# Build the needle by concatenation so this assertion does not match itself.
# Scope to git-tracked files (git grep) so stray local git worktrees under
# .claude/worktrees/ and other untracked/ignored paths can't trip the check —
# the contract is about what the repo SHIPS, not local scratch checkouts.
NEEDLE="AUTO_SYNC""_TOKEN"
HITS="$(git -C "$ROOT" grep -Il "$NEEDLE" -- \
    ':(exclude)tests/workflow-config.sh' \
    ':(exclude)CHANGELOG.md' 2>/dev/null | tr '\n' ' ')"
# CHANGELOG.md is an append-only historical record; it documents the token's
# removal (and its prior existence) and is intentionally exempt.
if [ -n "$HITS" ]; then
  fail "$NEEDLE still referenced outside the changelog (no live token setup may remain): $HITS"
else
  pass "no $NEEDLE reference in tracked files"
fi

# --- 14. bin/publish-template builds a correct consumer template snapshot (#143) ---
echo ""
echo "--- Running publish-template snapshot test ---"
if bash "$ROOT/tests/test-publish-template.sh"; then
  pass "publish-template builds a correct consumer-form snapshot"
else
  fail "publish-template snapshot test failed (see output above)"
fi

if [ "$FAILED" -ne 0 ]; then
  echo ""
  echo "Workflow config assertions FAILED."
  exit 1
fi
echo ""
echo "All workflow config assertions passed."
exit 0
