# HRS 1.2.7 top-to-bottom review

Owner request and review date: **2026-10-04**.
Public name: **New Player Random Start**. DEV checkout: `QA_fresh`.

**The presentation and payload identities are coherent. Repair the two runtime
logic defects below before exporting a new customer QA candidate.** The source
release gate passes its identity/structure checks; that does not clear these
behavioral findings. The wrong-folder setup path also needs a bounded repair.
The smaller status issue can be handled in that same manager pass.

This review inspected the current manager and graphical recipe, launcher
modules, all 15 runtime sources, build/payload contracts, customer guidance,
public-copy draft, evidence and QA/export wiring. Three parallel read-only
reviews covered manager behavior, runtime and release provenance. Root review
checked the current native window and challenged findings against source and
direct observations. No implementation was changed.

## Findings requiring implementation

### F1 — P1: recovery becomes available after movement has already happened

In OnGameUpdate, the player and chunk
observer move at lines 346–347. `BeginPlacement` only sets `PlacementCalled`
after the semantic comparison, at lines 358–359; its setter is in
PendingPlacement.

If the semantic comparison fails at lines 352–354, or an exception occurs
after the first movement and before `BeginPlacement`,
FailPending sees `PlacementCalled=false`
and skips restoration. It clears `pending` and records failure even though
the player may still be at the attempted candidate. This contradicts the
intended fallback to the original start.

This is a confirmed source ordering defect, not a newly observed gameplay
failure. Arm position recovery before the first mutation while preserving
the existing verification schedule and bounded retry behavior. Verify the
real path with failures after player movement, after observer movement and
during semantic comparison, plus a successful placement. Preserve the
durable no-repeat marker; this repair must not grant a reroll.

Include one related identity check in that repair review:
the world-reference/GUID rejection at lines 320–324 calls `FailPending`, but
restoration resolves the entity from the current world at lines 882–889.
It does not prove that this is the pending attempt's original world. A
replacement world with the same entity ID could receive the former world's
position. The missing check is visible in source; that engine sequence has
not been demonstrated. Test a changed-world context and ensure recovery
cannot move an entity in a different world.

### F2 — P2: the follow-up quest hook bypasses the Game Name guard

IntroRouteSetupPositionPrefix checks
Random mode, the objective ID and completed player/trader markers. It does
not call the existing runtime environment/name guard before changing the
`intro_buried_supplies` biome filter at lines 845–846.

With policy targeting Game A, a previously HRS-started character in Game B
can meet those marker/objective conditions even though its spawn was rejected
for `GAME_NAME_MISMATCH`. The global Harmony prefix can still modify its
follow-up quest. This is a confirmed guard omission; its gameplay frequency
is unmeasured.

Apply the existing name/context check before modifying the objective. Verify
a matching target still receives its intended route, while another Game Name,
an unsupported context and an unmarked character leave the objective intact.
Use the existing RuntimeEnvironmentGuard
boundary rather than inventing a second definition of target scope.

### F3 — P2: a wrong game-folder choice terminates first-run setup

Select-HrsGameRoot presents one folder chooser,
then throws if the user selects an invalid folder at lines 610–615. The call
at line 618 occurs before the manager form exists and outside a GUI error
handler. START.bat returns the process error and exits.

A newcomer selecting the Steam folder instead of the game folder loses setup
instead of receiving a persistent explanation and an opportunity to correct
the selection. In a normal double-click launch the transient console can close.
Show a short explanation and reopen the chooser. Cancel should close cleanly.
Verify wrong folder → corrected folder, discovery of one/multiple installations
and cancellation through the actual customer entry point without game actions.

### F4 — P3: a resolved blocker can remain the main status message

A Launch failure saves `managerError` at p0158.ps1:2107.
Later activation refreshes current guards and can enable Launch, but
Update-HrsStatus continues to prioritize that previous
error. Settings changes clear `managerNotice`, not `managerError`.

For example, a failed Launch followed by reopening Steam can leave an old
`STEAM_NOT_RUNNING` message beside an enabled Launch button. This is a source
state-flow finding; the real Steam sequence was not executed during review.
Retain the old diagnostic in history/details, while the main status reflects
current readiness. Verify the failed → resolved transition and ensure a still
unresolved error remains clearly represented.

## QA and engineering handoff gaps

- **Carry metadata provenance into the isolated QA context.** The draft
  release contract links the public-name metadata receipt,
  but Export-HrsCandidate.ps1
  currently includes only release/case contracts, build record and C# sources
  in its engineering companion. Include the authenticated receipt and original
  `ModInfo.before.xml` in the separate QA transfer/context, or add bounded
  optional companion inclusion. Customer payload pins are correct. Keep this
  engineering evidence outside the customer ZIP.
