#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
POLICY_WORKFLOW="$REPO_ROOT/.github/workflows/workflow-policy.yml"

setup() {
  command -v node >/dev/null || skip "Node.js is required for workflow policy tests"
}

# The workflow script is a YAML block scalar under `script: |` with 12-space
# indentation. The first non-empty line indented to 6 spaces is outside that
# block and marks the end of the extracted script.
extract_script() {
  awk '
    /script: \|/ { in_script = 1; next }
    in_script {
      if ($0 ~ /^      [^ ]/) exit
      if ($0 ~ /^            /) {
        sub(/^            /, "", $0)
        print
      } else {
        print ""
      }
    }
  ' "$POLICY_WORKFLOW"
}

run_policy() {
  local pr_json="$1"
  local issue_json="$2"
  local script
  script="$(extract_script)"

  run env WORKFLOW_SCRIPT="$script" PR_JSON="$pr_json" ISSUE_JSON="$issue_json" node <<'NODE'
const script = process.env.WORKFLOW_SCRIPT;
const pr = JSON.parse(process.env.PR_JSON);
const issue = JSON.parse(process.env.ISSUE_JSON);

const context = {
  repo: { owner: 'Mpfk', repo: 'auto' },
  payload: { pull_request: pr },
};

const github = {
  rest: {
    issues: {
      get: async ({ issue_number }) => {
        if (!issue || issue.number !== issue_number) {
          throw new Error('Not Found');
        }
        return { data: issue };
      },
    },
  },
};

let failed = null;
let info = null;
const core = {
  setFailed: (message) => {
    failed = message;
  },
  info: (message) => {
    info = message;
  },
};

(async () => {
  // This evaluates repository-controlled workflow code so tests can validate
  // real policy behavior from the workflow file itself.
  // Do not reuse this pattern with untrusted/external input.
  const fn = new Function('context', 'github', 'core', `return (async () => {\n${script}\n})();`);
  await fn(context, github, core);
  process.stdout.write(JSON.stringify({ failed, info }));
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
NODE
}

@test "workflow-policy: issue/{N} branch passes without explicit closing text" {
  run_policy '{"head":{"ref":"issue/67"},"title":"feat: branch-linked PR","body":"","draft":true}' '{"number":67,"labels":[]}'

  [ "$status" -eq 0 ]
  [[ "$output" == *'"failed":null'* ]]
  [[ "$output" == *'"info":"Workflow policy checks passed for issue #67 (branch: issue/67)."'* ]]
}

@test "workflow-policy: non-issue branch passes with valid closing keyword reference" {
  run_policy '{"head":{"ref":"copilot/add-policy-update"},"title":"fix: relax policy","body":"fIxEs #67","draft":true}' '{"number":67,"labels":[]}'

  [ "$status" -eq 0 ]
  [[ "$output" == *'"failed":null'* ]]
}

@test "workflow-policy: non-issue branch passes with resolves keyword reference" {
  run_policy '{"head":{"ref":"copilot/add-policy-update"},"title":"fix: relax policy","body":"Resolves #67","draft":true}' '{"number":67,"labels":[]}'

  [ "$status" -eq 0 ]
  [[ "$output" == *'"failed":null'* ]]
}

@test "workflow-policy: non-issue branch without linkage fails with actionable guidance" {
  run_policy '{"head":{"ref":"copilot/add-policy-update"},"title":"fix: relax policy","body":"No issue linkage","draft":true}' '{"number":67,"labels":[]}'

  [ "$status" -eq 0 ]
  [[ "$output" == *'"failed":"PR must either use an issue/{number} branch or include a valid issue-closing reference'* ]]
}

@test "workflow-policy: ready-for-review PR still requires linked issue in status/review" {
  run_policy '{"head":{"ref":"copilot/add-policy-update"},"title":"fix: relax policy","body":"Closes #67","draft":false}' '{"number":67,"labels":[]}'

  [ "$status" -eq 0 ]
  [[ "$output" == *'"failed":"PR cannot be ready-for-review unless linked issue #67 is status/review."'* ]]
}

@test "workflow-policy: issue/{N} ready-for-review PR still requires status/review" {
  run_policy '{"head":{"ref":"issue/67"},"title":"fix: relax policy","body":"","draft":false}' '{"number":67,"labels":[]}'

  [ "$status" -eq 0 ]
  [[ "$output" == *'"failed":"PR cannot be ready-for-review unless linked issue #67 is status/review."'* ]]
}
