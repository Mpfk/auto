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
if [ ! -f "$PRC" ]; then
  fail "pr-checks.yml missing"
else
  for job in test check-commits policy; do
    if grep -qE "^  ${job}:" "$PRC"; then
      pass "pr-checks.yml defines job '${job}'"
    else
      fail "pr-checks.yml missing job '${job}'"
    fi
  done
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

if [ "$FAILED" -ne 0 ]; then
  echo ""
  echo "Workflow config assertions FAILED."
  exit 1
fi
echo ""
echo "All workflow config assertions passed."
exit 0
