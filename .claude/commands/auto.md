---
description: Auto-drive the full workflow for an issue from its current state. Chains every phase automatically — research, planning, implementation, CI monitoring, review, and merge — running fully autonomously end-to-end without pausing for approval.
argument-hint: Optional issue number (auto-detects from current branch if omitted)
---

You are the Progress Driver. You autonomously execute the entire Auto workflow for a given issue, reading its current state and driving all remaining phases through to merge **without prompting the user**.

**Fully autonomous by default.** `/auto` self-approves both Gate 1 (plan) and Gate 2 (merge) and merges to `main` without stopping. The gates still exist as decision points — they are simply auto-approved here. A human who wants to inspect a gate runs the standalone commands instead: `/issue` presents Gate 1 via the Approve/Deny selection UI, and `/merge` presents Gate 2 via the selection UI. `/auto` itself never waits for approval.

**Input:** $ARGUMENTS — optional issue number.

**Step 0 — GitHub access mode.** Run `command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && echo GH_CLI || echo MCP` once. If the result is `MCP` (Claude Code cloud/remote sessions, where `gh` is not installed), every `gh` snippet below describes intent — execute the equivalent `mcp__github__*` tool per the mapping in `docs/auto/github-access.md`. All other instructions (git commands, state machine, gates) are unchanged. MCP mode is first-class, not a blocker.

---

## Step 1: Identify the Issue

**If $ARGUMENTS is provided:** use it as the issue number.

**If $ARGUMENTS is empty:** detect from the current branch:
```
git branch --show-current
```
If the branch matches `issue/{N}`, use N as the issue number.

If not on an issue branch and no argument given, stop: "No issue number provided and current branch is not `issue/{N}`. Please provide an issue number or check out the issue branch. Use `/issue` to create a new issue."

**Detect the repo:**
```
REPO=$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+?)(\.git)?$#\1#')
```
Use `$REPO` in all `gh api repos/$REPO/...` calls (or as `owner`/`repo` for MCP tools). Never hardcode the repo path.

**Read the issue:**
```
gh issue view {issue_number} --json number,title,labels,body \
  --jq '{number: .number, title: .title, status: ([.labels[].name] | map(select(startswith("status/")))[0]), body: .body}'
```

If `status/done` or `status/cancelled`, report it and stop.

If no `status/*` label exists, treat as `status/draft`.

---

## Step 1.5: Parent Issue with Sub-Issues

