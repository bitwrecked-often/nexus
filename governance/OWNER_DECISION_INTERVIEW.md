# Owner Decision Interview

## Purpose

This is the durable decision log for shaping the `4.1.0` Nexus mod infrastructure. The interview proceeds one yes/no question at a time. Each recorded answer governs the next question.

Target: reach at least 85% shape awareness before implementation begins. Shape awareness means the product editions, authority boundaries, support claims, state-changing behavior, artifact policy, and release path are sufficiently decided to prevent an AI from filling material gaps by inference.

## Interview Rules

- Ask exactly one materially useful yes/no question at a time.
- Prefer the question with the highest effect on downstream architecture.
- Record the owner's answer and its implementation consequence before asking the next question.
- Preserve decision chain of custody: originating observation, governing ideal, owner answer, rationale or qualification, downstream consequence, and superseding decision if one later changes it.
- If an answer is qualified, record the qualification without forcing a false binary interpretation.
- Do not treat an unanswered question as consent.
- Do not begin dependent implementation while its decision remains open.
- Keep questions short, plain, and free of hidden compound choices.
- At the end, record remaining unknowns and the basis for the 85% threshold assessment.

## Status

- Interview state: active
- Shape awareness: not yet assessed
- Current question: Q2
- Implementation authority: not granted by this interview alone
- Nexus publication authority: not granted

## Decisions

### Q1 — No-Scripts Product Outcome

Question:

> Should the scanner-friendly no-scripts Nexus download produce a meaningful tuning change by default, rather than install the vanilla baseline/template?

Answer: yes

Owner qualification:

> Keep the chain of custody for ideals in the logs so people can see how the project was made and use it as easy research for making their own work.

Originating observation:

- The current no-scripts/modlet-only XML reasserts the documented vanilla baseline and therefore has no intended tuning effect on the matching game baseline.
- The archive is presented as an animal population tuning product.

Governing ideals:

- A public artifact must produce its advertised outcome.
- Show the work so another person can understand, reproduce, critique, or adapt the method.
- Preserve why a decision was made, not only its final wording.

Decision consequence:

- The `4.1.0` scanner-friendly main download must deliver an observable, intentionally selected tuning outcome.
- It must not be shipped as a vanilla no-op while presented as active tuning.
- The exact preset shape and values remain undecided and require subsequent owner answers and field evidence.
- Release evidence must link this decision to implementation, tests, packaged files, and user-facing wording.

Decision state: accepted; dependent design remains open

### Q2 — No-Scripts Choice Without Code

Question:

> Should the no-scripts download give users multiple clearly labeled preset choices, instead of one fixed tuning preset?

Answer: pending

Consequence: pending

## Decision Chain-Of-Custody Standard

Each accepted decision must retain:

```text
Decision ID
Question
Originating observation or field evidence
Governing ideal
Owner answer
Owner rationale or qualification
Implementation consequence
Tests/evidence required
Files/releases affected
Decision state
Supersedes / superseded by
```

Keep this record concise enough to read and complete enough to reconstruct the design path. Link to detailed test or incident evidence rather than copying raw logs. Never include private tester identities, machine details, or conversation material unrelated to the decision.

## Routing

Future AIs must read this file after `PROJECT_MANIFEST.md` and `NEXT_AI_DEEP_REPO_AUDIT_ADDENDUM.md`, before selecting implementation work or asking the owner to repeat a recorded decision.
