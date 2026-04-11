#!/usr/bin/env bats
# Tests for detect_test_cmd() function in .githooks/lib/detect.sh

load '/Users/matt/Documents/PounceTek/Developer/GitHub/mpfk/auto/.githooks/lib/detect.sh' 2>/dev/null || {
  echo "⚠️ .githooks/lib/detect.sh not found - this is expected during RED phase" >&2
  exit 1
}

setup() {
  # Create a temporary directory for each test
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  
  # Create a mock workflow.conf
  cat > workflow.conf << 'EOF'
# workflow.conf — Project-specific workflow configuration
TEST_CMD="npm test"
SRC_DIRS="src/ lib/"
TEST_DIRS="tests/ test/"
MAIN_BRANCH="main"
EOF
  
  # Unset TEST_CMD to start fresh
  unset TEST_CMD
}

teardown() {
  # Clean up test directory
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    cd /
    rm -rf "$TEST_DIR"
  fi
}

@test "detect_test_cmd() with package.json sets npm test and writes back to workflow.conf" {
  # Create package.json
  echo '{"name":"test","scripts":{"test":"echo test"}}' > package.json
  
  # Reset workflow.conf to empty TEST_CMD
  sed -i '' 's/TEST_CMD=.*/TEST_CMD=""/' workflow.conf
  
  # Run detection (direct call to persist exports)
  detect_test_cmd
  
  [ "$TEST_CMD" = "npm test" ]
  
  # Check that workflow.conf was updated
  grep -q 'TEST_CMD="npm test"' workflow.conf
}

@test "detect_test_cmd() with pyproject.toml sets pytest and writes back" {
  # Create pyproject.toml
  echo '[project]' > pyproject.toml
  echo 'name = "test"' >> pyproject.toml
  
  # Reset workflow.conf to empty TEST_CMD
  sed -i '' 's/TEST_CMD=.*/TEST_CMD=""/' workflow.conf
  
  # Run detection (direct call to persist exports)
  detect_test_cmd
  
  [ "$TEST_CMD" = "pytest" ]
  
  # Check that workflow.conf was updated
  grep -q 'TEST_CMD="pytest"' workflow.conf
}

@test "detect_test_cmd() with go.mod sets go test ./... and writes back" {
  # Create go.mod
  echo 'module test' > go.mod
  echo 'go 1.19' >> go.mod
  
  # Reset workflow.conf to empty TEST_CMD
  sed -i '' 's/TEST_CMD=.*/TEST_CMD=""/' workflow.conf
  
  # Run detection (direct call to persist exports)
  detect_test_cmd
  
  [ "$TEST_CMD" = "go test ./..." ]
  
  # Check that workflow.conf was updated
  grep -q 'TEST_CMD="go test ./..."' workflow.conf
}

@test "detect_test_cmd() with multiple markers shows warning and does not set TEST_CMD" {
  # Create multiple project markers
  echo '{"name":"test"}' > package.json
  echo '[project]' > pyproject.toml
  
  # Reset workflow.conf to empty TEST_CMD
  sed -i '' 's/TEST_CMD=.*/TEST_CMD=""/' workflow.conf
  
  # Run detection
  run detect_test_cmd
  
  [ "$status" -eq 0 ]
  [ -z "$TEST_CMD" ]
  
  # Should contain warning about multiple markers
  [[ "$stderr" == *"Multiple project markers found"* ]]
  [[ "$stderr" == *"set TEST_CMD in workflow.conf"* ]]
  
  # workflow.conf should not be modified (still empty)
  grep -q 'TEST_CMD=""' workflow.conf
}

@test "detect_test_cmd() with no markers shows helpful message and does not set TEST_CMD" {
  # No project markers created
  
  # Reset workflow.conf to empty TEST_CMD  
  sed -i '' 's/TEST_CMD=.*/TEST_CMD=""/' workflow.conf
  
  # Run detection
  run detect_test_cmd
  
  [ "$status" -eq 0 ]
  [ -z "$TEST_CMD" ]
  
  # Should contain helpful message
  [[ "$stderr" == *"No project markers found"* ]]
  
  # workflow.conf should not be modified
  grep -q 'TEST_CMD=""' workflow.conf
}

@test "detect_test_cmd() with TEST_CMD already set does not override" {
  # Create package.json 
  echo '{"name":"test"}' > package.json
  
  # Set TEST_CMD in environment
  export TEST_CMD="custom test command"
  
  # Run detection
  run detect_test_cmd
  
  [ "$status" -eq 0 ]
  [ "$TEST_CMD" = "custom test command" ]
  
  # Should contain message about not overriding
  [[ "$output" == *"TEST_CMD already set"* ]]
  
  # workflow.conf should not be modified
  grep -q 'TEST_CMD="npm test"' workflow.conf
}