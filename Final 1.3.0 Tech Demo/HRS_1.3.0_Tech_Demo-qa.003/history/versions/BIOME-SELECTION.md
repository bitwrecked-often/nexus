# Historical Random Start: biome selection dev manifest

**Current execution order:** the user requested wiring review and an isolated
DEV acceptance round before the next QA package. Follow
the 1.2.5 wiring/DEV manifest.
This document remains the behavior contract. Its earlier direct-to-QA next
step is superseded; `1.2.5-qa.001` and its evidence remain preserved.

Status: **implemented in 1.2.5; candidate 1.2.5-qa.001 exported and verified; human QA pending**
Baseline: **1.2.4-qa.001** (7 Days to Die V3.3.0 b14; Windows, PowerShell 5.1, local single-player)
Purpose: Let a new Random-mode character start in any eligible biome with equal biome odds, in a requested biome, or according to player-set biome weights.

The user explicitly selected **1.2.5** on 2026-09-27. New source and evidence
are in `hrs_1.2.5`; earlier references to a future 1.2.4 candidate are historical.
See current readiness and
implementation review.

This is the governing development copy transferred from the QA solution on
2026-09-27. The as-received handoff packet is
`hrs_1.2.4/dev/qa/BIOME_SELECTION_DEV_PACKET.md`;
the approved interaction prototype is under
`hrs_1.2.4/dev/prototypes/biome-selection/`.
The original QA solution and the frozen `1.2.4-qa.001` ZIP remain untouched.
This document records design and acceptance, not a new build or QA result.

## Product promise and boundary

HRS records the player's **starting-biome intent** under the exact Game Name
before launch. It does not need the generated world's name. At the real first
spawn, the runtime resolves approved placed POIs in the active world, derives
the eligible biome set, draws one target biome using the saved method, and then
uses the existing guarded five-attempt placement path inside that biome.

Keep four states separate in manager copy, runtime diagnostics, and QA evidence:
**requested** (the policy), **eligible** (what this world actually contains),
**selected** (the single drawn target), and **completed** (the verified landing
biome, or ordinary-start fallback). A selected target is not a completed
arrival. A trader in another biome is a quest-routing fallback, not a new
starting-biome draw. Hazard protection follows only a completed HRS arrival's
actual starting biome.

Player-facing wording for Chosen must say **"Try to start in [biome]. If no
safe start is available there, use the normal start."** The manager cannot
know a not-yet-generated world's eligible placements before launch. The weight
dialog shows the *configured* proportions; the runtime removes absent biomes
and renormalizes. Neither display guarantees completed-landing frequencies,
because safety checks can return the player to the ordinary start. Do not
claim the three observed QA starts show a Forest bias.

## Mechanical outline — expand as implementation evidence arrives

| Step | Existing 1.2.4 anchor | Amendment | Evidence to record |
| --- | --- | --- | --- |
| Configure | Manager binds policy to exact Game Name | Save `Any`, `Chosen`, or `Weighted` separately from Standard/Random and protection | Manager readback and policy bytes |
| Discover | `GetWorldPrefabs` builds the approved placed-POI index at first spawn | Group those placements by their actual approach-point biome | Eligible pool and biome-name mapping on both supported world types |
| Decide | `PlacedPoiResolver.TrySelect` already draws uniformly among eligible biome groups | Apply requested method to **groups**, select one group once | Deterministic draw and absent/zero-weight cases |
| Preflight | Trader status is checked after POI selection and before reservation; late metadata has a bounded wait | Keep the selected biome while waiting; require a real route somewhere in the world | Ready, delayed, empty and unavailable trader cases |
| Land | Five distinct placed-instance attempts, rollback, settling and one-shot markers already exist | Retry only within the selected group | Attempt identity, rollback, final biome and marker state |
| Continue | Intro trader routing and optional arrival protection use the completed start | Route to a real trader and protect only the actual completed starting biome | Human-visible quest, hazard, reload and respawn observations |

