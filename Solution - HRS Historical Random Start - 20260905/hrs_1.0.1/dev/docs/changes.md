# Historical Random Start - Alpha 6 Method Changelog

## 2026-08-27 — DEV, QA, and Nexus routing consolidated

- Routed the project through `../../../HRS_DEV_QA_NEXUS_WORKFLOW.md` and the
  immutable artifact index at `../../QA_Testing/README.md`.
- Defined DEV as the only source/build/fix lane, QA as a clean customer-like
  observe/report lane, and Nexus review as a later separate minimal candidate.
- Recorded the current QA observation without assuming its cause: exact-name
  Random may appear to leave the player at a normal/default central-map start.
  QA must compare eligibility, selected authored candidate, native/final
  coordinates, chronological lifecycle/placement events, marker state, and
  hashes.
- Preserved the uploaded QA ZIP unchanged. No source, runtime artifact, live
  mod, save/world, game file, or frozen Nexus lane was changed by this routing
  pass.

## 2026-08-26 — 0.0.5 alpha tech-demo development lane opened

- Completed the larger-model non-live preparation work packages: current-truth
  front door, deliberate version inventory/conversion, established-pipeline
  map, feature ledger, private-material disposition, validation report,
  protected-state integrity report, and changed-file handoff.
- Converted only current active identity fields to
  `0.0.5-alpha-tech-demo`, with numeric game metadata `0.0.5`. Preserved `v1`
  schemas, `0.0.1` historical contracts/probes, `0.0.7-preview` chronology,
  and retained older generated binaries as historical evidence.
- Passed 271/271 non-live checks in PowerShell 7 and 271/271 in Windows
  PowerShell 5.1. The two suites affected by the descriptive folder's legacy
  `MAX_PATH` limit passed through a temporary short drive alias, which was
  removed without residue.
- Verified identical PowerShell function surfaces (158 each) between active
  and frozen lanes, zero source-manifest drift, zero frozen/Nexus differences,
  and unchanged `Data/Config`, `Mods`, executable, EAC, and server-config
  fingerprints. No additional main or runtime entry point was added.
- Added `n0132.md`
  to govern the larger-model situational-awareness cleanup, deliberate version
  conversion, pipeline feature mapping, validation, and evidence handoff.
- Created `bit_wrecked_historical_random_start_0.0.5-alpha-tech-demo_2026-08-26`
  as the sole active Historical Random Start development workspace for this
  session.
- Preserved
  `bit_wrecked_historical_random_start_0.0.1-alpha_nexus-review_2026-08-26`
  as the frozen Nexus-review baseline; no `0.0.5` work may enter that lane
  while review is pending.
- Initialized the active lane as a complete 241-file copy of the reviewed
  baseline and verified every relative file by SHA-256 with zero differences.
- Retained the established pipeline and main entry points. New `0.0.5`
  behavior must be implemented as bounded pipeline features, not additional
  main functions or parallel orchestration paths.
- Confined routine reads, edits, tests, and build outputs to the active
  `0.0.5-alpha-tech-demo` folder. Live game files, installed mods, saves, and
  the Nexus repository require separate explicit authorization before any
  mutation.

## 2026-08-21 — Final Alpha core execution-readiness review

- Added `n0138.md` and marked bounded staged
  implementation READY while retaining exact human gates for live deployment,
  launch, game observation, restore/reset/removal, and publication.
- Froze the core chain and explicitly separated the later overall GUI uplift.
- Defined versioned policy/result sidecars, portable management-state layout,
  release deployment ownership, execution sequence, attempt ceiling, human
  checkpoints, true blockers, required tests, and the completion gate.
- Resolved the remaining Alpha labels and visibility questions: Standard is not
  enabled, internal Phase 0A becomes `Setup requires validation`, deferred
  scopes are hidden, and `Open Mods Folder` is omitted.
- Corrected stale status/no-launch/planning-only language in the manifest, plan,
  README, routing, and current-awareness documents.

## 2026-08-21 — Alpha UX/recovery interview consolidation

- Replaced stale no-launch wording with an always-visible `Launch Game` action
  that only the local user can activate; Steam is required, automation is
  forbidden, and incomplete configuration launches with the mod inactive.
