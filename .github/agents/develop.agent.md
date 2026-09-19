---
description: "Implements one approved Auto task with strict Red-Green-Refactor and a retrospective."
tools: [read, edit, search, execute, "github/*", "github-mcp-server/*"]
user-invocable: true
mcp-servers:
  github-mcp-server:
    type: http
    url: "https://api.githubcopilot.com/mcp/"
    tools: ["*"]
    headers:
      X-MCP-Toolsets: "repos,issues,pull_requests,users,context"
---

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/develop.md`. Require materialized issue, branch, task,
acceptance criteria, paths, and test command. Complete one TDD cycle, post its
retrospective with configured GitHub tools, and leave the PR draft.
