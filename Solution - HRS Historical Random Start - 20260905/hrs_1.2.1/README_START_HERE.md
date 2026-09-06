# Historical Random Start - Start Here

Historical Random Start (HRS) restores a classic-style random starting location to
7 Days to Die while preserving normal progression after placement.

Current known-good release line: HRS 1.2.1.

This repository contains more than a runtime DLL. It includes:

- player-facing manager/UI behavior;
- runtime C# logic;
- policy and state handling;
- deployment/install/remove logic;
- deterministic build tooling;
- static validation;
- source and artifact manifests;
- QA evidence;
- release engineering;
- AI continuity and recovery documentation.

If you are a new human or AI:

DO NOT BEGIN BY SEARCHING THE REPOSITORY RANDOMLY.

Start with the map below.

## Read In This Order

1. `README_START_HERE.md`
   - orientation;
   - authority map;
   - safe starting point.

2. `HOW_THIS_WAS_MADE.md`
   - architecture;
   - why this small project behaves like a software stack;
   - development lessons.

3. `_planner_packet/LANDING_LIBRARY_INTEGRATION.md`
   - deep operational memory;
   - current authority;
   - integration history;
   - recovery information;
   - Version Conveyor rules;
   - "WE WALK FROM HERE" continuity contract.

4. Current re-entry handoff, if one exists
   - last known-good state;
   - exact unfinished gate;
   - exact next step.

5. Future `AGENTS.md` / Version Conveyor skill, when present
   - standing AI doctrine;
   - repeatable version-migration procedure.

Do not make the user or the next AI rediscover state that is already recorded.

## Authority Map

PLAYER EXPERIENCE / MANAGER
    -> `dev/ui/p0158.ps1`

RUNTIME BEHAVIOR
    -> `dev/src/runtime/main/`

DETERMINISTIC BUILD
    -> `dev/src/runtime/p0143.ps1`

STATIC RELEASE-SOURCE VERIFICATION
    -> `dev/src/runtime/main/p0228.ps1`

SOURCE MANIFEST
    -> `dev/src/runtime/main/j0219.json`

DEPLOYMENT LOGIC
    -> `dev/src/launcher/`

DEEP PROJECT MEMORY / RECOVERY / CONTINUITY
    -> `_planner_packet/LANDING_LIBRARY_INTEGRATION.md`

ARCHITECTURAL STORY
    -> `HOW_THIS_WAS_MADE.md`

LIVE QA / EVIDENCE
    -> `dev/evidence/`, `dev/out/`, and the flight recorder as applicable

Do not assume a file is authoritative merely because it has a formal-sounding name.

Resolve authority from the current manifest, current source, current Git state, and the latest
known-good evidence.

## Important State Separation

These states are deliberately different:

SOURCE

!=

BUILT CANDIDATE

!=

INSTALLED DEV CANDIDATE

!=

LIVE-TESTED CANDIDATE

!=

VERIFIED / PROMOTED ARTIFACT

!=

PUBLISHED RELEASE

Do not collapse these states merely to make validation pass.

A successful build does not mean successful live testing.

A successful live test does not automatically authorize promotion.

Promotion does not automatically authorize publication.

## Current 1.2.1 Architecture

HRS currently operates as a small integrated software stack.

Major layers include:

- UI / control plane;
- runtime / application logic;
- configuration / state;
- deployment;
- deterministic build;
- static validation;
- runtime game integration;
- QA / observability;
- release engineering.

The primary traditional stack component it does not have is a substantial database or storage
tier.

## Current Landing Model

The full certified landing library is preserved separately from the active production
selection.

Current production intent for 1.2.1:

- full certified NVG landing library preserved;
- active production selection is a curated balanced 80-point set;
- 16 points per biome;
- five biomes;
- uniform selection across the 80 active points.

Do not assume the full certified library and the active selectable pool are the same thing.

## Current Development Rule

Before modifying HRS:

1. identify the current Git checkpoint;
2. identify the last verified gate;
3. identify the authoritative files for the intended change;
4. preserve completed work;
5. continue forward from the current known-good state.

Do not revert newer working behavior because an older artifact, manifest, or document appears
more official.

Historical files may be evidence rather than present authority.

## Version Changes

Future version migrations should use the HRS Version Conveyor model.

Preferred pattern:

CURRENT KNOWN-GOOD VERSION
    ->
DEFINE TARGET VERSION INTENT
    ->
IDE EXECUTES SAFE MECHANICAL WORK
    ->
RECONCILE VERSION-COUPLED STATE
    ->
STATIC VALIDATION
    ->
DETERMINISTIC BUILD
    ->
CAPTURE CANDIDATE IDENTITY
    ->
DEV DEPLOYMENT
    ->
LIVE SMOKE
    ->
EVIDENCE
    ->
COMMIT
    ->
DELIBERATE PROMOTION / RELEASE DECISION

The IDE is the preferred high-throughput executor.

The user and planner own completion.

## Human Attention Is Expensive

The primary scarce resource for this project is the user's time and attention.

Machine operations may be numerous.

Human interruptions should be few.

Prefer:

- batching deterministic mechanical work;
- using existing authority instead of asking the user to restate it;
- returning at meaningful decision gates;
- leaving enough evidence that another AI can continue immediately.

Avoid:

- repeated repo rediscovery;
- asking for confirmation of routine mechanical work;
- making the user shuttle unchanged context between agents;
- turning token exhaustion into hours of human reconstruction.

## If The IDE Runs Out Of Tokens

This is expected.

The project does not reset.

The IDE should leave a re-entry handoff containing:

- what changed;
- current known-good state;
- wiring completed;
- validation performed;
- authoritative files;
- candidate identity;
- installed/tested identity;
- promotion status;
- known blockers;
- exact next step.

The next human/AI pair should resume from that state.

## WE WALK FROM HERE

"We walk from here" means:

THE USER AND PLANNER OWN COMPLETION FROM THE CURRENT STATE.

The IDE may stop.

A model session may end.

Tokens may run out.

Tools may change.

Progress does not reset.

When continuation is required:

1. recover the last verified gate;
2. preserve completed work;
3. load the authoritative context;
4. choose the next concrete action;
5. use the best available execution mechanism;
6. continue until the task is complete or a genuine external blocker exists.

WE OWN THE FINISH.

TOOLS ARE INTERCHANGEABLE.

PROGRESS IS NOT.

WE WALK FROM HERE.
