# HRS 1.2.3 — Closing Manifest / AI Re-entry Handoff
**Date:** 2026-09-05  
**Project:** Historical Random Start – Alpha 6 Method  
**Repository:** `bitwrecked-often/QA-Fresh`

## Executive closeout

The HRS 1.2.3 **mechanical work is complete** and was live-tested successfully.

Today we fixed and validated two connected gameplay defects:

1. **Trader-route resume after reload**
   - The HRS trader watcher could unsubscribe too early if `player.QuestJournal` was temporarily null during attach/reload.
   - Fixed so polling survives a temporarily unavailable journal while still stopping on terminal route states.

2. **Downstream intro quest biome mismatch**
   - HRS correctly rerouted the starter trader to the player's starting biome, but vanilla `intro_buried_supplies` still hardcoded `pine_forest`.
   - Implemented a narrow Harmony prefix that changes only the fresh runtime clone of the phase-1 `ObjectiveRandomGotoNPC` for `intro_buried_supplies`.
   - The objective biome filter is changed from vanilla `pine_forest` to the already-stored HRS initial biome, then vanilla `Quest.SetupPosition()` continues normally.

The finished mechanics were committed, pushed, reviewed through PR #1, and merged into `main`.

**Do not reopen these mechanics unless new regression evidence appears.**  
Cosmetic/UI work is intentionally deferred to a later branch.

---

## Repository state at close

### Completed branch
`hrs-1.2.3-trader-resume-fix`

### Commits merged
- `ebee970` — `Fix trader route resume after reload`
- `6ae06a0` — `Polish HRS 1.2.3 manager wording`
- `874b29d` — `Complete HRS 1.2.3 trader intro routing mechanics`

### Pull request
PR #1 — `Complete HRS 1.2.3 mechanical baseline`

### Merge commit
`6c6c8677bcaced6912d0ae320aead1d41ebd9985`

At merge time the branch was 3 commits ahead of `main`, 0 behind, and the working tree was clean.

---

## Exact live-tested 1.2.3 candidate

### Build attempt
`alpha-core-03312e99907b436ea3fba10d705da587`

### Candidate root
`hrs_1.2.1\dev\out\alpha-core-03312e99907b436ea3fba10d705da587`

### Exact DLL identity
- File: `d0163.dll`
- Bytes: `58880`
- SHA256: `8E12D468DA3EADB647AC48E5709C2F5BDA2EABA4A310A54DFC6A06228EFD5056`
- MVID: `68781a4a-b1ca-4cc2-81b9-8429cbc11354`
- Assembly name: `d0163`
- Assembly version: `0.0.0.0`
- Deterministic double build: `True`

### Important source hash
`c0167.cs` SHA256:
`5D04856281DC4657BCC76D2182D440EA5339D64550E8DE3C06B03EC7A0C4C260`

### ModInfo
- Name: `BitWrecked_HistoricalRandomStart`
- Version: `1.2.3`
- `SkipWithAntiCheat=true`

### Payload boundary
The built HRS payload contained only:
- `d0163.dll` — 58880 bytes
- `ModInfo.xml` — 429 bytes

**No Harmony DLL is bundled in the HRS payload.**

---

## Harmony dependency and build contract

HRS now compiles against the official TFP-supplied Harmony shipped with the game.

Official path:

`C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die\Mods\0_TFP_Harmony\0Harmony.dll`

Pinned identity:
- Assembly: `0Harmony`
- Version: `2.13.0.0`
- Bytes: `290304`
- SHA256: `C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF`
- MVID: `7b787fec-e12a-47a6-8027-108671090713`

`p0143.ps1` now treats Harmony as a pinned build input:
- hash checked,
- MVID checked,
- referenced during compilation,
- never copied into the HRS payload.

The final HRS DLL references:
- `Assembly-CSharp 0.0.0.0`
- `0Harmony 2.13.0.0`

Clean game logging proved TFP Harmony initialized before HRS, and HRS then logged `INTRO_ROUTE_PATCH_READY`.

---

## Bug 1 — trader route resume after reload

### Root cause
In `c0167.cs`, the trader observer previously disabled polling when `player.QuestJournal == null` during initial attach.

That allowed this failure sequence:
- attach,
- immediate observer call,
- temporarily null QuestJournal,
- `traderRouteSubscribed = false`,
- no later polling,
- trader route rewrite never resumes.

### Fix
The observer now:
- unsubscribes if the player is null,
- unsubscribes when the route is terminal,
- but only returns without unsubscribing if `QuestJournal` is temporarily null.

This preserves the watcher across initialization/reload timing.

### Validation
The focused fix was live-tested, including logout/reload, and worked.

Commit:
`ebee970`

---

## Bug 2 — intro buried supplies hardcoded to forest

### Proven root cause
Vanilla `intro_buried_supplies` phase 1 contains a `RandomGotoNPC` objective with:

- `biome_filter_type = OnlyBiome`
- `biome_filter = pine_forest`

HRS can correctly route the starter trader to another starting biome, but this downstream intro quest still tries to generate in forest.