- **Explicitly exercise existing-world eligibility.** The current
  README and foundation permit a supported existing
  world with a fresh character. Landing requirements
  and newcomer goals still emphasize fresh saves. The
  upcoming QA plan should include a fresh character in an existing supported
  world, a name configured before its world/save exists, an exact-name
  mismatch, and an already-played character reload. Current case definitions
  and all 46 Pending dispositions were preserved in this review.

## Presentation and customer flow

The current native capture shows the intended light
Bit Wrecked surface at **712 × 710**, picture-only circular 56px logo, restrained
orange highlights and white outlined Apply. Header, selection, state, actions
and footer are visible in this profile. The embedded Quiet recipe is Current;
the workbench is applied to the real manager, not merely a separate preview.

Keep the main controls: Game Name, Standard/Random, biome choice, optional
protection, Apply, Launch and Uninstall. The owner agreed to leave manual
Restore out of the customer screen. Keep automatic failed-Apply and in-flight
placement recovery; history helpers remain useful for DEV/QA/support.
None implements undo of a completed, saved landing.

Apply and Launch remain separate. Settings Applied requires acknowledgement;
Launch freshly verifies installation and current settings. Unsaved edits do
not mutate the Bridge policy. Owned-file removal preserves saves and progress.
Those paths are coherent in source, apart from the findings above.

The mandatory exact-name explanation is reachable in Help and accessibility
description, but not visible beside the field in the compact layout. A small
inline hint using the existing recipe text is an optional newcomer improvement;
avoid restoring the earlier wall of explanatory text. Keep the selected public
title and game/version subtitle. The public-copy draft uses natural game and
feature wording and remains unpublished.

The ordinary setup route matches the
foundation: one active policy per installation,
exact case-sensitive Game Name, actual-world POI lookup and fresh-character
eligibility. Historical coordinates are not the active selector. Any uses equal
chances across eligible biomes; weighted selection normalizes eligible weights.
Retries remain inside the selected biome and stop after five POIs. Protection
has its stated environmental-hazard limits. Trader routing uses real placed
traders and retains the documented first-session limitation.

## Checks, counter-evidence and limits

The verification record and adjacent receipts contain:

- Fresh source gate: **readyForQa=True, zero errors/warnings**. This is the
  automated gate result, not approval to ignore F1/F2.
- Native Windows PowerShell 5.1 parsing: **15 manager/launcher/build/graphics
  scripts, zero parse errors**. Test harnesses were not rerun.
- Generated design check: **Current, Embedded=True, Changed=False**.
- Consistent version/build identity and all **15 compiled-source hashes**,
  checked against both build and release records in the
  source-pin comparison.
  DLL: 76,800 bytes; current public-name XML: 410 bytes. Manager pins, contract
  and build record agree. The original build record remains preserved.
- Before/after SHA-256 comparison: **44 protected source/tool/artifact/contract/
  registry/public-map files unchanged**. Capture/read-only UI metadata added
  evidence only. No Apply, uninstall, game launch, new build, export or commit.

An initially suspected stale result accessibility name is **not a confirmed
customer defect**. Source initializes an explicit name that later text updates
do not set, but the actual UI snapshot correctly
reports “Last start: earlier settings.” Its generic pane classifications indicate
a fallback provider, so it does not qualify richer MSAA/Narrator behavior.
Keep actual keyboard, screen-reader and high-contrast checks in independent QA;
do not prescribe a speculative accessibility repair from this snapshot.

Other existing boundaries remain explicit: one Random transaction per game
process; an interrupted Reserved marker does not reconstruct the in-memory
landing transaction; b17 is the recognized qualification target. Unknown builds
are best-effort, and the installed local assembly differs from b17. The preserved
reference-only build root is not a playable QA environment. These observations
do not establish a new gameplay pass or certify every custom map.

## Next work order

1. Repair F1/F2 through the existing runtime paths and verify the related
   world-identity rejection. Run targeted valid/failure cases, then a pinned
   deterministic rebuild and refresh source/build/payload contracts together.
2. Repair F3/F4 in the manager; check the actual folder-choice and resolved-error
   paths plus affected Apply/acknowledgement/Launch guards. Preserve the compact
   layout and the current absence of a Restore control.
3. Add the explicit scenario/evidence handoff coverage above and refresh gates.
   Export a new immutable customer candidate only after the repaired source
   and package checks pass. Preserve every frozen 1.2.6 artifact.
4. Start independent QA with equivalent physical reproductions of the three
   returned sizing failures, then customer entry/install/upgrade/removal,
   accessibility, uncoached setup and qualified gameplay including trader routing.

Candidate `1.2.7-qa.001` remains **draft, unexported and unreserved**. All **46**
independent cases remain Pending. This review supplies a concrete repair order;
it does not execute those repairs, independent QA or publication.