- Renamed uninstall to `Remove from Game`: remove only verified deployed
  solution artifacts, retain the portable manager/history, and touch no system,
  shared, save, world, or unrelated-mod files.
- Added complete local correlated event history and Recovery containing Default
  plus five latest attempts. Failed/unavailable attempts remain visible; only
  immediately revalidated known-good states can be restored.
- Standardized the game-running lock for every capsule-changing action and
  rejected queuing, watchdogs, supervisors, telemetry, and crash-time action.
- Added a project-specific explanation contract informed by established UI
  guidance without imitating another platform's visual style.

## 2026-08-21 — Core vertical-slice and layered roadmap decision

- Defined the first complete increment as the exact-name frontend-to-runtime
  bridge: manual game-name entry, Standard/Random policy, genuinely-new-player
  first arrival, proven one-candidate atomic Random relocation, durable
  exactly-once marker, sanitized result, reload proof, and rollback.
- Moved trader routing, biome safeguards, discovery, broader scopes,
  multiplayer/server support, expanded coordinates, arrival protection,
  rooftops, and packaging into an explicit post-core sequence.
- Added a bounded completion mandate for a higher-level implementation AI:
  once the bridge packet is marked READY, ordinary build/test defects must be
  resolved through implementation and retesting rather than returned as
  premature stoppers.
- Limited pauses to genuine human/external, target/recovery, privacy,
  compatibility, destructive-action, publication, or irreconcilable-product
  blockers.
- Corrected stale README claims that no proof runtime exists and that launcher
  dependence remains an open owner decision.
- Expanded the scientific-methods whitepaper abstract and added a dedicated
  lessons-learned section covering vertical-slice completion, Standard as a
  negative control, exactly-once state, deliberate exact-name scoping,
  fail-closed behavior, plane separation, monotonic feature layering,
  evidence/rollback as completion work, and bounded AI autonomy.
- Added the same decision chronology to the review/reasoning log and routed the
  whitepaper explicitly as the project source for bridge rationale and
  accumulated engineering lessons.
- Added `n0137.md` with measured
  corpus sizing, human/operator competencies, required agent tools and
  behavior, 200k minimum/400k recommended/1M ideal context guidance, a
  cold-start packet, and a dated mapping to OpenAI Codex, Claude Code, Gemini,
  GitHub Copilot, and chat-only surfaces using official provider sources.
- Added Microsoft-informed human-in-the-loop rules to the plan and platform
  guide: structured action/argument approvals, PREPARED and post-observation
  checkpoints, resumable pending requests, approval-versus-authorization
  separation, trusted checkpoint storage, typed user observations, and bounded
  autonomous repair loops.
- Recorded the owner decision that neither AI nor launcher may start or
  automate Steam/the game in the core. Policy preparation ends at
  `WAITING_FOR_USER`; the owner independently opens Steam and chooses the normal
  non-EAC launch option.
- Added the owner-controlled EAC capability gate: the frontend explains the
  non-EAC requirement, runtime may positively confirm the approved lane, and
  active, unknown, or missing evidence fails closed without reservation or
  movement. No package component may disable, lower, configure, bypass, patch,
  or stop anti-cheat.
- Defined Historical Random Start as a manifest-owned solution capsule. Added
  a minimalist capsule state metric and an always-available, confirmed
  solution-only uninstall that removes and verifies only owned inventory while
  treating the game, Steam, saves/worlds, shared dependencies, other mods, and
  other Bit Wrecked solutions as external host objects.
- Added the bounded mod-coexistence contract. Recorded the narrow Phase 1A
  noninterference evidence and its claim limit; required unique capsule
  identities, recognized-version/drift/collision preflight, refusal to
  overwrite unknown owned-folder content, runtime competing-movement tests,
  and strict non-modification of Harmony and unrelated mods.

## 2026-08-20 — Phase 1A atomic relocation breakthrough

- Corrected the semantic proof boundary so the unchanged-state digest is
  compared immediately around placement and existing-observer synchronization
  in one deferred update callback, while retaining the complete reviewed
  semantic field set.
