# HRS Landing Library Integration Manifest

Status: ACTIVE PLANNING AUTHORITY
Recovered/confirmed: 2026-09-04

## Doctrine

**We walk from here.**

Known ground -> one path -> one artifact -> evidence -> record it -> next step.

Do not make the next AI rediscover completed work.
Do not broaden into old versions, archive material, or unrelated repo areas unless this manifest explicitly requires it.
If a recorded path fails, stop and locate the artifact. Do not infer that it moved.
Prefer surgical integration changes over full-file rewrites.

## Active workspace

Active repository:
C:\Users\mobil\OneDrive\Documents\GitHub\QA_remote_current

Active build:
C:\Users\mobil\OneDrive\Documents\GitHub\QA_remote_current\hrs_1.2.1

Old rollback/evidence repository:
C:\Users\mobil\OneDrive\Documents\GitHub\QA

The old repository is evidence/reference and rollback material. Do not modify it as part of the current integration.

## Product transaction

Historical Random Start restores the classic random-start experience by using the game's underlying placement/teleport rails.

The working start transaction is:

random placement
-> approved landing
-> primed/double teleport and ground settle
-> determine destination zone
-> apply selected arrival-biome protection
-> redirect starter trader quest for the actual landing area
-> return player to normal progression

These mechanics already exist and have been separately exercised. Expansion of the landing library is an integration task, not permission to redesign the transaction.

## Accepted existing behavior

Treat the following as previously tested-good unless the landing-library integration creates a specific regression risk:

- Standard/Random UX flow
- carousel behavior
- individual zone passes
- native/random placement rail
- primed/double-teleport landing behavior
- ground-settle validation
- arrival-zone protection behavior
- starter trader quest redirection behavior
- curated landing-location QA methodology

Do not spend model or operator time re-proving these merely to rediscover them.

## Landing-library authority

The original 40-point carousel was an EARLY QA stage.

It is NOT the final approved landing library.

The full deterministic campaign expanded to NVG identifiers sourced from the Navezgane POI catalog.

Recovered canonical campaign handoff:

C:\Users\mobil\OneDrive\Documents\GitHub\QA\hrs_1.1.0\dev\evidence\carousel\HANDOFF_CATALOG.md

Important repository-state warning:

The active remote-derived hrs_1.2.1 tree references later carousel evidence under dev\evidence\carousel, but that evidence directory and HANDOFF_CATALOG.md are absent from the current hrs_1.2.1 clone.

Therefore the old hrs_1.1.0 HANDOFF_CATALOG.md is currently the recovered authority for final landing certification evidence. Preserve it. Do not substitute the 40-point catalog or provisional screening counts.

## FINAL CERTIFIED LANDING SET

**171 locations are final state-certified.**

Certified ranges:

- NVG-0281 through NVG-0443 active survivors: 161 points
- NVG-0446 through NVG-0455: 10 points
- TOTAL FINAL CERTIFIED: 171

Final certification evidence states:

- controlled enemy-free save
- God ON
- collision ON
- fly/noclip OFF
- player stationary
- health 100
- exact origin restoration
- first certification batch: 161/161 PASS
- second certification batch: 10/10 PASS
- combined certification: 171/171 PASS
- certification complete

The campaign handoff also records:

- screening passes: 422 provisional
- rejected points: 33
- active engine-eligible points: 712

Those numbers are NOT substitutes for the final certified library.

**Integration authority = the 171 state-certified points only.**

## Current production/integration state

The production proof currently uses only two known-good Snow-zone locations:

- NG01
- NG02

That two-location implementation proves the downstream pipeline.

The integration objective is now:

**Replace the two-location selector input with the 171 final state-certified landing locations while preserving the existing working downstream transaction.**

Do not build 171 bespoke paths.

Find the authoritative structure currently supplying NG01/NG02 and feed the certified library through that same rail/data shape.

## Source-of-truth chain

For every integration change, establish:

SOURCE OF TRUTH
-> CURRENTLY WIRED FILE
-> DEPLOYED RESULT

Record exact paths as they are discovered.

Do not infer equivalence between:
- generated POI catalog entries,
- provisional screening passes,
- engine-eligible points,
- early 40-point carousel entries,
- and final state-certified points.

Only the 171 final state-certified points are approved for this integration.

## Immediate next discovery

Locate the exact active hrs_1.2.1 source artifact that defines or supplies the current NG01/NG02 production landing set.

Determine:

1. exact authoritative file path;
2. current data structure/shape;
3. how the selector consumes it;
4. how biome/zone identity follows the selected destination;
5. smallest safe integration seam for replacing two inputs with the 171-point certified library.

Do not edit until this wiring is understood.

## Stop conditions

Stop rather than guess if:

- the recorded path does not exist;
- the 171 certified identities/coordinates cannot be derived from preserved authority;
- current NG01/NG02 wiring is ambiguous;
- an apparent change would redesign already accepted mechanics;
- source-of-truth and deployed artifact cannot be connected;
- evidence conflicts between versions.

When stopped, gather the smallest piece of evidence needed to continue and update this manifest.

## Seal-up requirement

Before release packaging, the 171-point certification authority must no longer depend solely on the old hrs_1.1.0 workspace.

The authoritative certified landing data and sufficient provenance must be carried into the active hrs_1.2.1/release lineage so a future maintainer or AI can reconstruct:

- exactly which 171 locations are approved;
- their stable IDs and required coordinates/metadata;
- the certification basis;
- the runtime artifact that consumes them;
- and the deployed result.

This is required to seal the full stack without losing its evidence chain.

## Discovered runtime landing-selector seam

Authoritative active source discovered:

C:\Users\mobil\OneDrive\Documents\GitHub\QA_remote_current\hrs_1.2.1\dev\src\runtime\main\c0213.cs

Class:
NavezganeStartCatalog

Landing record shape:

CuratedStartPoint
- Id
- Experience
- X
- Y
- Z

Current catalog:
Points[]

Current release gate:
ApprovedPointIndices[]

Current proof configuration:
ApprovedPointIndices = { 0, 1 }

Therefore NG01 and NG02 are not separate implementations. They are the only two catalog entries currently admitted through the release-approved selector gate.

Selection path:

ApprovedPointIndices
-> random approved slot
-> Points[pointIndex]
-> TryResolve()
-> candidate Vector3 + pointId

TryResolve() validates:
- active world is Navezgane
- point index is valid
- X/Z remain inside CoordinateLimit
- candidate is inside world bounds

It then emits:
Vector3(point.X, point.Y + 1f, point.Z)
and the stable point Id.

Integration implication:

The existing runtime is structurally designed for a pool of approved landing inputs.

Do NOT redesign the selector.

The expected integration seam is:
1. populate/identify the authoritative 171 certified CuratedStartPoint records;
2. admit exactly those certified records through the existing approved-pool mechanism;
3. preserve TrySelect(), TryResolve(), and downstream landing behavior unless later tracing proves a specific compatibility issue.

Known special case already observed:
GetSearchRadius("NG01") returns 8 rather than the default LandingSearchRadius of 32.

Do not generalize or remove that exception until the complete downstream landing path has been traced.

Next unanswered question:
Locate the exact authoritative source containing the 171 certified point IDs and their coordinates/metadata. Do not reconstruct the 171 manually if an authoritative campaign artifact exists.

## Recovered authoritative 171-point production input set

Final certification membership is derived directly from POINT_PASS events in these two controlled certification runs:

C:\Users\mobil\OneDrive\Documents\GitHub\QA\hrs_1.1.0\dev\evidence\carousel\2026-09-01_run_b5dc7a10_certification-161-pass_events.tsv

C:\Users\mobil\OneDrive\Documents\GitHub\QA\hrs_1.1.0\dev\evidence\carousel\2026-09-01_run_d9b93450_certification-10-pass_events.tsv

Mechanical extraction proved:

- certification batch 1: 161 POINT_PASS events
- certification batch 1 unique IDs: 161
- first ID: NVG-0281
- last ID: NVG-0443

- certification batch 2: 10 POINT_PASS events
- certification batch 2 unique IDs: 10
- first ID: NVG-0446
- last ID: NVG-0455

Combined:

- POINT_PASS count: 171
- unique certified IDs: 171

No range arithmetic is used as production authority.
Membership is defined by the actual POINT_PASS events.

Canonical record source:

C:\Users\mobil\OneDrive\Documents\GitHub\QA\hrs_1.1.0\dev\out\carousel\GeneratedCarouselCatalog.cs

The 171 certified IDs were joined against GeneratedCarouselCatalog.cs.

Join result:

- Certified IDs: 171
- Missing catalog records: 0
- Duplicate catalog records: 0

Therefore every final certified landing ID resolves to exactly one canonical generated record containing:

- stable NVG ID
- prefab/experience label
- X
- Y
- Z

Authority chain:

final certification POINT_PASS event
-> certified NVG ID
-> GeneratedCarouselCatalog.cs record
-> CuratedStartPoint-compatible input
-> existing ApprovedPointIndices selector seam
-> TryResolve()
-> existing landing pipeline

Important exclusion behavior:

GeneratedCarouselCatalog.cs contains records that are not in the final certified set.
Example: NVG-0445 exists in the catalog but is not part of the final 171 certification membership.

