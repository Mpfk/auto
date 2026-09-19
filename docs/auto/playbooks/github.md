# GitHub capability contract

Contract: `AUTO-GITHUB-v1`

## Inputs

- Repository identity discovered from `git remote get-url origin`.
- The GitHub operations required by the active phase.
- Available local and host-provided transports.

## Outputs

- Verified GitHub state or a completed GitHub mutation.
- A transport-neutral result that phase playbooks can consume.

## Required capabilities

Phases may require issue and PR reads/writes, comments and labels, review
threads, check and workflow status, branch/ref operations, and merge status.
Test capability, not a provider name.

Prefer authenticated `gh` locally. When `gh` is missing or unauthenticated,
use host-provided GitHub tools that expose the needed capability. Git and the
Auto state machine remain unchanged. Never treat one transport's absence as a
blocker when the other can complete the operation.

If neither route can perform a required operation, stop with the failed
capability and exact setup guidance: authenticate `gh auth login` locally, or
connect/install the host's GitHub integration for the target repository with
the required Issues, pull-request, checks, and contents permissions.

## State transitions

GitHub mutations implement the phase transition requested by another playbook;
this contract does not invent transitions.

## Stopping conditions

Stop on ambiguous repository identity, insufficient permissions, stale state,
or absence of both transports. Re-read state after every consequential write.

## Gate authority

GitHub access does not grant gate authority. Apply `core.md` even when a tool
can merge, label, close, or otherwise mutate the repository without prompting.