- Produced two byte-identical reviewed builds, staged the exact two-file
  payload, preserved the superseded live payload, and installed the atomic
  artifact recoverably.
- Documented the critical target-name distinction: the stale/older
  `HRS_Phase1_Test_001` entry is not the authorized
  `HRS_Phase1A_Test_001` target. Continue against the reset target failed in
  native menu code, and New Game with the old name was safely rejected before
  mutation.
- Created the exact new Navezgane target and observed the complete successful
  runtime sequence: `RELOC_PLACEMENT_DEFERRED`, `RELOC_PLACEMENT_CALLED`,
  `RELOC_SEMANTIC_UNCHANGED`, and `RELOC_COMPLETED`.
- Visually confirmed the relocated spawn and normal exit. Game-managed and
  foreign-mod trees remained exact; the completed target persisted with 77
  files and a recorded aggregate.
- Did not claim a full foreign-save-tree pass: the same session had first saved
  the older no-`A` world and updated root New Game metadata, so its aggregate
  necessarily differed. Persistence reload remains pending.

## 2026-08-20 — Phase 1 external observation build

- Recorded and validated the exact private Navezgane observation target and a
  real pre-test absence baseline.
- Implemented the six-file observation-only DEV probe without placement,
  persistence, Harmony, network, command, or gameplay mutation paths.
- Aborted the first build cleanly when the restored legacy compiler rejected
  deterministic/C# 7.3 switches.
- With renewed owner authorization, pinned the installed Roslyn compiler and
  produced two byte-identical external DLLs.
- Defender and static call-graph scans passed; the staged artifact has not been
  loaded.
- After a separate owner approval, copied exactly the approved DLL and
  `ModInfo.xml` into the new owned DEV Mod folder; copied hashes and the
  post-copy Defender scan passed. The game was not launched.
- With a separately authorized, user-authenticated Steam session, completed
  the first EAC-disabled NewGame observation. The probe emitted the expected
  authoritative/local/NewGame eligible signal and no error reason; remaining
  Phase 1 runtime rows are still pending.
- Reloaded the exact disposable target and proved `LoadedGame` is classified
  as `OBS_LIFECYCLE_REJECTED`; payload and global metadata hashes remained
  stable and no existing world file changed.
- Completed one owner-authorized ordinary death/respawn in the disposable
  target and proved `Died` is also classified as
  `OBS_LIFECYCLE_REJECTED` without a probe action.
- Completed two ordinary deaths in one process and proved the second identical
  lifecycle key produces `OBS_DUPLICATE_SUPPRESSED` without growing the
  bounded observation set.
- Moved the exact owned DEV folder intact to external recovery and completed a
  normal no-probe reload with zero HRS lines or BitWrecked errors.
- Closed the Phase 1 review as a pass for the exact local single-player
  observation question while keeping Phase 1A mutation, multiplayer, and
  incomplete semantic state-delta claims gated.

## 2026-08-14 — Preview confirmation readability refinement

- Reworked the native confirmation copy into minimal first-Apply, changed
  pending-selection, and unchanged-refresh paths. Each shows only the action,
  short state/change summary, checked-folder signal, and preview-only boundary.
- The popup omits the raw game-folder path and says Random safeguards are
  inactive when Standard is selected. The native Yes/No buttons remain
  unchanged.
- Preserved actual changed values for pending reapply, session-only/no-game-
  change semantics, activity behavior, and all validation gates.

## 2026-08-14 — Preview Apply state-truth and folder edge fix

- Added one derived session-state renderer for folder-check-required,
  invalid-folder, not-applied, pending, and applied truth. Cancel is a visible
  outcome layered over the unchanged underlying state.
- Kept the last confirmed in-memory snapshot immutable while live
  Standard/Random and safeguard edits move the preview to Pending; reverting
  every value restores Applied.
- Added an exact validated-folder key. Any direct or Browse-driven path edit
  immediately makes the old snapshot stale, disables Apply, and requires
  `Check Game Folder`; Apply also rechecks the folder defensively.
- Expanded confirmation copy to show all current values and actual changes,
  including a path-redacted folder-change description and explicit unchanged
  refresh wording.