### A/B proof
Before implementing the permanent fix, a temporary diagnostic changed only the live game `quests.xml` entry for `intro_buried_supplies`:

`pine_forest` -> `snow`

On the same save/trader:
- `pine_forest` -> intro quest unavailable,
- `snow` -> intro quest appeared.

Vanilla XML was restored afterward.

That proved the downstream biome filter was the real cause.

---

## Permanent intro-route implementation

The permanent fix uses Harmony and does **not** globally modify XML.

### Patch target
`Quest.SetupPosition(EntityNPC, EntityPlayer, List<Vector2>, Int32)`

Harmony prefix:
`IntroRouteSetupPositionPrefix(Quest __instance, EntityPlayer player)`

### Registration
Registration occurs only for HRS Random policy.

If patch installation fails, HRS uses the existing valid contract:
- outcome: `FAILED`
- reason: `INTERNAL_FAILURE`
- marker state: `NOT_APPLICABLE`

No new `ResultV1` reason was invented.

### Narrow runtime guards
The prefix changes nothing unless all expected conditions match:
- HRS Random policy active,
- valid quest/player,
- quest ID exactly `intro_buried_supplies`,
- HRS relocation marker `Completed`,
- HRS trader route marker `Completed`,
- stored initial biome valid,
- sane objective list,
- exactly one phase-1 `ObjectiveRandomGotoNPC`,
- target not already positioned,
- filter type still `OnlyBiome`,
- filter still exactly vanilla `pine_forest`.

If compatibility/sanity checks fail, it logs `INTRO_ROUTE_FALLBACK` and leaves vanilla behavior alone.

### Biome mapping
- `1` -> `snow`
- `3` -> `pine_forest`
- `5` -> `desert`
- `8` -> `wasteland`
- `9` -> `burnt_forest`

### What this fix does NOT do
It does not:
- edit base XML,
- set `IntroComplete`,
- fabricate completion,
- force quest availability,
- alter unrelated quests,
- alter Standard mode,
- rewrite unrelated/non-HRS saves,
- own the game's progression system.

It changes one cloned objective filter immediately before vanilla setup, then vanilla continues.

---

## Runtime observability added

`SanitizedRuntimeLog` gained:
- `INTRO_ROUTE_PATCH_READY`
- `INTRO_ROUTE_FILTER_APPLIED`
- `INTRO_ROUTE_FALLBACK`

No new `ResultV1` reason was added.

Runtime log version is now:
`v=1.2.3 build=r120`

`build=r120` was intentionally left unchanged.

---

## Final clean live test

### Save
`HRS_123_INTRO_002`

### Mode
- Random
- starting-biome protection ON

### Installed DLL identity before play
- Bytes: `58880`
- SHA256: `8E12D468DA3EADB647AC48E5709C2F5BDA2EABA4A310A54DFC6A06228EFD5056`

The same hash was confirmed again after testing.

### Test path
1. Spawned in **desert**.
2. Completed starter objectives until `Locate Trader`.
3. Trader route was about **1.4 km**.
4. HRS routed to **Trader Bob**.
5. Bob offered **Intro to Buried Supplies**.
6. Game was restarted cleanly.
7. After reload, Bob still offered the intro quest.
8. Intro quest was accepted.
9. Quest target generated **in the desert**.
10. Distance was about **384 m**.
11. Quest was completed and turned in.
12. Bob then showed normal jobs.

The normal-jobs check was only a regression proof that HRS handed control back to vanilla progression. HRS is **not** taking ownership of the game's progression system.

---

## Final clean runtime log evidence

The clean reload showed:

`INTRO_ROUTE_PATCH_READY -> RUNTIME_READY -> RELOCATION_COMPLETED -> INTRO_ROUTE_FILTER_APPLIED`

This aligned with gameplay:
- desert start,
- desert Trader Bob route,
- intro quest available,
- intro buried supplies generated in desert.

---

## LIFECYCLE_REJECTED was investigated

A later log entry showed:

`LIFECYCLE_REJECTED`

This was not a regression.

The surrounding log proved:
- player was killed by a coyote,
- normal death/respawn began,
- player respawned near backpack,
- HRS received `PlayerSpawnedInWorld (reason: Died, ...)`,
- HRS rejected that non-initial spawn.

That is correct fail-closed one-shot behavior.

Do not reopen the implementation because of this already-explained entry.

---

## Test-environment contamination discovered and removed

The first live run exposed an unexpected old mod folder:

`Mods\mod`

Inspection proved it was an old HRS 0.0.5 residue from 2026-08-27.

Legacy contents included:
- `d0163.dll`
  - bytes: `29696`
  - SHA256: `70B3B96775A1B2EF3C5C88A918CF70B11705EC1FDFA31CADDD3DE36B540A8DFB`
- `ModInfo.xml`
  - Name: `mod`
  - Version: `0.0.5`
- old Bridge policy/result files.

Because both assemblies used the name `d0163`, that run was considered contaminated.

