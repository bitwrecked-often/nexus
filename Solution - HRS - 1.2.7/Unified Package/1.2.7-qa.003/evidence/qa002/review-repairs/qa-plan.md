# 1.2.7 review repairs: independent QA plan

Prepared 2026-10-04. Target: **1.2.7-qa.002**, draft until the new build,
contracts and immutable export are qualified. No customer QA has run.

The updated draft contract preserves all **46 original case
IDs**, each still **Pending**. The previous qa.001 case bytes are retained in
before/cases.qa001.json, SHA-256
`A40341627EE4223DE55FFE0535AC410F0A9D5EB9C55DB50DAD27BE9702DF8EE8`.
The release owner will refresh the build/release contract separately. This plan
does not reuse qa.001 or any 1.2.6 customer archive as the repaired candidate.

## Explicit coverage without extra case IDs

| Case | Required customer observation |
| --- | --- |
| HRS-QA-001 | Apply an exact Game Name before its save exists; the policy persists without creating the save. Reopen the customer manager and verify that intent. On a manual-selection setup, retry a wrong game folder and cancel cleanly. |
| HRS-QA-003B | Reuse a previously generated supported Random Gen world of at least 8192 with a fresh Game Name/character. Record both distinct names and the active world's placed-POI identity. |
| HRS-QA-006 | Reload an HRS-completed character without a second landing. Separately enable Random for a previously played Standard character and verify position/quest preservation. |
| HRS-QA-011 | With policy for Game A, observe ordinary behavior in a fresh mismatched Game B. Also advance a pending opening quest on an HRS-completed Game B without applying Game A's cached trader route. |
| HRS-BIOME-POI_SAFETY_EXHAUSTED | Observe a naturally suitable fallback, preserving ordinary character state and marker semantics. Record whether movement began; failure before movement is not proof of restoration after movement. |
| HRS-UX-OPERATIONS | Retest operation guards and automatic file recovery; when a transient Launch blocker clears, current guidance refreshes while Game details retains the diagnostic. A failed Apply still requires a successful acknowledged Apply. |
| HRS-UX-NEWCOMER | Observe uncoached fresh-character setup, including preparation before a save exists and reuse of a generated world. Distinguish Game Name from world name. |

Preparing before a save exists and reusing an existing generated world do not
require deleting player files, resetting a character, editing a save or creating
a new multi-save policy mechanism. The installed Bridge still holds one active
exact-name policy. Use ordinary game controls and disposable fixtures.

The runtime repair addresses restoration arming before the first movement,
original world/entity identity during restoration, and exact-name/environment
guards on the opening-quest hook. The precise movement, observer, semantic-error
and replacement-world/entity fault injections remain **isolated DEV evidence**.
They do not pass independent customer cases. If a natural fallback fixture is
unavailable, record Blocked with the missing condition; do not alter the customer
DLL to make it pass. Preserve the disclosed early-logout trader limitation when
using an existing pending-quest fixture.

## Handoff order

1. Finish the narrow source repairs and their scoped DEV checks. Qualify the new
   runtime with the unchanged pinned b17 references/toolchain and preserve the
   original qa.001 build record and earlier receipts.
2. Refresh qa.002 release/build pins and the 46-case contract together. Verify
   source gate, embedded design and exact customer inputs.
3. Export qa.002 once to an unused destination, preserving its ZIP, receipt and
   engineering companion. Independently verify/extract the exact archive and
   smoke its own START entry before building the portable wrapper.
4. Prepare the isolated QA workspace, add review material outside customer and
   frozen context, then manifest/verify the complete portable transfer.
5. Run independent QA in the order in QA_RUNBOOK.md. Actual
   display, accessibility, native dialogs, newcomer and gameplay evidence remain
   required. Publish only the unchanged tested customer ZIP after approval.

## Portable transfer layout

Use a fresh wrapper folder such as `qa-127-002/`:

```text
qa-127-002/
  START-HERE.md
  PACKAGE-IDENTITY.json
  QA-REVIEW-CHECKLIST.md
  QA-WORKFLOW.md
  1.2.7-qa.002.zip
  1.2.7-qa.002.zip.receipt.json
  1.2.7-qa.002.zip.companion.zip
  customer/HistoricalRandomStart_1.2.7/   Exact customer extraction
  context/                             Frozen contracts/build/runtime sources
  tools/                               Frozen QA tools and registry snapshot
  review/                              Supporting DEV/design/review evidence
  transfer-manifest.json
```

The existing New-HrsQaWorkspace
performs authenticated extraction and supplies the frozen tools/registry:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\New-HrsQaWorkspace.ps1 -CandidateId 1.2.7-qa.002 -ArchivePath .\qa_cycle\candidates\1.2.7-qa.002.zip -Destination 'C:\HRS QA\qa-127-002'
```

This command is for the packaging phase after export. No archive currently
exists merely because this plan names it. Use a new destination and preserve
the customer ZIP's exact bytes throughout.

Carry the following under `review/`, separate from the customer archive:

- The final review findings/repair work record and scoped DEV verification
  receipts, including runtime fault-injection results and manager retry/guidance
  checks, with their actual source and DLL identities.
- This QA plan/runbook, lane manifest/readiness record, current public-copy draft
  and final native capture. Preserve the source scope of earlier captures.
- The setup foundation at `dev/BUILD_SETUP_FOUNDATION.md`, the reference/build
  receipt and the public-name metadata receipt plus `ModInfo.before.xml`. Include
  snapshots referenced by that receipt, or an explicit portable source map for
  retained historical-only references. Freeze their hashes in the transfer
  manifest. The metadata receipt currently lives at
  `dev/qa/public-name-20261004/metadata-change-verification.json`.
- The returned sizing-failure description and corresponding acceptance/checklist
  material, clearly marked as historical 1.2.6 evidence to be retested.

The standard companion contains only rel/cases/build/C# inputs. It does not
automatically carry the metadata receipt or foundation. If the exporter remains
unchanged, give those review copies explicit locations in START-HERE; do not
silently add files to the already-frozen `context/` manifest. Portable review
Markdown can replace repository-only links with a source map and an origin note.

The 1.2.6 `Build-NativeUxTransfer.ps1` is a useful pattern, **not an executable
1.2.7 recipe**: it hardcodes its lane, old evidence paths and release identity.
A new 1.2.7 wrapper must derive qa.002 identity from its own receipt/contract,
verify every manifested path/size/hash and independently extract the wrapper.
Use that extraction's own tools for the release gate and workspace assertion;
verify the nested customer SHA again against the original receipt. Keep wrapper
verification output outside the sealed wrapper to avoid changing its manifest.

Exclude game reference DLLs, the reference-only executable marker, SDK/compiler
files, generated tmp/out/bin/obj, manager state and local private session paths.
The customer path uses native Windows PowerShell/.NET Framework; QA requires no
new graphics application or downloaded helper.

## Environment boundary

Formal gameplay QA targets **7 Days to Die V3.3.0 b17**, local single-player,
EAC disabled and the supplied `0_TFP_Harmony`. Assembly-CSharp SHA-256 must be
`AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146`, MVID
`7c57b7de-39a1-497d-bf48-8d5d1d4a1ff1`; Harmony SHA-256 must be
`C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF`.
The current installed Assembly-CSharp fingerprint differs. The authenticated
offline reference root can build the candidate but cannot be played or certify
QA. Other game builds require separate qualification; never rewrite the pins to
turn a differing environment into a b17 Pass.