- Added deterministic, modal-free test seams that cannot replace production
  dialogs outside the test host, plus an 11-case Apply workflow suite and a
  hardened AST write scan.
- Passed both PowerShell parsers, direct and BAT smoke tests, 11/11 workflow
  tests in both hosts, the existing 56/56 pure suite in both hosts, manual
  popup/state/log review, and a before/after live-tree fingerprint check.
- Preserved the sole opt-in, user-selected activity-log writer. No gameplay,
  policy, save, world, XML, DLL, executable, `Mods`, `Data/Config`, Harmony,
  registry, service, task, installation, launch, or release behavior was added.

## 2026-08-14 — Session-only preview apply and confirmation

- Added `Apply Preview Settings` beside `Check Game Folder`.
- Added a confirmation popup that lists the exact setting changes and a
  success popup that shows the applied session values.
- Added explicit activity-log entries for apply, cancel, and each changed
  setting; the activity pane opens after a successful apply.
- Kept the action preview-only: it records values in the open window and does
  not write policy, saves, runtime settings, or game files.
- Advanced the player preview to `0.0.7-preview`.

## 2026-08-14 — Starting-biome or all-biomes safeguard scope

- Replaced the four independent biome checkboxes with two simpler,
  mutually-exclusive choices: `Starting biome only` and `All dangerous
  biomes`.
- Left both choices unchecked by default and always available. With neither
  selected, Random keeps every native biome hazard active; Standard ignores
  either prepared preference and remains an exact no-op.
- Defined `Starting biome only` as a one-time authoritative resolution from
  the initial Random landing biome. A dangerous landing suppresses only that
  biome's reviewed hazard family for the character; later dangerous biomes
  remain fully active. An ordinary landing grants no relief.
- Defined `All dangerous biomes` as the four reviewed Burnt Forest, Desert,
  Snow, and Wasteland hazard families for that eligible Random character.
  Zombies, falls, POIs, ordinary damage, weather presentation, and
  progression remain outside the safeguard.
- Constrained the future policy to `None`, `ArrivalBiome`, or
  `AllDangerousBiomes`. The server derives either no mask, exactly one family
  bit, or all four bits; arbitrary combinations and invalid values fail closed
  before placement.
- Advanced the read-only player preview to `0.0.6-preview`. Runtime biome
  suppression, policy writing, and gameplay mutation remain unimplemented.
- Passed PowerShell 7 and Windows PowerShell 5.1 parsing, BAT and direct smoke
  tests, both 56/56 pure-contract runs, four-file JSON parsing, the forbidden
  operation scan, static and interactive two-scope assertions, visual
  main/help review, the official Alpha 6 source check, all 11 monitored
  live-game hashes, and the closed-process boundary.

## 2026-08-14 — Two-choice product simplification

- Reduced the complete player-facing start model to exactly `Standard` and
  `Random`. Standard is the game's normal start and remains an exact no-op;
  Random owns every approved custom-start behavior.
- Removed the former third policy choice from the current launcher, manifest,
  plan, security/state model, UX contracts, assurance packet, and active
  evidence wording. A stale third-mode policy value is now invalid and fails
  closed before selection or placement.
- Kept broader coordinate search, Wasteland rooftops, distance agency, drops,
  and arrival protection as separately gated future Random extensions rather
  than another start type.
- Reassigned the four default-off, always-editable biome safeguards to Random.
  Standard retains the choices in memory for player preparation but ignores
  them completely.
- Limited nearest-valid-trader continuity to a completed eligible Random start
  and made the separately reviewed Phase 1C safeguard proof part of the core
  two-choice completion gate.
- Advanced the read-only player preview to `0.0.5-preview`. No runtime helper,
  policy writer, gameplay payload, or live-game mutation was added.
- Revalidated The Fun Pimps' Alpha 6 post through its working official
  WordPress permalink (`?p=1150`) and replaced the old slug, which now renders
  the site homepage without the release-note evidence.