Therefore GeneratedCarouselCatalog.cs is the canonical record-data source, but final certification POINT_PASS membership determines which records are production-approved.

Do not admit records merely because they exist in the generated catalog.

Next integration phase:

Create a reproducible 171-record CuratedStartPoint-compatible production input artifact from:
1. exact POINT_PASS membership from the two final certification runs;
2. exact record data from GeneratedCarouselCatalog.cs.

Do not manually transcribe or reconstruct the 171 points.

## Recovered authoritative 171-point production input set

Final certification membership is derived directly from POINT_PASS events in these two controlled certification runs:

C:\Users\mobil\OneDrive\Documents\GitHub\QA\hrs_1.1.0\dev\evidence\carousel\2026-09-01_run_b5dc7a10_certification-161-pass_events.tsv

C:\Users\mobil\OneDrive\Documents\GitHub\QA\hrs_1.1.0\dev\evidence\carousel\2026-09-01_run_d9b93450_certification-10-pass_events.tsv

Mechanical extraction proved:

- certification batch 1: 161 POINT_PASS events
- certification batch 1 unique IDs: 161
- first ID: NVG-0281
- last ID: NVG-0443

- certification batch 2: 10 POINT_PASS events
- certification batch 2 unique IDs: 10
- first ID: NVG-0446
- last ID: NVG-0455

Combined:

- POINT_PASS count: 171
- unique certified IDs: 171

No range arithmetic is used as production authority.
Membership is defined by the actual POINT_PASS events.

Canonical record source:

C:\Users\mobil\OneDrive\Documents\GitHub\QA\hrs_1.1.0\dev\out\carousel\GeneratedCarouselCatalog.cs

The 171 certified IDs were joined against GeneratedCarouselCatalog.cs.

Join result:

- Certified IDs: 171
- Missing catalog records: 0
- Duplicate catalog records: 0

Therefore every final certified landing ID resolves to exactly one canonical generated record containing:

- stable NVG ID
- prefab/experience label
- X
- Y
- Z

Authority chain:

final certification POINT_PASS event
-> certified NVG ID
-> GeneratedCarouselCatalog.cs record
-> CuratedStartPoint-compatible input
-> existing ApprovedPointIndices selector seam
-> TryResolve()
-> existing landing pipeline

Important exclusion behavior:

GeneratedCarouselCatalog.cs contains records that are not in the final certified set.
Example: NVG-0445 exists in the catalog but is not part of the final 171 certification membership.

Therefore GeneratedCarouselCatalog.cs is the canonical record-data source, but final certification POINT_PASS membership determines which records are production-approved.

Do not admit records merely because they exist in the generated catalog.

Next integration phase:

Create a reproducible 171-record CuratedStartPoint-compatible production input artifact from:
1. exact POINT_PASS membership from the two final certification runs;
2. exact record data from GeneratedCarouselCatalog.cs.

Do not manually transcribe or reconstruct the 171 points.

## Integration execution checkpoint — 171-point selector wiring

### State reached

The final state-certified Navezgane landing library has now been mechanically materialized and wired into the active HRS 1.2.1 runtime source.

Generated integration artifact:

`dev\out\integration\certified-171-curated-start-points.cs.inc`

Artifact record count:

`171`

Artifact SHA256:

`EF60EBC8E473AD76768B807CC9095CAF726C47891DEB03D8098E655AD4B1B07E`

The artifact was generated by taking only `POINT_PASS` membership from the two final controlled certification event ledgers and joining those IDs to their exact records in the canonical generated carousel catalog.

Mechanical generation checks:

- certified IDs: 171
- generated CuratedStartPoint records: 171
- first certified record: NVG-0281
- last certified record: NVG-0455
- missing canonical records: 0
- duplicate canonical records: 0

### Active runtime wiring

Modified source:

`dev\src\runtime\main\c0213.cs`

Existing NG01 through NG12 survey records remain present.

The 171 certified NVG records were appended after the existing 12 records and therefore occupy `Points[]` indices:

`12..182`

`ApprovedPointIndices` now contains exactly:

`12..182`

Approved production selector count:

`171`

This means the production random selector admits the final certified NVG library rather than the former two-point NG01/NG02 proof pool.

### Preserved runtime behavior

This integration changes the selector input population only.

The following existing runtime machinery has not been intentionally redesigned:

- TrySelect
- TryResolve
- TryFindSafeLanding
- TryGetPoint
- GetSearchRadius
- NG01 search-radius special case
- downstream placement/settle behavior
- arrival-zone protection
- starter-trader quest repair

The integration objective remains:

certified input -> existing selector -> existing landing pipeline -> destination handling -> normal progression

### Recovery event during wiring

An initial automated edit failed because PowerShell `$input` conflicted with the automatic variable and the proposed edit was not fully populated.

Git diff identified the incomplete edit before build or commit.

`dev\src\runtime\main\c0213.cs` was restored exactly from checkpoint commit:

`a5e781c`

A read-only preflight then confirmed:

- integration artifact exists: True
- certified records: 171
- approval seam matches: 1
- NG12 insertion anchor matches: 1
- NVG-0281 already wired before edit: False

The integration was then regenerated in memory, validated before write, and written UTF-8 without BOM.

### Current boundary

The 171-point library is wired into active source.

It has NOT yet been compiled into a new runtime DLL.

It has NOT yet replaced the verified release DLL.

It has NOT yet been deployed to the game installation.

Next boundary: inspect/identify the authoritative HRS 1.2.1 runtime build path and compile the same runtime architecture with the expanded certified input library.


## Build-path discovery checkpoint

Authoritative runtime build recipe:

`dev\src\runtime\p0143.ps1`

This is the existing deterministic HRS runtime builder.

### Toolchain contract

The build recipe requires:

- Windows PowerShell 5.1
- `C:\Program Files\dotnet\dotnet.exe`
- Roslyn compiler:
  `C:\Program Files\dotnet\sdk\10.0.400\Roslyn\bincore\csc.dll`
- pinned dotnet host SHA256:
  `AB1B71FD3DD71062E074C9FAB8312081A81B7F2B3E0327C48C4D249C8D1A3135`
- pinned game Assembly-CSharp MVID:
  `229796d0-95ca-4662-b426-1a6f1f1596ed`

The build refuses to proceed if the game is running or if the pinned toolchain/game identity has changed.

### Release source set

The DLL is compiled from exactly these 11 runtime source files:

- c0140.cs
- c0147.cs
- c0167.cs
- c0181.cs
- c0184.cs
- c0185.cs
- PolicyV1.cs
- ResultV1.cs
- c0213.cs
- c0217.cs
- c0218.cs

Therefore the 171-point integration remains inside the existing runtime architecture because `c0213.cs` is already part of the authoritative release compilation set.

### Build behavior

The recipe performs two independent deterministic builds of:

`d0163.dll`

The two SHA256 hashes must match.

Only after deterministic equality is proven does the recipe create a candidate payload under:

`dev\out\alpha-core-<GUID>\mod\`

containing:

- d0163.dll
- ModInfo.xml
- Bridge directory

It also writes build provenance to:

`j0144.json`

including source hashes, compiler hashes, reference hashes, game Assembly-CSharp MVID, DLL size, DLL SHA256, and deterministic-double-build status.

### Release verification relationship

`dev\src\runtime\main\p0228.ps1` is the static/release verification gate, not the compiler.

It is currently still encoded for the old NG01/NG02 two-point proof and therefore must be deliberately updated to recognize the 171-point production selector before it can pass against the expanded source.

The verifier must not be bypassed or weakened.

### Current boundary

The 171 certified landing inputs are wired into `c0213.cs`.

The authoritative deterministic build path is now identified.

No new DLL has been built yet.

No verified release artifact has been replaced.

No installed game artifact has been changed.

Next boundary: update the release/static verification assertions so they certify the new 171-point production pool rather than the obsolete NG01/NG02 proof pool.


## Release-verifier assumption inventory

Read-only inspection of:

`dev\src\runtime\main\p0228.ps1`

identified the verifier assumptions affected by the 171-point integration.

### Invariants that remain valid

The existing NG01 through NG12 survey catalog remains part of `Points[]`.

Therefore these verifier checks remain conceptually valid and should be preserved:

- exactly 12 legacy `NG##` survey anchors
- NG01 through NG12 uniqueness/contiguity checks
- coordinate/elevation bounds checks for those 12 survey anchors
- required legacy survey experience names
- NG01 exact reviewed-street anchor
- NG02 exact survey anchor
- NG01 special search radius of 8
- generic `Points.Length` resolver bounds protection
- prevention of direct random selection across the entire `Points[]` array
- one game-owned RNG draw
- existing runtime selector/resolver/placement order checks

The 171 certified NVG records do not replace the 12 legacy survey records; they extend the catalog after them.

### Assertions that are obsolete

The verifier currently requires the literal production pool:

`private static readonly int[] ApprovedPointIndices = { 0, 1 };`

and throws:

`The explicit NG01/NG02 approved selection pool is missing.`

Those assertions describe the former two-location proof build and are now obsolete.

The production approval contract is now:

- approved count: 171
- first approved `Points[]` index: 12
- last approved `Points[]` index: 182
- approved records correspond to the final certified NVG library
- first certified ID: NVG-0281
- last certified ID: NVG-0455