The old folder was **not deleted**. It was quarantined outside the Mods loader path:

`C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die\HRS_Quarantine\legacy_mod_0.0.5_20260827`

The clean reload after quarantine is the authoritative runtime-validation run.

---

## Files changed by the 1.2.3 mechanical branch

Exactly six repository files changed:

1. `HRS_1.2.3_INTRO_BURIED_SUPPLIES_MANIFEST.md`
2. `hrs_1.2.1/dev/src/runtime/main/ModInfo.xml`
3. `hrs_1.2.1/dev/src/runtime/main/c0167.cs`
4. `hrs_1.2.1/dev/src/runtime/main/c0217.cs`
5. `hrs_1.2.1/dev/src/runtime/p0143.ps1`
6. `hrs_1.2.1/dev/ui/p0158.ps1`

Important: the active source remains physically under the historical `hrs_1.2.1` workspace path. We deliberately did **not** casually copy the sealed 1.2.1 tree into a new `hrs_1.2.3` folder.

Do not interpret the directory name as the runtime semantic version.

---

## Manager state

The DEV manager lane was intentionally used for exact candidate build/install testing.

Known state:
`$useDevCandidate = $true`

The manager builds through `p0143.ps1`, then installs from the returned `candidateRoot`.

If the HRS Bridge already exists, the manager may skip the fresh build/install path. For today's final test, the superseded installed candidate was removed first so the manager had to install the new build.

Superseded candidate:
- bytes: `56832`
- SHA256: `04B8CEECD22E404249CA02D3803639E25EB64188A2FABAC0D88A00C137785416`

That candidate is not final because it predates the intro-route source fix.

---

## Release/promotion distinction

The mechanics are complete and merged into `main`, but do **not** silently claim that all release bookkeeping/publishing steps are complete.

Important later:
- exact tested 1.2.3 DLL is `8E12D468...`,
- `j0219.json` was intentionally not piecemeal edited during development because it described older verified evidence,
- re-author/update 1.2.3 evidence only during deliberate promotion/release work,
- do not treat old 1.2.1 evidence as proof of the 1.2.3 DLL,
- clean-room packaging rules still apply,
- no public Nexus upload was performed today.

---

## Existing stash — do not lose it

An older stash still exists:

`1.2.1 release-manager wiring`

It came from:
`hrs_1.2.1/dev/ui/p0158.ps1`

**Do not casually pop this stash.**

It may now be obsolete or require deliberate reconciliation against the merged 1.2.3 manager state. A blind pop could reintroduce old 1.2.1 assumptions/hashes.

---

## Sealed 1.2.1 reference remains frozen

Do not alter or repurpose the sealed verified 1.2.1 DLL.

Path:
`hrs_1.2.1\dev\verified\main\d0163.dll`

Identity:
- bytes: `56832`
- SHA256: `C732AC84E47B8E0A4FBBD0F2B89401C1597D181A5A32EC1B1A1B4A8664142222`
- MVID: `f65efba4-1a77-4e9b-b51a-31050e506118`

It remains historical evidence/reference.

---

## Deferred work

### Explicitly deferred
**Cosmetics / UI / presentation polish**

The next AI may work on:
- wording,
- visual arrangement,
- cosmetic manager presentation,
- non-functional polish.

Start that work from current `main` on a new cosmetics-only branch.

### Do not casually change
Without new regression evidence, do not reopen:
- relocation mechanics,
- trader-route state machine,
- reload behavior,
- intro buried-supplies biome mapping,
- Harmony target/guard semantics,
- vanilla progression behavior.

If a cosmetic integration change actually touches these boundaries, regression-test only the impacted integration surface.

---

## Recommended next-session starting position

### If next task is cosmetics
1. Start from current `main`.
2. Create a new cosmetics-only branch.
3. Treat merge commit `6c6c8677bcaced6912d0ae320aead1d41ebd9985` as the completed 1.2.3 mechanical baseline.
4. Preserve the tested mechanics.
5. Do not pop the old 1.2.1 stash without deliberate review.
6. Keep functional and cosmetic changes separate.

### If next task is release finalization
1. Do not modify mechanics.
2. Rebuild/verify exact source state if required by the release process.
3. Promote the tested artifact under controlled rules.
4. Re-author evidence/bookkeeping for 1.2.3.
5. Clean-room package from an allowlist.
6. Do not bundle Harmony.
7. Do not publish publicly until release gates are deliberately completed.

---

## Final status

**HRS 1.2.3 mechanics: COMPLETE**

**Live behavior: PROVEN**

**Exact tested DLL:**  
`8E12D468DA3EADB647AC48E5709C2F5BDA2EABA4A310A54DFC6A06228EFD5056`

**Merged to main:**  
`6c6c8677bcaced6912d0ae320aead1d41ebd9985`

**Cosmetics: DEFERRED**

**Public publishing: NOT PERFORMED**

### Primary instruction to the next AI
Do not make the user pay to rediscover this work. Treat the 1.2.3 mechanics as the known-good baseline and continue from here.
