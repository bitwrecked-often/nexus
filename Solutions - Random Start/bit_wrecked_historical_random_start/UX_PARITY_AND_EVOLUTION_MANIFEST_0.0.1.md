# Historical Random Start - Alpha 6 Method UX Parity and Evolution Manifest 0.0.1

Status: Planning authority for UX study and launcher-shell evolution

Implementation authorization: Documentation, comparison fixtures, and staged
launcher-shell work only after Phase 0A prerequisites are satisfied

Gameplay/runtime authorization: No

Release authorization: No

## Purpose

Guide a capable implementation AI through the comparison, redesign, and staged
evolution of the Historical Random Start - Alpha 6 Method Windows launcher without requiring the
owner to restate the project's visual history or product boundaries.

This manifest uses leveraged reasoning deliberately. It defines outcomes,
evidence, constraints, tests, and escalation boundaries while allowing the
implementer to choose sound internal structure, dimensions, helper functions,
and small usability improvements. It does not authorize the implementer to
invent product behavior, broaden file writes, or claim runtime compatibility.

## Desired Result

Create a launcher that is immediately recognizable as a sibling of Wasteland
Animal Population Tuning while being unmistakably designed for world-scoped
spawn policy.

The result should preserve the Bit Wrecked visual language and operational
trust model, inherit the newer module host's accessibility and hardening, and
replace inherited Wasteland/blank-template controls with the Historical Random
Start workflow.

Functional launcher policy work is subordinate to the core runtime proof. The
UX plan may produce comparison evidence, pure state models, fixtures, and
hardened read-only infrastructure before that proof, but it must not create the
appearance of a working product through enabled writes or launch actions.

Fidelity means preserving the learned experience, not copying every pixel or
retaining controls that no longer have a valid capability.

## Authority and Source Order

When sources differ, use this order:

1. `2026-08-13_historical_random_start_manifest.md` for product behavior and
   hard safety boundaries.
2. `2026-08-13_historical_random_start_plan.md` for phase order and gates.
3. This manifest for launcher UX comparison and evolution.
4. `evidence/2026-08-14_day_2_ui_comparison.md` for observed current-state
   evidence.
5. The accepted module-host implementation and acceptance harness for current
   host security, accessibility, responsiveness, and logging patterns.
6. Wasteland 4.1.1 for proven visual language and interaction history.
7. The blank framework shell for geometry and scaffold reference only.

Historical Wasteland behavior never overrides this project's world-policy,
write, runtime, privacy, or release boundary.

## Compared Sources

| Source | Role | SHA-256 at this review |
| --- | --- | --- |
| `Support_Files_Do_Not_Edit/HistoricalRandomStart_Tool.ps1` | Day 2 project-shell baseline | `886CA2D1C20C3BD5B653974C1349FB9A162587DCE3076DE28C5FFBC2D9AB36A6` |
| `../bit_wrecked_mod_framework_template/blank_working_example/Blank_BitWreckedMod_Tool.ps1` | Neutral copied scaffold | `FE81A3A9C2DA5F3B39087865E133B2E99C86B4EB707FCBA6260CE11AA85A24F9` |
| `../bit_wrecked_mod_framework_template/module_host/BitWrecked_ModuleHost_Tool.ps1` | Hardened current host | `F3C65750D1613C537319F17AFE9FBDABAFDF56854F8984E0B31A5220482AE291` |
| `../7dtd_wasteland_animal_population_tuning_files/Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1` | Completed first-mod reference | `168F333A8D5A4C9CA150A40205DF2E148207DE2D1D3F978E7884E45B7C425FEF` |

The owner-provided Day 2 screenshot is conversational visual evidence. Its
observations are transcribed into the dated evidence note so the plan does not
depend on conversation history surviving.

The first hash and the comparison measurements below intentionally preserve
the Day 2 pre-0.0.5 baseline. They are historical comparison evidence, not a
claim that the evolving preview still has that hash or line count.

### Current reviewed preview fingerprint

The historical table above is unchanged. After the 2026-08-14 session-only
Apply edge fix, the separately reviewed current implementation is:

| Source | Version | Size (bytes) | Lines | SHA-256 |
| --- | --- | ---: | ---: | --- |
| `Support_Files_Do_Not_Edit/HistoricalRandomStart_Tool.ps1` | `0.0.7-preview` | 65,815 | 1,478 | `8AF32340DFECE64250FE053F0A188A1FFC9F58B3F361EBECF283FF4F8F468E5D` |

Test and review details are recorded in
`evidence/2026-08-14_preview_apply_edge_fix_test_report.md`.

## Day 2 Baseline Finding

The reviewed Day 2 project shell was a successful identity retarget of the blank
template, not yet a full adaptation of the completed Wasteland product or
hardened module host.

- Current and blank scripts are both 753 lines.
- 641 of 670 normalized nonblank current lines match the blank shell: 95.7%.
- 384 normalized current lines exactly match the Wasteland visual UI block:
  57.3%. This understates visual similarity because product-specific source,
  quoting, accessibility, and feature behavior differ.
- The current shell and Wasteland use the same 620-by-660 collapsed form,
  930-by-660 initial expanded form, fixed 620-pixel main side, expandable log,
  panel geometry, visual palette, and primary layout grammar.

The shell therefore passes visual-family recognition but has not yet earned
functional, accessibility, security, or product-specific UX parity.

## Design Doctrine

### Preserve recognition, not accidental inheritance

Retain the parts that teach a returning user where they are:

- Bit Wrecked logo and brand treatment;
- clear project name and version/state;
- short status card;
- visible selected game folder;
- one central task workspace;
- one obvious next action;
- expandable Layered Reasoning Log / Recent Actions;
- restrained colors, rounded panels, plain Windows controls; and
- local, native, account-free operation.

Do not retain a checkbox, table heading, button, tooltip, or panel merely
because Wasteland or the blank shell had one.

### Prefer the hardened host beneath the familiar face

The blank shell is a geometry reference. The accepted module host is the
preferred source for:

- DPI awareness;
- high-contrast palette handling;
- accessible names, descriptions, roles, and tab order;
- bounded visible logging;
- explicit persistent-log consent and path restrictions;
- fixed allowlists rather than arbitrary discovery;
- responsive validation workers and stale-result rejection;
- measurable startup/render/validation performance; and
- strict action/capability boundaries.

Do not copy the monolithic Wasteland script wholesale and do not extend the
older blank-shell writer simply because it is already present.

### Make absent capabilities absent

Disabled speculative controls are not a roadmap. If a capability has no
approved handler, omit it from the functional UI or place it only in a clearly
identified design fixture.

The finished launcher must not show `Remove Mod`, `Install`, `Runtime Not
Built`, or a generic reserved checkbox unless a current approved capability
gives that control a truthful purpose.

## Component Disposition Matrix

| Current component | Disposition | Target reasoning |
| --- | --- | --- |
| Bit Wrecked header/logo | Retain | Strong family identity; no gameplay coupling. |
| Project title/version/state | Adapt | Show launcher version and honest capability/release state without internal phase jargon in customer builds. |
| Green recognized-folder card | Replace state model | Folder recognition is not runtime readiness. Use text plus neutral/success/warning state appropriate to the whole selected context. |
| Game-folder text and chooser | Retain and harden | Keep familiar location; use canonical local-path validation and accessible wording. |
| Generic five-column empty table | Replace | Build the world/save index with `World`, `Status`, and `Spawn Policy`; add supporting identity only when needed to avoid collisions. |
| Empty-state paragraphs | Retain only in design build | Customer build should show actionable world discovery or a precise empty/error state. |
| `Validate Current Game Settings` | Rename and split by capability | Current shell validates only the folder. Later validation must name exactly what it reads: folder, saves, policy index, runtime installation, or launch readiness. |
| Reserved world-policy checkbox | Remove | It is inherited placeholder theater, not an approved interaction. |
| `Runtime Not Built` | Remove from functional build | Useful only as a design-shell truth label; not a customer action. |
| `Remove Mod` | Omit until approved | No installation ownership or removal handler exists. |
| `Open Mods Folder` | Omit from initial policy workflow | Not part of the likely task and introduces an unrelated process/folder capability. Reconsider only with evidence. |
| `Close` | Retain | Clear local desktop behavior. |
| Log expander/split pane | Retain and improve | Preserve history; constrain or proportion widescreen behavior so fullscreen does not become mostly empty log. |
| Runtime-only log default | Retain | Proven privacy and support model. |
| Optional persistent log | Retain from hardened host | Explicit consent, local path, bounded writes, no game-root/network/device paths, disabling never deletes. |
| Ordinary tooltips | Replace with approved explanation model | Use concise accessible text; optionally preserve Wasteland's useful tooltip-to-log indexing only when it remains low-noise. |
| Fixed pixel geometry | Adapt | Preserve hierarchy, not clipping. The implementer may widen/reflow for world names, DPI, and accessibility. |