The verifier should certify this structure mechanically rather than merely searching for a large hard-coded text literal.

### Runtime-log observation

`p0228.ps1` also verifies sanitized runtime candidate events for NG01 through NG12 in `c0217.cs`.

That is a separate runtime logging invariant and is not yet assumed to require change solely because the production selector pool expanded.

Do not broaden that check without evidence that the logging implementation itself depends on enumerating all selectable IDs.

### Static summary

The current final summary reports:

`surveyPoints=12`

That value remains true for the legacy NG survey set.

A separate certified/approved production count should be added or otherwise represented when the verifier is updated so that the release evidence distinguishes:

- legacy survey anchors: 12
- production certified inputs: 171

### Current boundary

No verifier source has been changed yet.

Next boundary: surgically replace only the obsolete NG01/NG02 approval assertion with structural checks for the 171 certified NVG production pool, while preserving the valid 12-point survey invariants and downstream runtime assertions.


## Production-selector verifier checkpoint

- Updated `dev\src\runtime\main\p0228.ps1` to recognize the 171 certified `NVG-####` landing records.
- Replaced the obsolete NG01/NG02-only approval assertion with a structural requirement that `ApprovedPointIndices` contain exactly indices 12 through 182, count 171.
- Preserved the existing 12-point NG01-NG12 survey/reference validation and all downstream runtime/pipeline assertions.
- Static summary now reports `approvedPoints=171` while retaining `surveyPoints=12`.
- Corrected the stale comment in `c0213.cs`: NG01-NG12 remain survey/reference data and are not selectable; the release-approved pool is the final state-certified NVG landing library.
- No build has been run yet. No verified DLL has been replaced. No installed mod has been changed.
- Next boundary: inspect the active source manifest/provenance contract that must be updated for the changed runtime source before compiling/promoting a new artifact.

## Deterministic build checkpoint

- Authoritative runtime build `dev\src\runtime\p0143.ps1` completed successfully under Windows PowerShell 5.1.
- Build attempt: `alpha-core-a754e44b4db4443090d7b0324fec972a`.
- Candidate root: `dev\out\alpha-core-a754e44b4db4443090d7b0324fec972a`.
- Candidate DLL bytes: `57344`.
- Candidate DLL SHA256: `96FC8D6A15A74BE0B78B17EFB9091445A2DDE8DBA893E67C80600A77F2C47B38`.
- Deterministic double-build result: `True`.
- Assembly-CSharp MVID remained pinned at `229796d0-95ca-4662-b426-1a6f1f1596ed`.
- Compiler/runtime reference pins passed.
- No verified DLL has been replaced. No installed mod has been changed.
- Next boundary: reconcile `j0219.json` source/provenance entries and expected artifact with the new deterministic candidate before any promotion.

## Verified-artifact provenance discrepancy

The first post-integration static verification reached the expected-artifact gate and failed because j0219.json did not match the actual erified\main\d0163.dll.

Read-only identity comparison established:

- Manifest expected artifact bytes: 39936
- Manifest expected artifact SHA256: 5377702596DF1398ED961CFA0D26E8649744B4EA713EF406B304963B5B9DEB6A
- Manifest expected artifact MVID: e7cc34aa-905a-4e07-a272-d74a9827568e
- Actual verified artifact bytes: 39936
- Actual verified artifact SHA256: DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507
- Actual verified artifact MVID: 6bd5ed25-0ccc-4688-afea-8c9e6f0f06d4
- New deterministic candidate bytes: 57344
- New deterministic candidate SHA256: 96FC8D6A15A74BE0B78B17EFB9091445A2DDE8DBA893E67C80600A77F2C47B38
- Authoritative build pinned Assembly-CSharp MVID: 229796d0-95ca-4662-b426-1a6f1f1596ed

Conclusion:

The existing expectedArtifact metadata and existing verified DLL do not form the previously claimed artifact identity. The old verified DLL has not been modified or replaced.

No promotion action is authorized from this discrepancy alone.

Next boundary: determine the authoritative provenance relationship for the existing verified artifact before changing expectedArtifact or replacing erified\main\d0163.dll.
# 1.2.1 DETERMINISTIC CANDIDATE / VERIFIED-ARTIFACT RECONCILIATION CHECKPOINT

## Purpose

This checkpoint records the complete state reached during reconciliation of the
1.2.1 runtime candidate and the existing verified artifact.

The critical distinction is:

- the new deterministic candidate exists and has been independently measured;
- the existing verified artifact has NOT been replaced;
- the release manifest and verified artifact currently describe different
  artifact identities;
- the static verifier correctly refuses to treat them as equivalent;
- no promotion is authorized until the provenance/promotion contract is
  established.

The next AI must preserve this boundary and must not "fix" the situation merely
by making the verifier pass.

## 1. What changed before the build

The 1.2.1 runtime was expanded from the former NG01/NG02 production proof pool
to the final certified 171-point NVG landing library.

The intended production selector contract is:

- legacy NG01-NG12 remain survey/reference records;
- production selection uses exactly 171 certified records;
- approved Points[] indices are exactly 12 through 182;
- first certified ID: NVG-0281;
- last certified ID: NVG-0455;
- exactly one game-owned RNG draw is used;
- full Points[] random selection is prohibited;
- existing resolver, placement, rollback, safety, and runtime assertions remain.

The verifier `p0228.ps1` was deliberately updated to structurally validate the
171-point production pool while preserving the valid NG01-NG12 survey checks.

This was NOT intended to weaken verification.

## 2. Authoritative files

Runtime source:

    dev\src\runtime\main\

Build recipe:

    dev\src\runtime\p0143.ps1

Static/release verifier:

    dev\src\runtime\main\p0228.ps1

Release source/provenance manifest:

    dev\src\runtime\main\j0219.json

Build provenance:

    j0144.json inside the deterministic candidate root

QA release metadata:

    dev\qa\rel.json

Planner packet:

    _planner_packet\LANDING_LIBRARY_INTEGRATION.md

## 3. Authoritative build inputs

The build was performed with Windows PowerShell 5.1.

Toolchain:

    C:\Program Files\dotnet\dotnet.exe

Pinned dotnet SHA-256:

    AB1B71FD3DD71062E074C9FAB8312081A81B7F2B3E0327C48C4D249C8D1A3135

Roslyn:

    C:\Program Files\dotnet\sdk\10.0.400\Roslyn\bincore\csc.dll

Pinned game Assembly-CSharp MVID:

    229796d0-95ca-4662-b426-1a6f1f1596ed

The authoritative release compilation set contains exactly 11 C# files:

    c0140.cs
    c0147.cs
    c0167.cs
    c0181.cs
    c0184.cs
    c0185.cs
    PolicyV1.cs
    ResultV1.cs
    c0213.cs
    c0217.cs
    c0218.cs

The 171-point integration is therefore inside the established runtime
architecture. c0213.cs is already part of the authoritative release set.

## 4. New deterministic candidate

Authoritative build attempt:

    alpha-core-3b3c955d328c45b7b97091f768c07b7f

Candidate root:

    dev\out\alpha-core-3b3c955d328c45b7b97091f768c07b7f

Candidate payload:

    dev\out\alpha-core-3b3c955d328c45b7b97091f768c07b7f\mod\

Candidate payload contains:

    d0163.dll
    ModInfo.xml

Candidate DLL:

    Bytes: 57344
    SHA-256:
    96FC8D6A15A74BE0B78B17EFB9091445A2DDE8DBA893E67C80600A77F2C47B38
    MVID:
    bd4f954c-b72a-40d3-a08f-35acedf31648

Candidate ModInfo.xml:

    Bytes: 429
    SHA-256:
    03B906BB2D92BF7D679CA2BB9E4B60FF7A37912AE59629B06B54A155F1C22707
    Version: 1.2.1

The build provenance file j0144.json reports:

    schema: hrs-release-build/v1
    deterministicDoubleBuild: True
    assemblyCSharpMvid:
        229796d0-95ca-4662-b426-1a6f1f1596ed
    dllBytes:
        57344
    dllSha256:
        96FC8D6A15A74BE0B78B17EFB9091445A2DDE8DBA893E67C80600A77F2C47B38

Therefore the new candidate is a genuine deterministic build result, not a
manually copied payload.

## 5. Existing verified artifact

The existing 1.2.1 verified DLL is:

    dev\verified\main\d0163.dll

Measured identity:

    Bytes: 39936
    SHA-256:
    DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507
    MVID:
    6bd5ed25-0ccc-4688-afea-8c9e6f0f06d4

The same identity exists under:

    hrs_1.2.0\dev\verified\main\d0163.dll

and:

    hrs_1.2.1\dev\verified\main\d0163.dll

Both are:

    39936 bytes
    DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507
    MVID 6bd5ed25-0ccc-4688-afea-8c9e6f0f06d4

This proves the current 1.2.1 verified artifact retained the previous verified
artifact identity.

## 6. Original provenance discrepancy

Before reconciliation, j0219.json described:

    expected bytes: 39936
    expected SHA-256:
    5377702596DF1398ED961CFA0D26E8649744B4EA713EF406B304963B5B9DEB6A
    expected MVID:
    e7cc34aa-905a-4e07-a272-d74a9827568e

Those values did not match the actual verified DLL.

