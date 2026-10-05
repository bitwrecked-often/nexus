# HRS 1.2.6 trader-session notice — DEV manifest

**Current presentation handoff — 2026-10-04:** `1.2.6-qa.003` is frozen and
independently package-verified after the owner-approved native UX round. The
readiness record and
UX manifest are the current resume points.
Use the new portable transfer's `qa-003/START-HERE.md`; all **46 independent QA
cases remain Pending**. The qualified runtime and first Random-session trader
limitation are unchanged. QA precedes Nexus and the site; no publication
occurred. Earlier 002/001 checkpoints below are preserved history.

## Preserved candidate 002 checkpoint — 2026-10-03

Status: **polished 1.2.6-qa.002 frozen, independently extracted and verified;
41 independent QA cases Pending; publication pending**. The
current QA readiness record identifies
the exact distribution ZIP, qualified runtime reuse and local game-fingerprint
mismatch. The owner selected independent QA before Nexus. Unrun manual and
gameplay checks remain unrun, not passed. The
publication handoff retains the original
001 record as preserved history beneath its current 002 update.
The portable QA transfer is built and independently verified; use its
`qa-002/START-HERE.md` and the readiness record's exact archive links.

**2026-10-03 source update:** the owner requested a minimalist Bit Wrecked
manager and public-copy polish. See the
UX work manifest for implementation and
offline verification and the 002 packaging checkpoint. The current manager,
picture-only logo and README are included in frozen `1.2.6-qa.002`. The original
`1.2.6-qa.001` archive, receipt, companion and build record remain unchanged.
The unchanged deterministic b17 runtime and all 15 runtime source files were
authenticated against 001 for reuse; no rebuild or current-game certification
is claimed. The trader notice and runtime route behavior described below are
preserved. Earlier build/DEV/export checkpoints describe their recorded inputs.

## Baseline and decision

The QA return manifest
and finding
are the change contract. In one run, a player left Wasteland before Journey to
Settlement assigned a trader, then returned to a Pine Forest trader objective.
The failing log lacked a completed route decision. The exact lifecycle cause
is still a hypothesis. This lane implements the approved session notice; it
does not claim a runtime repair.

The source baseline is `1.2.5-qa.002` (frozen ZIP SHA-256
`90C404EBE1A974448CA85529C1D1274DE6D2429B0A404BBB8E89323584A5966D`).
Lane provenance hashes 52 copied source
and customer-input files. Prior QA binaries, case dispositions, and generated
state were not copied into this lane. The public-release map remains unchanged.

## Bounded implementation

- Preserve the pre-write Yes/No confirmation. After Yes, block Launch Game,
  apply the policy, and complete readback before showing **Settings Applied**.
- The success popup restates exact Game Name, biome selection, and protection.
  Every Random selection includes the first-session warning. Standard omits it.
  Launch stays disabled until OK; after OK it requires a closed game and running
  Steam. Form activation refreshes that condition after Steam starts.
- A failed Apply shows only its error and leaves Launch blocked for that
  attempt. There is no automatic launch.
- The customer README says to complete the opening tasks in the same session
  until the Journey to Settlement trader marker appears. The player may visit
  the trader later. If the player exits earlier, the landing stays saved but
  the quest may point to Pine Forest on return.
- Runtime trader routing, placement, and protection behavior are unchanged.
  Only `ModInfo.xml` and sanitized log version labels change from 1.2.5/r125
  to 1.2.6/r126. `SkipWithAntiCheat=true` remains in ModInfo.

## Build and available evidence

The pinned Windows PowerShell 5.1 build used game `Assembly-CSharp.dll` SHA-256
`AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146`
(V3.3.0 b17) and SDK 10.0.401. Its deterministic double build passed;
`d0163.dll` SHA-256 is
`E5EA99BBD4DBAE122264835CC2090157F3A549C0E6FB379EB5DF5860EEF56D7B`.
The build record is under `hrs_1.2.6/dev/qa/trader-notice/`.

