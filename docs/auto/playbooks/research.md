# Research contract

Contract: `AUTO-RESEARCH-v1`

## Inputs

- Issue number, exactly one strategy (`codebase`, `docs`, `external`, or
  `constraints`), scope hints, and the latest retrospective if one exists.

## Outputs

- Structured key findings with evidence, actionable recommendations, open
  questions, and a confidence assessment.

## State transitions

Research contributes to `status/researching` and planning. It does not change
workflow state by itself.

## Stopping conditions

Stop when issue number or strategy is missing. Stay read-only and say when the
assigned angle yields no relevant evidence. Do not repeat a failed approach
documented in the latest retrospective.

## Gate authority

Research has no gate authority. Its evidence informs Gate 1.