- Passed PowerShell 7 and Windows PowerShell 5.1 parsing, BAT and direct GUI
  smoke tests, both 56/56 pure-contract runs, four-file JSON parsing, static
  two-mode assertions, visual main/help review, the forbidden-operation scan,
  official-source content checks, and all 11 monitored live-game hashes.

## 2026-08-14 — Default-off biome-comfort agency revision

- Changed Burnt Forest, Desert, Snow, and Wasteland relief to initialize
  unchecked. The ordinary biome hazards therefore remain the default unless the
  player deliberately opts out for selected biomes.
- Kept all four checkboxes visible and enabled under Standard, Random, and
  Wilderness so players can prepare choices without controls greying out.
  Explanatory copy states that only Wilderness can use those preferences.
- Replaced the repeated two-column labels with one aligned row under `Turn off
  Wilderness biome hazards (optional)`: Burnt Forest, Desert, Snow, Wasteland.
- Preserved Standard and Random as zero-effect paths for biome relief; dormant
  visible selections grant no runtime authority and create no character mask.
- Advanced the read-only shell to `0.0.4-preview` and updated its smoke
  assertions for unchecked defaults, always-enabled controls, mode transitions,
  and selection retention. Both PowerShell parsers, the launcher smoke test,
  the 56-case pure suite in both engines, and the final visual review pass.
- Changed no live XML, biome configuration, save, world, DLL, Harmony file,
  `Mods` content, runtime policy, or gameplay behavior.

## 2026-08-14 — Nearest opening-trader continuity planned

- Confirmed from the installed V3.1 definitions that `Journey to Settlement`
  currently selects its phase-one trader destination through a Pine Forest
  biome filter, then awards 500 XP and one stone shovel through the native
  quest completion path.
- Defined Random and Wilderness continuity: after a confirmed custom placement,
  point only that opening destination to the deterministic nearest valid native
  trader across any biome. Standard remains an exact no-op.
- Preserved the native quest ID, phase, state, starter CVar, objective flow,
  shovel, XP, challenge rewards, trader tiers, inventory, and all later trader
  quests. Resetting, deleting, cloning, re-adding, or auto-completing the quest
  is forbidden.
- Bounded the future route to one authoritative attempt per eligible character,
  with untouched native quest handling on uncertainty and no second teleport.
- Recorded static evidence for the native quest-accepted event, closest-POI
  selection, and location setter. Runtime synchronization, durability,
  dedicated/listen behavior, and clean-client behavior remain unproven and are
  assigned to Phase 1B after Phase 1A placement succeeds.
- Advanced the read-only shell to `0.0.3-preview` with one plain-language line
  explaining nearest-trader handling in `How It Works`. Both PowerShell parsers,
  the built-in launcher smoke test, and a visual clipping/branding review pass.
- Changed no live quest XML, game configuration, save, world, DLL, Harmony
  file, `Mods` content, runtime policy, or gameplay behavior.

## 2026-08-14 — Wilderness biome-comfort preview

- Added separate `Snow hazards off`, `Burnt Forest hazards off`, `Desert
  hazards off`, and `Wasteland hazards off` checkboxes to the player preview.
  They initialize checked and become interactive only when Wilderness is
  selected.
- Kept the promise narrow: a future checked option may suppress only that
  biome's hazard/storm debuff family for the eligible Wilderness-start
  character. Zombies, falls, POIs, weather visuals, ordinary temperature,
  progression, hunger, thirst, infection, and ordinary damage remain.
- Inventoried the exact four hazard/storm families and native whole-world
  `BiomeProgression` setting in the current installed V3.1 files. The global
  setting is read/respect-only and cannot be silently written by per-biome
  controls.
- Added per-character scope, compatibility, rollback, malformed-state, and
  multiplayer-spillover requirements to the planning and negative-test packet.
- Recorded official Fun Pimps developer evidence that the modern biome-hazard
  system has an off path that removes biome debuffs while cosmetic weather
  remains, without making a broader unsupported claim about every Alpha 6
  environmental mechanic.
- Required fail-closed candidate rejection when checked relief cannot be
  proven, rather than placing the player and attempting broad buff removal.
- Advanced the read-only shell to `0.0.2-preview` and passed its parser and
  built-in GUI smoke test.
