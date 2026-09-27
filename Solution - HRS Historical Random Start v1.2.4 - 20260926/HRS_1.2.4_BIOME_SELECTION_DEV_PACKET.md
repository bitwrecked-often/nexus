# Historical Random Start — full development handoff packet

Prepared: 2026-09-26
Current QA candidate: `1.2.4-qa.001`
Next objective: ship a **new QA candidate** whose Windows manager controls the biome selection used by the actual game runtime.

This packet is self-contained for transfer to the dev workspace. The smaller `HRS_BIOME_SELECTION_DEV_MANIFEST.md` in the same folder records the agreed feature contract. The prototype folder is the approved native Windows UX reference.

## 1. What happened in QA today

- The QA tester tried Historical Random Start 1.2.4 three times and reported that the flow worked. Two of the three Random starts landed in Forest. No defect was reported in installation, placement, opening journey, or game launch during those trials.
- Three starts are too few to establish a statistical bias. The product concern is real: a player expecting a surprising first day currently has no way to request a biome or favor dangerous ones.
- We reviewed the 1.2.4 package and confirmed that its manager exposes only **Standard**, **Random**, and **Protect from hazards in starting biome**. Its exact-shape policy accepts only `Standard`, `Random`, and `RandomSafe`.
- We first made a browser mock. The user correctly redirected the design to match the existing `START.bat` flow. That mock was removed.
- We built a standalone PowerShell WinForms prototype launched by its own `START.bat`, using the same `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File` method as the QA manager and matching its simple Windows form style.
- The first WinForms prototype was too tall and its inline weight controls were clipped at the tester's display scaling. The user supplied a screenshot. We shortened the main form and moved the five weights into a separate **Edit weights...** dialog. The user approved that revised look.
- The approved prototype is UI only. Its **Apply Settings** button shows the confirmation flow but does not write a policy, install a DLL, launch the game, or alter a save.

Prototype verification here: the PowerShell parser passed; `START.bat -SmokeTest` passed checks for Standard/Random enabling, Chosen odds, Custom odds, and all-zero rejection; and captures of the main form and weight dialog were visually reviewed at the local display scaling. The revised form still needs a live check at the tester's higher scaling before it is treated as production-ready.

The QA observation is tester-reported; there are no world seeds, coordinates, screenshots of each landing, or game logs in this packet. Treat the 1.2.4 gameplay run as a positive smoke test, not as proof of a particular biome distribution.

## 2. Exact artifacts and how to find them

All paths below are relative to the `nexus` repository root unless stated otherwise.

| Artifact | Path | Use |
| --- | --- | --- |
| Baseline QA ZIP | `Solution - HRS Historical Random Start v1.2.4 - 20260926/1.2.4-qa.001.zip` | Exact package the tester used. SHA-256: `6FDECA0D76AD233A80B70493C7714F1E7FD277EEAC6FA56FD423112B1482F5C5`. |
| Extracted baseline | `Solution - HRS Historical Random Start v1.2.4 - 20260926/1.2.4-qa.001/HistoricalRandomStart_1.2.4/` | Readable manager modules, README, manifest, and verified runtime DLL. |
| Approved prototype launcher | `Solution - HRS Historical Random Start v1.2.4 - 20260926/biome-selection-prototype/START.bat` | Double-click to try the native popup. |
| Approved prototype form | `Solution - HRS Historical Random Start v1.2.4 - 20260926/biome-selection-prototype/dev/ui/BiomeSelectionPrototype.ps1` | Copy the layout and interaction pattern into the real manager. SHA-256: `D7F7BE2CF42A6B774D3B35AB6C90BABB60B1E957D804F5002D3DC34D5DF54684`. |
| Prototype captures | `biome-selection-prototype/prototype-preview.png` and `prototype-preview-weights.png` | Visual reference for main form and weight dialog. |
| Feature manifest | `Solution - HRS Historical Random Start v1.2.4 - 20260926/HRS_BIOME_SELECTION_DEV_MANIFEST.md` | Short contract for implementation and verification. |

The baseline ZIP is tracked in `nexus`. The extracted folder, prototype, manifest, and this packet are currently **local untracked files**. A Git pull alone will not bring those local files into another checkout. Copy this packet and the prototype folder when transferring the work, or add them to the intended repository deliberately.

The 1.2.4 verified runtime is `dev/verified/main/d0163.dll`, SHA-256 `D0B4F6EC8E7E17042869484AAC608BFB8472F0C348C2063FA08245BDEDA08617`. `package-manifest.json` lists the expected file sizes and hashes. The current `START.bat` loads `dev/ui/p0158.ps1`, which loads the PowerShell launcher modules and deploys the verified DLL only after its game-build and hash checks.

## 3. Existing 1.2.4 behavior to preserve

