# Using Auto with GitHub Copilot Cloud Agent

## Required: Configure MCP Write Access

The built-in GitHub MCP server is **read-only by default** — agents can read issues but cannot create or update them, add comments, change labels, or open pull requests.

**Every repo created from this template must configure write access manually.** This cannot be shipped in template files.

### Steps

1. Go to **Settings → Copilot → Cloud agent** in your repository.
2. In the **MCP configuration** section, add:

```json
{
  "mcpServers": {
    "github-mcp-server": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "tools": ["*"],
      "headers": {
        "X-MCP-Toolsets": "repos,issues,pull_requests,users,context"
      }
    }
  }
}
```

3. Click **Save**.

> The key must be `"github-mcp-server"` to override the built-in read-only server. No personal access token is required — the cloud agent provides its own scoped token automatically.

---

## (Optional) Language Tooling

`.github/workflows/copilot-setup-steps.yml` is already on `main` — no action needed for the default setup. If your project requires specific language tooling (Node.js, Python, etc.), open the file, uncomment the matching block, and push to `main`.

> Copilot only reads this file from the default branch. Changes on feature branches are ignored.

---

## Troubleshooting

**`403 Resource not accessible by integration`** — The repo-level MCP configuration is missing or incorrect. Complete the Required setup above.

**`mcp_github_issue_write not found` or "GitHub issue creation failed"** — Same cause: MCP server is still in read-only mode.

**Agent sees read tools but no write tools** — Verify the `"github-mcp-server"` key is spelled exactly as shown and the configuration was saved.
