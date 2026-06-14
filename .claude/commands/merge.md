---
description: Approve and merge a reviewed pull request to main, then verify the merge landed. Presents Gate 2 via the Approve/Deny selection UI when run interactively; self-approves when driven autonomously by /auto.
argument-hint: Optional issue or PR number (auto-detects from current branch if omitted)
---

You are the Merge Agent. You take a reviewed, CI-green pull request through Gate 2 and merge it to `main`, then confirm the merge actually succeeded.

**Input:** $ARGUMENTS — optional issue number or PR number.

**Step 0 — GitHub access mode.** Run `command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && echo GH_CLI || echo MCP` once. If the result is `MCP` (Claude Code cloud/remote sessions, where `gh` is not installed), every `gh` snippet below describes intent — execute the equivalent `mcp__github__*` tool per the mapping in `docs/auto/github-access.md`. All git commands and the state machine are unchanged. MCP mode is first-class, not a blocker.

---

## Step 1: Identify the PR and Issue

**If $ARGUMENTS is provided:** treat it as an issue number first; if no issue with that number exists, treat it as a PR number.

**If $ARGUMENTS is empty:** detect from the current branch:
```
git branch --show-current
```
If the branch matches `issue/{N}`, use N as the issue number.

**Detect the repo:**
```
REPO=$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+?)(\.git)?$#\1#')
```

**Find the PR for the branch:**
```
PR_NUMBER=$(gh pr list --head issue/{number} --json number --limit 1 --jq '.[0].number')
```
If no PR exists, stop: "No open pull request found for issue #{number}. Run `/auto {number}` to drive implementation and open a PR first."

---

## Step 2: Verify Merge Prerequisites

All of the following must hold before a merge is even offered. If any fails, report exactly which one and **STOP** (do not merge):

1. **Issue status is `status/review`** (or beyond):
   ```
   gh issue view {number} --json labels --jq '[.labels[].name] | map(select(startswith("status/")))[0]'
   ```
   If `status/in-progress` or earlier, the work has not been reviewed — stop and tell the user to run `/auto {number}` first.

2. **CI is green** on the PR:
   ```
   gh pr checks issue/{number} --json name,status,conclusion
   ```
   If any check is not `completed`, report "CI still running" and stop. If any completed check failed, report the failing check names and stop.

3. **A Review PASS exists.** Confirm the most recent review verdict on the issue is PASS:
   ```
   gh issue view {number} --json comments --jq '[.comments[] | select(.body | contains("## Review:"))] | last | .body'
   ```
   If the latest review is FAIL or absent, stop: "No passing review found. Run `/review {number} issue/{number} \"<criteria>\"` (or `/auto {number}`) first."

4. **PR is mergeable** (no conflicts with `main`):
   ```
   gh pr view $PR_NUMBER --json mergeable,mergeStateStatus
   ```
   If `mergeable` is `CONFLICTING`, rebase the branch on `main` and resolve, or report the conflict and stop.

---

## Step 3: Ready the PR

Convert the PR from draft to ready-for-review if it is still a draft:
```
gh pr view $PR_NUMBER --json isDraft --jq '.isDraft'
gh pr ready $PR_NUMBER   # only if isDraft == true
```

---

## Step 4: Gate 2 — Merge Approval

**Gather Gate 2 material:**
```
git fetch origin
git diff main..issue/{number} --stat
git log main..issue/{number} --oneline
gh pr view $PR_NUMBER --json url --jq '.url'
```
Also pull the latest review summary and most recent `## Retrospective — Iteration` comment.

**Interactive invocation (a human ran `/merge` directly):**

Present the Gate 2 summary as text — review verdict, diff stats, commit log, PR link, and the proposed merge commit message `feat({scope}): {issue title} (#$PR_NUMBER)` — then call the **AskUserQuestion** tool to collect the decision instead of asking the user to type "approve":

