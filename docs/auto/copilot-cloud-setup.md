# Using Auto with GitHub Copilot Cloud Agent

When running this workflow via the GitHub Copilot cloud agent (GitHub Agents on the web), three one-time setup steps are required before the agents can create issues, manage branches, and write pull requests.

## Why This Is Needed

The Copilot cloud agent runs in an ephemeral GitHub Actions environment. By default it only has a scoped `GITHUB_TOKEN`. The `gh` CLI calls made by the Orchestrator, TDD, and Review agents need write access to Issues, Pull Requests, and repository Contents — permissions that require a personal access token passed as `GH_TOKEN`.

The `copilot-setup-steps.yml` workflow tells the cloud agent what tooling to install before starting work. Without it, the environment starts cold with no guarantees about installed tools.

## Step 1 — Create the `copilot` Actions Environment

1. Go to your repository on GitHub
2. Navigate to **Settings → Environments**
3. Click **New environment** and name it exactly: `copilot`
4. Click **Configure environment**

> The environment name must be exactly `copilot` — this is the name GitHub Copilot cloud agent looks for when injecting secrets into its runtime shell.

## Step 2 — Create a Fine-Grained Personal Access Token

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens**
2. Click **Generate new token**
3. Set **Resource owner** to the account or organisation that owns this repo
4. Under **Repository access**, select **Only select repositories** and choose this repo
5. Under **Permissions**, grant:
   - **Issues** → Read and write
   - **Pull requests** → Read and write
   - **Contents** → Read and write
6. Generate and copy the token

## Step 3 — Add `GH_TOKEN` to the `copilot` Environment

1. Return to **Settings → Environments → copilot**
2. Under **Environment secrets**, click **Add secret**
3. Name: `GH_TOKEN`
4. Value: paste the fine-grained PAT from Step 2
5. Click **Add secret**

The `gh` CLI automatically reads `GH_TOKEN` from the environment — no `gh auth login` step is needed anywhere in the agent code.

## (Optional) Customise for Your Language

`.github/workflows/copilot-setup-steps.yml` ships with the template and is already on `main` — no action needed for the default setup.

If your project requires specific language tooling (Node.js, Python, etc.), open the file, uncomment the example block matching your stack, and push the change to `main`. Any tools installed here are available in all subsequent agent sessions.

> The Copilot cloud agent only reads this file from the default branch (`main`). Changes on feature branches are ignored.

## Troubleshooting

If agents fail with permission errors, verify:
- The `copilot` Actions environment exists under **Settings → Environments**
- `GH_TOKEN` is set as an environment secret inside it

To confirm the setup file itself is valid, run it manually: **Actions → Copilot Setup Steps → Run workflow**. It should complete without errors.

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