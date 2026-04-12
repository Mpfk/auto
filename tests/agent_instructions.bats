#!/usr/bin/env bats
# Content verification tests for agent instruction files (issue #48)

REPO_ROOT="/Users/matt/Documents/PounceTek/Developer/GitHub/mpfk/auto"
ORCHESTRATE="$REPO_ROOT/.github/agents/orchestrate.agent.md"
COPILOT_INSTRUCTIONS="$REPO_ROOT/.github/copilot-instructions.md"
DEVELOP="$REPO_ROOT/.github/agents/develop.agent.md"

# Test 1: orchestrate.agent.md does NOT contain branch creation in Phase A
@test "orchestrate.agent.md: Phase A does not create a feature branch" {
  # Phase A ends before Phase B; check that branch creation is not a numbered step in Phase A
  # Extract Phase A content (between "## Phase A" and "## Phase B")
  phase_a=$(awk '/^## Phase A/,/^## Phase B/' "$ORCHESTRATE")
  run echo "$phase_a"
  [[ "$output" != *"Create a feature branch"* ]]
}

# Test 2: orchestrate.agent.md DOES contain Phase C: Implementation Kickoff
@test "orchestrate.agent.md: Phase C: Implementation Kickoff section exists" {
  grep -q "Phase C: Implementation Kickoff" "$ORCHESTRATE"
}

# Test 3: copilot-instructions.md does NOT have "Create a feature branch" as step 3
@test "copilot-instructions.md: branch creation is not step 3 in step-by-step" {
  # Step 3 should NOT be "Create a feature branch"
  run grep -n "^3\. \*\*Create a feature branch" "$COPILOT_INSTRUCTIONS"
  [ "$status" -ne 0 ]
}

# Test 4: copilot-instructions.md DOES contain retrospective reference for CI failure
@test "copilot-instructions.md: CI failure re-invocation mentions retrospective" {
  grep -q "retrospective from the last develop agent run" "$COPILOT_INSTRUCTIONS"
}

# Test 5: develop.agent.md DOES contain Retrospective Logging section
@test "develop.agent.md: Retrospective Logging section exists" {
  grep -q "Retrospective Logging" "$DEVELOP"
}

# Test 6: develop.agent.md DOES contain add_issue_comment instruction
@test "develop.agent.md: add_issue_comment is referenced in retrospective instructions" {
  grep -q "add_issue_comment" "$DEVELOP"
}

# Test 7: develop.agent.md DOES contain list_issue_comments instruction
@test "develop.agent.md: list_issue_comments is referenced in retrospective instructions" {
  grep -q "list_issue_comments" "$DEVELOP"
}

# Test 8: copilot-instructions.md Phase 1 does NOT mention branch creation
@test "copilot-instructions.md: Phase 1 Init does not mention feature branch" {
  phase1=$(awk '/^### Phase 1: Init/,/^### Phase 2:/' "$COPILOT_INSTRUCTIONS")
  run echo "$phase1"
  [[ "$output" != *"feature branch"* ]]
}

# Test 9: copilot-instructions.md GitHub-Native Triggers item 6 includes retrospective
@test "copilot-instructions.md: GitHub-Native Triggers CI failure item mentions prior retrospective" {
  grep -q "prior retrospective as context" "$COPILOT_INSTRUCTIONS"
}
