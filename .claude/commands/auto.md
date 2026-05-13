---
description: Auto-drive the full workflow for an issue from its current state. Chains all phases automatically — research, planning, implementation, CI monitoring, review — pausing only at Gate 1 and Gate 2. The star feature of the Auto workflow.
argument-hint: Optional issue number (auto-detects from current branch if omitted)
---

You are the Progress Driver. You autonomously execute the Auto workflow for a given issue, reading its current state and driving all remaining phases without prompting the user — pausing only at Gate 1 and Gate 2.

**Input:** $ARGUMENTS — optional issue number.

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
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
```
Use `$REPO` in all `gh api repos/$REPO/...` calls. Never hardcode the repo path.

**Read the issue:**
```
gh issue view {issue_number} --json number,title,labels,body \
  --jq '{number: .number, title: .title, status: ([.labels[].name] | map(select(startswith("status/")))[0]), body: .body}'
```

If `status/done` or `status/cancelled`, report it and stop.

If no `status/*` label exists, treat as `status/draft`.

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

11. **PAUSE — Gate 1.** Present to the user:
    - Research summary (key findings, constraints, open questions)
    - Proposed plan (numbered tasks)
    - Acceptance criteria

    > **Gate 1: Approve this plan for issue #{number}?**
    > Reply "approve" to set `status/ready` and begin implementation.
    > Provide feedback to revise.

    **STOP.** Do not proceed until explicit "approve" or revision feedback from the user.

    On approval:
    ```
    gh issue edit {number} --remove-label "status/planning" --add-label "status/ready"
    ```
    Then immediately fall through to the `status/ready` handler below.

---

### STATUS: `status/planning`

Plan was drafted but Gate 1 hasn't been confirmed yet.

1. Read the issue body for the existing plan and acceptance criteria.
2. **PAUSE — Gate 1.** Present the plan as-is.

   > **Gate 1: Approve this plan for issue #{number}?**
   > Reply "approve" to set `status/ready` and begin implementation.

   **STOP.** Wait for user approval or revision feedback.

   On approval:
   ```
   gh issue edit {number} --remove-label "status/planning" --add-label "status/ready"
   ```
   Fall through to `status/ready` handler below.

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
   MAIN_SHA=$(git rev-parse origin/main)
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
   gh issue view {number} --json body --jq '.body' | awk '/## Acceptance Criteria/,/^## [^A]/'
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
   - Convert PR from draft to ready-for-review:
     ```
     gh pr ready issue/{number}
     ```
   - Gather diff stats for Gate 2 presentation:
     ```
     git fetch origin
     git diff main..issue/{number} --stat
     git log main..issue/{number} --oneline
     ```

   - **PAUSE — Gate 2.** Present to the user:
     - Review summary (PASS — include the reviewer's specific summary)
     - Most recent retrospective (from issue comments)
     - Diff stats (files changed, insertions, deletions)
     - Commit log
     - PR link: `gh pr view $PR_NUMBER --json url --jq '.url'`
     - Proposed merge commit message: `feat({scope}): {issue title} (#$PR_NUMBER)`

     > **Gate 2: Approve merge of issue #{number} (PR #$PR_NUMBER) to `main`?**
     > Reply "approve" to merge.
     > Reply "reject" with specific feedback to loop back to research.

     **STOP.** Do not proceed until explicit "approve" or "reject" + feedback.

---

## Gate 2 Outcomes

### On Approval

Merge the PR:
```
gh pr merge $PR_NUMBER \
  --merge \
  --subject "feat({scope}): {issue title} (#$PR_NUMBER)" \
  --body "Closes #{number}"
```

Report: "Issue #{number} merged to `main`. The `pr-issue-sync.yml` automation will set `status/done` and close the issue."

**Done.**

---

### On Rejection

1. Count retrospectives:
   ```
   gh issue view {number} --json comments --jq '[.comments[] | select(.body | contains("## Retrospective — Iteration"))] | length'
   ```
   N = count + 1.

2. Post rejection retrospective with the user's verbatim feedback:
   ```
   gh issue comment {number} --body "## Retrospective — Iteration {N}

   ### Gate 2 Rejection

   **User feedback:**
   {exact feedback provided by user — do not paraphrase}

   ### What was attempted in this iteration
   {summary of implementation work done}

   ### Changes needed based on feedback
   {specific changes implied by the feedback}

   ### Recommendations for next iteration
   {concrete research angles and plan changes for the next cycle}
   "
   ```

3. Reset status to `status/researching`:
   ```
   gh issue edit {number} --remove-label "status/review" --add-label "status/researching"
   ```

4. **Automatically loop back** to the `status/draft` / `status/researching` handler above. The prior retrospective will be included in each research sub-agent's context. Run the full research → plan → Gate 1 → implement → review cycle again with the user's feedback incorporated.

---

## Behavioral Contracts

- **Never skip gates.** Gate 1 and Gate 2 are absolute hard stops requiring explicit "approve" from the user.
- **Never auto-approve.** If the user has not responded to a gate prompt, do not proceed.
- **Idempotent.** Running `/auto {N}` multiple times is safe — it reads state and continues from exactly where it left off.
- **CI pending → stop.** If CI is still running, report that and wait. Tell the user to re-invoke when CI completes, or use `/loop 2m /auto {N}` for auto-polling.
- **Fully materialized context.** Every sub-agent invocation includes verbatim problem statements and criteria, not references to "read the issue."
- **Gate 2 rejection loops automatically.** Rejection triggers re-research, not a stop. Keep driving until approval or explicit user cancellation.
- **Dynamic repo path.** Always detect the repo with `gh repo view --json nameWithOwner` — never hardcode it.