The amendment is a new input to the **Decide** step, carried through the
manager/runtime policy. It is not a new world-generation workflow or a new
relocation engine. A biome with an eligible POI can be selected even when its
trader is elsewhere; the existing cross-biome trader fallback remains separate
from the start-biome draw.

**Change boundary:** extend the biome draw at `PlacedPoiResolver.TrySelect` and
transport the validated selection through the manager/runtime policy. Preserve
the existing placed-world scan, five distinct-instance attempts, rollback,
chunk wait, terrain clearance, settling, trader preflight and intro routing,
starting-biome protection, one-shot marker, and ordinary-start fallback. Do
not rewrite those paths to implement biome preference. If a focused test finds
a defect in one of them, record the failing evidence and make the smallest
repair that addresses it, then rerun the affected entry-path and regression
checks. The coordinated policy and manager upgrade is real integration work,
even though the landing algorithm's new decision is narrow. This follows the
development doctrine.

## Why this work exists

The 1.2.4 QA tester confirmed that Standard and Random starts work. Two of three Random trials landed in Forest. Three trials do not establish a probability defect, but they showed a product issue: players cannot choose whether the first day should be broadly unpredictable or favor a harsher biome. The next candidate needs explicit, visible control over the biome draw.

## Approved Windows UX

Use the existing native WinForms manager style and launch path. `START.bat` invokes `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File` for the manager. The approved standalone prototype is at:

`hrs_1.2.4/dev/prototypes/biome-selection/START.bat`

Its form source is `dev/ui/BiomeSelectionPrototype.ps1` relative to that
prototype folder. It is a visual and interaction reference only; its Apply
Settings button does not write a policy or install a mod.

Keep the current **Standard** and **Random** radio buttons and exact **New game name** field. Under Random, add a compact **Random starting biome** section with these selection methods:

| Selection | UI behavior | Runtime meaning |
| --- | --- | --- |
| Any biome (equal chance) | Default choice; no extra controls | Draw uniformly from biomes with an eligible placed POI in the active world. |
| Choose a biome | Show Forest, Burnt Forest, Desert, Snow, Wasteland dropdown | Attempt only the requested biome. |
| Set custom weights | Open the separate native **Edit weights...** dialog | Draw among eligible biomes in proportion to their positive weights. |

The custom dialog has five integer controls, each from 0 through 100, and shows
the percentage normalized across the **configured** five values beside each
biome. Label this a preview of configured weights, not odds for an unknown
world. Its prototype defaults are **Forest 10, Burnt Forest 20, Desert 20,
Snow 25, Wasteland 25**. A zero weight excludes that biome. Block saving an
all-zero set. Cancel must discard uncommitted dialog edits. Retain committed
values while the manager stays open, including when switching selection
methods. When opening an already configured game, show its saved selection
rather than silently resetting the form to Standard. For a completed character,
state that changing settings will not trigger a second HRS start.

Keep **Protect from hazards in starting biome** as a separate checkbox. It
affects protection after a completed arrival and never changes selection odds.
Preserve the manager's confirmation popup, Apply Settings, Launch Game,
Uninstall Mod, and game-root display. Confirmation must show the exact Game
Name, method, chosen biome or weights, protection state, and ordinary-start
fallback. Main and weight-dialog controls must remain readable at Windows
display scaling of 100%, 150%, and 200%; fit the main form within the available
screen height or provide working scroll access. Use keyboard-reachable controls,
logical tab order, clear labels and accessible names. Prefer a layout container
for the new section over adding more hard-coded vertical coordinates to the
existing form; verify behavior in the actual PowerShell 5.1 host rather than
assuming a modern .NET project DPI setting applies.

## Runtime selection contract

The development source already implements the Any draw in
`PlacedPoiResolver.TrySelect`: it groups resolved placed POIs by biome and
draws uniformly from the eligible biome keys. The amendment extends that one
decision point to Chosen and Weighted. It must not rebuild the placement,
rollback, settling, trader, or protection machinery. The three QA Forest
observations do not call for tuning the existing random generator.