Disposable manager callback fixtures cover Standard success/cancel, every
Random selection (Any, five Chosen, two Weighted, including protection On),
and injected Apply failure. They capture the popup after the policy file
exists while Launch is disabled, and check warning inclusion/exclusion. See
`hrs_1.2.6/dev/qa/trader-notice/` for exact records. These fixtures replace
modal display with capture; they do not prove live popup legibility.
The manager's actual `START.bat -SmokeTest` passed without installation or
launch. A disposable ownership fixture passed fresh install, 1.2.5-to-1.2.6
upgrade, exact inventory, conflict refusal, and uninstall. Policy and compiled
codec checks passed (71 assertions and seven fixed vectors). Twelve offline
runtime consumer cases and seven compiled-DLL startup/preflight cases passed;
these are regression checks for unchanged routing, not live gameplay evidence.
The startup and consumer records are in the same evidence folder. The 1.2.5
QA command-path test was not copied as an active 1.2.6 test because it depends
on a generated 1.2.5 contract-draft output; QA command-path validation belongs
to the new candidate export.

A local r001 DEV set was copied
outside OneDrive and its own `START.bat -SmokeTest` passed. No live Apply or
game installation was performed during this setup.

The subsequent r001 live manager observation
records an operator-attested Random/Any/protection-On **Settings Applied**
popup, disabled Launch until OK, and an enabled Launch afterward with Steam
running. The installed policy and exact payload hashes passed read-only
validation. A prior storage-location rejection was fail-closed; its manager
path was not established. A subsequent Standard Apply showed the verified
settings popup without a first-trader warning, and policy revision 4 read back
as Standard. A Steam-closed Random/Any Apply showed the warning and left
Launch disabled after OK; starting Steam enabled Launch in the same manager.
The revision 5 policy digest validated. Remaining live gates below are still
pending.
The first live storage rejection supplied the visible failed-Apply branch:
there was no success popup and Launch stayed disabled. The separate disposable
callback fixtures deliberately injected failures during policy readback and
after DLL copy, confirmed rollback and the same blocked Launch state. Together
these cover the safe failure check without intentionally damaging the live
game installation; the first manager window's exact folder remains unknown.

Candidate contract preparation preceded the export. The exact b17
double-build record was copied to
`hrs_1.2.6/dev/builds/1.2.6-qa.001/build-record.json`; its SHA-256 is
`D0A4BF534D275A39DBD0A4D531E91EC5E7C72AD39640EA30B90819C27A582FDE`.
`qa_cycle/New-Hrs126Contract.ps1` generated `rel.json` and `cases.json` from
the pinned game, Harmony, source and payload. The release gate reports
`readyForQa=True`, zero errors and warnings; this mechanical result does not
override the human DEV acceptance gates below. The contract has 41 distinct
Pending cases, including the notice, uninterrupted first-session assignment,
early logout, post-assignment return and cross-biome fallback. QA tooling
passed 61/61, candidate-workflow fixtures 39/39, and checkout-byte checks
passed. The source README now uses player-facing version wording so an
approved customer ZIP does not carry a stale DEV label. The exported customer
ZIP was independently extracted and passed its manager smoke test; it has not
had a live game run from those exact bytes.

## Acceptance before QA export

Owner disposition on 2026-09-30: the live Random and Standard notice checks,
Steam-closed Apply/refresh, safe failure behavior and automated selection
fixtures were accepted as sufficient to export. Remaining fresh-tester,
Chosen/Weighted live popup, actual display-scale and exact customer live-game
checks were deferred by owner direction, not marked Pass. The candidate was
exported as an explicit exception to the original ordered gate below.

1. In an isolated game installation, run a real Random Apply. Verify the
   installed policy readback precedes **Settings Applied**; inspect its exact
   text and Launch state before and after OK. Check Standard omits the warning.
2. Force a safe Apply failure. Verify no success popup and blocked Launch.
   Apply with Steam closed, acknowledge success, start Steam, then return to
   the manager; verify Launch becomes available without restarting it.
3. Have a new tester explain that the opening tasks continue in the first
   session until the Journey to Settlement marker appears; trader visit may
   happen later. Verify the README communicates the same boundary and the
   known limitation.
4. Check actual Windows scaling at 100%, 150%, 200%, and 225%. The earlier
   1.2.5 225% check is prior-source evidence; it is not a 1.2.6 pass.
5. Export a new immutable candidate, verify its exact-byte contract, receipt,
   file hashes and extracted folder layout. From its own extracted `START.bat`,
   verify Apply, launch, upgrade and uninstall with EAC off and the supplied
   `0_TFP_Harmony`. Record tested build separately from best-effort builds.

The frozen 1.2.5 QA ZIP and its transfer files remain untouched. The
uninterrupted trader assignment, early logout, post-assignment return and
cross-biome fallback cases remain Pending. The owner has chosen the future
public label **Tech Demo** and clarified that independent QA must complete
before Nexus publication. Actual upload has not occurred.
