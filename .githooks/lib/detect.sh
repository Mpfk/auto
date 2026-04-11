#!/bin/bash
# detect.sh - Shared test command detection helper
# Sources by .githooks/ scripts and CI to auto-detect test commands

detect_test_cmd() {
  local repo_root="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  
  # If TEST_CMD already set, don't override
  if [ -n "${TEST_CMD:-}" ]; then
    echo "TEST_CMD already set to: $TEST_CMD"
    return 0
  fi
  
  # Count project markers to detect conflicts
  local markers=()
  local detected_cmd=""
  
  # Check for project markers in priority order
  if [ -f "$repo_root/package.json" ]; then
    markers+=("package.json")
    detected_cmd="npm test"
  fi
  
  if [ -f "$repo_root/pyproject.toml" ] || [ -f "$repo_root/setup.py" ]; then
    if [ -f "$repo_root/pyproject.toml" ]; then
      markers+=("pyproject.toml")
    else
      markers+=("setup.py")
    fi
    detected_cmd="pytest"
  fi
  
  if [ -f "$repo_root/Cargo.toml" ]; then
    markers+=("Cargo.toml")
    detected_cmd="cargo test"
  fi
  
  if [ -f "$repo_root/go.mod" ]; then
    markers+=("go.mod")
    detected_cmd="go test ./..."
  fi
  
  if [ -f "$repo_root/pom.xml" ]; then
    markers+=("pom.xml")
    detected_cmd="mvn test"
  fi
  
  if [ -f "$repo_root/build.gradle" ] || [ -f "$repo_root/build.gradle.kts" ]; then
    if [ -f "$repo_root/build.gradle" ]; then
      markers+=("build.gradle")
    else
      markers+=("build.gradle.kts")
    fi
    detected_cmd="gradle test"
  fi
  
  # Handle multiple markers
  if [ ${#markers[@]} -gt 1 ]; then
    echo "⚠ Multiple project markers found — set TEST_CMD in workflow.conf" >&2
    echo "Found: ${markers[*]}" >&2
    return 0
  fi
  
  # Handle no markers
  if [ ${#markers[@]} -eq 0 ]; then
    echo "No project markers found. Create package.json, pyproject.toml, go.mod, etc. or set TEST_CMD in workflow.conf" >&2
    return 0
  fi
  
  # Single marker found - set TEST_CMD and write back
  export TEST_CMD="$detected_cmd"
  echo "Detected test command: $TEST_CMD (from ${markers[0]})"
  
  # Write back to workflow.conf
  if [ -f "$repo_root/workflow.conf" ]; then
    # Use sed to replace the TEST_CMD line
    if sed -i '' "s|^TEST_CMD=.*|TEST_CMD=\"$detected_cmd\"|" "$repo_root/workflow.conf" 2>/dev/null; then
      echo "Updated workflow.conf with detected test command"
    else
      # Fallback for non-BSD sed
      sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$detected_cmd\"|" "$repo_root/workflow.conf" 2>/dev/null || {
        echo "Warning: Could not update workflow.conf" >&2
      }
    fi
  fi
  
  return 0
}