## Target Information Architecture

The first functional launcher should read top-to-bottom as:

```text
Bit Wrecked identity | Historical Random Start - Alpha 6 Method | launcher version/state

Context status sentence
Selected 7DTD game folder                          [Choose Game Folder]

Recent world saves
World / Game              Status                  Spawn Policy
[up to five recent rows; selected row is explicit]

[Browse for Another World] [Load All Worlds]

Selected-world policy
ACTIVE/BYPASSED | Standard / Random
Random opening trader quest -> nearest valid trader
Starting-biome-only / all-dangerous-biomes Random safeguard scope
Plain-language saved result and safety/fallback explanation

[Apply] [Launch Game] [Close]
Configuration incomplete — mod not enabled (when applicable)
Non-EAC status — Required / Confirmed / Runtime lane unconfirmed

Expandable Layered Reasoning Log / Recent Actions
```

This is an information model, not a mandatory pixel layout. A stronger design
may use a list view, grid, detail pane, radio group, dropdown, segmented control,
or another native WinForms arrangement if it satisfies every state, keyboard,
accessibility, and test requirement.

### New-game identity and target scope amendment — owner decision 2026-08-21

The UI must distinguish an identity that already exists from a game the player
is about to create. Add a target selector with two initial paths:

```text
Choose target

( ) Existing game
    [read-only discovered-game list]

( ) New game
    Exact game name: [________________________] [Copy Name]
```

The New Game field is the first functional bridge. The player saves policy for
one exact proposed name and types or pastes that same name into the game's New
Game screen. The runtime fails closed unless the game-reported name matches.
After creation, the next read-only scan replaces the provisional presentation
with the discovered save identity and its categorical runtime result.

Do not merge the following independent concepts in one control:

- **Target scope:** exact new-game name, one discovered game, or all games;
- **Start policy:** Standard or Random; and
- **Runtime trigger:** fixed to a genuinely new player's first eligible
  arrival, at most once per player/game.

`All Games` broadens only target scope. It never means move established players
on load. Reload, reconnect, death, respawn, and continued play remain no-action
paths after reservation/completion. The UI must state this invariant plainly:

> Applies only to each player's first arrival. Existing players are never
> moved.

The authoritative behavior matrix is the `Canonical Policy Eligibility Grid`
in `2026-08-13_historical_random_start_plan.md`. UI states and capability
predicates must cite its `PEG-*` row IDs; this UX manifest must not create a
second behavioral grid.

The first implementation enables only the exact-name New Game path. The
discovered list initially provides status/history, and `All Games` may appear
only as a clearly unavailable future scope. Enabling discovered-game mutation
or all-game/server scope requires independent capability predicates and
multiplayer evidence; visual presence is not authorization.

The exact-name field rejects blank input, leading/trailing whitespace,
ambiguous normalization, and collision with a discovered game. Matching is
exact after the one documented canonicalization procedure; do not use
substring, fuzzy, or best-effort matching. Keep the armed value visible as
`Armed for: <name>` and provide a Copy Name action to reduce transcription
error.

## Required Launcher States

The UI must model these states explicitly rather than encoding them only in
button colors:

| State | Required visible truth | Allowed actions |
| --- | --- | --- |
| No recognized game root | Folder not recognized; no world policy loaded. | Choose folder, view log, close. |
| Valid root, no saves | Folder recognized; no save instances found. | Refresh/browse if defined, view log, close. |
| Saves discovered, no row selected | Count and five-recent rule explained. | Select, browse, load all. |
| Newly discovered save | `BYPASSED — vanilla spawn`; Vanilla selected. | Edit while game closed, save after confirmation. |
| Saved bypassed world | Saved policy and timestamp/record status shown. | Edit while closed; then follow manual Steam instructions. |
| Saved active custom world | `ACTIVE` text plus exact mode; green only reinforces. | Edit while closed; then follow manual Steam instructions. |
| Active with Vanilla selected | Active launcher policy but exact gameplay no-op. | Must not imply custom relocation. This wording needs owner-approved resolution before release. |
| In-memory edits, not saved | Clearly say changes are local to the open window and will not affect launch until saved. | Save/discard while game closed; no disk-side pending record. |
| Game running | Read-only lock reason shown. | View current saved state and log only; no policy mutation, save, or policy launch. |
| Validation in progress | Exact read being performed; UI remains responsive. | Cancel only if designed; unrelated read-only navigation may remain. |
| Malformed/mismatched policy | Fail closed to Vanilla; precise reason shown. | Repair through reviewed save flow only. |
| Runtime unavailable/incompatible | Custom launch not presented as ready. | Vanilla/bypass path and diagnostic validation only. |
| Saved-settings success | World, previous/new policy, timestamp, launcher version, result. | Close popup; independently open Steam when ready. |
| Save failure | No false success and no partial/pending policy. | Read reason, retry after correction, or stay vanilla. |

No UI state may imply that Random is active merely because the game
folder exists or a dropdown value was changed.

## World Identity and List Rules

- Default view contains the five most recently modified save instances, not
  merely five unique world names.
- Display enough information to distinguish two game saves with the same world
  or game name.
- Internal identity uses canonical storage root, world name, and game name; a
  world GUID may be used as an additional mismatch check.
- Do not parse or display Steam IDs or private player identity.
- `Browse for Another World` adds or focuses one selected valid save without
  silently loading every save.
- `Load All Worlds` is explicit and may use responsive background enumeration
  if measurement requires it.
- Sorting and selection must remain stable while validation completes.

## Policy-Control Rules

- Bypassed always produces vanilla game behavior.
- Vanilla always produces an exact gameplay no-op, whether the launcher status
  model ultimately permits it under ACTIVE or normalizes it to BYPASSED.
- Random uses the native authored spawnpoint list.
- Any future broader safe-world distance agency is an extension of Random,
  never a third start type.
- Random includes nearest-valid-trader continuity for only the
  opening stone-shovel quest after the separately approved Phase 1B gate. This
  is explanatory core behavior, not a checkbox or destination editor.
- Standard, existing characters, unrelated quests, quest state, rewards,
  progression, and later trader routes remain untouched.
- Hide or disable mode-irrelevant settings with an explanation; do not allow a
  stale `Random Distance` slider to imply it affects Standard. The two
  Random-start safeguard preferences below are the explicit exception to
  hiding or disabling mode-irrelevant controls.
- Random exposes one aligned row titled `Random-start safeguards (optional)`
  with exactly two checkboxes: `Starting biome only` and `All dangerous
  biomes`.
- Both are unchecked by default and are mutually exclusive; checking one
  clears the other. Saved settings are then respected rather than silently
  reset.
- The controls remain visible and editable for Standard and Random so players
  can prepare one preference. Explanatory copy must say they apply only to
  Random, and Standard remains an exact no-op regardless of their values.
- Starting-biome-only resolves no family or exactly the authoritative landing
  biome's reviewed hazard/storm family. Every other dangerous biome stays
  active. All-dangerous-biomes resolves all four reviewed families.
- Neither checked means complete vanilla hazard behavior. The UI must
  explicitly say that zombies, falls, POI danger, ordinary damage, lootstage,
  gamestage, and unrelated effects remain active under either safeguard.
- If required relief is unavailable, the Random placement must fall back
  before landing; the launcher/runtime must not imply safety.
- A policy or saved value that requests a third start type is invalid and must
  fail closed to untouched Standard behavior.
- Read the native whole-world `BiomeProgression` state as compatibility
  context. Never silently write that global setting to fulfill per-character
  safeguard-scope controls.
- Settings values are selected from strict allowlists/ranges; UI validation is
  convenience, while the persisted policy and runtime both revalidate.
- The UI never accepts or stores arbitrary destination coordinates.

## Save, Lock, and Launch Rules

