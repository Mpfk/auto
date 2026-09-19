# GitHub access by capability

Auto runs locally and in hosted Claude Code, GitHub Copilot, and OpenAI Codex
environments. GitHub access is selected by capability rather than by hard-coded
provider assumptions.

## Selection protocol

1. Discover the repository from `git remote get-url origin`.
2. Determine which operations the active phase needs: issue/PR reads or writes,
   comments and labels, review threads, checks, branches/refs, or merge state.
3. Prefer authenticated `gh` in local sessions:

   ```bash
   command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
   ```

4. For any missing capability, use the GitHub tools provided by the host.
5. Stop only when neither route can perform a required operation. Report the
   exact missing capability and how to authenticate `gh` or connect/install the
   host integration for the target repository.

Do not treat a missing `gh` binary as a blocker when host tools can complete the
operation. Do not assume that a connected integration can write: verify its
installation and repository permissions when a mutation returns 403.

## Capability mapping

| Capability | Preferred local route | Host-tool intent |
|---|---|---|
| Read/search issues | `gh issue view/list` | fetch/search issue |
| Create/update issue | `gh issue create/edit` | create/update issue |
| Comments and labels | `gh issue comment/edit` | add comment/update labels |
| Read/open/update PR | `gh pr view/list/create/ready` | fetch/list/create/update PR |
| Review threads/findings | `gh api` review endpoints | list/reply/resolve review threads |
| Checks and workflow runs | `gh pr checks`, `gh run` | commit/PR checks and workflow jobs |
| Branch/ref operations | `git`, `gh api` | create/update/list branch or ref |
| Merge and verify | `gh pr merge/view` | merge PR, then re-read PR and issue |

Tool names differ across hosts; match the operation and verify the response.
When an update API replaces full label sets, read existing labels first and
write the complete intended set.

## Sub-issues

When native sub-issue APIs are available, use them. Otherwise use the portable
representation: a child checklist in the parent body and `Parent: #N` in each
child. `$auto` accepts either form when fanning out independent work.

## Review evidence

All providers write the same issue comment defined by
`playbooks/review.md`: verdict, provider, reviewed head SHA, preflight result,
and finding links. Before Gate 2, re-read the PR head and reject a record for any
other SHA.

Codex-native review is requested with `@codex review`. If it is unavailable,
errors, or does not complete within five minutes, use the local `$review`
fallback and record provider `codex-local`.

## Managed cloud branches

Some hosted sessions enforce a provider-assigned push branch. That is the only
exception to `issue/{number}`. Keep the issue-first rule, use a draft PR, and put
`Closes #N` in the PR body. Native git credentials may work even when `gh` does
not.

## Hooks

Hooks that call GitHub must no-op with a warning when their required transport
is unavailable. Local policy checks and tests still run.
