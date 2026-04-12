#!/usr/bin/env bats

REPO_ROOT="/Users/matt/Documents/PounceTek/Developer/GitHub/mpfk/auto"
LABEL_SYNC="$REPO_ROOT/.github/workflows/labels-sync.yml"
REPO_SETUP="$REPO_ROOT/.github/workflows/repo-setup.yml"

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
