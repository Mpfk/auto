#!/usr/bin/env bats

REPO_ROOT="/Users/matt/Documents/PounceTek/Developer/GitHub/mpfk/auto"
LABEL_SYNC="$REPO_ROOT/.github/workflows/labels-sync.yml"
REPO_SETUP="$REPO_ROOT/.github/workflows/repo-setup.yml"
PR_SYNC="$REPO_ROOT/.github/workflows/pr-issue-sync.yml"
CI_GATE="$REPO_ROOT/.github/workflows/ci-issue-gate.yml"

@test "labels-sync.yml: manual-only trigger prevents bootstrap overlap" {
  run grep -q '^  push:' "$LABEL_SYNC"
  [ "$status" -ne 0 ]
}

@test "labels-sync.yml: workflow_dispatch remains available for intentional reruns" {
  grep -q '^  workflow_dispatch:' "$LABEL_SYNC"
}

@test "repo-setup.yml: owns automatic setup on pushes to main" {
  grep -q '^  push:' "$REPO_SETUP"
  grep -q '^    branches: \[main\]' "$REPO_SETUP"
}

@test "pr-issue-sync.yml: no direct status/review promotion on PR lifecycle" {
  run grep -q "status/review" "$PR_SYNC"
  [ "$status" -ne 0 ]
}

@test "ci-issue-gate.yml: workflow_run trigger listens to CI workflows" {
  grep -q '^  workflow_run:' "$CI_GATE"
  grep -q 'Test Suite' "$CI_GATE"
  grep -q 'Conventional Commits Check' "$CI_GATE"
  grep -q 'Workflow Policy' "$CI_GATE"
}
