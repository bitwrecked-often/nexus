# Phase 1A Unchecked-Semantic Relocation — First-Load Result

Date: 2026-08-20  
Decision: Placement-path proof PASS; full relocation acceptance FAIL/NO-GO

The owner authorized the unchecked-semantic first-load launch. The exact
reviewed probe loaded, initialized, and created the approved local single-player
Navezgane target. The player reported spawning and exited normally without
intentional changes.

Sanitized runtime evidence contains exactly:

```text
[HRS-P1A-RELOC] v=0.0.1 build=b14 reason=RELOC_READY
[HRS-P1A-RELOC] v=0.0.1 build=b14 reason=RELOC_PLACEMENT_CALLED
[HRS-P1A-RELOC] v=0.0.1 build=b14 reason=RELOC_VERIFICATION_FAILED
```

This proves reservation/selection, semantic-before capture, and the one virtual
`SetPosition` call completed without throwing. It also proves the bounded
post-placement predicate did not become fully true by tick 120. No
`RELOC_SEMANTIC_CHANGED` or `RELOC_SEMANTIC_UNCHANGED` reason exists, so the
failure occurred before semantic-after comparison. The marker remains Reserved,
and the target must not be retried.

Post-close aggregate evidence was captured at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\phase1a-unchecked-semantic-post-verification-failed-2026-08-20.json`

All protected aggregates equal the pre-launch baseline:

| Protected tree | Result | SHA-256 |
| --- | --- | --- |
| Game managed | unchanged | `2EA9679D59A7DC759DC4F582A6673B0F2106CE475DA4F7FF998DE907BFCD5C4C` |
| Foreign Mods | unchanged | `B56FE9701B98231617DBED2431865CA077AF4B84105C26388496A336D056BD51` |
| Foreign saves | unchanged | `CE3564E1E1BB04F8348A1570D36CA8302641ABCA2EFE509A495C5366FAC1C23D` |

The failed target has 74 files, 19,295,384 bytes, and aggregate
`59C0B7CFD04F35449D243AF33FD54090BB48597619CDAF4000161C69172FF866`.
No identities, coordinates, filenames, or underlying semantic values were
published.

Read-only analysis is required to distinguish chunk-readiness timing, safety,
position tolerance, entity/world continuity, and environment guard failure
without weakening acceptance conditions blindly.