1. Use the existing curated historical catalog and actual placed POIs in the active world. Resolve each candidate placement to one of the five supported biome categories. Keep the current supported map scope: Navezgane and Random Gen worlds of at least 8K.
2. A biome is eligible for the draw only when at least one catalog-approved placed POI exists there. Do not substitute map area, raw biome area, or total POI count for biome odds.
3. **Any biome:** each eligible biome has probability `1 / eligibleBiomeCount`. **Chosen biome:** its probability is 1 if eligible. **Custom weights:** for each eligible biome with a positive weight, probability is `weight / sum(eligible positive weights)`. Ignore absent biomes and zero weights when normalizing.
4. Select one biome first. Then retain the 1.2.4 within-biome behavior: attempt at most five distinct placed POI instances in that biome, with the same guarded placement, rollback, and verification. A failed attempt does not silently move the player into another biome.
5. If the chosen biome is absent, the weighted eligible pool is empty, all attempts fail, or no usable trader route can be established, keep the ordinary start. Report a specific sanitized reason. Never report a requested-biome arrival unless placement completed there.
6. Preserve the one-shot completed marker: reload, ordinary respawn, and changing manager settings for an already started character do not draw another destination. Preserve current trader behavior, including a real trader in another biome when needed, and current starting-biome hazard protection semantics.
7. Log the selection method, requested biome or weights, eligible biome pool, selected biome, attempted POI biome, and final outcome in the existing sanitized diagnostic style. These fields must let QA distinguish biome selection from later safety fallback.

The current `PlacedPoiResolver.TryResolveBiome` mapping is:

| UI category | Application ID | Game biome names currently accepted |
| --- | ---: | --- |
| Forest | 3 | `pine_forest`, `forest` |
| Burnt Forest | 9 | `burnt_forest` |
| Desert | 5 | `desert` |
| Snow | 1 | `snow` |
| Wasteland | 8 | `wasteland`, `city_wasteland`, `wasteland_hub` |

This is source observation, not new cross-world QA. Keep one explicit mapping
for selection, completed-biome marker and protection; verify it on Navezgane
and Random Gen V3.3.0 b14. Reject unknown runtime biome names instead of
coercing them to a display label. Use an integer cumulative draw for Weighted
and a deterministic seam in focused tests; never weight by placement count.
Select the biome once before the first attempt and retain it across all retries.

The result contract should distinguish at least: requested biome absent,
weighted eligible pool empty, placed-POI pool empty, trader route unavailable,
and five-attempt safety exhaustion. Keep existing marker semantics: an
unreserved preflight rejection leaves the marker absent; a placement that
reserved the one-shot marker uses the established rollback/failed-marker path.
Never mark a failed placement completed, and do not automatically redraw on
reload to hide a failure.

## Policy, upgrade, and deployment contract

The current manager and DLL accept only `Standard`, `Random`, and `RandomSafe`
in exact-shape `hrs-policy/v1` JSON. Both sides validate the canonical field
order and SHA-256 policy digest. The new controls therefore require a
coordinated policy revision and newly built runtime. Keep the top-level
mode/protection meaning and add a separate biome-selection setting; do not
encode biome choices as additional `mode` values. The selected schema and
bridge filename must be fixed with cross-language canonical test vectors
*before* wiring the form, deployment and recovery consumers. A new v2 policy
must never be silently interpreted by the old v1 DLL.

Define a versioned policy with these logical fields: exact Game Name, revision,
Standard/Random/RandomSafe mode, selection kind (`Any`, `Chosen`, `Weighted`),
chosen biome when applicable, all five integer weights, timestamp, and digest.
The manager and DLL must agree on canonical serialization, digest input, valid
ranges, inactive-field canonical values, and mapping to runtime biome IDs.
Update policy readback, atomic writing, bridge ownership, deployment inventory,
recovery history/snapshots, and result correlation where the revised policy
affects them. Ensure only one policy is authoritative after upgrade; reject
ambiguous or malformed bridge state. Preserve the current atomic replacement
and readback pattern rather than introducing partial policy writes.