- No write occurs on startup, folder choice, save selection, policy selection,
  validation, navigation, log expansion, or application close.
- While the game is closed, the owner may create an in-memory edit. It becomes
  effective only after explicit summary, confirmation, atomic save, and
  verification.
- No separate on-disk pending-settings mechanism is permitted.
- The game-running lock disables only this launcher's mutation controls. It
  does not lock game files or the game process.
- Process detection uses canonical executable paths and fails closed when
  process identity cannot be established.
- Save success creates the bounded local policy update and separate Saved
  Settings Record defined by the persistence contract.
- One always-visible `Launch Game` action exists. Only the local person who
  opened the manager may click it; AI, timers, automation, recovery, and other
  controls cannot activate it. Steam must be running. The upper status area,
  not the button, explains incomplete configuration and the non-EAC lane.
- The shell never offers to disable, lower, configure, bypass, patch, or stop
  EAC. Before launch it shows a requirement, not a verification claim. After
  launch it may show `Confirmed` only from the separately reviewed runtime
  signal; missing or ambiguous evidence renders `Runtime lane unconfirmed` and
  keeps Random inactive.

## Logging and Explanation Rules

- Keep the Layered Reasoning Log visible across launcher views.
- Tag entries at minimum as `[Host]`, `[Historical Random Start - Alpha 6 Method]`,
  `[Validation]`, `[Lock]`, `[Policy]`, `[Confirmation]`, `[Save]`, or
  `[Launch]` as appropriate.
- Log requested actions, safe summarized inputs, outcomes, cancellation,
  stale-result rejection, and confirmed writes.
- Do not log repaint/focus noise, raw policy JSON, Steam IDs, tokens, private
  player data, or unrelated paths.
- Keep visible entries bounded; preserve a separately bounded session model if
  needed for the current run.
- Persistent logging is off by default and uses the hardened host writer and
  consent/path rules, not the older blank-shell `WriteAllText` implementation.
- The Saved Settings Record is not the activity log.
- Explanatory tooltips may be indexed into the log only when each explanation
  is useful, uniquely routed, deduplicated, and does not drown action history.

## Accessibility and Display Requirements

- Set DPI-aware WinForms scaling and test at 100% and 150% minimum.
- Test the owner-observed widescreen/maximized expanded-log layout.
- Use text with color; never rely on green/red alone.
- Give every interactive and dynamic control meaningful accessible names and
  descriptions.
- Define deterministic tab order and sensible initial/focus-return behavior.
- Support keyboard selection and activation for save rows, policy choices,
  save, popup actions, log controls, and close.
- Respect Windows High Contrast and preserve visible keyboard focus.
- Do not clip long world/game names; use ellipsis plus accessible/full detail.
- Do not claim Narrator, keyboard, High Contrast, or DPI success without the
  required manual observation.

## Responsive Layout Guidance

The implementer may change the 620-pixel main width. The original dimension is
not a product requirement.

Required behavior:

- the task workspace remains usable at the documented minimum window size;
- opening the log does not compress the main task area below usability;
- maximizing does not turn the application into an uncontrolled empty canvas;
- the log may consume extra width, but the split ratio and maximum useful log
  width should be evidence-driven;
- long text wraps or ellipsizes intentionally;
- controls do not overlap at supported scaling; and
- collapsing the log restores a stable compact window without losing history.

The AI may choose a maximum content width, proportional splitter, two-stage
layout, resizable world list, or other native approach after recording why it
is better than blind pixel parity.

## Leveraged-Reasoning Authority

The implementing AI may, without asking about every small choice:

- refactor copied shell code into host, view, state, validation, and persistence
  helpers;
- choose native WinForms controls and exact spacing;
- widen or reflow the workspace for world names and accessibility;
- improve wording while preserving defined semantics;
- remove inherited controls that have no approved capability;
- adopt newer module-host infrastructure over older blank-shell code;
- create fixtures, test seams, development-only timing, and screenshot-capture
  helpers inside the staged project boundary; and
- make small reversible UX improvements supported by evidence and recorded in
  the project reasoning log.

The implementing AI must not independently:

- change Standard or Random semantics, or add a third start type;
- decide the unresolved launcher-only policy handoff;
- add writes beyond the approved persistence contract;
- create or install runtime gameplay code;
- edit the live `Mods` folder, game files, saves, worlds, or Harmony;
- import Wasteland payload or animal-specific behavior;
- add telemetry, networking, accounts, registry state, services, tasks, or
  hidden installation;
- promise EAC or clean-client compatibility;
- publish, push, upload, package, or distribute; or
- mark a test gate complete without evidence.

Escalate one owner decision at a time when a choice changes product semantics,
authority, persistence, runtime compatibility, release scope, or irreversible
behavior.

## Work Plan

### UX-0 — Freeze evidence and comparison fixtures

- Preserve hashes and line counts for all four compared sources.
- Record the owner screenshot observations and exact current-shell behavior.
- Capture compact and expanded reference screenshots in the future only when
  an approved local capture method and privacy review exist.
- Build a control inventory: label, location, capability, enabled state,
  accessible state, tooltip, log behavior, and disposition.

Deliverable: dated UI evidence note and control-disposition matrix.

### UX-1 — Define the state and capability model

- Convert every required launcher state in this manifest into a pure model.
- Define capability predicates for discovery, validation, editing, saving,
  launch, logging, and lock state.
- Ensure rendering cannot expose a handler the active state does not own.
- Resolve all Phase 0A persistence and policy-handoff prerequisites before
  enabling a write or launch capability.

Deliverable: state transition table, capability table, and negative cases.

### UX-2 — Uplift the shell infrastructure

- Preserve the current BAT as the human entry point.
- Replace older blank-shell infrastructure with reviewed host helpers where
  appropriate.
- Add DPI, high contrast, accessibility metadata, tab order, bounded log,
  hardened optional log writer, and responsive explicit validation.
- Keep all center behavior read-only and design-only during this step.

Deliverable: hardened shell parity proof with no policy/game writes.

### UX-3 — Build the read-only world index

- Discover save instances without parsing player identity.
- Show five recent instances by default.
- Add browse-one and load-all.
- Render saved policy state read-only if a valid index already exists; missing
  policy defaults visually to bypassed/Vanilla without writing it.
- Add game-running observation and read-only lock presentation without mutation.

Deliverable: read-only world-list proof and fixture matrix.

### UX-4 — Build the in-memory policy editor

- Add ACTIVE/BYPASSED and mode controls.
- Reveal only settings relevant to Random, with the documented always-editable
  safeguard-preference exception.
- Enforce UI range/allowlist checks without treating UI validation as security.
- Show saved versus in-memory values clearly.
- Do not persist during this step.

Deliverable: state-rendering and keyboard/accessibility proof; zero writes.

### UX-5 — Add approved local save workflow

Prerequisite: Phase 0A persistence contract and owner policy-handoff decision.

- Add summary and explicit confirmation.
- Perform atomic package-local policy save and verify the result.
- Create the separate Saved Settings Record.
- Show the detailed success/failure popup.
- Prove no pending/partial policy survives failed writes.

Deliverable: filesystem-boundary, atomicity, malformed-input, and rollback tests.

### UX-6 — Add direct-user launch handoff

Prerequisite: a proven runtime policy handoff.

- Keep `Launch Game` visible in every state and require direct local-user
  activation. Steam must already be running.
- Put readiness and non-EAC instructions in the upper status area. Incomplete
  configuration says `Configuration incomplete — mod not enabled`; it does not
  turn the launch button into a warning surface.
- Provide no automated activation, attachment, sign-in, or game-command path.
- Provide no EAC-changing or `fix automatically` control. On an active or
  unconfirmed lane, explain that the owner must exit normally and independently
  choose Steam's non-EAC option; never attempt a mid-session change.
- Recheck process state only to keep launcher mutation disabled while the game
  is running; do not control the process.

Deliverable: state-transition, no-process-start static scan, running-game lock,
and vanilla fail-closed proof.

### UX-7 — Accessibility, performance, and visual review

- Run automated accessibility-name, role, tab-order, scaling-path, and static
  boundary checks.
- Measure cold start, first render, save enumeration acknowledgement,
  validation, view updates, and log performance.
- Manually inspect keyboard-only use, Narrator, High Contrast, 100%/150% DPI,
  compact log, expanded log, maximized widescreen, long names, and five/all
  world lists.