- Target: 7 Days to Die **V3.3.0 (b14)**, Windows, PowerShell 5.1, local single-player. Supported maps are Navezgane and Random Gen worlds of at least 8K. The existing README does not claim bundled pregens or custom maps as tested.
- Game starts with anti-cheat disabled and the supplied `0_TFP_Harmony` kept intact. The package does not replace game DLLs.
- The manager ties a policy to the **exact Game Name**, which is different from the generated world's name. It checks the exact game build and package identities before installing.
- Standard uses the usual start. Random uses catalog-approved **actual placed POIs** in the active world, attempts at most five distinct instances in the chosen biome, rolls back unsafe attempts, and keeps the ordinary start if no safe relocation completes.
- A completed start is one-shot: reload and normal respawn do not choose another destination. The current catalog has 80 selected entries represented by 79 distinct prefab names; an individual world may contain fewer eligible placements.
- The opening journey points to a real trader in the active world, preferring one in the landing biome and allowing an existing trader elsewhere when needed. With no usable trader route, the ordinary start remains.
- Optional protection suppresses recognized environmental hazards of the **starting biome** only; it does not promise immunity from every debuff or from hazards elsewhere.
- Upgrade and uninstall retain the current ownership, verification, save-preservation, and unrelated-file protections.

## 4. Approved player experience

Keep the native manager, its current title/header, exact Game Name field, Standard/Random radios, protection checkbox, Apply Settings confirmation, Launch Game, Uninstall Mod, and game-folder display. Under Random, add a compact **Random starting biome** group:

1. **Any biome (equal chance)** — default selection. Choose uniformly among biome categories that contain an eligible placed POI in the active world.
2. **Choose a biome** — show Forest, Burnt Forest, Desert, Snow, and Wasteland. A successful relocation must land in the requested biome. If unavailable or unsafe, keep the usual start and report why.
3. **Set custom weights** — open the separate native **Edit weights...** dialog. Five integer controls accept 0–100 and show normalized percentages. Prototype defaults: Forest 10, Burnt Forest 20, Desert 20, Snow 25, Wasteland 25. Zero excludes a biome; all-zero values cannot be saved.

Preserve the edited weights while switching controls during a manager session. When reopening an existing configured game, populate the controls from its saved policy. The protection checkbox stays independent of biome selection. The manager confirmation should state the chosen selection method, selected biome or weights, protection state, and exact Game Name.

The main form was intentionally kept near the height of the 1.2.4 manager, and the longer weight editor became a second dialog after the tester saw clipped rows at high display scaling. Verify fit and readability at 100%, 150%, and 200% Windows scaling, including access to the bottom buttons on a shorter screen.

## 5. Runtime selection rules

1. Build the existing catalog-approved placed-POI index for the active world. Resolve each eligible placement to a stable application biome category, using an explicit source mapping from game biome identifiers to the five UI categories. Check Navezgane and Random Gen naming; do not infer category from the UI label alone.
2. Compute the set of biomes that have at least one eligible placed POI. **Any** gives each such biome `1/N` probability, regardless of the number of placements or area. **Chosen** considers only the requested biome. **Weighted** ignores zero-weight and absent biomes, then normalizes the remaining positive weights: `P(biome) = weight(biome) / sum(eligible positive weights)`.
3. Draw one biome before drawing a placed POI. Use the existing guarded within-biome candidate logic, including the five distinct-instance attempt limit. Do not silently switch biomes because the selected biome later fails safety verification.
4. If the requested biome is absent, no positive-weight eligible biome remains, a safe landing cannot be completed, or no usable opening trader route exists, keep the ordinary start with a specific sanitized reason. No success marker or arrival claim should be recorded for an uncompleted relocation.
5. Keep the existing rollback, one-shot marker, protection semantics, and trader routing. Record enough sanitized diagnostic detail to distinguish **selection** from **placement outcome**: method, requested biome or weights, eligible biome pool, selected biome, attempted POI biome, and final result.

The dialog's displayed percentages are configured odds across its five values. In an active world, absent biomes are removed and the remaining weights are renormalized. Completed landing frequencies can also differ because selected-biome safety attempts may fall back to the ordinary start. UI/help text and QA logs should not imply that the dialog can predict final landing frequencies for every world.

## 6. Policy and installer integration

The current PowerShell `m0161.psm1` uses `hrs-policy/v1` with an exact field count, canonical JSON shape, strict allowed modes, and a SHA-256 digest. The runtime DLL validates the same contract. The deployed bridge currently uses `policy.v1.json` and `result.v1.json`; deployment inventory and removal ownership also check bridge contents. Adding controls only to the form would leave the DLL unable to understand them.

