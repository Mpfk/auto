#!/usr/bin/env bash
# Opt-in Codex fixture smoke test. It never mutates a live GitHub repository.

set -euo pipefail

if [[ "${RUN_CODEX_E2E:-0}" != "1" ]]; then
  echo "SKIP: set RUN_CODEX_E2E=1 to run the ephemeral Codex fixture"
  exit 0
fi

command -v codex >/dev/null 2>&1 || { echo "FAIL: codex is not installed"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FIXTURE="$TMP/repo"
mkdir -p "$FIXTURE/bin"
git -C "$FIXTURE" init -q -b main
git -C "$FIXTURE" config user.name "Auto Fixture"
git -C "$FIXTURE" config user.email "auto@example.invalid"

cp "$ROOT/AGENTS.md" "$FIXTURE/AGENTS.md"
cp -R "$ROOT/.agents" "$FIXTURE/.agents"
mkdir -p "$FIXTURE/docs/auto"
cp -R "$ROOT/docs/auto/playbooks" "$FIXTURE/docs/auto/playbooks"

cat > "$FIXTURE/bin/gh" <<'SH'
#!/usr/bin/env bash
echo '{"stubbed":true,"args":"'$*'"}'
SH
chmod +x "$FIXTURE/bin/gh"

(cd "$FIXTURE" && PATH="$FIXTURE/bin:$PATH" codex exec --ephemeral \
  'Use $issue to explain the next state transition. Do not write files or contact a live repository.')

echo "PASS: ephemeral Codex fixture completed with stubbed GitHub transport"

