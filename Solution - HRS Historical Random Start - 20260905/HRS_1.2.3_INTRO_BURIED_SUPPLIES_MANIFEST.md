# HRS 1.2.3 — Downstream Intro Quest Biome Filter Manifest

**Project:** Historical Random Start – Alpha 6 Method  
**Branch:** `hrs-1.2.3-trader-resume-fix`  
**Working repo:** `C:\Users\mobil\OneDrive\Documents\GitHub\QA_fresh`  
**Runtime source:** `hrs_1.2.1\dev\src\runtime\main\c0167.cs`  
**Status:** Root cause proven by controlled A/B diagnostic. Permanent HRS fix not yet implemented.

---

## 1. What happened

HRS successfully performed the intended first-stage flow:

1. The player selected **Random** with starting-biome protection.
2. HRS relocated the player.
3. HRS stored the initial biome.
4. HRS rewrote `quest_whiteRiverCitizen1` ("Journey to Settlement") to a trader in the same starting biome.
5. In the test case, the player was routed to **Trader Hugh** in the **snow biome**.
6. The starter trader quest successfully turned in at Hugh; receiving the **stone shovel** proves that vanilla accepted the trader handoff and completed the starter quest.

The failure happened **after** that successful handoff:

- Hugh did not initially offer the next special introductory quest.
- Normal trader jobs were also unavailable because vanilla gates those behind `IntroComplete = 1`.
- `IntroComplete` is only set after completing the separate `intro_buried_supplies` onboarding quest.

So the original trader redirect was not the failing component.

---

## 2. Proven root cause

Vanilla `quests.xml` defines the next onboarding quest:

`intro_buried_supplies`

Its phase-1 objective is:

```xml
<objective type="RandomGotoNPC" phase="1">
    <property name="completion_distance" value="20"/>
    <property name="distance" value="100-500"/>
    <property name="nav_object" value="quest"/>
    <property name="biome_filter_type" value="OnlyBiome"/>
    <property name="biome_filter" value="pine_forest"/>
</objective>
```

That means vanilla is still assuming the onboarding path begins in the pine forest.

Trader Hugh is correctly wired to:

`trader_hugh_quests`

and that list **does include**:

`intro_buried_supplies`

Therefore Hugh is capable of offering the quest. The problem is that the quest's location generator is constrained to `pine_forest`, while HRS intentionally moved the opening progression into the player's starting biome.

### Controlled A/B diagnostic

For diagnosis only, the live game file:

`C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die\Data\Config\quests.xml`

was temporarily changed from:

`biome_filter = pine_forest`

to:

`biome_filter = snow`

for **only** the `intro_buried_supplies` `RandomGotoNPC` objective.

Result:

- Before diagnostic change: Hugh did **not** expose the intro buried-supplies special job.
- After diagnostic change to `snow`: Hugh **did** expose `intro_buried_supplies`.

This proves that the downstream vanilla `pine_forest` filter is the blocker for the snow-biome HRS flow.

---

## 3. Current diagnostic state

At the end of the A/B test:

### Live game XML
`intro_buried_supplies` currently has:

`biome_filter = snow`

### Untouched backup
The original vanilla file was preserved as:

`C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die\Data\Config\quests.xml.HRS_DIAG_BACKUP`

The backup still contains:

`biome_filter = pine_forest`

The diagnostic XML change is **global to the game installation**. It is not scoped to the HRS save and must not become the release solution.

The diagnostic quest was observed as available but was **not accepted**.

---

## 4. Why a permanent XML patch is the wrong solution

Shipping an XML change such as:

- `pine_forest -> snow`
- `pine_forest -> AnyBiome`
- or a permanent XPath replacement

would modify the quest definition for every game loaded with that configuration/mod.

That would violate the desired HRS behavior:

> HRS behavior should apply only to the HRS-selected game/session and should not silently change unrelated saves.

The save can hold per-player/per-game state, but vanilla XML is a global recipe.

Therefore:

**Do not ship the diagnostic `quests.xml` edit.**

---

## 5. Permanent HRS design

The permanent fix should remain in the HRS runtime lane.

### Existing HRS state already available

HRS already stores the player's initial biome in its own marker/CVar state.

Current HRS biome codes:

| HRS code | Vanilla biome |
|---:|---|
| 1 | `snow` |
| 3 | `pine_forest` |
| 5 | `desert` |
| 8 | `wasteland` |
| 9 | `burnt_forest` |

### Required behavior

When all of the following are true:

- current policy is HRS **Random**
- current game/session passes the existing HRS environment/policy guard
- relocation marker is **Completed**
- initial biome is known
- quest is exactly `intro_buried_supplies`
- objective is its phase-1 `RandomGotoNPC` objective

HRS should make that **quest instance** use the player's stored starting biome rather than vanilla's fixed `pine_forest`.

Examples:

- snow start -> `snow`
- desert start -> `desert`
- wasteland start -> `wasteland`
- burnt start -> `burnt_forest`
- forest start -> leave vanilla `pine_forest`

### Scope requirement

The implementation should alter the **runtime quest/objective instance or its generation path**, not the global base XML definition.

That preserves:

- unrelated saves
- Standard mode
- non-HRS games
- vanilla configuration files

### Fail-closed behavior

If HRS cannot safely identify or modify the exact intro objective:

- do not alter unrelated quest data
- do not set `IntroComplete` manually
- do not fabricate quest completion
- do not force a trader job
- preserve vanilla behavior
- emit a sanitized HRS diagnostic reason

---

## 6. What we are NOT going to do

Do not:

- modify the sealed 1.2.1 verified artifact
- revive or use 1.2.2
- ship the edited base `Data\Config\quests.xml`
- globally change `intro_buried_supplies` to `AnyBiome`
- hard-code the permanent fix to Hugh or snow
- manually set `IntroComplete = 1`
- manually award or complete `intro_buried_supplies`
- treat the existing `04B8CEECD22E404249CA02D3803639E25EB64188A2FABAC0D88A00C137785416` DLL as the final 1.2.3 artifact after a new runtime code change

The current 04B8 candidate remains useful evidence for the first trader-route/reload fix, but a downstream runtime fix will produce a new candidate identity.

---

# Execution Instructions

We will execute these **one step at a time** and stop after each step for evidence review.

## Phase 0 — Restore vanilla diagnostic state

### Step 0.1 — Confirm the game is closed

```powershell
Get-Process 7DaysToDie -ErrorAction SilentlyContinue
```

Expected: no output.

### Step 0.2 — Restore the untouched vanilla `quests.xml`

With the game closed:

```powershell
$quests = 'C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die\Data\Config\quests.xml'
$backup = "$quests.HRS_DIAG_BACKUP"

if (Get-Process 7DaysToDie -ErrorAction SilentlyContinue) {
    throw '7 Days to Die is running. Close it first.'
}

if (-not (Test-Path -LiteralPath $backup)) {
    throw "Diagnostic backup not found: $backup"
}

Copy-Item -LiteralPath $backup -Destination $quests -Force
```

### Step 0.3 — Verify restoration

```powershell
(Get-Content $quests)[1519..1525]
```

Expected:

```xml
<property name="biome_filter_type" value="OnlyBiome"/>
<property name="biome_filter" value="pine_forest"/>
```

Do not delete the backup until restoration has been verified.

---

## Phase 1 — Identify the correct runtime hook

Before editing HRS, determine the exact 7DTD runtime class and timing used by XML objective type `RandomGotoNPC`.

We need to answer two questions:

1. What concrete runtime class represents `RandomGotoNPC`?
2. Is its biome filter consumed:
   - when the trader builds its available special quest list,
   - when the quest object is instantiated,
   - or only when the player accepts the quest?

This matters because an `OnQuestAccepted` fix may be too late if availability is calculated before acceptance.

### Required discovery target

Locate the Assembly-CSharp types/methods related to:

- `RandomGotoNPC`
- trader quest generation / quest availability
- special quest lists
- objective biome filtering

No code change is authorized until this boundary is understood.

---

## Phase 2 — Implement the narrow runtime override

Once the runtime boundary is proven, implement the smallest change in the active HRS 1.2.3 source lane.

Preferred behavior:

1. Read HRS initial biome from the existing marker store.
2. Map it to the vanilla biome string.
3. Target only `intro_buried_supplies`.
4. Target only its phase-1 `RandomGotoNPC` objective.
5. Apply the starting-biome filter early enough for the trader to consider the special quest valid.
6. Leave forest starts effectively vanilla.
7. Preserve fail-closed behavior.
8. Add sanitized HRS log reasons for the new boundary.

Suggested diagnostic log concepts:

- `INTRO_ROUTE_READY`
- `INTRO_ROUTE_FILTER_APPLIED`
- `INTRO_ROUTE_FALLBACK`

Exact reason names can be chosen after the runtime hook is identified.

---

## Phase 3 — Build a new deterministic 1.2.3 candidate

After source change:

1. Run source/static verification.
2. Build with the pinned HRS Windows PowerShell 5.1 build path.
3. Require deterministic double-build success.
4. Record:
   - DLL byte count
   - SHA256
   - MVID
   - source hashes
   - ModInfo version
5. Treat this as a **new candidate identity**.

Do not reuse the prior 04B8 hash as final release evidence.

---

## Phase 4 — Focused functional regression

Use a new test game name.

Required regression:

1. Random start in a non-forest biome.
2. Confirm relocation works.
3. Confirm starting-biome protection works when enabled.
4. Complete tutorial.
5. Confirm `Journey to Settlement` routes to the trader in the starting biome.
6. Perform logout/reload before trader-route completion to preserve the already-required reload regression.
7. Return and complete the starter trader handoff.
8. Confirm shovel reward.
9. Confirm `intro_buried_supplies` now appears at that same-biome trader.
10. Accept it.
11. Confirm its phase-1 target is valid for the starting biome.
12. Complete enough of the intro chain to prove `IntroComplete` can be reached normally.

Do not manually set vanilla CVars to force success.

---

## Phase 5 — Evidence and promotion

After the focused regression passes:

1. Capture HRS log sequence.
2. Commit the runtime fix and existing 1.2.3 identity edits without unrelated changes.
3. Push the branch.
4. Rebuild/re-author the 1.2.3 source manifest/evidence for the exact tested artifact.
5. Promote the **exact tested DLL bytes** into the verified lane.
6. Rewire the release manager to the newly promoted 1.2.3 SHA.
7. Reconcile the old release-manager stash deliberately; do not blindly pop it.
8. Verify install and uninstall semantics.
9. Proceed to clean-room publishing only after all final checks pass.

---

## Release gate

The HRS 1.2.3 release remains blocked until:

- the global diagnostic XML edit is removed
- the runtime-only downstream intro fix is implemented
- a new deterministic candidate is built
- same-biome trader routing still passes
- reload/resume still passes
- `intro_buried_supplies` is available and valid in the starting biome
- exact artifact identity is captured and promoted

---

## Current conclusion

The original same-biome trader redirect is working.

The newly discovered defect is a **downstream vanilla biome assumption**:

> HRS changes where the opening progression occurs, but vanilla `intro_buried_supplies` still assumes that opening progression is in `pine_forest`.

The permanent HRS fix will preserve vanilla files and translate that one downstream onboarding objective to the HRS player's stored starting biome at runtime, scoped only to the approved HRS game/session.