- Changed no live XML, biome configuration, save, world, DLL, Harmony file,
  `Mods` content, runtime policy, or gameplay behavior. Wilderness, rooftops,
  and biome comfort remain deferred behind the Alpha 6 core proof.

## 2026-08-14 — Phase 0A pre-build assurance packet

- Reconfirmed the installed V3.1.0 b14 display version, Steam build, Unity
  version, managed-assembly hashes, loader environment, compiler availability,
  spawn-event ordering, native authored-point selector, native grounded/
  headroom validator, and game-owned CVar serialization route.
- Added the Phase 1 observation-only design, pinned no-SDK compiler recipe,
  machine-readable dependency record, strict private-target schema, fictional
  target example, pure Alpha 6 core decision model, and negative fixtures.
- Passed 56/56 pure checks under PowerShell 7 and Windows PowerShell 5.1 and
  recorded exact tested-file hashes and a forbidden-operation static scan.
- Kept the first DLL at NO-GO pending an exact external disposable target,
  backup, source review, dependency/scanner disposition, and explicit owner
  approval.
- Created no runtime source, binary, staged payload, game copy, save backup,
  policy writer, installation, gameplay change, or live game modification.

## 2026-08-14 — Owner-designated private lab target class

- Added the strict `OwnerDesignatedDisposableLiveInstall` target class for one
  exact owner-designated Steam installation used as a customer-grade private
  Phase 1 observation lab.
- Kept build/output staging external and restricted any future runtime copy to
  the exact owned `Mods/mod_DEV/` folder after
  payload-specific approval.
- Required a new-game-only target and explicit protection of existing saves,
  worlds, Mods, Harmony, game files, and `_game_dev_ai_tracking`.
- Explicitly withheld wipe, reinstall, broad-delete, copy, and load authority;
  each requires its own exact approval where applicable.
- Extended the pure target validator with positive and fail-closed owner-lab
  cases; the amended suite passes 66/66 in PowerShell 7 and Windows PowerShell
  5.1.

## 2026-08-14 — Player-facing product name selected

- Named the mod `Historical Random Start - Alpha 6 Method`.
- Updated the launcher title, informational popup, preview wording, and
  activity filename to use the player-facing name.
- Retained the existing workspace folder and technical filenames so project
  routing and saved work remain stable.

## 2026-08-14 — Player-facing preview wording revision

- Reworked the clickable shell for a Facebook/community player audience:
  replaced Phase 0A, payload, runtime, and placeholder language with plain
  terms such as `Preview`, `Check Game Folder`, and `How It Works`.
- Removed the disabled `Runtime Not Built`, `Remove Mod`, `Open Mods Folder`,
  generic feature table, and unfinished world-policy checkbox from the visible
  experience.
- Added clear player-facing popups explaining the three planned start choices
  and confirming that the preview does not change the game.
- Replaced popup bullet characters with ASCII hyphens to avoid Windows
  encoding artifacts such as `â€¢`.
- Moved `How It Works` into the top header so players see the explanation
  before choosing a folder or checking the game.
- Removed the warning-style safety paragraph from the informational popup;
  the preview status is already explained in the main window.
- Added a validated historical factoid: random first starts are documented in
  Alpha 6 and still reported in Alpha 17.4, with Alpha 18 as the repeatable
  world-name/seed transition. The evidence note is stored under `evidence/`.
- Presented the factoid as a small Bit Wrecked quote card with the project
  logo inside the informational popup.
- Renamed the visible activity area to `Recent activity` and simplified its
  save wording.
- Smoke-tested the revised PowerShell shell successfully. No gameplay,
  installation, policy, save, world, XML, DLL, Harmony, or live `Mods` action
  was added.

## 2026-08-14 — Phase 0A and UX-0/UX-1 contracts drafted

- Added the Phase 0A security/state baseline covering authority, state
  transitions, marker semantics, configuration bounds, atomic-write rules,
  sanitized logging, resource limits, and unresolved owner decisions.
- Added the UX-0 control inventory and UX-1 pure state/capability model,
  including truthful control disposition, stale-result handling, running-game
  lock behavior, accessibility requirements, and negative model cases.
