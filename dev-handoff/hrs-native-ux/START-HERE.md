# HRS native UX DEV handoff

Prepared **2026-10-04**. Paperwork revision **1**. Owner: **Bit Wrecked**.

This packet prepares the next native manager revision. It contains the reviewed design, implementation requirements, copy and QA recipe. DEV starts from the current source, integrates the work, creates a new candidate and returns it for independent QA. The product remains Historical Random Start; this work preserves its gameplay policy and known trader-session boundary.

## Read and implement

| Document | Purpose |
| --- | --- |
| [Native UX doctrine](../../HRS_NATIVE_UX_DOCTRINE.md) | Durable design rules, recipe values and source guidance |
| [Next DEV manifest](../../HRS_NATIVE_UX_NEXT_DEV_MANIFEST.md) | Concrete requirements, implementation order and return checklist |
| [UI copy contract](UI-COPY-CONTRACT.md) | Labels, confirmations, conditional fallback and truthful error/recovery wording |
| [Newcomer usability checklist](NEWCOMER-USABILITY-CHECKLIST.md) | Small human review of setup, comprehension and recovery |
| [QA harness manifest](../../HRS_QA_HARNESS_ARCHITECTURE_MANIFEST.md) | Assisted replay, evidence and operator gameplay handoff |
| [Prototype record](../../prototypes/hrs-1.2.6-compact-header/preview-summary.json) | Revision14 source, decisions, captures and qualification scope |
| [Original QA review](../../QA-REVIEW-1.2.6-qa.002.md) | Three sizing failures and the frozen candidate's evidence |

## External copy to integrate

| Draft | Destination |
| --- | --- |
| [Customer README](external/README-DRAFT.md) | New candidate's customer README, after checking delivered behavior |
| [Release notes](external/RELEASE-NOTES-DRAFT.md) | Returning release's notes |
| [Nexus and project-site copy](external/NEXUS-LISTING-DRAFT.md) | Listing fields and optional site metadata |
| [Known issue](external/KNOWN-ISSUE-DRAFT.md) | Matching public notice and support response |

The drafts describe the intended delivery. DEV must reconcile them with the implementation returned to QA. Keep planned changes out of a published description until they exist and have the required evidence. Final release version, candidate ID, tested build, customer archive identity and release decision remain pending; record them in the return packet. Optional project-site fields apply only when an actual site is available.

## Start work

1. Locate the upstream recipe, native controls and generator; use the prototype diff as a review reference.
2. Implement the manifest requirements, including reachable help, explicit state, selection radios, guarded operations and geometry fixes.
3. Integrate the copy contract and external drafts; remove manual Restore descriptions from the new customer materials.
4. Run focused component checks, the real customer-path acceptance matrix and the newcomer review. Keep fixture and live results distinct.
5. Export a newly identified candidate with current hashes, receipts, documentation and case definitions. Return unresolved checks and failures explicitly.

The original qa.002 archive and evidence remain preserved. This documentation packet is not a customer build or publication approval. See [handoff-manifest.json](handoff-manifest.json) for document identities and readiness fields.
