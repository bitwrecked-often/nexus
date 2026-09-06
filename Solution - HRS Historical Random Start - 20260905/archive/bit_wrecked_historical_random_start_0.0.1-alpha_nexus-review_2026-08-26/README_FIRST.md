# Historical Random Start - Alpha 6 Method — Read Me First

Player-facing mod name: `Historical Random Start - Alpha 6 Method`

The `bit_wrecked_historical_random_start` folder is the stable project
workspace path; it is also separate from the player-facing product name.

Status: Independent sibling project; Alpha core execution packet READY; Phase
1A atomic relocation observed once; persistence reload and bounded exact-name
launcher/runtime bridge implementation are next

Implementation status: Private proof runtime source and one successful guarded
atomic-relocation artifact exist; no release runtime or functional policy
bridge exists yet

Release status: Not approved for packaging, Nexus, GitHub, or distribution

Clickable player preview: `7DTD_HistoricalRandomStart.bat`

## Purpose

This folder is the canonical workspace for the Bit Wrecked Historical Random
Start project. It recreates an older-style first-character start experience
through exactly two player-facing choices: Standard and Random. Standard is a
true gameplay no-op; Random owns every approved custom-start behavior.

This is not the Wasteland Animal Population Tuning project and is not an
umbrella package. Wasteland material may be consulted only for generic process,
UI, logging, validation, packaging, and rollback patterns.

## Start Here Every Time

Read these files in order before planning or changing this project:

1. `README_FIRST.md`
2. `DOCUMENT_ROUTING.md`
3. `CURRENT_SITUATIONAL_AWARENESS.md`
4. `ALPHA_CORE_EXECUTION_PACKET_0.0.1.md`
5. `2026-08-13_historical_random_start_manifest.md`
6. `2026-08-13_historical_random_start_plan.md`
7. `evidence/2026-08-13_phase_0_discovery_report.md`
8. `UX_PARITY_AND_EVOLUTION_MANIFEST_0.0.1.md`
9. `DEV_TEST_AND_SOFTWARE_ASSURANCE_CONTRACT_0.0.1.md`
10. `PHASE_1_PREBUILD_SOFTWARE_ASSURANCE_PACKET_0.0.1.md`
11. `evidence/2026-08-14_phase_0a_installed_build_and_api_fingerprint.md`
12. `evidence/2026-08-14_phase_0a_pure_contract_test_report.md`
13. `evidence/2026-08-14_v3_1_biome_hazard_inventory.md`
14. `evidence/2026-08-14_v3_1_starter_trader_routing_inventory.md`
15. `src/runtime/PHASE_1_OBSERVATION_PROBE_DESIGN_0.0.1.md`
16. `src/runtime/PHASE_1_PINNED_BUILD_RECIPE_0.0.1.md`
17. `OPEN_SOURCE_GOVERNANCE_AND_SECURITY_MANIFEST_0.0.1.md`
18. `OPENSSF_READINESS.md`
19. `evidence/2026-08-14_day_2_ui_comparison.md`
20. `2026-08-13_historical_random_start_review_and_reasoning_log.md`
21. `security/PHASE_0A_SECURITY_STATE_BASELINE_0.0.1.md`
22. `UX_0_1_CONTROL_INVENTORY_AND_STATE_MODEL_0.0.1.md`
23. `tests/PHASE_0A_NEGATIVE_TEST_MATRIX_0.0.1.md`
24. `CHANGELOG.md`
25. `2026-08-14_preview_apply_edge_fix_manifest.md`
26. `evidence/2026-08-14_preview_apply_edge_fix_test_report.md`
27. `AI_IMPLEMENTATION_REQUIREMENTS_AND_PLATFORM_GUIDE.md` when selecting a
    replacement implementation AI, context window, or human operator

For a human-friendly Windows entry, double-click
`7DTD_HistoricalRandomStart.bat`. It opens the branded player preview. The
preview explains the planned start choices, checks the selected game folder,
uses popups for plain-language guidance, and previews two optional Random
safeguard scopes: `Starting biome only` or `All dangerous biomes`. Both begin
unchecked, are mutually exclusive, and remain editable under both start
choices; Standard ignores them. It also
explains that a future completed Random start will point the opening stone-
shovel quest to the nearest valid trader. `Apply Preview Settings` can now
record the selected values in the open preview session and confirm them in a
popup and the activity log. The preview explicitly distinguishes applied from
pending selections, and any folder edit requires a new current-folder check;
it does not persist policy or change the game yet.

Then read only the task-specific framework or evidence documents routed by
`DOCUMENT_ROUTING.md`.

## Current Truth

The concise current working picture is maintained in
`CURRENT_SITUATIONAL_AWARENESS.md`. Read it before using older work as a
reference or proposing implementation.

Execution supersession, 2026-08-21: the Alpha core is now bounded and READY in
`ALPHA_CORE_EXECUTION_PACKET_0.0.1.md`. Implement only manual exact-name
Standard/Random, verified Apply, direct-user-only Launch Game, genuinely-new-
player first-arrival runtime gating, exactly-once state, sanitized sidecar
result, local history, validated recovery, and Remove from Game. Trader,
biome, discovery, All Games, multiplayer, distance, expanded placement, drops,
protection, and rooftops remain disconnected. The older preview descriptions
below are historical current-state facts, not the execution feature list.