Actual verified DLL was:

    39936 bytes
    DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507
    MVID 6bd5ed25-0ccc-4688-afea-8c9e6f0f06d4

This discrepancy was detected by the release verifier.

## 7. j0219.json reconciliation

During investigation, j0219.json was updated so that expectedArtifact describes
the newly built deterministic candidate:

    name:
        d0163.dll

    status:
        BuiltVerified

    bytes:
        57344

    sha256:
        96FC8D6A15A74BE0B78B17EFB9091445A2DDE8DBA893E67C80600A77F2C47B38

    mvid:
        bd4f954c-b72a-40d3-a08f-35acedf31648

This made the manifest describe the candidate identity.

IMPORTANT:

This did NOT promote the candidate.

It only reconciled expectedArtifact metadata with the newly established
deterministic candidate identity.

## 8. Why p0228.ps1 still fails

The verifier explicitly resolves:

    dev\verified\main\d0163.dll

It does not substitute the deterministic candidate merely because one exists.

The verifier:

1. resolves verifiedRoot;
2. requires verified d0163.dll;
3. requires verified ModInfo.xml;
4. hashes the verified DLL;
5. compares bytes and SHA-256 to expectedArtifact;
6. loads the verified DLL;
7. compares its MVID;
8. compares source and verified ModInfo.xml.

After j0219.json was changed to the new candidate identity, the verified DLL
remained the old identity.

Therefore p0228.ps1 correctly throws:

    Release source manifest expected artifact drifted.

This is correct behavior.

The verifier must NOT be bypassed.

## 9. Important current artifact matrix

CURRENT CANDIDATE:

    Path:
    dev\out\alpha-core-3b3c955d328c45b7b97091f768c07b7f\mod\d0163.dll

    Bytes:
    57344

    SHA-256:
    96FC8D6A15A74BE0B78B17EFB9091445A2DDE8DBA893E67C80600A77F2C47B38

    MVID:
    bd4f954c-b72a-40d3-a08f-35acedf31648

CURRENT VERIFIED:

    Path:
    dev\verified\main\d0163.dll

    Bytes:
    39936

    SHA-256:
    DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507

    MVID:
    6bd5ed25-0ccc-4688-afea-8c9e6f0f06d4

CURRENT MODINFO CANDIDATE:

    Version:
    1.2.1

    Bytes:
    429

    SHA-256:
    03B906BB2D92BF7D679CA2BB9E4B60FF7A37912AE59629B06B54A155F1C22707

## 10. QA rel.json is still stale

Current dev\qa\rel.json reports:

    version: 1.2.0
    buildId: r120
    sourceCommit:
        0aa4350505f7989d6ff6f109a4a1ca37167d16d2
    laneStatus:
        development

Its artifacts still describe:

    d0163.dll
    39936 bytes
    SHA-256:
    5377702596DF1398ED961CFA0D26E8649744B4EA713EF406B304963B5B9DEB6A

    ModInfo.xml
    428 bytes
    SHA-256:
    81A59FCE042FECAEF13102458517A28385BFC18947219CFD289C672BFB6013E8

This is another explicit indication that the release metadata has not yet
been promoted/reconciled to the new 1.2.1 candidate.

Do NOT casually rewrite rel.json merely to make values line up. Its role in the
promotion contract must first be understood.

## 11. Historical documentation discrepancy

Older documentation contains multiple historical identities, including:

    DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507
    MVID 6bd5ed25-0ccc-4688-afea-8c9e6f0f06d4

and:

    5377702596DF1398ED961CFA0D26E8649744B4EA713EF406B304963B5B9DEB6A
    MVID e7cc34aa-905a-4e07-a272-d74a9827568e

These appear in historical 1.1.x/earlier provenance notes.

Do not infer current release authority solely from historical documentation.

The current candidate identity is independently established by the current
deterministic build and j0144.json.

## 12. What has NOT happened

The following remain true:

- Existing verified DLL has NOT been replaced.
- Existing verified DLL has NOT been overwritten.
- No installed game artifact has been changed.
- No installed mod has been changed.
- No candidate has been silently promoted.
- p0228.ps1 has NOT been weakened.
- The verifier has NOT been bypassed.
- The old verified artifact remains available.
- No promotion is authorized solely because deterministicDoubleBuild is True.

## 13. Known-good evidence

The following has been directly established:

1. 171 certified NVG landing inputs are wired into the runtime source.
2. p0228.ps1 was updated to recognize the 171-point production pool.
3. The legacy NG01-NG12 survey invariants remain.
4. Approved production indices are structurally checked as 12 through 182.
5. The authoritative deterministic build completed.
6. The candidate contains d0163.dll and ModInfo.xml.
7. Candidate DLL size is 57344 bytes.
8. Candidate DLL SHA-256 is
   96FC8D6A15A74BE0B78B17EFB9091445A2DDE8DBA893E67C80600A77F2C47B38.
9. Candidate DLL MVID is
   bd4f954c-b72a-40d3-a08f-35acedf31648.
10. Candidate ModInfo version is 1.2.1.
11. deterministicDoubleBuild is True.
12. Assembly-CSharp MVID remains
    229796d0-95ca-4662-b426-1a6f1f1596ed.
13. Existing verified DLL remains the old 39936-byte artifact.
14. 1.2.0 and 1.2.1 verified DLLs currently have the same old identity.
15. p0228.ps1 correctly detects the candidate/verified mismatch.
16. No promotion has occurred.

## 14. Exact next boundary

STOP before changing any additional release artifact.

The next AI/operator must determine the authoritative promotion/provenance
relationship among:

    j0219.json
    j0144.json
    dev\out\alpha-core-3b3c955d328c45b7b97091f768c07b7f
    dev\verified\main\d0163.dll
    dev\verified\main\ModInfo.xml
    dev\qa\rel.json
    p0228.ps1

Specifically determine:

- what operation officially promotes a deterministic candidate;
- whether promotion is expected to replace dev\verified\main;
- which manifest is authoritative before promotion;
- which evidence must exist before promotion;
- whether rel.json is generated, manually maintained, or promotion output;
- whether the existing verified artifact is a historical baseline or a
  deliberately protected release artifact;
- whether a promotion script already exists elsewhere in the project.

The next action should remain READ-ONLY until that contract is established.

Do not solve the mismatch by copying files.

Do not solve the mismatch by weakening p0228.ps1.

Do not solve the mismatch by blindly rewriting rel.json.

Do not delete the old verified artifact.

The current state is valuable evidence and should be preserved.

## 15. Resume instruction for the next AI

Start from this checkpoint.

Assume the deterministic 1.2.1 candidate is real and reproducibly built.

Assume the existing verified artifact is real and intentionally untouched.

The unresolved question is not "can we build it?"

We already can.

The unresolved question is:

    "What is the authoritative, documented promotion path from the
     deterministic candidate to the verified 1.2.1 release artifact?"

Answer that question from the project evidence before performing any write,
copy, replacement, or promotion operation.

## UX smoke-test / DEV candidate wiring checkpoint

### UX smoke test result

The current HRS entry point was launched using:

    START.bat

The manager opened successfully with no startup or PowerShell error.

Observed UI state:

    Bit Wrecked - Historical Random Start
    Historical Random Start
    Release 1.2.1 DEV
    Setup ready - choose Standard or Random

Visible controls included:

    New Game Name
    Standard
    Random
    Protect the arrival biome hazard (snow proof)
    Apply
    Launch Game
    Uninstall Mod

Detected game folder:

    C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die

This proves the current BAT -> UI/manager path is operational.

### Important limitation of that smoke test

The current UX/deployment path still consumes the verified runtime lane.

The authoritative deployment chain is presently understood as:

    START.bat
      ->
    dev\ui\p0158.ps1
      ->
    deployment backend m0162
      ->
    dev\verified\main\d0163.dll
    dev\verified\main\ModInfo.xml

The current `dev\verified\main\d0163.dll` is NOT the new 171-point candidate.

Its identity remains:

    Bytes:
        39936

    SHA-256:
        DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507

    MVID:
        6bd5ed25-0ccc-4688-afea-8c9e6f0f06d4

That verified artifact is the same binary identity carried forward from the
previous verified lane.

Therefore the successful UX launch proves the manager path works, but it does
NOT yet prove the new 171-point runtime works in game.

### Current runtime behavior if Apply/Launch were used now

If the current manager is used without additional wiring, it will deploy the
existing verified runtime.

That runtime corresponds to the earlier two-point production proof lane.

The previous production selector was restricted to:

    NG01
    NG02

The rest of the established runtime transaction remains the same:

    random placement
      ->
    approved landing
      ->
    double teleport / settle
      ->
    determine destination context
      ->
    arrival-biome protection
      ->
    starter trader quest redirect
      ->
    normal progression

Therefore the present UX is expected to work, but only against the older
two-point production selector rather than the new 171 certified NVG locations.

### New deterministic candidate waiting for test integration

The new deterministic 1.2.1 candidate remains:

    dev\out\alpha-core-3b3c955d328c45b7b97091f768c07b7f\mod\d0163.dll

Identity:

    Bytes:
        57344

    SHA-256:
        96FC8D6A15A74BE0B78B17EFB9091445A2DDE8DBA893E67C80600A77F2C47B38

    MVID:
        bd4f954c-b72a-40d3-a08f-35acedf31648

