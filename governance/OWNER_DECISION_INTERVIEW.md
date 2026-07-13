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
- Current question: Q4
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

Answer: yes

Originating observation:

- A single fixed preset would make the download useful but would choose one play style for every no-scripts user.
- The no-scripts edition cannot use interactive controls to personalize XML after download.

Governing ideals:

- Meaningful behavior should not remove player choice.
- Scanner-friendly packaging should remain readable and code-free.
- Choices must be understandable before files are copied.

Decision consequence:

- The no-scripts product will provide multiple clearly labeled tuning presets.
- Every preset must state its intended effect, exact payload identity, install path, compatibility evidence, conflicts, and removal path.
- Presets must be mutually exclusive unless a future composition model is explicitly designed and tested.
- Packaging must prevent or clearly detect accidental simultaneous installation of conflicting presets.
- Exact preset count, values, names, and archive layout remain open.

Decision state: accepted; packaging shape remains open

### Q3 — One Download Or Separate Downloads

Question:

> Should all no-scripts presets be bundled into one Nexus download, rather than published as separate downloadable files?

Answer: yes

Owner qualification:

> The bundled presets can also give modders something to attach as a pipeline for feature sets.

Originating observation:

- Separate downloads fragment discovery, versioning, documentation, and chain of custody.
- A single code-free bundle can expose several readable XML outcomes and their derivation in one reviewed artifact.

Governing ideals:

- Keep the customer choice simple while making the underlying method reusable research.
- Treat presets as transparent feature-set definitions, not opaque finished blobs.
- Preserve one versioned evidence chain across player and modder uses.

Decision consequence:

- Publish the no-scripts preset collection as one versioned Nexus download.
- Give every preset a stable ID, readable name, exact effect, source definition, generated payload, and evidence link.
- Include a player-facing selection/install layer and a separate modder-facing feature-set/index layer in the same artifact.
- The modder layer must explain how preset definitions flow into generated XML without requiring reverse engineering.
- Validation must prove that documentation and generated payloads correspond to the same preset definitions.
- The bundle must avoid making a user install every preset at once.

Decision state: accepted; composition rules remain open

### Q4 — Player Preset Exclusivity

Question:

> Should ordinary players install exactly one preset at a time, even though modders may reuse preset definitions in broader feature-set pipelines?

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