- Compare against the owner screenshot, blank template, Wasteland reference,
  and hardened host without demanding pixel identity.

Deliverable: UX acceptance report with screenshots/evidence where approved.

## Required Test Matrix

At minimum, cover:

1. Launch with no valid game root; zero writes.
2. Valid root with no saves.
3. One save, five saves, more than five saves, and duplicate world/game names.
4. Browse-one without loading all.
5. Load-all with responsive acknowledgement and stable selection.
6. Newly discovered save defaults visually to BYPASSED/Vanilla without a write.
7. Standard and Random render only truthful controls; the two always-editable
   safeguard preferences visibly state that Standard ignores them.
8. Vanilla and bypassed paths communicate exact no-op behavior.
9. In-memory edits disappear without an explicit save and create no pending
   file.
10. Game starts while launcher is open; controls lock and unsaved changes are
    not persisted.
11. Process identity is unavailable; mutation fails closed.
12. Malformed, oversized, unknown-version, out-of-range, mismatched-world, and
    duplicate policy records.
13. Atomic save success, write denial, interruption, verification failure, and
    cleanup of approved temporary files.
14. Saved Settings Record correctness and separation from the activity log.
15. Persistent log off, consent cancelled, invalid path, valid local path,
    disabled after writing, and bounded runtime log.
16. Policy/save validation delayed while selection changes; stale results are
    discarded.
17. 100% and 150% DPI; High Contrast; keyboard-only; long names; Narrator.
18. Compact, expanded, resized, and maximized-log layouts.
19. No startup, navigation, selection, validation, or log-expansion writes.
20. No Wasteland, live Mods, game, world, save, Harmony, registry, network,
    service, scheduled-task, or publication side effects.

## Acceptance Criteria

The launcher-shell evolution is accepted only when:

- a returning Wasteland-tool user recognizes the Bit Wrecked family without
  being shown Wasteland-specific controls;
- a new user can identify the selected game, save, saved status, and spawn
  policy without reading project documentation;
- the likely next action is singular and truthful in every state;
- no control implies a capability that is absent;
- game-folder recognition cannot be mistaken for custom-runtime readiness;
- the five-recent, browse-one, and load-all workflows are distinct;
- ACTIVE/BYPASSED and policy meaning are communicated in text;
- the game-running lock is visible, local to the launcher, and leaves viewing
  available;
- logging, persistence, accessibility, and responsiveness meet the hardened
  host standard;
- layout remains usable on the owner-observed widescreen display and supported
  DPI settings;
- all writes are explicit, confirmed, bounded, atomic, verified, and within the
  approved package-local boundary; and
- no gameplay/runtime/release claim is made from launcher UX success alone.

## Open Decisions That Must Remain Visible

1. Should Random fail closed to Standard unless the game was started
   through the Bit Wrecked launcher?
2. How should `ACTIVE + Vanilla` be worded, given that Vanilla is an exact no-op
   while green currently means custom spawn policy?
3. What exact customer-facing name should replace internal `Phase 0A` language
   once the launcher reaches a testable build?
4. Whether `Open Mods Folder` ever belongs in this product after runtime
   installation ownership exists.

Ask only one owner yes/no question at a time when an answer becomes blocking.

## Stop Conditions

Stop and report if:

- achieving visual parity requires copying Wasteland payload or mutation logic;
- a world/policy control cannot map to one exact capability and state;
- layout changes make keyboard, DPI, High Contrast, or long-name use worse;
- discovery requires private player identity;
- responsiveness appears to require unbounded enumeration or speculative
  concurrency;
- persistent logging cannot meet the hardened local-path/consent boundary;
- a save or launch action would precede Phase 0A authorization;
- the UI would silently resolve an open product decision; or
- the work would touch the live game or become a public package.

## Exact Next Action

Create the UX-0 control inventory and UX-1 pure state/capability model as
documentation and tests while runtime work completes Phase 0A, Phase 1, and
Phase 1A. Continue Phase 1B and Phase 1C only through their separately reviewed
packets. Do not redesign the shell into a functional policy manager or enable
any policy write, launch, install, remove, or gameplay action before the native
authored-spawnpoint, nearest-trader, and Random-safeguard proofs receive their
explicit go decisions.
