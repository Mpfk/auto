# Documentation contract

Contract: `AUTO-DOCUMENT-v1`

## Inputs

- Issue, branch, implemented-change summary, and changed source/configuration
  paths.

## Outputs

- Concise user, API, architecture, or decision documentation proportional to
  the change, with setup changes reflected in `README.md` where needed.
- No low-value document when the change is purely internal and needs none.

## State transitions

Documentation runs alongside development and must finish before review PASS. It
does not change the issue status independently.

## Stopping conditions

Stop when required context is missing, implementation is not yet concrete, or
documentation would be empty. Fail placement checks for Markdown outside the
approved locations in `core.md`.

## Gate authority

Documentation has no gate authority. Missing required docs blocks review.

