#!/usr/bin/env bats
# Tests for .githooks/pre-push.d/020-test-suite-gate.sh hook behavior

setup() {
  # Create a temporary directory for each test
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  git init --quiet
  
  # Create a mock workflow.conf with empty TEST_CMD
  cat > workflow.conf << 'EOF'
# workflow.conf — Project-specific workflow configuration
TEST_CMD=""
SRC_DIRS="src/ lib/"
TEST_DIRS="tests/ test/"
MAIN_BRANCH="main"
EOF

  # Create mock .githooks structure
  mkdir -p .githooks/lib .githooks/pre-push.d
  
  # Copy the real detect.sh helper
  cp /Users/matt/Documents/PounceTek/Developer/GitHub/mpfk/auto/.githooks/lib/detect.sh .githooks/lib/detect.sh
  
  # Create the updated pre-push hook that we want to implement
  cat > .githooks/pre-push.d/020-test-suite-gate.sh << 'EOF'
#!/bin/bash
# Runs the full test suite before allowing a push.
REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/workflow.conf"

# Source the shared detection helper
source "$REPO_ROOT/.githooks/lib/detect.sh"

branch=$(git rev-parse --abbrev-ref HEAD)
if ! echo "$branch" | grep -qE '^issue/'; then
  exit 0
fi

echo "Running test suite before push..."

# Call detect_test_cmd to auto-detect or use existing TEST_CMD
detect_test_cmd

# If no test command after detection, gracefully skip
if [ -z "${TEST_CMD:-}" ]; then
  echo "⚠️  No test command configured or detected. Skipping test suite."
  echo "Create package.json, pyproject.toml, go.mod, etc. or set TEST_CMD in workflow.conf"
  exit 0
fi

# Run the test command
if ! eval "$TEST_CMD" 2>&1; then
  echo ""
  echo "ERROR: Test suite failed. Fix failing tests before pushing."
  exit 1
fi
EOF
  chmod +x .githooks/pre-push.d/020-test-suite-gate.sh
  
  # Create a feature branch to trigger the hook
  git checkout -b issue/123 --quiet
}

teardown() {
  # Clean up test directory
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    cd /
    rm -rf "$TEST_DIR"
  fi
}

@test "pre-push hook: TEST_CMD empty, no project markers → graceful skip, exit 0" {
  # No project files, TEST_CMD empty - should skip gracefully
  
  run ./.githooks/pre-push.d/020-test-suite-gate.sh
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Running test suite before push..."* ]]
  [[ "$output" == *"No test command configured or detected. Skipping test suite."* ]]
}

@test "pre-push hook: TEST_CMD empty, package.json present → test command runs" {
  # Create package.json with a successful test command
  echo '{"scripts":{"test":"echo \"All tests passed\""}}' > package.json
  
  run ./.githooks/pre-push.d/020-test-suite-gate.sh
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Running test suite before push..."* ]]
  [[ "$output" == *"Detected test command: npm test"* ]]
  [[ "$output" == *"All tests passed"* ]]
}

@test "pre-push hook: TEST_CMD set manually in workflow.conf → test command runs directly" {
  # Set TEST_CMD manually in workflow.conf
  sed -i '' 's/TEST_CMD=""/TEST_CMD="echo Manual test passed"/' workflow.conf
  
  run ./.githooks/pre-push.d/020-test-suite-gate.sh
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"Running test suite before push..."* ]]
  [[ "$output" == *"TEST_CMD already set to: echo Manual test passed"* ]]
  [[ "$output" == *"Manual test passed"* ]]
}

@test "pre-push hook: test suite fails → hook exits 1" {
  # Create package.json with a failing test command
  echo '{"scripts":{"test":"echo \"Test failed\"; exit 1"}}' > package.json
  
  run ./.githooks/pre-push.d/020-test-suite-gate.sh
  
  [ "$status" -eq 1 ]
  [[ "$output" == *"Running test suite before push..."* ]]
  [[ "$output" == *"Test failed"* ]]
  [[ "$output" == *"ERROR: Test suite failed. Fix failing tests before pushing."* ]]
}