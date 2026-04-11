# Using Auto with GitHub Copilot Cloud Agent

When running this workflow via the GitHub Copilot cloud agent (GitHub Agents on the web), two one-time setup steps are required before the agents can create issues, manage branches, and write pull requests.

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

## Step 4 — Merge `copilot-setup-steps.yml` to `main`

The Copilot cloud agent only reads `.github/workflows/copilot-setup-steps.yml` from the **default branch** (`main`). It ignores the file on feature branches.

After cloning this template:

1. Customise `.github/workflows/copilot-setup-steps.yml` for your project's language tooling (follow the commented examples in the file)
2. Merge the file to `main` via a pull request or direct commit before running the cloud agent for the first time

## Step 5 — Validate the Setup

You can verify the setup file is syntactically correct and the environment is wired up by running the workflow manually:

1. Go to **Actions → Copilot Setup Steps**
2. Click **Run workflow → Run workflow**
3. Confirm it completes without errors

If the job fails with a permissions error, double-check that the `copilot` environment exists and the `GH_TOKEN` secret is set.

## Customising for Your Language

Open `.github/workflows/copilot-setup-steps.yml` and uncomment the example block matching your stack, or add your own steps. The file ships with examples for Node.js and Python.

Any tools installed during setup steps are available in all subsequent agent sessions — no need to reinstall them per-session.

## Native Automation Workflows

This template now includes GitHub-native automation workflows:

- `.github/workflows/issue-state-guard.yml` normalizes and validates status labels.
- `.github/workflows/issue-native-automation.yml` reacts to issue labels, assignment, and slash commands.
- `.github/workflows/pr-issue-sync.yml` syncs issue status from PR lifecycle events.

These workflows are event-driven and run in standard GitHub Actions. They complement, not replace, Copilot cloud setup steps.

For repository guardrails:

- Run `Label Sync` once to seed status/type labels.
- Run `Branch Protection Bootstrap` once to require policy + test checks on `main`.
- Add repository secret `GH_ADMIN_TOKEN` (repo admin permissions) before running `Branch Protection Bootstrap`.