# Future Updates

> These items are improvements to the **`auto` workflow template itself** — not to any application or software built on top of it.

## Pending Items

### 1. Auto-invoke Develop agents on Copilot assignment

**Current state:** When Copilot is assigned to a `status/ready` issue, `issue-native-automation.yml` posts a structured kickoff comment with the branch name and TDD instructions.

**Gap:** GitHub Actions cannot directly invoke a Copilot agent. The user still needs to open a Copilot session and trigger the Develop agent manually (or use the "Assign to Copilot" button on `github.com`).

**Desired state:** Assignment triggers the Develop agent automatically with fully materialized context (issue number, branch, acceptance criteria, file paths).

**Blocked by:** GitHub platform — no API to invoke a custom agent from a workflow today. Revisit when GitHub exposes agent invocation from Actions.

---

### 2. Auto-invoke review agent when PR is ready for review

**Current state:** `pr-issue-sync.yml` moves the issue to `status/review` and posts a comment prompting the user to invoke the review agent.

**Gap:** The review agent invocation is manual. The user must open Copilot chat and trigger it themselves.

**Desired state:** Marking a PR as "ready for review" automatically runs the review agent and posts its output as a PR comment, then surfaces Gate 2 material.

**Blocked by:** Same platform limitation as above.

---

### 3. Validate end-to-end native flow with a smoke test

**Current state:** The lifecycle automation workflows (state guard, native automation, PR/issue sync) are deployed but not yet validated with a real issue.

**Desired state:** One smoke-test issue confirms the full lifecycle:
- Issue created → `status/draft` added automatically
- Plan approved via `/auto plan-approved` → `status/ready`
- Copilot assigned → branch created, `status/in-progress`
- PR opened → `status/in-progress` maintained
- PR marked ready → `status/review`
- PR merged → `status/done`, issue closed

---

### 4. Copilot agent name detection robustness

**Current state:** `issue-native-automation.yml` detects a Copilot assignee by checking if the login contains `"copilot"` (case-insensitive).

**Gap:** This may not match all GitHub Copilot actor patterns, especially in enterprise orgs.

**Desired state:** A configurable pattern in `workflow.conf` or a GitHub-provided actor type field, so detection is reliable across account types.