Candidate ModInfo.xml:

    Version:
        1.2.1

    Bytes:
        429

    SHA-256:
        03B906BB2D92BF7D679CA2BB9E4B60FF7A37912AE59629B06B54A155F1C22707

The candidate build is deterministic and is supported by j0144.json.

### Testing strategy decided at this boundary

Do NOT overwrite `dev\verified\main` merely to perform the first in-game test.

Do NOT promote the candidate simply because the UX is ready.

Instead, add the smallest possible DEV-only candidate source path to the
existing deployment/manager architecture.

Desired architecture:

    NORMAL / RELEASE LANE
        source = dev\verified\main

    DEV TEST LANE
        source =
        dev\out\alpha-core-3b3c955d328c45b7b97091f768c07b7f\mod

The UX itself does not need to be redesigned.

The existing Standard / Random interface and Apply / Launch flow are already
working.

The required change is only to let DEV/testing select the exact deterministic
candidate as the deployment source while preserving the existing verified lane
unchanged.

### Why the DEV test lane matters

Testing the exact candidate before promotion preserves the release rule:

    promote exact tested bytes

It avoids this unsafe shortcut:

    candidate build
      ->
    overwrite verified artifact
      ->
    test afterward

Instead the intended sequence should be:

    deterministic candidate
      ->
    DEV deployment
      ->
    focused in-game integration QA
      ->
    record exact tested hash/MVID
      ->
    authorize promotion
      ->
    copy/promote those exact tested bytes
      ->
    final verified-lane checks

This preserves rollback and provenance.

### Scope of the upcoming in-game test

The 171 individual landing coordinates have already been certified.

Do NOT repeat the full 171-point certification campaign.

The upcoming test is an integration smoke test of the newly expanded selector
through the existing runtime transaction.

The focused test should prove:

1. Random mode launches using the new deterministic candidate.
2. The selector can choose from the 171 certified production pool rather than
   only NG01/NG02.
3. The existing landing machinery accepts the chosen point.
4. Double-jump / ground-settle behavior still executes.
5. Arrival-zone/biome protection still works when requested.
6. Starter-trader quest redirect still works.
7. The player reaches normal progression.
8. No obvious regression was introduced by expanding the input library.

The individual coordinates themselves are already certified inputs and should
not be unnecessarily re-QA'd.

### Exact next engineering step

Close the HRS manager before editing the deployment path.

Then perform READ-ONLY inspection of:

    dev\ui\p0158.ps1

and the deployment backend identified as:

    m0162

The goal of that inspection is to find the exact location where the deployment
source resolves:

    dev\verified\main

Do not edit first.

Find the existing source-resolution point, then introduce the smallest possible
DEV-only override.

The verified release lane must continue to resolve exactly as it does now.

### Resume instruction for the next AI

We are now at the beginning of runtime integration testing.

Do not return to the 171-point data-generation or certification work.

Do not rebuild unless a source edit makes rebuilding necessary.

Do not overwrite `dev\verified\main`.

Do not redesign the UX.

Start by locating the exact deployment-source resolution in `p0158.ps1` and/or
m0162.

The next goal is:

    wire the exact deterministic 1.2.1 candidate into a DEV-only test path,
    then launch the existing UX and perform the first 171-point runtime smoke
    test.

This is the current boundary.

## 2026-09-04 — Certified landing asset inventory / balanced-pool decision

Live blind sampling exposed an apparent biome skew. Full inventory of the 171
currently selectable certified NVG points confirmed that the RNG itself was not
the cause; the certified asset population was uneven by biome.

Original certified selectable distribution:

- desert: 46
- snow: 42
- burnt_forest: 40
- pine_forest: 27
- wasteland: 16
- total: 171

Therefore a uniform random draw across all 171 points gives wasteland only
16/171 (~9.4%) probability while desert + snow together account for 88/171
(~51.5%).

The Navezgane POI catalog was joined to the selector IDs using InstanceId.
Obvious Navezgane-only / development-only assets were excluded when any of
these markers were present:

- Zoning = DevOnly
- navonly tag
- hideui tag

Exactly 11 assets were excluded. All 11 were Perishton/snow assets:

NVG-0443
NVG-0446
NVG-0447
NVG-0448
NVG-0449
NVG-0450
NVG-0451
NVG-0452
NVG-0453
NVG-0454
NVG-0455

This leaves 160 generic-eligible certified assets:

- burnt_forest: 40
- desert: 46
- pine_forest: 27
- snow: 31
- wasteland: 16

Each eligible biome contains only unique prefab identities within the certified
set; duplicate-prefab count is zero in every biome.

Decision:

Preserve the complete certified landing library as evidence/reserve inventory,
but reduce the production selectable pool to a balanced set of:

- 16 pine_forest
- 16 desert
- 16 snow
- 16 burnt_forest
- 16 wasteland
- total production pool: 80

This produces a natural 20% biome distribution if the runtime continues using
a uniform random draw over the 80 active records.

The initial generated 80-point proposal is NOT yet runtime authority. It was
created by sorting eligible records by Tier/Prefab and taking the first 16 from
each non-wasteland biome. That selection method introduces unnecessary asset-
family bias and should be refined for representative generic/RWG-style POI
variety before c0213.cs is changed.

Wasteland is the limiting biome and therefore all 16 currently eligible
wasteland certified assets are retained unless later evidence disqualifies one.

No runtime selector change was made at this inventory boundary.

## 2026-09-04 — Balanced-80 live smoke pass

Fresh DEV candidate built from the balanced 80-point selector and updated runtime identity.

Candidate build:
- attempt: alpha-core-9c424a54f321420d9dc4175992bd7b10
- dll bytes: 56832
- dll sha256: C732AC84E47B8E0A4FBBD0F2B89401C1597D181A5A32EC1B1A1B4A8664142222
- dll MVID: f65efba4-1a77-4e9b-b51a-31050e506118
- deterministicDoubleBuild: True

Live test:
- game name: test222
- map: Navezgane
- mode: RandomSafe
- arrival-biome protection: enabled
- runtime identity observed: v=1.2.1 build=r120
- runtime reached: RELOCATION_COMPLETED
- live settled position: approximately (-1920.4, 61.1, -1915.1)

Catalog lookup matched the live position to:

- NVG-0286
- prefab: hotel_ostrich
- display name: Ostrich Hotel
- biome: wasteland
- certified anchor: (-1923, 61, -1912)

This directly proves that the balanced 80-point production pool is active and can
select wasteland correctly. The final settled position remained within a few
meters of the certified anchor, consistent with normal HRS surface-settle
adjustment.

No promotion to dev\verified\main has occurred yet.

## Future Workflow Contract — Version Conveyor / One-Way Ticket

### Why this exists

The HRS 1.2.1 integration exposed a major AI-token and engineering-time cost that was
previously hidden when version work was performed inside an IDE agent.

A seemingly small runtime change can require coordinated movement across:

- runtime source;
- selector/configuration authority;
- static verifier expectations;
- source manifest bytes and SHA256 values;
- aggregate source-manifest SHA256;
- runtime version/build identity;
- deterministic build output;
- candidate DLL bytes/SHA256/MVID;
- expected-artifact metadata;
- DEV deployment wiring;
- installed-candidate validation;
- live game smoke evidence;
- planner/handoff documentation;
- Git staging and commit boundaries.

The expensive part is often not writing the new feature.

The expensive part is rediscovering and reconciling all of the version-coupled state around
that feature.

During this integration, performing those steps manually made the hidden workflow visible.
This explains a significant portion of the token consumption previously observed when IDE
agents performed apparently simple version changes.

### Core rule

DO NOT PAY THE NEXT MODEL TO REDISCOVER VERSION STATE.

A version migration should be treated as a one-way conveyor:

CURRENT KNOWN-GOOD VERSION
    ->
LOAD AUTHORITATIVE VERSION MAP
    ->
APPLY INTENTIONAL SOURCE CHANGES
    ->
RECONCILE ALL VERSION-COUPLED AUTHORITIES
    ->
BUILD DETERMINISTIC CANDIDATE
    ->
UPDATE CANDIDATE IDENTITY
    ->
DEPLOY THROUGH DEV LANE
    ->
LIVE SMOKE
    ->
RECORD EVIDENCE
    ->
COMMIT CHECKPOINT
    ->
NEXT KNOWN-GOOD VERSION

Do not move backward on this conveyor unless a validation gate fails.

### Required future automation / skill

A future HRS migration skill or scripted workflow should be created to batch the mechanical
parts of this process.

Suggested responsibility:

`Invoke-HrsVersionConveyor`

The skill/script should NOT invent product decisions or silently promote artifacts.

It should automate deterministic reconciliation after the human/AI has supplied the intended
source change and target version.

At minimum it should:

1. Identify the current package root and target version.

2. Load the authoritative runtime/source manifest.

3. Inventory all controlled source files before mutation.

4. Record pre-change Git status and commit identity.

5. Apply or accept the intentional runtime/source changes.

6. Detect every manifest-controlled file that changed.

7. Recalculate changed-file:
   - byte length;
   - SHA256.

8. Recalculate the ordered aggregate source-manifest SHA256 using exactly the same algorithm
   as the release verifier.

