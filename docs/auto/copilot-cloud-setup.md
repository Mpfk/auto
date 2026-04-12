# Using Auto with GitHub Copilot Cloud Agent

No authentication setup is required. The Copilot cloud agent provides its own token with the permissions needed to create issues, manage branches, and open pull requests in the repository it is working in.

The only setup you may need is language tooling — if your project requires specific runtimes or dependencies to be pre-installed.

## (Optional) Customise for Your Language

`.github/workflows/copilot-setup-steps.yml` ships with the template and is already on `main` — no action needed for the default setup.

If your project requires specific language tooling (Node.js, Python, etc.), open the file, uncomment the example block matching your stack, and push the change to `main`. Any tools installed here are available in all subsequent agent sessions.

> The Copilot cloud agent only reads this file from the default branch (`main`). Changes on feature branches are ignored.

## Troubleshooting

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