Check whether this issue is a **parent** that was decomposed into sub-issues (see `/issue`'s sub-issue logic):
```
gh api repos/$REPO/issues/{number}/sub_issues --jq 'length'   # GH_CLI mode
```
In MCP mode, sub-issues are tracked as a checklist in the parent body (`- [ ] #child`) — read the parent body and extract the referenced child issue numbers instead.

**If the issue has sub-issues**, do not implement the parent directly — drive its children, then merge the parent:

1. List the child issue numbers and their `status/*` labels.
2. Apply the concurrency strategy from the "Managing Autonomous Sub-agent Teams" section of `CLAUDE.md`:
   - **File-disjoint children** (the normal case — `/issue` only creates sub-issues when tasks split cleanly): spawn one `/auto {child}` sub-agent per child **in parallel**, each with `isolation: "worktree"`. Give each sub-agent fully materialized context (its child issue's plan and acceptance criteria verbatim) and explicit authority to self-approve both gates within this autonomous run.
   - **Any children that touch overlapping files:** serialize those — spawn the next only after the prior child's PR merges.
3. Wait for all child sub-agents to merge their PRs to `main`.
4. Pull `main` and confirm each child landed (append `&& echo _PULL_DONE_` and verify the sentinel).
5. Once all children are `status/done`, run `/merge {number}` on the parent if it has its own integration PR; otherwise close the parent (`gh issue close {number}` and set `status/done`) since its work is fully delivered by the merged children.

**If the issue has no sub-issues**, proceed to the State Machine below as a single unit of work.

---

## State Machine

Execute the section below that matches the current status label.

---

### STATUS: `status/draft` or `status/researching`

Research and planning is needed.

1. Announce: "Issue #{number} is in `{status}`. Running research and planning..."

2. If status is `status/draft`, move to researching:
   ```
   gh issue edit {number} --remove-label "status/draft" --add-label "status/researching"
   ```

3. Extract the problem statement verbatim from the issue body. This is the research input — use it directly, not "the issue says to read the issue."

4. **Prior retrospective check** (re-research cycle after Gate 2 rejection):
   ```
   gh issue view {number} --json comments --jq '[.comments[] | select(.body | contains("## Retrospective — Iteration"))] | length'
   ```
   If count > 0, read the latest:
   ```
   gh issue view {number} --json comments --jq '[.comments[] | select(.body | contains("## Retrospective — Iteration"))] | last | .body'
   ```
   Include this retrospective text in each research sub-agent's scope hints.

5. **Select research strategies** (2–4):
   - `codebase` — for any non-trivial feature
   - `docs` — when ADRs or prior decisions may constrain the approach
   - `external` — when evaluating libraries or unfamiliar patterns
   - `constraints` — for security-sensitive or performance-sensitive work

6. **Spawn research sub-agents in parallel.** For each selected strategy, invoke a sub-agent using the instructions from `.claude/commands/research.md`. Provide each sub-agent with fully materialized context:
   - Issue number
   - Strategy
   - Scope hints: relevant directories, keywords, and topics for this specific problem
   - Prior retrospective (verbatim, if any)

   Wait for all sub-agents to return before proceeding.

7. **Synthesize findings:**
   - **ALIGN:** Findings that two or more strategies confirm — high confidence
   - **CONFLICT:** Resolve with priority: project conventions > ADRs > external best practices. Constraint findings are hard boundaries.
   - **GAPS:** Areas with no coverage — flag as risks

   Post synthesis as issue comment:
   ```
   gh issue comment {number} --body "## Research Synthesis

   ### Findings by Theme
   {organized findings with confidence and sources}

   ### Hard Constraints
   {non-negotiable constraints}

   ### Open Questions
   {anything unresolved — or 'None'}
   "
   ```

   If critical open questions would significantly change the plan, pause and ask the user before proceeding.

8. **Set label to `status/planning`:**
   ```
   gh issue edit {number} --remove-label "status/researching" --add-label "status/planning"
   ```

9. **Write plan and acceptance criteria.** Create numbered independently testable tasks (one per `/develop` invocation). Write testable acceptance criteria as checkboxes.

10. **Update issue body** with the complete Research, Plan, and Acceptance Criteria sections.

11. **Gate 1 — self-approved (autonomous).** Post a brief plan summary as an issue comment for the record (key findings, numbered tasks, acceptance criteria), then advance without pausing:
    ```
    gh issue edit {number} --remove-label "status/planning" --add-label "status/ready"
    ```
    `/auto` is fully autonomous — it does not stop for Gate 1 approval. (A human who wants to review the plan before implementation runs `/issue {number}` instead, which presents Gate 1 via the selection UI.)

    Then immediately fall through to the `status/ready` handler below.

---

### STATUS: `status/planning`

A plan was drafted but `status/ready` hasn't been set yet.

1. Read the issue body for the existing plan and acceptance criteria.
2. **Gate 1 — self-approved (autonomous).** `/auto` does not pause for plan approval. Advance directly:
   ```
   gh issue edit {number} --remove-label "status/planning" --add-label "status/ready"
   ```
   Fall through to the `status/ready` handler below. (To review a plan before it advances, a human runs `/issue {number}`, which presents Gate 1 via the selection UI.)

---

### STATUS: `status/ready`

Gate 1 was approved. Begin implementation.

1. Announce: "Issue #{number} is `status/ready`. Starting implementation..."

2. Set label to `status/in-progress`:
   ```
   gh issue edit {number} --remove-label "status/ready" --add-label "status/in-progress"
   ```

3. **Ensure branch exists:**
   ```
   gh api repos/$REPO/git/refs/heads/issue/{number} 2>/dev/null && echo "exists" || echo "missing"
   ```
   If missing (native automation hasn't fired yet), create it from main:
   ```
   MAIN_SHA=$(gh api repos/$REPO/git/ref/heads/main --jq '.object.sha')
   gh api repos/$REPO/git/refs --method POST \
     --field ref="refs/heads/issue/{number}" \
     --field sha="$MAIN_SHA"
   ```

4. **Check out branch:**
   ```
   git fetch origin
   git checkout issue/{number}
   ```

5. **Read plan from issue body.** Extract the numbered tasks and acceptance criteria verbatim.

6. **Spawn develop and documentation sub-agents in parallel.**

   For the first (or only) task, invoke a develop sub-agent using the instructions from `.claude/commands/develop.md` with:
   - Issue number: `{number}`
   - Branch: `issue/{number}`
   - Task: `{task 1 description verbatim}`
   - Acceptance criteria: `{acceptance criteria verbatim}`

   If multiple independent tasks exist, spawn one develop sub-agent per task in parallel.

   In parallel with develop, invoke a documentation sub-agent using the instructions from `.claude/commands/document.md` with:
   - Issue number: `{number}`
   - Branch: `issue/{number}`
   - Changes summary: `{description of what the develop agent will implement}`
   - Modified files: `{source and test file paths from the plan}`

7. Wait for all sub-agents to complete.

8. Fall through to `status/in-progress` handling below to monitor CI.

---

### STATUS: `status/in-progress`

Implementation is active. Monitor CI and act on results.

1. **Find the PR:**
   ```
   gh pr list --head issue/{number} --json number,isDraft --limit 1
   ```
   If no PR exists (first push just completed but PR not yet created), create one:
   ```
   ISSUE_TITLE=$(gh issue view {number} --json title --jq '.title')
   gh pr create \
     --title "$ISSUE_TITLE" \
     --body "Closes #{number}" \
     --draft \
     --head issue/{number} \
     --base main
   ```

2. **Check CI status:**
   ```
   gh pr checks issue/{number} --json name,status,conclusion
   ```

   **If all checks are pending/queued:** Report: "CI is running for issue #{number}. Re-run `/auto {number}` when CI completes, or use `/loop 2m /auto {number}` to auto-poll." **STOP.**

   **If any check is failing:**
   - Capture failure details:
     ```
     gh pr checks issue/{number} --json name,conclusion,detailsUrl --jq '[.[] | select(.conclusion == "failure" or .conclusion == "timed_out")] | .[] | "FAIL: \(.name) — \(.detailsUrl)"'
     ```
   - Read the most recent retrospective:
     ```
     gh issue view {number} --json comments --jq '[.comments[] | select(.body | contains("## Retrospective — Iteration"))] | last | .body'
     ```
   - Re-invoke a develop sub-agent with full failure context. Include the exact failing check names and the prior retrospective in the task description:
     ```
     Task: "Fix CI failures: {failure names and details}"
     Acceptance criteria: {from issue body, verbatim}
     Context: Prior retrospective: {retrospective text}
     ```
   - After develop completes, loop back to the top of this state to re-check CI.

   **If ALL checks pass:**
   - The `ci-issue-gate.yml` workflow should have set label to `status/review` automatically. Verify:
     ```
     gh issue view {number} --json labels --jq '[.labels[].name] | map(select(startswith("status/")))[0]'
     ```
   - If still `status/in-progress`, set manually:
     ```
     gh issue edit {number} --remove-label "status/in-progress" --add-label "status/review"
     ```
   - Fall through to `status/review` handling below.

---

### STATUS: `status/review`

CI is green. Run the Review Agent.

1. **Double-check CI:**
   ```
   gh pr checks issue/{number} --json name,status,conclusion
   ```
   If any checks are failing, reset to `status/in-progress`:
   ```
   gh issue edit {number} --remove-label "status/review" --add-label "status/in-progress"
   ```
   Loop back to the `status/in-progress` handler to fix.

2. **Get PR number:**
   ```
   PR_NUMBER=$(gh pr list --head issue/{number} --json number --limit 1 --jq '.[0].number')
   ```

3. **Extract acceptance criteria** from issue body:
   ```
   gh issue view {number} --json body --jq '.body' | awk '/## Acceptance Criteria/{f=1;next} /^## /{f=0} f{print}'
   ```

4. **Invoke review sub-agent** using the instructions from `.claude/commands/review.md` with:
   - Issue number: `{number}`
   - Branch: `issue/{number}`
   - Acceptance criteria: `{verbatim from issue body}`

   Wait for the review to complete and return PASS or FAIL.

5. **If Review returns FAIL:**
   - Note the specific issues from the review output.
   - Re-invoke a develop sub-agent targeting the exact failures:
     - Task: `"Fix review issues: {failure list from review output}"`
     - Acceptance criteria: `{from issue body, verbatim}`
   - Push, wait for CI (`gh pr checks`), re-check once CI completes, re-run review. Loop until PASS.

6. **If Review returns PASS and CI is confirmed green:**
   - **Gate 2 — self-approved (autonomous).** `/auto` does not pause for merge approval. Drive the merge by following the steps in `.claude/commands/merge.md` in **autonomous mode** (self-approve — do **not** call AskUserQuestion):
     - Verify the four merge prerequisites (`status/review`, CI green, Review PASS, mergeable).
     - Ready the PR (`gh pr ready issue/{number}`).
     - Merge with the conventional subject and verify success (PR `MERGED`, issue closed `status/done`, `main` advanced).
   - This is the same logic a human gets from `/merge {number}`, minus the interactive Gate 2 prompt. See `## Gate 2 Outcomes` below for the merge command and the rejection loop (the latter is reached only when a human denies via standalone `/merge`).

---

## Gate 2 Outcomes

### On Approval (autonomous — the default `/auto` path)

Merge the PR and verify it landed:
```
gh pr merge $PR_NUMBER \
  --merge \
  --subject "feat({scope}): {issue title} (#$PR_NUMBER)" \
  --body "Closes #{number}"
```
Use the type matching the issue (`feat`/`fix`/`refactor`/`docs`/`chore`), not always `feat`. Then verify success per `merge.md` Step 5: PR `state == MERGED`, issue closed and `status/done` (set manually if `pr-issue-sync.yml` hasn't fired), and `main` advanced.

Report: "✅ Issue #{number} merged to `main` and closed (`status/done`)."

**Done.**

---

### On Rejection (only when a human denies via standalone `/merge`)

`/auto` never rejects at Gate 2 on its own — it self-approves. This loop exists for the case where a human ran `/merge {number}` directly and denied. When that happens, `/merge` posts the `## Retrospective — Iteration N` comment (with the user's verbatim feedback) and resets the issue to `status/researching`. A subsequent `/auto {number}` then re-enters at the `status/researching` handler above; the prior retrospective is included in each research sub-agent's context, and the full research → plan → implement → review → merge cycle runs again with the feedback incorporated.

---

## Behavioral Contracts

- **Fully autonomous.** `/auto` self-approves Gate 1 and Gate 2 and merges to `main` without prompting. It does not wait for user input at any phase. (Interactive gate review lives in the standalone `/issue` and `/merge` commands, which use the Approve/Deny selection UI.)
- **Gates still gate on facts, not on people.** Auto-approval is not "skip the checks." Gate 1 still requires a synthesized plan and acceptance criteria; Gate 2 still requires `status/review`, CI green, a Review PASS, and a mergeable PR. A failure in any of these is a hard stop — autonomy removes the *human pause*, never the *quality bar*.
- **Verify the merge.** Never assume a merge succeeded. Confirm PR `state == MERGED`, the issue closed at `status/done`, and `main` advanced (per `merge.md` Step 5).
- **Idempotent.** Running `/auto {N}` multiple times is safe — it reads state and continues from exactly where it left off.
- **CI pending → stop and poll.** A single command invocation cannot block on CI. If CI is still running, report that and stop; tell the user to re-invoke when CI completes, or use `/loop 2m /auto {N}` for auto-polling. (This is a practical wait, not an approval gate.)
- **Sub-issue fan-out.** A parent issue with sub-issues is driven by spawning one `/auto {child}` sub-agent per child (Step 1.5), per the "Managing Autonomous Sub-agent Teams" pattern in `CLAUDE.md`.
- **Fully materialized context.** Every sub-agent invocation includes verbatim problem statements and criteria, not references to "read the issue."
- **Dynamic repo path.** Always detect the repo from `git remote get-url origin` — never hardcode it.
- **Environment-portable.** When `gh` is unavailable (Step 0 result `MCP`), execute every GitHub operation via `mcp__github__*` tools per `docs/auto/github-access.md`. Cloud sessions that assign their own push branch use that branch and link the issue with `Closes #N` in the PR body.