9. Verify that static-contract expectations still match the intended runtime architecture.

10. Find stale version/build strings across release runtime sources.

11. Require explicit authority before changing a build identifier.
    Never invent the next build ID merely because the package version changed.

12. Run the authoritative deterministic builder.

13. Require deterministic double-build success.

14. Capture candidate:
    - attempt ID;
    - candidate root;
    - DLL bytes;
    - DLL SHA256;
    - DLL MVID;
    - game Assembly-CSharp compatibility MVID.

15. Update expected-artifact metadata only from the candidate that was actually built.

16. Do NOT automatically promote the candidate to `dev\verified\main`.

17. Deploy the candidate through the existing DEV candidate lane.

18. Record the exact installed candidate identity.

19. Require live smoke evidence before promotion.

20. Capture smoke evidence including:
    - game name;
    - mode;
    - selected point if available;
    - biome;
    - live position;
    - certified/catalog anchor;
    - runtime version/build line;
    - terminal runtime state such as `RELOCATION_COMPLETED`.

21. Update the flight recorder automatically with the completed migration evidence.

22. Show the exact Git working tree before commit.

23. Exclude generated candidate/output directories from commits unless explicitly required.

24. Produce a re-entry handoff containing:
    - what changed;
    - known-good state;
    - validation performed;
    - authoritative files;
    - current candidate identity;
    - installed/tested identity;
    - promotion status;
    - unresolved blockers;
    - exact next action.

### Important separation of authorities

The conveyor must preserve these distinctions:

CERTIFIED SOURCE / ASSET LIBRARY
is not the same as
ACTIVE PRODUCTION SELECTION

SOURCE MANIFEST
is not the same as
EXPECTED BUILT ARTIFACT

BUILT CANDIDATE
is not the same as
INSTALLED TEST CANDIDATE

INSTALLED TEST CANDIDATE
is not the same as
VERIFIED/PROMOTED ARTIFACT

VERIFIED/PROMOTED ARTIFACT
is not automatically the same as
PUBLISHED RELEASE

Never collapse these states merely to make validation pass.

### Failure behavior

The future conveyor must fail closed.

If any of these occur:

- unexpected source drift;
- missing authority;
- unknown build ID;
- manifest mismatch;
- deterministic-build mismatch;
- candidate identity mismatch;
- unexpected deployment contents;
- live smoke failure;
- unrecognized Git changes;

STOP at that gate and report the discrepancy.

Do not repair unrelated state automatically.

Do not overwrite historical evidence merely because newer state exists.

### Desired AI behavior

The next AI should treat this manifest as its map.

It should not begin a new version by searching the entire repository and reconstructing the
release architecture from scratch.

Instead:

1. Read this flight recorder.
2. Confirm the current Git checkpoint.
3. Load the small set of authoritative files named here.
4. Run the conveyor checks.
5. Continue forward from the last known-good gate.

The objective is:

STAGE CONTEXT ONCE.
ROUTE FROM THE MAP.
BATCH MECHANICAL RECONCILIATION.
SPEND MODEL TOKENS ON JUDGMENT, NOT REDISCOVERY.

### 1.2.1 lesson

The 1.2.1 balanced-landing integration demonstrated why this is necessary.

A gameplay-level change ultimately required coordinated work involving:

- c0213.cs;
- c0217.cs;
- p0228.ps1;
- j0219.json;
- p0143.ps1 build behavior;
- p0158.ps1 DEV deployment behavior;
- candidate artifact identity;
- installed runtime validation;
- live Navezgane evidence;
- this flight recorder;
- Git checkpointing.

Doing that work manually was valuable because it exposed the true dependency graph.

The next version should benefit from that discovery rather than repeat it.

Treat 1.2.1 as the manual reference implementation for the future HRS Version Conveyor.

## Planner / IDE Execution Contract

The Version Conveyor is intended to be executed by the IDE coding agent, not manually by the
planner/chat model under normal conditions.

Default division of labor:

PLANNER / CHATGPT:
- define the version intent;
- define architectural constraints;
- identify what must not regress;
- provide the IDE with this manifest and the exact migration objective;
- review the IDE's evidence and handoff;
- make judgment calls when a gate fails;
- decide whether promotion/release is appropriate.

IDE / CODING AGENT:
- perform repository edits;
- carry forward version-coupled state;
- reconcile manifests and hashes;
- detect controlled source drift;
- update approved verifier contracts when explicitly required by the change;
- run deterministic builds;
- collect candidate identity;
- prepare DEV deployment;
- run available static/automated validation;
- update the flight recorder;
- produce the re-entry handoff;
- stop at promotion/release gates unless explicitly authorized.

The planner should NOT normally repeat the manual 1.2.1 migration sequence step-by-step.

Manual intervention is the fallback path when:
- the IDE reports a failed gate;
- authority is ambiguous;
- the generated evidence is inconsistent;
- the IDE attempts to collapse candidate/tested/verified/released states;
- a product or architectural decision is required.

The normal next-version workflow is therefore:

PLANNER DEFINES INTENT
    ->
IDE EXECUTES VERSION CONVEYOR
    ->
IDE RETURNS EVIDENCE/HANDOFF
    ->
PLANNER REVIEWS
    ->
IDE CONTINUES OR STOPS AT THE NEXT AUTHORIZED GATE

Spend planner-model tokens on architecture, judgment, and verification.

Spend IDE-agent tokens on repository movement, mechanical reconciliation, and execution.

The manual 1.2.1 process is the reference implementation, not the desired recurring workflow.

## Authoritative Execution & Continuity Contract — WE WALK FROM HERE

This section is authoritative if any earlier workflow wording appears ambiguous.

### Meaning of "We Walk From Here"

"We walk from here" means:

THE USER AND PLANNER/CHATGPT OWN COMPLETION OF THE WORK FROM THE CURRENT STATE.

It does not mean that the planner must personally perform every repository mutation.

It means that responsibility for finishing the requested work remains with the user and
planner regardless of which execution mechanism is available.

Tools are interchangeable.

Ownership of completion is not.

The working rule is:

WE OWN THE FINISH.
TOOLS ARE EXECUTION MECHANISMS.
PROGRESS CONTINUES FROM THE LAST KNOWN-GOOD GATE.

### Preferred execution model

For large repository migrations, version changes, manifest reconciliation, deterministic
builds, repetitive file edits, and other mechanically expensive operations, the IDE coding
agent is the preferred executor.

This is because the IDE operates directly inside the repository and can efficiently perform:

- repository inspection;
- multi-file edits;
- reference tracing;
- manifest reconciliation;
- hash and byte recalculation;
- deterministic build execution;
- candidate inspection;
- automated validation;
- Git inspection;
- documentation updates.

The preferred normal workflow is:

USER + PLANNER DEFINE INTENT
    ->
PLANNER DEFINES ARCHITECTURE AND GUARDRAILS
    ->
IDE EXECUTES MECHANICAL REPOSITORY WORK
    ->
IDE RETURNS EVIDENCE AND CURRENT STATE
    ->
USER + PLANNER REVIEW
    ->
CONTINUE TO NEXT VERIFIED GATE

The IDE is therefore a high-throughput execution worker.

It is not the owner of the outcome.

### Why the IDE is preferred for mechanical work

The planner/chat model does not continuously inhabit the repository.

When the user and planner execute repository work manually, state must repeatedly cross the
chat boundary.

The manual loop becomes:

PLANNER REASONS
    ->
PLANNER PROVIDES COMMAND
    ->
USER EXECUTES COMMAND
    ->
USER RETURNS OUTPUT
    ->
PLANNER RECONSTRUCTS CURRENT STATE
    ->
PLANNER DETERMINES NEXT STEP

This process works and was successfully used during the HRS 1.2.1 integration.

However, it creates additional cost because:

- live repository state must repeatedly be transported into chat;
- paths and authorities must repeatedly be confirmed;
- file mutations must be surfaced back for inspection;
- hashes and manifests are often reconciled one gate at a time;
- screenshots, command output, and logs become part of the working context;
- interactive shell behavior introduces additional failure modes;
- long sessions accumulate substantial context;
- the planner must repeatedly reconstruct state that an IDE agent can reread directly.

This explains why apparently small version changes can consume large amounts of model context
and execution time.

### Manual execution remains fully supported

The user and planner CAN execute the entire Version Conveyor manually.

Manual execution is not an unsupported or inferior recovery mode.

It is simply more expensive in interaction and context movement.

Manual execution becomes the correct path when:

- the IDE runs out of tokens;
- the IDE loses useful context;
- an IDE session terminates;
- the IDE reaches a tool limitation;
- the IDE reports an ambiguous failure;
- generated evidence is inconsistent;
- repository authority is unclear;
- an architectural judgment is required;
- the IDE attempts an unsafe shortcut;
- promotion or release requires deliberate approval;
- the user chooses to continue directly with the planner.

At that point:

WE WALK FROM HERE.

The planner should not tell the user to restart the project, rediscover the repository, or
repeat completed work merely because the previous execution agent stopped.

The planner should recover the last known-good state and continue forward.

### Token exhaustion is expected

IDE token exhaustion is considered a normal lifecycle event for this project.

It must be designed for rather than treated as an exceptional failure.

A future IDE session may consume its available context while performing a version migration,
large integration, QA pass, or release-preparation task.