- Phase 0 inspected the installed V3.1.0 b14 game and current APIs read-only.
- Native `ModEvents.PlayerSpawnedInWorld` is the preferred lifecycle hook.
- No initial Harmony patch is indicated; Harmony files must not be modified.
- Random can use the native spawnpoint list without editing it.
- Broader arbitrary-coordinate and rooftop placement may be explored later as
  separately gated Random extensions; they are not a third start type.
- EAC-enabled custom-code behavior is not an approved initial release lane.
- Clean-client placement and protection behavior remain unproven.
- The existing module host is a proven base but its current contract is
  intentionally read-only and must not be broadly loosened.
- A project-branded 0.0.7 player preview and root BAT now exist. They provide
  read-only folder recognition, plain-language guidance, two Random-start
  safeguard-scope controls, a session-only Apply Preview Settings action with
  confirmation, explicit applied/pending and stale-folder truth,
  nearest-opening-trader guidance, and recent activity; gameplay, policy
  persistence, and installation behavior do not exist yet.
- The two safeguard scopes begin unchecked, never grey out, and cannot both be
  selected. Players may prepare one under either displayed start choice, but
  it has future gameplay authority only for an eligible Random-start
  character. `Starting biome only` suppresses only the dangerous hazard family
  resolved at the initial landing; every other dangerous biome stays active.
  `All dangerous biomes` suppresses all four reviewed families. Standard
  ignores both, and neither selected means complete vanilla biome hazards.
  Zombies, falls, POI danger, weather visuals, progression, and ordinary
  damage remain.
- The current installed V3.1 definitions and native whole-world
  `BiomeProgression` setting were inventoried read-only. This supports GUI and
  contract design only; biome suppression, expanded Random placement,
  rooftops, and arrival protection remain unimplemented. The bounded
  safeguard scope must never silently change that global setting.
- The installed V3.1 starter quest is `quest_whiteRiverCitizen1` (`Journey to
  Settlement`). Its phase-one destination currently filters to Pine Forest,
  while its phase-two interaction already uses the closest trader. Static API
  inspection found a narrow native event/location route for a later Phase 1B
  proof; runtime authority, synchronization, save durability, and clean-client
  behavior remain unproven.
- Day 2 visual review found strong Wasteland-family resemblance but confirmed
  that the shell still uses older blank-template infrastructure. The routed UX
  manifest governs its evidence-led evolution toward the hardened module host.
- The project follows a proof-first, two-lane strategy: native authored-
  spawnpoint relocation is the core proof; arbitrary-coordinate Random search,
  distance agency, drop, and protection are separately gated extensions.
- Functional launcher policy work may now implement only the READY Alpha core;
  Phase 1B/1C and every later layer remain disconnected.
- The first DLL requires a complete project-local test-wiring and software-
  assurance packet before compilation, live copying, or provider review.
- The Phase 1 pre-build packet now pins the current build/API fingerprint,
  source layout, compiler recipe, dependencies, target schema, and marker API
  candidate. The installed Steam root is owner-designated as the private
  customer-grade observation lab, but compilation/copy/load remain gated on an
  exact target record, external build stage, backup or absence baseline, source
  review, scanner disposition, hashes, and artifact-specific approval.
- Project-owned work is GPL-3.0-or-later and targets OpenSSF OSPS Baseline
  v2026.02.19 plus the Best Practices Passing badge. It is not currently
  assessed, badged, certified, provider-approved, or independently audited.
- The full GPL text referenced by `LICENSE.md` is not yet present, so packaging
  and publication remain blocked even though the SPDX declaration is correct.
- Phase 0A security/state and UX-0/UX-1 contracts are inputs to the approved
  bounded execution packet; claims still require their named evidence.
- The amended pure-model subset of the negative-test matrix passes 66/66 checks in
  PowerShell 7 and Windows PowerShell 5.1. Every game-runtime case remains
  pending. No DLL copy/load, policy writer, or gameplay behavior is authorized
  merely by designating the installation as a lab. Steam/game launch remains
  exclusively user-controlled.

## Resolved Launcher/Runtime Decision

Runtime does not require the game process to have been launched by the Bit
Wrecked GUI. It requires a valid saved policy, an exact target match, the fixed
genuinely-new-player first-arrival gate, and every runtime safety check. Manual
use of the game's normal non-EAC launch option remains valid.

## Hard Boundaries

Unless the READY packet and an exact human checkpoint authorize the action:

- do not edit live `Mods`; the planned release target is the manifest-verified
  `BitWrecked_HistoricalRandomStart` folder and any live deployment/removal
  requires its exact human checkpoint. The historical `_DEV` probe is not an
  overwrite target;
- do not edit game XML, DLLs, executables, saves, or world files;
- do not edit, disable, rename, or remove existing Mods or existing saves;
- do not wipe or reinstall without separate approval naming the exact action;
- do not modify `0_TFP_Harmony`;
- do not create Developer Mode or console-command behavior;
- do not modify the Wasteland project;
- do not create a combined umbrella module;
- do not package, publish, push, upload, or distribute;
- do not claim clean-client or EAC compatibility; and
- do not treat a successful happy path as release approval.

## Working Location

Canonical project root:

`_game_dev_ai_tracking/solutions/bit_wrecked_historical_random_start/`

The project may later gain staged source, tests, package, and version folders,
but they should be added only when their phase and ownership are defined.
