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

# Test 2: orchestrate.agent.md DOES contain Phase C implementation section
@test "orchestrate.agent.md: Phase C implementation section exists" {
  grep -q "Phase C: Implementation Handoff" "$ORCHESTRATE"
}

@test "orchestrate.agent.md: asks whether to assign Copilot develop agent" {
  grep -q "Would you like me to assign the Copilot 'develop' Agent to begin work" "$ORCHESTRATE"
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

# --- Issue #52: MCP tool name and fallback tests ---

ISSUE_AGENT="$REPO_ROOT/.github/agents/issue.agent.md"
STATE_GUARD="$REPO_ROOT/.github/workflows/issue-state-guard.yml"
ISSUE_NATIVE="$REPO_ROOT/.github/workflows/issue-native-automation.yml"
PR_SYNC="$REPO_ROOT/.github/workflows/pr-issue-sync.yml"
CI_GATE="$REPO_ROOT/.github/workflows/ci-issue-gate.yml"

# Test: issue.agent.md uses correct MCP tool names (no old names)
@test "issue.agent.md: no references to deprecated create_issue tool name" {
  run grep -w "create_issue" "$ISSUE_AGENT"
  [ "$status" -ne 0 ]
}

@test "issue.agent.md: no references to deprecated update_issue tool name" {
  run grep -w "update_issue" "$ISSUE_AGENT"
  [ "$status" -ne 0 ]
}

@test "issue.agent.md: no references to deprecated get_issue tool name" {
  run grep -w "get_issue" "$ISSUE_AGENT"
  [ "$status" -ne 0 ]
}

@test "issue.agent.md: references issue_write tool" {
  grep -q "issue_write" "$ISSUE_AGENT"
}

@test "issue.agent.md: references issue_read tool" {
  grep -q "issue_read" "$ISSUE_AGENT"
}

# Test: issue.agent.md sets intermediate labels
@test "issue.agent.md: sets status/researching label" {
  grep -q "status/researching" "$ISSUE_AGENT"
}

@test "issue.agent.md: sets status/planning label" {
  grep -q "status/planning" "$ISSUE_AGENT"
}

# Test: issue.agent.md has fallback section
@test "issue.agent.md: has fallback section for update failure" {
  grep -q "Fallback" "$ISSUE_AGENT"
}

@test "issue.agent.md: ready handoff references Copilot develop agent" {
  grep -q "Assign to Copilot 'develop' Agent to begin work" "$ISSUE_AGENT"
}

# Test: orchestrate.agent.md uses correct MCP tool names (no old names)
@test "orchestrate.agent.md: no references to deprecated create_issue tool name" {
  run grep -w "create_issue" "$ORCHESTRATE"
  [ "$status" -ne 0 ]
}

@test "orchestrate.agent.md: no references to deprecated update_issue tool name" {
  run grep -w "update_issue" "$ORCHESTRATE"
  [ "$status" -ne 0 ]
}

@test "orchestrate.agent.md: no references to deprecated get_issue tool name" {
  run grep -w "get_issue" "$ORCHESTRATE"
  [ "$status" -ne 0 ]
}

@test "orchestrate.agent.md: references issue_write tool" {
  grep -q "issue_write" "$ORCHESTRATE"
}

@test "orchestrate.agent.md: includes explicit Gate 1 decision wording" {
  grep -q "Gate 1: Approve this plan to move the issue to status/ready" "$ORCHESTRATE"
}

# Test: issue-state-guard.yml no longer auto-advances draft -> ready (3A)
@test "issue-state-guard.yml: does not auto-advance to status/ready" {
  run grep -q "Auto-advanced to status/ready" "$STATE_GUARD"
  [ "$status" -ne 0 ]
}

# Test: assignment path no longer auto-promotes to status/ready
@test "issue-native-automation.yml: copilot assignment does not auto-promote status/ready" {
  run grep -q "Plan is present but label wasn't updated — auto-promote" "$ISSUE_NATIVE"
  [ "$status" -ne 0 ]
}

# Test: /auto plan-approved is restricted to maintainers
@test "issue-native-automation.yml: plan approval checks maintainer association" {
  grep -q "author_association" "$ISSUE_NATIVE"
  grep -q "OWNER" "$ISSUE_NATIVE"
  grep -q "MEMBER" "$ISSUE_NATIVE"
}

# Test: /auto plan-approved validates source status
@test "issue-native-automation.yml: plan approval requires planning or researching status" {
  grep -q "status/planning" "$ISSUE_NATIVE"
  grep -q "status/researching" "$ISSUE_NATIVE"
}

# Test: PR sync no longer promotes status/review from ready_for_review or review_requested
@test "pr-issue-sync.yml: does not reference ready_for_review transitions" {
  run grep -q "ready_for_review" "$PR_SYNC"
  [ "$status" -ne 0 ]
}

@test "pr-issue-sync.yml: does not reference review_requested transitions" {
  run grep -q "review_requested" "$PR_SYNC"
  [ "$status" -ne 0 ]
}

# Test: CI-driven workflow exists and targets status/review on green checks
@test "ci-issue-gate.yml: exists and sets status/review" {
  grep -q "name: CI Issue Gate" "$CI_GATE"
  grep -q "status/review" "$CI_GATE"
}

@test "issue-native-automation.yml: ready comment mentions Copilot develop agent" {
  grep -q "Assign to Copilot 'develop' Agent to begin work" "$ISSUE_NATIVE"
}

@test "issue-native-automation.yml: plan approved comment includes next step" {
  grep -q "Gate 1 approved" "$ISSUE_NATIVE"
}

@test "ci-issue-gate.yml: review kickoff comment includes next-step instructions" {
  grep -q "Review kickoff" "$CI_GATE"
  grep -q "Invoke Copilot 'review' Agent" "$CI_GATE"
}

@test "pr-issue-sync.yml: merge completion comment includes gate closeout" {
  grep -q "Gate 2 complete" "$PR_SYNC"
}