On an explicit upgrade Apply Settings action, migrate an existing 1.2.4 policy as follows: `Standard` remains Standard; `Random` becomes Random with Any biome; `RandomSafe` becomes Random with Any biome and protection on. Preserve exact Game Name and advance the revision. Do not discard saves, progress, unrelated files, or completed one-shot markers. Reject unsupported game builds and mismatched package/runtime hashes as the current manager does.

The extracted `1.2.4-qa.001` package contains PowerShell manager modules and a
verified `d0163.dll`, but no C# source, as expected for a customer ZIP. The
matching development source **is present in this repo** under
`hrs_1.2.4/dev/src/runtime/main/`, including `PlacedPoiResolver.cs`,
`PolicyV1.cs`, and the trader/arrival consumers. The repo's verified DLL
SHA-256 is `D0B4F6EC8E7E17042869484AAC608BFB8472F0C348C2063FA08245BDEDA08617`,
matching the QA packet. Its pinned build recipe and candidate build record are
under `hrs_1.2.4/dev/src/runtime/p0143.ps1` and
`hrs_1.2.4/dev/builds/1.2.4-qa.001/`. Do not reconstruct from the older
`nexus1` prototype. Confirm source/build provenance as Batch 0, then extend
this 1.2.4 source; changing the GUI alone cannot change landings.

## Research context and work order

Public research reviewed 2026-09-27. These are existing public discussions,
not a new community consultation or a representative player survey:

- A player on [r/7daystodie asked to begin directly in Wasteland for a
  challenge](https://www.reddit.com/r/7daystodie/comments/1re5b76/spawning_in_a_different_biome/).
  Another [reported a world with no nearby Forest trader for the intro](https://www.reddit.com/r/7daystodie/comments/1uxpagg/worlds_generating_without_traders/).
  Product inference: offer both surprise and a chosen challenge, but keep
  ordinary-start and real-trader fallbacks visible. Neither post proves a
  V3.3.0 HRS defect.
- In [The Fun Pimps prefab/RWG forum thread](https://community.thefunpimps.com/threads/prefab-to-rwg.46839/),
  modders describe placement depending on tags, sizes and generator bias;
  the same seed did not initially spread a prefab across the requested biomes.
  Engineering inference: world area or configured biome labels cannot stand in
  for actual placed eligible instances. The live placed-world index remains
  authoritative.
- The [ISI Randomized Traders mod's own implementation notes](https://github.com/IronSharkInc/ISI_RandomizedTraders)
  explicitly adjust Journey to Settlement and trade-route quests when trader
  geography changes. That is peer-mod evidence for testing the full opening
  journey, not authority for changing HRS's existing trader policy.
- Microsoft's [WinForms layout guidance](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/controls/walkthrough-arranging-controls-on-windows-forms-using-a-flowlayoutpanel)
  recommends layout panels for controls that must reflow. Its
  [NumericUpDown guidance](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/controls/numericupdown-control-overview-windows-forms)
  supports bounded 0–100 integer entry; its
  [accessibility guidance](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/advanced/properties-on-windows-forms-controls-that-support-accessibility-guidelines)
  calls for meaningful names and tab order. These support the approved compact
  main form and separate weight editor; compatibility must be checked in the
  actual Windows PowerShell 5.1 WinForms host.

### Ordered DEV batches and stop points

The user can perform **UX-only QA now** by opening
`hrs_1.2.4/dev/prototypes/biome-selection/START.bat`: inspect Any, Chosen and
Weighted; open and cancel the weight editor; check all-zero rejection; verify
buttons and labels at the user's actual display scaling. Record screenshots
and wording feedback. This prototype cannot validate policy persistence,
installation, game launch or any landing. Full gameplay QA waits for Batch 4's
new extracted customer ZIP.

0. Record the candidate/source/build identities, source mapping and current
   Any-biome behavior; preserve `1.2.4-qa.001` and the existing QA feedback.
   The earlier QA packet's missing-source warning is closed for this checkout.
1. Specify policy v2 (including filename and canonical inactive fields) and
   make manager/runtime test vectors match. Exercise valid v1 migration,
   malformed/tampered/ambiguous files, revision advance, readback, owned
   upgrade and removal before any gameplay test.
2. Extend only the existing eligible-biome draw to Any, Chosen and Weighted.
   Retain one biome for all five distinct-instance attempts, rollback, trader
   preflight, protection and one-shot markers. Test deterministic draws and
   every terminal fallback, then review the source diff.
3. Connect the approved WinForms prototype to the real manager. Check saved
   selection readback, editing/cancel, confirmation, launch, ownership,
   keyboard access and 100/150/200% scaling in the actual host.
4. Build with the qualified V3.3.0 b14 recipe, run the release gate, export a
   fresh unused candidate ID, verify the immutable ZIP and isolated extraction,
   and test the extracted manager. A DEV compile is not QA evidence.
5. Hand that exact ZIP to the user for live QA. The user checks Navezgane and
   an 8K-or-larger Random Gen world: Standard, Any, each available Chosen
   biome, Weighted with zero and nonzero values, requested-biome absence,
   five-attempt exhaustion, trader/intro, protection, reload and respawn.
   Capture package hash, game build, Game Name, world identity, selected
   policy, sanitized log/result and human-visible outcome for each case.
   Stop before publication; only the exact QA-passed ZIP can be considered
   for Nexus and the site.

The user performs the live game interactions; automation prepares policy,
observes logs and records evidence. Do not use simulated selector passes as a
substitute for the user's actual landing and quest observations.

## Verification before a new QA package

- Policy round trips through manager and DLL with identical digest; malformed schema, unknown biome, invalid weight, all-zero Weighted selection, reordered fields, and tampered digest fail closed.
- Deterministic selector tests cover equal biome odds independent of placement counts, weighted normalization after absent biomes are removed, zero weights, a single positive weight, and a chosen biome absent from the world.
- Manager tests cover reopening a saved selection, switching modes without losing entered weights, canceling the weight dialog, protection independent of biome odds, and the existing confirmation, upgrade, uninstall, and ownership checks.
- In-game QA covers Standard, Any, each chosen biome available in the world, custom weights, safe fallback, trader route, protection, reload, and respawn on Navezgane and supported Random Gen worlds.
- Visual QA at 100%, 150%, and 200% scaling checks the main popup and the separate weight dialog for clipped controls, overlap, and access to bottom buttons.
- Package a new candidate ID and version with updated DLL/ModInfo hashes, manifest, README, and a clean ZIP. Test the extracted ZIP through its own `START.bat`. Do not change the approved `1.2.4-qa.001` artifact in place.

## Details to fill as the work proceeds

These are deliberate open entries, not permission to skip a gate. Add exact
identities and results when each batch reaches them; distinguish source
observation, DEV test, customer-package QA and publication approval.

| Item | Current position | Fill in with evidence |
| --- | --- | --- |
| Policy schema and bridge filename | Versioned revision required; exact v2 bytes not yet chosen | Canonical field order, inactive-field values, digest vectors, old/new file ownership and migration results |
| Selector seam | Reuse `PlacedPoiResolver.TrySelect` and the existing game RNG | Final function boundary, deterministic fixtures, eligible-set examples and bounded-draw results |
| Sanitized result reasons | Distinct selection and safety outcomes required | Final enum/string names, manager mapping and real log examples |
| WinForms integration | Approved standalone prototype only | Real manager source diff, saved-state readback, confirmation copy, keyboard/scaling screenshots |
| Runtime build | Qualified V3.3.0 b14 recipe exists | New source hash, pinned inputs, two-build equality, DLL/ModInfo hashes and release-gate result |
| New QA candidate | `1.2.4-qa.001` remains frozen | Unused candidate ID, ZIP/receipt hashes, isolated-extraction result and exact tester copy |
| Live player QA | Not started for biome selection | World/Game Name, requested/eligible/selected/completed states, quest/hazard/reload observations, pass/fail per case |

Revisit the design only when an observation contradicts it. Record the specific
finding and the smallest amendment here before changing player-facing
semantics or broadening supported worlds.

## Incremental work journal

Use this section as the resume point for short sessions and optional bounded
agents. Add a dated entry when a session changes source, contracts, evidence,
or batch status. Each entry names the batch, repository HEAD and dirty files,
decision or change, exact command/result, evidence location and class, open
question, next single action, and owner of any running game/build. The
integration owner reconciles parallel results here before advancing a gate.

**2026-09-27 checkpoint — design handoff, Batch 0 pending.** HEAD at packet
creation: `8354ea979235ebdaa88e4fa2c69ba011f89fd2e4`; biome design,
prototype transfer and handoff files are uncommitted. Frozen candidate:
`1.2.4-qa.001`, ZIP SHA-256
`6FDECA0D76AD233A80B70493C7714F1E7FD277EEAC6FA56FD423112B1482F5C5`.
No policy v2, runtime selector change, manager integration or new QA candidate
exists. Next single action: verify the current checkout, candidate/source/build
pins and live selector seam for Batch 0, then record the result before choosing
policy v2 bytes. No game or build is running for this checkpoint.

## Handoff output

**2026-09-27 implementation checkpoint — Batches 0–4 delivered to QA.**
Base HEAD `19804e2c97886e516326b73b435fe9eb2093b8b8`; source and contracts
are uncommitted working-tree bytes. The received `QA_Return_20260927/` and
`QA_upload_after_Review_and_Change_Suggestions/` remain untouched/untracked.
New files are under `hrs_1.2.5/`, plus `qa_cycle/New-Hrs125Contract.ps1` and
`qa_cycle/Test-HrsBiomeObservation.ps1`. Shared changes are the QA event
sanitizer/biome observation checks, byte-preserving Git attributes, generated
output ignores, candidate registry and current entry documents.

Batch 0 matched frozen ZIP/DLL and all 13 runtime source pins; three returned
`obj/` cache entries differed or were missing. Batch 1 fixed policy.v2.json
canonical bytes with seven vectors; 71 policy/migration/recovery/draw checks
pass, including deliberate write/readback failure. Batch 2 extends only the
biome decision; 50 resolver/pending-path checks pass. Batch 3 integrates the
real manager, restores saved settings, retains/cancels edits correctly and
moves confirmation ahead of installation; PowerShell 5.1 smoke and programmatic
1/1.5/2 scaling checks pass. Actual display-DPI and keyboard checks are retained
as human case HRS-BIOME-Manager, not claimed complete by the programmatic test.

Batch 4 pinned double build, verified-DLL policy vectors, eight ownership
checks, QA tools 59/59, placed observation 13 and biome observation ten pass.
Source and isolated release gates both report zero errors/warnings. Exported
`1.2.5-qa.001` ZIP is 69,952 bytes, SHA-256
`91F5FB375FFFA5FDE9A67C827B1BB184D1AA79E163A672947374B0AA55DA23D9`.
Isolated workspace: `hrs_1.2.5/dev/out/qa-001/`; its own START.bat passes
manager smoke. All commands and precise evidence boundaries are recorded in
the linked review/readiness records. Frozen 1.2.4 ZIP hash rechecked unchanged.

Next single action: user runs the extracted 1.2.5 manager and starts live QA
from the readiness runbook. All 31 contract cases are Pending. No game/build
is running under this task, and no live game files or saves were modified.
Publication remains outside this implementation handoff.

Return the source changes, reproducible build instructions, new QA ZIP, package/file hashes, test results, and a short list of any behavior that differs from this manifest. Bring that new candidate back to this QA workspace for installation and live game testing.
