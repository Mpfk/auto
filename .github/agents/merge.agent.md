---
description: "Validates Auto Gate 2, merges an approved PR, and verifies final issue and branch state."
tools: [read, search, "github/*", "github-mcp-server/*"]
mcp-servers:
  github-mcp-server:
    type: http
    url: "https://api.githubcopilot.com/mcp/"
    tools: ["*"]
    headers:
      X-MCP-Toolsets: "repos,issues,pull_requests,users,context"
---

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/merge.md`. Use configured GitHub MCP capabilities. Copilot
has no structured selection UI, so request typed Gate 2 approval unless the
invoking context explicitly grants autonomy. If GitHub Actions are unavailable
and no checks exist, accept only the documented CI fallback evidence. Reject
stale review evidence and verify the merge rather than trusting the mutation
response.
