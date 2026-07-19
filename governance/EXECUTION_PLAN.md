# 4.1.0 Execution Plan

## Purpose

This is the short, current route for preparing the `4.1.0` baseline. It keeps day-to-day work understandable without replacing the project manifest, owner decision record, audit addendum, or detailed work packet.

The live session planner is the sandboxed working copy. This file is its durable repository mirror so another AI or maintainer can resume from evidence instead of conversational memory.

## Operating Rules

- Keep no more than one phase `Active`.
- Update this file and the live planner together at phase boundaries or when a material blocker changes the route.
- Record outcomes, evidence paths, and commits; link detailed logs instead of copying them here.
- Use established policy for reversible engineering mechanics. Escalate only product behavior, rights, public identity, publication, irreversible state, or accepted release risk.
- Preserve the QA-frozen solution behavior and the immutable `4.0.1` artifacts.
- A completed planning phase does not authorize a build, tag, GitHub Release, Nexus upload, or archival of an existing Nexus file.

Status meanings:

- `Complete` — pass gate met and durable evidence exists.
- `Active` — the single current body of work.
- `Pending` — ordered work that must not start before its dependencies pass.
- `Blocked` — cannot advance without identified evidence, authority, or an external result.

## Current Route

| ID | Phase | Status | Required output | Pass gate |
| --- | --- | --- | --- | --- |
| P0 | Establish owner-level product shape and release boundaries | Complete | Recorded scope, package allowlist, identity, GPL, staging, retention, and authority decisions | `OWNER_DECISION_INTERVIEW.md` is closed for primary-baseline preparation and no material owner question remains open for P1 |
| P1 | Fingerprint the frozen baseline and reconcile current truth | Complete | Per-file SHA-256 baseline record, document-authority map, version/identity map, and contradiction register | Baseline is recorded before any solution-file edit; historical ZIP hashes still match; contradictions are resolved or explicitly bounded |
| P2 | Implement non-behavioral release infrastructure | Complete | Approved documentation/metadata alignment, exact edition allowlists, ignored staging, non-mutating validation, evidence templates, and proportionate repository-health controls | Offline checks pass; package behavior is unchanged; historical artifacts remain byte-identical; optional editions cannot borrow unsupported claims |
| P3 | Present release-readiness review | Complete | One concise owner-facing report of guarantees, evidence, deferred live checks, blockers, and exact proposed candidate contents | Planning set agrees across player, vendor/support, and machine-readable views; remaining owner gates are explicit; owner accepts the planning set |
| P4 | Build and promote one `4.1.0` candidate | Active | One validated candidate promoted to the ignored `final-upload` stage with external checksum, inventory, provenance, and acceptance evidence | Owner accepts the planning gate; exact candidate passes every applicable check; publication remains separately authorized |

## Gate Register

| Gate | Current handling |
| --- | --- |
| Frozen baseline fingerprint | Satisfied by `evidence/baselines/7dtd_wasteland_animal_population_tuning/4.1.0/`; all 32 raw Git blobs validate |
| Primary casual-player ZIP | Governed by the accepted eight-file allowlist; no candidate exists yet |
| No-scripts edition outcome | A meaningful outcome is required; if that cannot be supplied without changing the frozen payload, block or defer that optional edition rather than inventing values or claims |
| Vortex edition | Requires install-through-removal evidence from the exact candidate before it can carry support claims |
| Root/governance document license scope | Remains a separate rights decision; the primary README and changelog decision does not silently answer it |
| GitHub settings and live service state | Must be recorded from actual service evidence when relevant; committed policy is not proof of enforcement |
| Candidate build and promotion | Owner authorized one technical-only P4 `PreparePrimary` cycle; no candidate has been built or promoted yet |
| Tag, GitHub Release, Nexus upload, or prior-file archival | Requires explicit owner authorization for each applicable public action |

## Durable Update Record

Append only concise phase transitions here. Detailed governance changes remain in `governance/CHANGELOG.md`.

| Date | Transition | Evidence |
| --- | --- | --- |
| 2026-07-12 | Planner established; P0 closed and P1 made active | `governance/OWNER_DECISION_INTERVIEW.md`; initial planner commit |
| 2026-07-12 | P1 completed; P2 made active | `governance/REPOSITORY_TRUTH_MAP.md`; tracked baseline record and 32-file SHA-256 manifest |
| 2026-07-12 | P2 completed; P3 made active | Commit `789f7c8`; full offline gate `25 passed, 0 failed`; `governance/RELEASE_READINESS_4.1.0.md` |
| 2026-07-13 | Owner accepted P3; P4 made active | `governance/RELEASE_READINESS_4.1.0.md`; one technical-only `PreparePrimary` cycle authorized; no public action authorized |

## Routing And Precedence

Use this file to choose the next phase, then use the governing documents for the work itself. If this route conflicts with current evidence or authority, the precedence rules in `NEXT_AI_DEEP_REPO_AUDIT_ADDENDUM.md` win. Record and correct the planner mismatch; do not silently harmonize it.
