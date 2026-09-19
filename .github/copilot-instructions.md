# Auto — GitHub Copilot adapter

Auto's provider-neutral rules live in `docs/auto/playbooks/core.md`. Read that
file and `docs/auto/playbooks/github.md` before acting, then read the playbook
for the active phase. These shared contracts preserve the existing issue-first,
two-gate, TDD, Conventional Commit, draft-PR, review, CI fallback, and
verified-merge behavior.

## Copilot interface

The agents in `.github/agents/` are thin adapters:

- `orchestrate` and `issue` -> `docs/auto/playbooks/issue.md`
- `research` -> `docs/auto/playbooks/research.md`
- `develop` -> `docs/auto/playbooks/develop.md`
- `documentation` -> `docs/auto/playbooks/document.md`
- `review` -> `docs/auto/playbooks/review.md`
- `merge` -> `docs/auto/playbooks/merge.md`

Use the configured GitHub MCP tools in GitHub-hosted Copilot. In a local
environment, authenticated `gh` is preferred when present. Test the needed
capability and follow `docs/auto/github-access.md` instead of assuming a
specific tool is available.

Copilot has no structured gate selection UI: present Gate 1 or Gate 2 in plain
text and wait for typed approval. Do not infer autonomous gate authority from an
ordinary implementation request. When Actions are unavailable and zero checks
exist, follow the shared CI fallback requirements and record the local result.

Every specialist prompt must materialize the issue number, branch, task,
acceptance criteria, relevant paths, and done condition. Keep PRs draft until
CI and the normalized review record pass.
