# Using Auto with GitHub Copilot Cloud Agent

## Required: Configure GitHub MCP Server Write Access

The built-in GitHub MCP server in the cloud agent is **read-only by default**. This means agents can read issues but cannot create or update them, add comments, change labels, create branches, or open pull requests.

**Every repo created from this template must configure write access manually.** This is a repo-level setting that cannot be shipped in template files.

### Setup Steps

1. Go to your repository on GitHub.
2. Navigate to **Settings → Copilot → Cloud agent**.
3. In the **MCP configuration** section, add:

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

4. Click **Save**.

> **Why is this needed?** The built-in GitHub MCP server uses a specially scoped token that only has read-only access. The repo-level MCP configuration overrides this with the write-enabled endpoint (`https://api.githubcopilot.com/mcp/` without the `/readonly` suffix). The key must be `"github-mcp-server"` to override the built-in server. No personal access token is required — the cloud agent provides its own scoped token automatically.

> **Why can't agent frontmatter handle this?** The `mcp-servers` block in `.agent.md` files configures which MCP tools the agent can use and the endpoint URL, but it does not change the token scope granted by the platform. The repo-level config is what actually grants write permissions.

## (Optional) Customise for Your Language

`.github/workflows/copilot-setup-steps.yml` ships with the template and is already on `main` — no action needed for the default setup.

If your project requires specific language tooling (Node.js, Python, etc.), open the file, uncomment the example block matching your stack, and push the change to `main`. Any tools installed here are available in all subsequent agent sessions.

> The Copilot cloud agent only reads this file from the default branch (`main`). Changes on feature branches are ignored.

## Troubleshooting

**Agent returns `403 Resource not accessible by integration` when updating issues:**
The repo-level MCP configuration is missing or incorrect. Follow the "Required" setup steps above. This is the most common issue — the `mcp-servers` frontmatter in agent files is not sufficient on its own.

**Agent says "GitHub issue creation failed" or "mcp_github_issue_write not found":**
Same root cause — the MCP server is still in read-only mode. Configure write access via Settings → Copilot → Cloud agent.

**Agent sees `github-mcp-server-issue_read` but no write tools:**
The built-in MCP server is read-only. Verify the repo-level MCP configuration is set correctly.

To confirm the setup file is valid, run it manually: **Actions → Copilot Setup Steps → Run workflow**. It should complete without errors.