Implement a coordinated **versioned policy revision** in both manager and runtime. Keep `Standard`, `Random`, and `RandomSafe` as the top-level mode/protection meaning, and add a separate biome-selection field and data. The manager and DLL must agree on field order, canonical serialization, digest input, biome IDs, weight range, defaults, and invalid-state handling. Update atomic write/readback, bridge ownership, deployment checks, recovery history/snapshots, and result correlation wherever the new policy changes their contracts. Ensure one authoritative policy after upgrade; reject ambiguous, malformed, or tampered state.

On an explicit upgrade Apply Settings action, migrate an existing valid 1.2.4 policy as follows: Standard remains Standard; Random becomes Random with Any biome; RandomSafe becomes Random with Any biome and protection on. Preserve exact Game Name, advance revision, and keep existing saves, progress, unrelated files, and consumed one-shot markers. Do not rewrite while the game is running. Retain the current build-MVID, runtime-hash, and ModInfo ownership gates.

## 7. Main implementation challenge

The `1.2.4-qa.001` package includes the verified runtime binary but **not the matching C# source for its 1.2.4 POI resolver**. A search of the nearby `nexus1` source tree found an older prototype, whose runtime uses an earlier spawn-selection approach and does not contain the 1.2.4 placed-POI resolver. Do not treat that older code as a drop-in source for this binary.

First locate the matching 1.2.4 source and reproducible build inputs. If the source cannot be located, reconstruct the runtime with explicit equivalence checks against 1.2.4 behavior before adding biome selection. The source gap is the largest risk to schedule and to preservation of the working placement/trader behavior. The prototype PowerShell form is a layout reference, not a substitute for this runtime work.

Other integration risks to address:

- A biome may exist on a map but contain no approved placed POI; normalize only over the eligible set.
- A biome with approved POIs may still fail all placement safety checks; preserve the vanilla fallback and make it visible in results.
- Biome identifier differences between Navezgane and Random Gen can misroute a selection; use tested mappings.
- Changing strict policy JSON or bridge filenames can make a previously installed package appear unowned or corrupt; design migration and removal checks together.
- Updating a policy for a completed character must not cause another random start.
- WinForms fixed coordinates can clip at high DPI; keep the compact main form and separate editor, then visually test on the tester's scaling.

## 8. Ordered dev work

1. **Recover the source baseline.** Find the exact 1.2.4 runtime source/build recipe and identify the placed-POI selection path, biome resolution, policy codec, markers, trader route, and diagnostics. Record provenance and required game DLL references.
2. **Lock the contract.** Choose the new policy schema/filename and exact canonical serialization. Define stable biome IDs, weight validation, v1 migration, and fail-closed behavior. Add shared contract vectors or equivalent cross-language checks.
3. **Implement runtime selection.** Build the eligible biome pool, perform Any/Chosen/Weighted biome draws, keep the current distinct POI attempts and safety fallback, and log selection versus outcome.
4. **Wire the native manager.** Integrate the approved compact form and separate weight dialog into the real `p0158.ps1` flow. Load current policy, validate, confirm, write atomically, read back, and update status. Keep real Launch Game and Uninstall Mod behavior.
5. **Update deployment and recovery.** Revise bridge file ownership, snapshots/history, upgrade path, manifests, hashes, README, and version strings together. Do not alter the existing `1.2.4-qa.001` ZIP in place.
6. **Verify before handoff.** Run deterministic policy/selector tests and game smoke tests, package a fresh candidate, extract its ZIP to a clean location, and exercise its own `START.bat`.

## 9. Acceptance checks for the new QA candidate

| Area | Required observation |
| --- | --- |
| Policy | Manager and DLL round-trip the same version/digest. Unknown biome, invalid weights, all-zero Weighted, wrong field order, bad digest, and ambiguous bridge state fail closed. |
| Any | Eligible biomes receive equal draw probability even when placement counts differ. Missing biomes receive zero. |
| Chosen | Every completed landing is in the requested biome; missing/unsafe requested biome yields the ordinary start with a clear reason. |
| Weighted | Zero excludes; absent biomes renormalize; one positive weight acts like Chosen; the five configured percentages update correctly. |
| Safety and progression | Five-attempt limit, rollback, trader routing, protection, completed marker, reload, and respawn behave as in 1.2.4. |
| Manager | Reopens saved selection; Standard, Random, protection, confirmation, launch, upgrade, and uninstall work; 100/150/200% scaling has no clipped controls. |
| Package | Exact game-build gate, verified DLL/ModInfo identity, clean extracted ZIP, new candidate ID/version, README, and reproducible hashes are present. |

Return to this QA workspace with the new ZIP, source location/commit, build steps, hashes, test results, and any deliberate deviation from this packet. Then repeat live trials on Navezgane and a supported Random Gen world, logging the chosen selection, biome, final outcome, and any fallback. Publish or replace the current QA artifact only after that candidate passes its own review.