The expected lifecycle is:

IDE HAS RUNWAY
    ->
IDE EXECUTES WORK
    ->
IDE APPROACHES OR REACHES CONTEXT LIMIT
    ->
IDE LEAVES RE-ENTRY HANDOFF
    ->
USER RETURNS TO PLANNER/CHATGPT
    ->
PLANNER LOADS HANDOFF
    ->
WE WALK FROM HERE
    ->
TASK CONTINUES FROM LAST VERIFIED GATE

The user should not be required to explain the project again.

The next model should not be paid to rediscover already-established architecture.

### Mandatory IDE re-entry handoff

Before an IDE/Codex session ends, or whenever substantial work has occurred that may need to
be resumed elsewhere, it must leave a re-entry handoff.

The handoff must contain at minimum:

1. WHAT CHANGED
   - exact files modified;
   - important behavior changes;
   - version-related changes;
   - manifest or verifier changes.

2. CURRENT KNOWN-GOOD STATE
   - what is confirmed working;
   - last completed validation gate;
   - current runtime architecture;
   - what must not be reverted.

3. WIRING / INTEGRATION COMPLETED
   - deployment wiring;
   - selector wiring;
   - runtime wiring;
   - manifest relationships;
   - UI/manager relationships;
   - build-path relationships.

4. VALIDATION / EVIDENCE PERFORMED
   - static verifier results;
   - deterministic build results;
   - smoke-test results;
   - hashes;
   - byte counts;
   - MVID values;
   - game/runtime compatibility evidence.

5. AUTHORITATIVE FILES / MANIFESTS
   - exact paths;
   - which file owns which decision;
   - which manifest is currently authoritative;
   - which evidence is historical only.

6. BUILD / CANDIDATE STATE
   - candidate attempt ID;
   - candidate root;
   - DLL bytes;
   - DLL SHA256;
   - DLL MVID;
   - deterministic-build status.

7. INSTALLED / TESTED STATE
   - which candidate was installed;
   - game/test name;
   - test mode;
   - observed runtime identity;
   - selected landing point if applicable;
   - terminal runtime result.

8. PROMOTION STATE
   - whether `dev\verified\main` has changed;
   - whether the candidate is merely built;
   - whether it is installed for DEV testing;
   - whether it has been promoted;
   - whether it has been published.

9. KNOWN BLOCKERS / OPEN QUESTIONS
   - failures;
   - ambiguity;
   - stale metadata;
   - cosmetic cleanup;
   - release decisions still requiring authority.

10. EXACT NEXT STEP
    - one concrete action from the current known-good gate.

The handoff exists specifically to prevent a later model from reverting to older assumptions
or repeating already-completed work.

### Version Conveyor ownership

The Version Conveyor is a shared workflow with distinct responsibilities.

USER:
- owns product intent;
- approves meaningful behavioral changes;
- observes live game behavior;
- decides when the result meets the intended experience.

PLANNER / CHATGPT:
- owns continuity;
- maintains architectural understanding;
- defines constraints and gates;
- reviews evidence;
- detects conceptual mistakes;
- directs the IDE;
- takes over manually when needed;
- continues until the work is complete or a genuine external blocker exists.

IDE / CODING AGENT:
- performs high-volume repository execution;
- carries version-coupled state forward;
- edits files;
- reconciles manifests;
- runs builds;
- runs automated validation;
- gathers evidence;
- updates documentation;
- prepares the next gate;
- leaves a re-entry handoff before context loss whenever possible.

No single tool owns completion.

The user and planner do.

### One-way version migration principle

Once a version migration begins from a known-good checkpoint, work should normally move in
one direction:

KNOWN-GOOD VERSION
    ->
TARGET VERSION INTENT
    ->
SOURCE CHANGES
    ->
CONTROLLED DRIFT DETECTION
    ->
VERIFIER RECONCILIATION
    ->
SOURCE MANIFEST RECONCILIATION
    ->
VERSION IDENTITY REVIEW
    ->
DETERMINISTIC BUILD
    ->
CANDIDATE IDENTITY
    ->
DEV DEPLOYMENT
    ->
LIVE SMOKE
    ->
EVIDENCE
    ->
COMMIT
    ->
PROMOTION DECISION
    ->
RELEASE

Do not move backward merely because an execution agent changed.

Do not reconstruct previous versions from memory when authoritative files and handoffs exist.

Do not replace current known-good implementation with an older implementation because an
earlier manifest, artifact, or document appears authoritative without first resolving its
provenance.

### Gates remain deliberate

Automation must not collapse these states:

CERTIFIED SOURCE / ASSET LIBRARY

ACTIVE PRODUCTION SELECTION

SOURCE MANIFEST

BUILT CANDIDATE

INSTALLED DEV CANDIDATE

LIVE-TESTED CANDIDATE

VERIFIED / PROMOTED ARTIFACT

PUBLISHED RELEASE

These are distinct states.

A successful build does not imply successful live testing.

A successful live test does not automatically authorize promotion.

Promotion does not automatically authorize publication.

The planner and user decide when to cross consequential gates.

### Failure doctrine

If a gate fails:

STOP AT THE FAILED GATE.

Determine the actual cause.

Preserve the last known-good state.

Do not make unrelated changes merely to silence the verifier.

Do not rewrite historical evidence to make newer state appear valid.

Do not blindly update hashes until the intentional source change is understood.

Do not promote a candidate solely because a manifest expects it.

Do not invent version/build authority.

Fix the cause, validate again, and continue forward.

### Context and token doctrine

The project should minimize repeated model rediscovery.

Primary rule:

DO NOT PAY MODELS TO REDISCOVER CONTEXT.

Instead:

STAGE ONCE.
MAP AUTHORITIES.
RECORD GATES.
LEAVE HANDOFFS.
ROUTE FROM THE MAP.

Planner-model context should be spent primarily on:

- architecture;
- judgment;
- integration decisions;
- failure analysis;
- risk;
- validation interpretation;
- release decisions.

IDE-agent context should be spent primarily on:

- code movement;
- repository inspection;
- repetitive edits;
- manifest reconciliation;
- build execution;
- evidence collection.

If IDE context is exhausted, the work does not reset.

The planner resumes from the last documented gate.

### The 1.2.1 reference implementation

HRS 1.2.1 is the manual reference implementation for this workflow.

During 1.2.1, the user and planner manually traversed:

- asset inventory;
- biome distribution analysis;
- generic/RWG eligibility filtering;
- balanced 80-point selection;
- c0213.cs selector modification;
- p0228.ps1 verifier reconciliation;
- j0219.json manifest reconciliation;
- aggregate SHA256 regeneration;
- c0217.cs runtime identity correction;
- deterministic candidate generation;
- candidate DLL identity capture;
- DEV deployment;
- live Navezgane smoke testing;
- catalog-to-live-position validation;
- flight-recorder updates;
- Git checkpointing;
- Nexus security/scanner documentation.

That manual process exposed the real dependency graph.

Future versions should consume that knowledge rather than rediscover it.

### Definition of success for future versions

A successful future migration should feel different from the 1.2.1 archaeology.

The ideal pattern is:

USER: defines what the next version should accomplish.

PLANNER: converts that intent into an architectural work packet and points the IDE to this
manifest.

IDE: executes the Version Conveyor and returns evidence.

PLANNER + USER: inspect the evidence and make the next decision.

If IDE execution ends early:

WE WALK FROM HERE.

The planner loads the handoff, identifies the last verified gate, and continues the work with
whatever tool remains available.

The objective is not to avoid manual work at all costs.

The objective is to avoid repeating work that has already been understood.

### Final continuity rule

At any point in this project, the phrase:

"WE WALK FROM HERE"

means:

- accept the current repository state as the starting point;
- identify the last verified gate;
- preserve completed work;
- recover authoritative context;
- choose the next concrete action;
- use the best available execution mechanism;
- continue through failures and tool changes;
- maintain evidence;
- own the task until completion or a genuine external blocker.

The IDE may stop.

A model session may end.

Tokens may run out.

Tools may change.

The project does not reset.

WE WALK FROM HERE.

## Human Attention Budget

The primary scarce resource for this project is the user's time and attention, not model
tokens alone.

Automation, IDE execution, and future Version Conveyor tooling should therefore optimize for
MINIMUM HUMAN RE-ATTENTION.

The user should spend attention on:

- product intent;
- architectural decisions;
- meaningful behavioral choices;
- validation judgment;
- live-game observations;
- promotion and release decisions;
- genuine failures or ambiguity.

The user should NOT routinely spend attention on:

- repetitive repository inspection;
- recalculating known hashes;
- rediscovering file authority;
- carrying unchanged context between agents;
- confirming routine deterministic operations;
- reconstructing what an earlier IDE session already completed;
- supervising mechanical file-by-file migration work.

### Preferred batching behavior

The IDE should batch safe mechanical work whenever the authority and intended direction are
already known.

Prefer:

- completing all safe deterministic reconciliation before requesting review;
- batching related multi-file edits;
- recalculating controlled hashes and manifests in one pass;
- running available automated validation before returning;
- collecting evidence before asking the user to inspect the result;
- updating the flight recorder and re-entry handoff as part of the same work packet;
- surfacing only meaningful decision gates.

Avoid:

- asking the user to approve trivial intermediate operations;
- stopping after every mechanical repository mutation;
- repeatedly asking for information already recorded in authoritative manifests;
- making the user act as the transport mechanism for unchanged context;
- consuming human attention to compensate for an incomplete handoff;
- forcing the user to reconstruct repository state after token or session exhaustion.

A good automation run may perform many machine operations internally while requiring only a
small number of human decisions.

MACHINE STEPS MAY BE NUMEROUS.

HUMAN INTERRUPTIONS SHOULD BE FEW.

### Desired interaction pattern

The preferred workflow is:

USER DEFINES INTENT
    ->
PLANNER DEFINES GUARDRAILS
    ->
IDE BATCHES SAFE EXECUTION
    ->
MEANINGFUL GATE
    ->
USER + PLANNER REVIEW
    ->
IDE CONTINUES

The number of internal implementation steps is not the optimization target.

The optimization target is how little human re-attention is required to move safely from one
known-good state to the next.

### Token exhaustion and human attention

If the IDE runs out of tokens or its session ends, the cost must not be transferred to the
user as hours of reconstruction work.

The required re-entry handoff must preserve enough state that the user can return to
ChatGPT/planner and say:

"WE WALK FROM HERE"

and continue from the last verified gate.

The user should not have to retell the project history.

The planner should not have to rediscover the dependency graph.

The new execution environment should consume the handoff and continue.

### Attention-preservation rule

Before interrupting the user, an execution agent should ask:

1. Is this a genuine product, architectural, validation, promotion, or release decision?
2. Is required authority actually missing?
3. Is a safety or correctness gate genuinely blocked?
4. Could this step be completed deterministically from existing authority without user input?

If the fourth answer is YES and the first three are NO, continue the mechanical work instead
of interrupting the user.

### Success criterion

The Version Conveyor succeeds not merely when it reduces model tokens.

It succeeds when a future version requires substantially less of the user's elapsed time and
attention than the manual HRS 1.2.1 integration.

The desired experience is:

DEFINE THE VERSION.
LET THE IDE MOVE THE MACHINERY.
REVIEW THE MEANINGFUL EVIDENCE.
MAKE THE IMPORTANT DECISIONS.

If execution stops unexpectedly:

PRESERVE THE STATE.
LEAVE THE TRAIL.
WE WALK FROM HERE.

## External Engineering Guidance — Future Agent Architecture

This section records external software-engineering guidance that supports the HRS continuity
and Version Conveyor design.

It is evidence and architectural guidance for future AI agents.

It does not replace HRS-specific authorities elsewhere in this manifest.

### GitHub / Microsoft agent guidance

Current GitHub Copilot guidance distinguishes between persistent repository instructions and
task-specific agent skills.

Repository/custom instructions are intended for guidance that broadly applies to work in the
repository, such as:

- project conventions;
- build expectations;
- validation requirements;
- repository architecture;
- standing behavioral constraints.

Agent skills are intended for more detailed procedures that should be loaded when a particular
kind of task is being performed.

A Copilot agent skill may contain:

- a required `SKILL.md`;
- detailed procedural instructions;
- supporting Markdown;
- scripts;
- examples;
- other task-specific resources.

GitHub's guidance recommends using custom instructions for simple rules relevant to most work
and skills for detailed procedures that are only relevant to particular tasks.

GitHub also supports several layers of durable repository guidance, including:

- `.github/copilot-instructions.md`;
- path-specific `.instructions.md` files;
- `AGENTS.md` in supported agent environments;
- repository-specific agent skills.

The engineering reason for these mechanisms is directly relevant to HRS:

REPOSITORY CONTEXT SHOULD BE RECORDED ONCE AND REUSED.

The agent should not require the user to repeatedly reconstruct project conventions,
architecture, build procedure, or validation expectations in every new session.

Official references current at the time this section was recorded:

GitHub Docs:
https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills

GitHub Docs:
https://docs.github.com/en/copilot/reference/custom-instructions-support

GitHub Docs:
https://docs.github.com/en/copilot/concepts/prompting/response-customization

GitHub Docs:
https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions

### Release-engineering guidance

Established release-automation practice also supports the HRS Version Conveyor model.

A mature release process should make the path from known-good source to validated candidate
repeatable rather than depending on a developer manually remembering every dependency.

The useful principles are:

- define the release process once;
- automate repeatable mechanical work;
- preserve dependencies between stages;
- validate at known gates;
- retain evidence from each stage;
- reduce unnecessary manual handoffs;
- fail at the actual failed gate rather than masking the failure;
- keep consequential promotion/release decisions explicit.

These principles match the HRS Version Conveyor architecture.

### Recommended mature HRS structure

The current large integration manifest is valuable because it contains history, evidence,
provenance, decisions, known-good state, and recovery information.

However, a future IDE agent should not necessarily be required to consume the entire historical
flight recorder as its primary operating procedure for every routine version migration.

The preferred mature architecture is:

LANDING_LIBRARY_INTEGRATION.md
    =
DURABLE MEMORY / FLIGHT RECORDER / PROVENANCE / RECOVERY AUTHORITY

AGENTS.md and/or repository-wide agent instructions
    =
SHORT STANDING DOCTRINE THAT EVERY HRS CODING AGENT SHOULD KNOW

HRS VERSION CONVEYOR SKILL
    =
TASK-SPECIFIC EXECUTABLE PLAYBOOK FOR MOVING ONE KNOWN-GOOD VERSION TO THE NEXT

IDE / CODING AGENT
    =
HIGH-THROUGHPUT EXECUTION WORKER

USER + PLANNER
    =
INTENT, CONTINUITY, JUDGMENT, VALIDATION INTERPRETATION, AND OWNERSHIP OF COMPLETION

In short:

MANIFEST = MEMORY

AGENT INSTRUCTIONS = DOCTRINE

VERSION CONVEYOR SKILL = PROCEDURE

IDE = WORKER

USER + PLANNER = CONTINUITY AND JUDGMENT

### Why this separation matters

The flight recorder will continue to grow over the lifetime of HRS.

That growth is useful for:

- provenance;
- debugging;
- historical evidence;
- recovery;
- understanding why decisions were made.

But continuously injecting all historical detail into every routine agent task can itself
become a context cost.

Therefore future HRS automation should use layered context.

Layer 1 — standing doctrine:
small, stable instructions that apply almost everywhere.

Layer 2 — task skill:
the detailed Version Conveyor procedure loaded when performing a version migration.

Layer 3 — manifest / flight recorder:
consulted for current authority, historical evidence, recovery, or when the task requires it.

Layer 4 — current re-entry handoff:
the smallest precise description of where the immediately preceding agent stopped.

This provides both durability and context efficiency.

### Future HRS Version Conveyor skill

When IDE capability is available, consider creating a repository skill such as:

`.github/skills/hrs-version-conveyor/SKILL.md`

or another skill location supported by the active IDE/agent environment.

The skill should encode the mechanical workflow already discovered during HRS 1.2.1.

It should point to this manifest for authoritative project history rather than duplicating all
history inside the skill.

Its purpose should be approximately:

TAKE CURRENT KNOWN-GOOD HRS VERSION
    ->
LOAD CURRENT AUTHORITIES
    ->
APPLY TARGET VERSION INTENT
    ->
RECONCILE VERSION-COUPLED STATE
    ->
RUN STATIC VALIDATION
    ->
BUILD DETERMINISTIC CANDIDATE
    ->
CAPTURE EXACT ARTIFACT IDENTITY
    ->
PREPARE DEV TEST
    ->
RECORD EVIDENCE
    ->
LEAVE RE-ENTRY HANDOFF
    ->
STOP AT DELIBERATE PROMOTION/RELEASE GATE

The skill should automate procedure.

It should NOT invent product intent, architectural authority, build identifiers, promotion
authority, or release approval.

### Human-attention implication

External tooling guidance reinforces the existing HRS Human Attention Budget.

The purpose of persistent instructions and reusable skills is not merely to reduce machine
token consumption.

For this project, their greater value is reducing repeated human re-attention.

A successful HRS agent architecture should allow the user to define the next version once,
allow the IDE to execute substantial mechanical work without repeated supervision, and return
only when meaningful evidence or a genuine decision gate requires attention.

The user should not become the context-transfer mechanism between model sessions.

### Guidance to the next AI

If you are the next AI working on HRS:

Do not interpret this large manifest as a reason to create another large prompt manually for
every version.

Use it as durable project memory.

Prefer a layered architecture:

1. Read the current re-entry handoff.
2. Read standing repository/agent instructions.
3. Load the Version Conveyor skill when performing a version migration.
4. Consult this manifest for authority, provenance, or unresolved ambiguity.
5. Operate from the last verified gate.
6. Batch deterministic mechanical work.
7. Preserve meaningful human decision gates.
8. Leave a new re-entry handoff if your execution runway may end.

The design objective is:

DO NOT REDISCOVER THE PROJECT.

DO NOT MAKE THE USER RECONSTRUCT THE PROJECT.

LOAD THE MAP.
LOAD THE PROCEDURE.
CONTINUE FROM THE VERIFIED STATE.

If your execution environment fails or your context ends:

PRESERVE THE STATE.
LEAVE THE TRAIL.
WE WALK FROM HERE.
