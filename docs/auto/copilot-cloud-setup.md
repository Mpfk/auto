# Using Auto with GitHub Copilot Cloud Agent

## GitHub MCP Server Write Access

The built-in GitHub MCP server in the cloud agent is **read-only by default**. This means agents can read issues but cannot create or update them, create branches, or open pull requests.

**Auto's custom agents (issue, orchestrator) ship with `mcp-servers` frontmatter that overrides the built-in read-only server with write access at `https://api.githubcopilot.com/mcp/`.** Repos created from this template get write-enabled GitHub tools automatically when using the `@issue` or `@orchestrator` agents — no manual repo setup needed.

### If you're NOT using the custom agents

If you use the default **Copilot** agent (not `@issue` or `@orchestrator`), it won't have the MCP override. You can add write access repo-wide:

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

> **Why `https://api.githubcopilot.com/mcp/`?** The write-enabled endpoint (without `/readonly` suffix) provides create and update permissions. The `X-MCP-Toolsets` header controls which toolsets are available. The key must be `"github-mcp-server"` to override the built-in server.
>
> No personal access token is required — the cloud agent provides its own scoped token automatically.

## (Optional) Customise for Your Language

`.github/workflows/copilot-setup-steps.yml` ships with the template and is already on `main` — no action needed for the default setup.

If your project requires specific language tooling (Node.js, Python, etc.), open the file, uncomment the example block matching your stack, and push the change to `main`. Any tools installed here are available in all subsequent agent sessions.

> The Copilot cloud agent only reads this file from the default branch (`main`). Changes on feature branches are ignored.

## Troubleshooting

**Agent says "GitHub issue creation failed" or "mcp_github_issue_write not found":**
The MCP server is still in read-only mode. Follow the "Required" section above to configure write access.

**Agent sees `github-mcp-server-issue_read` but no write tools:**
The built-in MCP server is read-only. Verify that agents have the `mcp-servers` frontmatter override pointing to `https://api.githubcopilot.com/mcp/` with key `github-mcp-server`.

To confirm the setup file is valid, run it manually: **Actions → Copilot Setup Steps → Run workflow**. It should complete without errors.

If an agent fails with a `gh` authentication error despite no PAT being required, this likely means the repository's GitHub Actions settings are restricting the default token permissions. Check **Settings → Actions → General → Workflow permissions** and ensure **Read and write permissions** is selected.

## Native Automation Workflows

This template now includes GitHub-native automation workflows:

- `.github/workflows/issue-state-guard.yml` normalizes and validates status labels.
- `.github/workflows/issue-native-automation.yml` reacts to issue labels, assignment, and slash commands.
- `.github/workflows/pr-issue-sync.yml` syncs issue status from PR lifecycle events.

These workflows are event-driven and run in standard GitHub Actions. They complement, not replace, Copilot cloud setup steps.

For repository guardrails:

- The `Repo Setup` workflow runs automatically on every push to `main`.
- It syncs labels and applies branch protection using `GITHUB_TOKEN` — no additional secrets required.
- To trigger manually: GitHub Actions → `Repo Setup` → `Run workflow`.