- Added the Phase 0A negative-test matrix with launcher, persistence, runtime,
  protection, privacy, resource, compatibility, and forbidden-side-effect
  cases. All cases remain pending; no pass claim is made.
- Updated project routing, first-read guidance, situational awareness, plan,
  and reasoning records.
- Changed no launcher code, gameplay payload, live game file, Harmony file,
  save, world, XML, DLL, or live `Mods` content.

## 2026-08-14 — Open-source governance and security baseline

- Declared GPL-3.0-or-later as the project-owned source and documentation
  license and recorded corresponding-source and proprietary-asset boundaries.
- Added the Linux Foundation/OpenSSF-aligned governance manifest, pinned the
  initial OSPS Baseline target to v2026.02.19, and prohibited unsupported badge,
  certification, Scorecard, SLSA, audit, and provider-approval claims.
- Added `n0183.md`, `SECURITY.md`, `n0149.md`,
  `n0146.md`, and `n0179.md`.
- Recorded the absent complete GPL license text as a packaging/publication
  blocker rather than treating the existing summary as a complete packet.
- Updated project routing, first-read guidance, manifest, situational awareness,
  and layered reasoning. No gameplay, live game, Harmony, save, or older-project
  files were changed.

## 2026-08-13 — Project organization and Phase 0 record

- Established the independent solution root at
  `solutions/bit_wrecked_historical_random_start/`.
- Moved the manifest, plan, and design review/reasoning log from the tracking
  root into the project solution.
- Added permanent project and document routing.
- Preserved the Phase 0 installed-build discovery as project evidence.
- Recorded the open launcher-only activation decision without choosing an
  answer for the owner.
- Updated the next action to Phase 0A documentation and contract design.
- Changed no gameplay payload, game file, Harmony file, save, world, XML, DLL,
  or live `Mods` content.
- Added the clickable `preview/START.bat` design-shell launcher.
- Retargeted the payload-free Bit Wrecked blank framework shell to this
  project's identity and copied the approved local brand asset and GPL license.
- Added the framework normalization manifest, support-file boundary, and empty
  payload placeholder. No gameplay or policy action was enabled.

## 2026-08-14 — Day 2 UX comparison and evolution plan

- Compared the owner-provided current-window screenshot with the current shell,
  neutral template, completed Wasteland 4.1.1 launcher, and accepted module
  host.
- Recorded quantitative source similarity and current visual observations.
- Added a detailed UX parity/evolution manifest containing component
  disposition, target information architecture, required states, leveraged-
  reasoning authority, phased work, tests, acceptance criteria, open decisions,
  and stop conditions.
- Routed the UX work packet through the project manifest, plan, README, document
  map, evidence index, and reasoning log.
- Changed no launcher code, gameplay payload, live game file, Harmony file,
  save, world, XML, DLL, or live `Mods` content.
- Added `n0150.md` to preserve the accepted approach,
  current working object, reference-only boundary, design direction, open
  decisions, and exact next action for future sessions.
- Added a dated reasoning-log entry confirming that older works remain
  observation-only and current changes stay inside this unpublished solution.
- Adopted a proof-first, two-lane product strategy in the main manifest.
- Defined native authored-spawnpoint, direct-grounded relocation as the core
  runtime proof and moved arbitrary Wilderness search, drop, protection, and
  distance agency into a separately gated experimental lane.
- Added Phase 1A and corrected the governing execution order so functional
  launcher work cannot outrun runtime feasibility evidence.
- Clarified that installed Vanilla is a gameplay no-op rather than absence of
  loaded custom code.
- Updated situational awareness, UX authority, README context, and the
  reasoning log without changing launcher or gameplay code.
- Added the combined DEV test-wiring and software-assurance contract covering
  artifact identity, source/build provenance, dependencies/SBOM, hashes,
  compatibility, EAC disclosure, scanner-friendly behavior, provider access,
  owned installation/removal, backup/rollback, diagnostic privacy, abort
  conditions, release lanes, and promotion evidence.
- Routed the pre-DLL assurance gate through the manifest, plan, situational
  awareness, README, document map, and reasoning log.
