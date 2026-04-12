#!/usr/bin/env bats
# Content verification tests for docs/auto/agent-flow.md (issue #48)

AGENT_FLOW="docs/auto/agent-flow.md"

@test "flowchart does not contain '+ branch' in the GitHub Issue node" {
  run grep -n "create GitHub Issue + branch" "$AGENT_FLOW"
  [ "$status" -ne 0 ]
}

@test "Phase Coordination table Init row does not contain '+ branch'" {
  run grep -n "Creates GitHub Issue + branch" "$AGENT_FLOW"
  [ "$status" -ne 0 ]
}

@test "Phase Coordination table Implement row contains 'Creates feature branch'" {
  run grep -n "Creates feature branch" "$AGENT_FLOW"
  [ "$status" -eq 0 ]
}

@test "CI failure row contains 'prior retrospective'" {
  run grep -n "prior retrospective" "$AGENT_FLOW"
  [ "$status" -eq 0 ]
}

@test "Transition Rules in-progress to review contains 'CI checks are green on the PR'" {
  run grep -n "CI checks are green on the PR" "$AGENT_FLOW"
  [ "$status" -eq 0 ]
}

@test "Orchestrate agent description does not mention feature branch in status/draft context" {
  run grep -n "status/draft.*feature branch\|feature branch.*status/draft\|and feature branch" "$AGENT_FLOW"
  [ "$status" -ne 0 ]
}