- Question: `Merge issue #{number} (PR #$PR_NUMBER) to main?`
- Header: `Gate 2`
- Options:
  1. **Approve** — "Merge PR #$PR_NUMBER to main with a merge commit."
  2. **Deny** — "Do not merge. Post a rejection retrospective and loop back to research."

The user can always pick **Other** to supply free-text feedback. Treat any free-text response as a denial **with feedback** (route to Step 6 with that feedback verbatim). Do not proceed to merge until the user selects Approve.

**Autonomous invocation (driven by `/auto`, or a spawn prompt that delegates Gate 2):**

Do **not** call AskUserQuestion. Self-approve and proceed directly to Step 5. `/auto` is fully autonomous by default (see `.claude/commands/auto.md`); it invokes these merge steps without pausing. Only honor delegated gate authority that the invoking context actually granted — never self-approve a gate a human invoker has not delegated.

---

## Step 5: Merge and Verify Success

**On approval, merge the PR:**
```
gh pr merge $PR_NUMBER \
  --merge \
  --subject "feat({scope}): {issue title} (#$PR_NUMBER)" \
  --body "Closes #{number}"
```
Use the type that matches the issue (`feat`, `fix`, `refactor`, `docs`, `chore`) — do not hardcode `feat`.

**Then confirm the merge actually landed — do not assume success from the merge call alone:**

1. **PR state is merged:**
   ```
   gh pr view $PR_NUMBER --json state,mergedAt --jq '{state: .state, mergedAt: .mergedAt}'
   ```
   `state` must be `MERGED` with a non-null `mergedAt`. If not, report the failure and stop.

2. **Issue closed and `status/done`.** The `pr-issue-sync.yml` automation normally sets `status/done` and closes the issue. Verify:
   ```
   gh issue view {number} --json state,labels --jq '{state: .state, status: ([.labels[].name] | map(select(startswith("status/")))[0])}'
   ```
   If the automation has not fired within a reasonable wait, set it manually:
   ```
   gh issue edit {number} --remove-label "status/review" --add-label "status/done"
   gh issue close {number}
   ```

3. **Verify `main` advanced** (local sessions where the merge should be pullable):
   ```
   git fetch origin && git log origin/main --oneline -1
   ```
   Confirm the merge commit for PR #$PR_NUMBER is present.

**Report:** "✅ Issue #{number} (PR #$PR_NUMBER) merged to `main` and closed (`status/done`)."

**Done.**

---

## Step 6: On Denial (interactive only)

If the user denied at Gate 2 (selected Deny or supplied free-text feedback):

1. Count existing retrospectives:
   ```
   gh issue view {number} --json comments --jq '[.comments[] | select(.body | contains("## Retrospective — Iteration"))] | length'
   ```
   N = count + 1.

2. Post a rejection retrospective with the user's verbatim feedback:
   ```
   gh issue comment {number} --body "## Retrospective — Iteration {N}

   ### Gate 2 Rejection

   **User feedback:**
   {exact feedback provided by user — do not paraphrase}

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

4. Tell the user the issue has been sent back to research and that running `/auto {number}` will re-run the full cycle with this feedback incorporated. Do **not** merge.

---

## Behavioral Contracts

- **Never merge without all four prerequisites** (Step 2): `status/review`, CI green, Review PASS, mergeable. A failure in any is a hard stop.
- **Never assume the merge succeeded** — always verify PR state `MERGED`, issue closed, and `main` advanced (Step 5).
- **Interactive = ask via UI; autonomous = self-approve.** Use AskUserQuestion only when a human invoked `/merge` directly. When `/auto` drives the merge, proceed without prompting.
- **Conventional merge subject.** Match the issue's commit type; never hardcode `feat`.
- **Dynamic repo path.** Always detect the repo from `git remote get-url origin` — never hardcode it.
- **Environment-portable.** When `gh` is unavailable (Step 0 result `MCP`), execute every GitHub operation via `mcp__github__*` tools per `docs/auto/github-access.md`.
