#!/usr/bin/env bash
# Verify the checked-in Codex interface and shared provider contracts.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

expect_file() {
  if [[ -f "$ROOT/$1" ]]; then pass "$1 exists"; else fail "$1 is missing"; fi
}

expect_contains() {
  local file="$1" text="$2" label="$3"
  if grep -qF "$text" "$ROOT/$file" 2>/dev/null; then pass "$label"; else fail "$label"; fi
}

expect_file "AGENTS.md"
expect_contains "AGENTS.md" "## Code Review Rules" "AGENTS.md defines native review rules"
expect_contains "AGENTS.md" "docs/auto/playbooks/core.md" "AGENTS.md loads the shared core"

skills=(auto issue merge develop review document research)
SEEN_NAMES="$(mktemp)"
SEEN_DESCRIPTIONS="$(mktemp)"
trap 'rm -f "$SEEN_NAMES" "$SEEN_DESCRIPTIONS"' EXIT

for skill in "${skills[@]}"; do
  file=".agents/skills/$skill/SKILL.md"
  expect_file "$file"
  [[ -f "$ROOT/$file" ]] || continue

  name="$(sed -n 's/^name: *//p' "$ROOT/$file" | head -1 | tr -d '"')"
  description="$(sed -n 's/^description: *//p' "$ROOT/$file" | head -1 | tr -d '"')"
  if [[ "$name" == "$skill" ]]; then pass "$skill skill name is exact"; else fail "$skill skill name is '$name'"; fi
  if [[ -n "$description" ]]; then pass "$skill skill has a description"; else fail "$skill skill description is empty"; fi
  if grep -qxF "$name" "$SEEN_NAMES"; then fail "duplicate skill name: $name"; else printf '%s\n' "$name" >> "$SEEN_NAMES"; fi
  if grep -qxF "$description" "$SEEN_DESCRIPTIONS"; then fail "duplicate skill description: $description"; else printf '%s\n' "$description" >> "$SEEN_DESCRIPTIONS"; fi

  expect_contains "$file" "docs/auto/playbooks/core.md" "$skill skill references the shared core"
  expect_contains "$file" "docs/auto/playbooks/$skill.md" "$skill skill references its phase playbook"
done

playbooks=(core github auto issue merge develop review document research)
for playbook in "${playbooks[@]}"; do
  file="docs/auto/playbooks/$playbook.md"
  expect_file "$file"
  [[ -f "$ROOT/$file" ]] || continue
  for marker in "## Inputs" "## Outputs" "## State transitions" "## Stopping conditions" "## Gate authority"; do
    expect_contains "$file" "$marker" "$playbook playbook declares $marker"
  done
done

# Provider adapters must use the same shared contracts rather than copy them.
adapters=(
  CLAUDE.md
  .github/copilot-instructions.md
  .claude/commands/auto.md
  .claude/commands/issue.md
  .claude/commands/merge.md
  .claude/commands/develop.md
  .claude/commands/review.md
  .claude/commands/document.md
  .claude/commands/research.md
  .github/agents/orchestrate.agent.md
  .github/agents/issue.agent.md
  .github/agents/merge.agent.md
  .github/agents/develop.agent.md
  .github/agents/review.agent.md
  .github/agents/documentation.agent.md
  .github/agents/research.agent.md
)
for adapter in "${adapters[@]}"; do
  expect_contains "$adapter" "docs/auto/playbooks/" "$adapter loads a shared playbook"
done

expect_file ".github/codex/prompts/review.md"
expect_file ".github/codex/schemas/review-result.json"
expect_file "docs/auto/codex-setup.md"
expect_file "docs/auto/codex-github-action.md"
expect_file "bin/auto-review-preflight"

if find "$ROOT/.github/workflows" -maxdepth 1 -type f -iname '*codex*' | grep -q .; then
  fail "an active Codex workflow was shipped"
else
  pass "no active Codex workflow is shipped"
fi

if [[ "$(cat "$ROOT/.auto-version")" == "0.4.0" ]]; then
  pass ".auto-version is 0.4.0"
else
  fail ".auto-version is not 0.4.0"
fi

echo
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
