---
description: "Creates or refines an Auto issue, runs research, synthesizes a plan, and handles Gate 1."
tools: [read, edit, search, execute, agent, web, "github/*", "github-mcp-server/*"]
mcp-servers:
  github-mcp-server:
    type: http
    url: "https://api.githubcopilot.com/mcp/"
    tools: ["*"]
    headers:
      X-MCP-Toolsets: "repos,issues,pull_requests,users,context"
---

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/issue.md`. Use configured GitHub MCP capabilities in the
hosted environment. Complete duplicate search, research, plan, acceptance
criteria, and interactive Gate 1; do not write implementation code.
