# Optional Codex GitHub Action

Auto does not enable a Codex Action or require an OpenAI secret. Teams that want
an opt-in CI review can add their own workflow using the checked-in prompt and
schema assets.

The secure shape is two jobs:

1. A read-only Codex job receives `OPENAI_API_KEY`, checks out untrusted
   repository code, and writes a schema-constrained result artifact. It has no
   GitHub write permission.
2. A separate publisher job has GitHub issue/PR write permission but no OpenAI
   API key. It treats the JSON as data, never executes it, and publishes a
   normalized review record.

```yaml
name: Optional Codex review

on:
  workflow_dispatch:
    inputs:
      issue_number:
        description: Issue that receives the normalized review record
        required: true
      ref:
        description: Immutable commit SHA to review
        required: true

jobs:
  review:
    permissions:
      contents: read
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ inputs.ref }}
          persist-credentials: false
      - uses: openai/codex-action@v1
        with:
          openai-api-key: ${{ secrets.OPENAI_API_KEY }}
          prompt-file: .github/codex/prompts/review.md
          output-schema-file: .github/codex/schemas/review-result.json
          output-file: codex-review.json
      - uses: actions/upload-artifact@v4
        with:
          name: codex-review
          path: codex-review.json

  publish:
    needs: review
    permissions:
      contents: read
      issues: write
      pull-requests: write
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: codex-review
      - name: Publish normalized result
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          verdict=$(jq -r '.verdict' codex-review.json)
          provider=$(jq -r '.provider' codex-review.json)
          head=$(jq -r '.reviewed_head_sha' codex-review.json)
          printf '## Review: %s\n- Provider: `%s`\n- Reviewed head SHA: `%s`\n- Preflight: `PENDING`\n' \
            "$verdict" "$provider" "$head" > review-comment.md
          gh issue comment "${{ inputs.issue_number }}" --body-file review-comment.md
```

Adapt the trigger and issue lookup to your repository. Run
`bin/auto-review-preflight` before changing `Preflight` to `PASS`; never let the
model output choose shell commands or receive the publisher token. For current
inputs and hardening guidance, see the official
[Codex GitHub Action documentation](https://learn.chatgpt.com/docs/github-action)
and [non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode).
