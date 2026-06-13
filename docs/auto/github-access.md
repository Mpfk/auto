# GitHub Access Modes — gh CLI and MCP Fallback

The Auto workflow commands (`.claude/commands/*.md`) describe GitHub operations
as `gh` CLI invocations. The `gh` CLI is **not available in every environment**
that runs these commands. In Claude Code **cloud/remote sessions** (claude.ai/code,
mobile, GitHub Action-triggered sessions), `gh` is not installed and GitHub access
is provided exclusively through the GitHub MCP server (`mcp__github__*` tools).

This document defines how every Auto command detects its environment and maps
each `gh` operation to its MCP equivalent.

## Detection Protocol (Step 0 of every command)

Run once at the start of a command:

```bash
command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && echo GH_CLI || echo MCP
```

- **`GH_CLI`** — execute the `gh` snippets in the command files literally.
- **`MCP`** — treat every `gh` snippet as a description of *intent* and execute
  the equivalent `mcp__github__*` tool from the mapping table below. All other
  instructions (git commands, state machine, gates, TDD rules) are unchanged.

Never report "gh is unavailable" as a blocker. The MCP path is a fully
supported first-class mode, not a degraded one.

## Operation Mapping

| `gh` invocation | MCP equivalent | Notes |
|---|---|---|
| `gh repo view --json nameWithOwner` | *(no API call needed)* `git remote get-url origin` and parse `owner/repo` | Works in both modes; prefer it everywhere |
| `gh issue view N --json title,body,labels` | `mcp__github__issue_read` (method `get`) | |
| `gh issue view N --json comments` | `mcp__github__issue_read` (method `get_comments`) | Filter for `## Retrospective — Iteration` in the results yourself |
| `gh issue list` | `mcp__github__list_issues` | |
| `gh issue list --search "..."` | `mcp__github__search_issues` | |
| `gh issue create` | `mcp__github__issue_write` (method `create`) | |
| `gh issue edit N --body "..."` | `mcp__github__issue_write` (method `update`, `body`) | |
| `gh issue edit N --add-label X --remove-label Y` | `mcp__github__issue_read` (method `get_labels`) **then** `mcp__github__issue_write` (method `update`, `labels`) | ⚠️ `labels` **replaces** the full set — read existing labels first and write the complete new set |
| `gh issue comment N --body "..."` | `mcp__github__add_issue_comment` | |
| `gh pr list --head BRANCH` | `mcp__github__list_pull_requests` | Filter by head branch |
| `gh pr create --draft ...` | `mcp__github__create_pull_request` (`draft: true`) | |
| `gh pr view N --json url` | `mcp__github__pull_request_read` (method `get`) | |
| `gh pr checks BRANCH` | `mcp__github__pull_request_read` (method `get_status`) | For failure details: `mcp__github__actions_list` / `mcp__github__get_job_logs` |
| `gh pr ready BRANCH` | `mcp__github__update_pull_request` (`draft: false`) | |
| `gh pr comment N --body "..."` | `mcp__github__add_issue_comment` (pass the PR number as `issue_number`) | |
| `gh pr merge N --merge --subject S --body B` | `mcp__github__merge_pull_request` (`merge_method: "merge"`, `commit_title`, `commit_message`) | |
| `gh pr view N --json state,mergedAt,mergeable,mergeStateStatus,isDraft` | `mcp__github__pull_request_read` (method `get`) | Used by `/merge` to verify mergeability and confirm the merge landed |
| `gh issue close N` | `mcp__github__issue_write` (method `update`, `state: "closed"`) | |
| `gh api repos/$REPO/git/refs/heads/BR` (existence check) | `mcp__github__list_branches` | |
| `gh api repos/$REPO/git/refs --method POST ...` (create branch) | `mcp__github__create_branch` (`from_branch: main`) | |
| `gh api repos/$REPO/issues/N/sub_issues` (list) | *(no MCP endpoint)* — read the parent body checklist (`- [ ] #child`) instead | See **Sub-issues** below |
| `gh api repos/$REPO/issues/PARENT/sub_issues --method POST -F sub_issue_id=ID` (link) | *(no MCP endpoint)* — write a child checklist into the parent body and a `Parent: #N` line into each child via `mcp__github__issue_write` (method `update`) | See **Sub-issues** below |

## Sub-issues

GitHub's native sub-issue REST API (`/repos/{owner}/{repo}/issues/{number}/sub_issues`)
is reachable in **GH_CLI mode** via `gh api`. Linking requires the child's numeric
database **id** (from `gh api repos/$REPO/issues/{child} --jq '.id'`), not its issue
number.

The GitHub MCP server exposes **no sub-issue endpoint**, so in **MCP mode** the Auto
commands fall back to a checklist-based linkage that automation and humans can both
read:

- The parent issue body carries a task list of children: `- [ ] #{child} — {task}`.
- Each child body carries a `Parent: #{parent}` reference line.

`/auto` reads whichever representation exists when fanning out per-child sub-agents
(Step 1.5 of `auto.md`).

## Interactive Approval UI (Claude Code only)

The `/issue` (Gate 1) and `/merge` (Gate 2) commands collect approval through the
Claude Code **AskUserQuestion** selection UI (Approve / Deny / Other) rather than
asking the user to type "approve". This is a Claude Code feature with **no Copilot
equivalent** — the Copilot agent definitions in `.github/agents/` keep the plain-text
"Gate N: Approve…?" prompt. `/auto` is fully autonomous and presents no gate UI in
either environment.

## Cloud-Session Constraints

Claude Code cloud sessions impose constraints beyond gh availability:

1. **Assigned push branch.** The session designates its own branch (e.g.
   `claude/...`) and pushes to other branch names may be denied. When the
   environment assigns and enforces a branch name, develop on that branch
   instead of `issue/{number}` and link the issue via `Closes #N` in the PR
   body. This is the sanctioned exception to the branch-naming rule in
   `CLAUDE.md` — never an excuse to skip the issue itself.
2. **Draft PRs.** Cloud sessions require PRs to be created as drafts, which
   matches the Auto workflow's existing rule (draft until Gate 2).
3. **Git push works natively.** The environment injects git credentials, so
   `git push` / `git fetch` work even though `gh auth` does not exist.

## Git Hooks

`.githooks/` scripts already guard with `command -v gh` and skip gracefully
when it is absent (see `.githooks/pre-push.d/010-issue-status-consistency.sh`).
Hook authors must preserve this pattern: any new hook that calls `gh` must
no-op with a warning when `gh` is unavailable.
