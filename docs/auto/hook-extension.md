# Hook Extension Convention

Auto ships git hooks as a plugin system. Each hook type (pre-commit, commit-msg, pre-push) has a dispatcher script and a corresponding `.d/` directory of numbered shell scripts. The dispatcher runs every executable `*.sh` in lexical order, stopping on the first non-zero exit.

## Dispatcher pattern

`.githooks/pre-commit` (representative — commit-msg and pre-push follow the same pattern):

```bash
#!/bin/bash
# Dispatcher: runs all executable scripts in pre-commit.d/
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)/pre-commit.d"
if [ -d "$HOOK_DIR" ]; then
  for hook in "$HOOK_DIR"/*.sh; do
    [ -x "$hook" ] || continue
    "$hook"
    status=$?
    if [ $status -ne 0 ]; then
      exit $status
    fi
  done
fi
exit 0
```

Scripts run in shell lexical order (`010-…` before `020-…` before `100-…`), so the number prefix controls execution order.

## Number-range reservation

| Range | Owner | Behavior |
|-------|-------|----------|
| `000`–`099` | Auto framework | The sync updater may overwrite these files on framework updates. |
| `100`+ | Consumer repo | The updater never touches these files. They run after all Auto scripts. |

Auto's built-in scripts currently occupy the `010`–`030` range. The full `000`–`099` band is reserved so future Auto scripts can be inserted without conflicting with consumer hooks.

## Adding a consumer hook

1. Create your script in the appropriate `.d/` directory with a name starting at `100`:

   ```bash
   # .githooks/pre-commit.d/100-my-lint.sh
   #!/bin/bash
   npm run lint --silent
   ```

2. Make it executable:

   ```bash
   chmod +x .githooks/pre-commit.d/100-my-lint.sh
   ```

3. Commit it to your repo. It will run after all Auto guards on every commit.

Consumer scripts receive the same arguments as the dispatcher (for commit-msg hooks, `$1` is the commit message file path).

## Surviving framework updates

Auto's sync updater respects the `100+` range — it will never create, overwrite, or delete files with a `1xx` or higher prefix. Your consumer hooks survive every framework update automatically.

If you use `.autosyncignore` (see issue #88 / #91) you can protect additional specific files from being overwritten, including scripts in the `000`–`099` range that you have intentionally customized.

## Summary

- **Add consumer hooks at `100+`.** They run last and are never overwritten by Auto.
- **Leave `000`–`099` to Auto.** Framework updates may modify those files.
- **Always `chmod +x` new scripts** — the dispatcher skips non-executable files silently.
