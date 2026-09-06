# Historical Random Start Phase 1A

## Scientific reasoning and methods for atomic semantic-preservation testing

Version: 0.0.1 working paper  
Status: first successful runtime case observed; isolated replication and
persistence reload pending  
Scope: 7 Days to Die V3.1.0 (b14), Windows x64, local single-player,
Navezgane, launched through the game's standard non-EAC option

## Abstract

This working paper describes the method used to test a narrowly scoped player
spawn-relocation mechanism without asserting that a single successful trial
proves general correctness. The central problem was causal: an early design
captured a comprehensive digest of player gameplay state before placement but
did not compare it until later update callbacks. Ordinary health, stamina,
food, water, progression, item, and buff updates could therefore change the
digest independently of placement. The resulting `RELOC_SEMANTIC_CHANGED`
observation could not identify placement as the cause.

The corrected method retains the comprehensive digest but moves the comparison
boundary. It captures state immediately before one native placement call,
synchronizes the player's existing chunk observer, and captures the same state
again in the same deferred game-update callback. Equality is required before a
later bounded verifier checks containing-chunk readiness, native spawn safety,
and final position. On the first exact-target trial, the runtime emitted
`RELOC_PLACEMENT_DEFERRED`, `RELOC_PLACEMENT_CALLED`,
`RELOC_SEMANTIC_UNCHANGED`, and `RELOC_COMPLETED` in order, and the owner
visually confirmed the relocated spawn.

This result is evidence of feasibility for the pinned environment. It is not
yet evidence of multiplayer safety, cross-version compatibility, universal
semantic preservation, statistical reliability, or persistence after reload.

The work also produced a systems-engineering lesson for the next phase. The
appropriate unit of completion is not another isolated feature or a more
polished launcher; it is one narrow vertical slice connecting informed player
intent to the proven runtime mechanism and back to truthful evidence. The
first slice therefore uses one manually entered exact new-game name, an
explicit Standard/Random choice, an independently validated policy, the fixed
genuinely-new-player first-arrival gate, one atomic Random relocation, a
durable per-player/game completion marker, and a sanitized categorical result.
Standard is the zero-action control. Trader routing, biome safeguards,
automatic discovery, multiplayer, expanded placement, protection, and
rooftops are later layers. This ordering makes the foundational claim directly
testable and prevents unfinished extensions from obscuring whether the basic
product works end to end.

## Plain-language explanation: finding the native onramp

The game already contains the basic machinery needed to choose spawn points,
place a player, and load the surrounding world. Think of that machinery as a
set of native rails. The missing piece was a safe onramp.

If a mod moves the player while the game is still building the new character,
the normal spawn process can move the player back. Waiting an arbitrary number
of seconds is not reliable either: different computers load at different
speeds, and ordinary player values continue changing while the mod waits.

Our method does not guess the right moment. The game tells us. First,
`PlayerSpawnedInWorld` signals that a New Game spawn event is underway. We
inspect the exact game, world, player, and one-shot marker, ask the game's own
spawn list for one candidate, remember that candidate, and then get out of the
way. We do not move the player inside that spawn event.

After the spawn handler has returned, the game calls `GameUpdate`. That later
callback is the onramp. Inside one callback, the mod:

1. takes a compact fingerprint of the player's important gameplay state;
2. uses the game's normal position method to place the player once;
3. moves the player's existing chunk observer to the same location so the game
   knows which part of the world to load;
4. immediately takes the same state fingerprint again; and
5. stops unless the two fingerprints match.

We call this a **single-callback atomic observation window**. “Atomic” does not
mean the player or the whole game is frozen. It means the mod does not return to
another game-update cycle between the before-and-after measurements. Ordinary
health, stamina, hunger, buff, inventory, quest, or progression updates do not
get an extra later frame in which to create a false difference.

Matching fingerprints do not automatically declare success. The mod then gives
the destination a short, bounded period to settle. It verifies that the
containing chunk loaded, the game still considers the point safe, and the
player actually remained at the intended position. Only then does it mark the
one allowed attempt Completed. A failure remains consumed instead of rolling
again and repeatedly moving the player.

So the breakthrough is not a hidden developer switch or a new teleport. It is
the careful reuse of native rails in the order the game itself announces:

```text
game begins New Game spawn
  -> mod validates and remembers one native candidate
  -> vanilla spawn handler finishes
  -> game supplies the next update callback
  -> one uninterrupted place + observer-sync + state-check window
  -> bounded destination verification
  -> persistent one-shot completion
```

In short: **the game provides the rails and signals the onramp; the mod enters
once, proves the move preserved reviewed player state, verifies the landing,
and never uses developer mode or a console teleport.**

## 1. Methodological classification

The work is best classified as an **iterative engineering case study with
requirement-traceable verification and an instrumented single-case runtime
demonstration**.

It is not described as a randomized controlled experiment:

- there is one owner-operated machine and one pinned game build;
- candidate selection is native and random, but test conditions are not
  randomly assigned to experimental groups;
- the current dataset contains one successful exact-target runtime trial;
- no sampling model, effect-size estimate, confidence interval, or population
  inference is justified; and
- several earlier trials were diagnostic iterations of different artifacts,
  not interchangeable repetitions of one frozen treatment.

This classification follows the ACM SIGSOFT principle that empirical software
engineering reports should name an appropriate method, explain data collection
and analysis, link conclusions to explicit evidence, and disclose major
limitations. The paper uses NASA-style verification traceability to connect
each claim to a requirement, method, environment, outcome, anomaly, and
corrective action. These sources guide the structure; this project does not
claim formal ACM review, NASA certification, NIST conformance, or SLSA level.

## 2. Research questions and bounded claims

### RQ1 — Guarded execution

Can the artifact restrict one relocation attempt to the exact local,
single-player, EAC-disabled, New Game target while rejecting other targets and
lifecycle events before placement?

### RQ2 — Placement feasibility

Can one native candidate be selected and one native player-position operation
be called after spawn finalization without teleport, respawn, console command,
Harmony patching, explicit chunk request, or observer creation?

### RQ3 — Synchronous semantic preservation

Does the reviewed comprehensive gameplay-state digest remain equal across the
synchronous boundary consisting of player placement and existing-observer
synchronization?

### RQ4 — Bounded completion

After atomic semantic equality, does the same attempt reach containing-chunk,
native safety, and position acceptance before writing the Completed marker?

### RQ5 — Persistence and non-repetition

After a normal exit and read-only reload, does Completed remain present and
prevent selection and placement from running again?

RQ1 through RQ4 have one successful exact-target observation in the pinned
environment. RQ5 remains pending. Broader noninterference across all unrelated
saves was not established by this mixed session because an older, differently
named save was opened first.

## 3. Hypotheses and decision rules

For the atomic semantic test, let:

- `S` be the reviewed set of gameplay-semantic fields;
- `D(S)` be their deterministic in-memory digest;
- `P` be the one player `SetPosition(candidate, true)` call; and
- `O` be the one existing-observer `SetPosition(candidate)` call.

The operational null and alternative are:

- **H0:** `D(S_before) != D(S_after(P,O))`; the synchronous intervention changed
  at least one represented semantic field, so the attempt must not complete.
- **H1:** `D(S_before) == D(S_after(P,O))`; no represented field changed across
  the synchronous intervention boundary, so later spatial verification may
  begin.

Acceptance requires all of the following, in order:

1. exact environment, target, lifecycle, authority, locality, and marker gates;
2. one native candidate-selection call;
3. one deferred placement after the spawn callback returns;
4. one pre-intervention digest capture;
5. one player placement and one existing-observer synchronization;
6. one immediate post-intervention digest capture in the same callback;
7. digest equality;
8. containing-chunk readiness within the monotonic deadline;
9. one native safety check and bounded position agreement; and
10. successful Completed-marker write/readback.

Any missing gate, unexpected call count, digest mismatch, timeout, unsafe
position, position mismatch, or marker failure is terminal. The probe does not
reroll, retry placement, clear Reserved, or silently convert a failed attempt
into a pass.

## 4. What “atomic” means here

“Atomic” is used in a deliberately narrow observational sense: both digest
captures and the two reviewed position operations occur without returning from
the same game-update callback. This removes **intervening later update
callbacks** from the comparison interval.

It does not mean:

- a CPU atomic instruction;
- a database transaction;
- a lock-free or thread-safety guarantee;
- suspension of all engine subsystems;
- proof that `SetPosition` has no unrepresented synchronous side effects; or
- proof that no other code can run inside methods called by the intervention.

The causal advantage is therefore specific. The earlier comparison was:

`digest before -> placement -> return -> ordinary ticking -> later digest`

The corrected comparison is:

`digest before -> placement -> observer sync -> immediate digest -> return`

Unity documents `Update` as a per-frame callback and warns that execution order
between different objects is not generally guaranteed unless explicitly
documented or configured. That reinforces why equality across later callbacks
was a confounded measure. The stronger basis in this case is the installed
game's inspected call paths plus the same-callback implementation; the Unity
documentation supplies general lifecycle context rather than proof of this
game's private internals.

### 4.1 The lifecycle onramp

The native capabilities were visible individually, but they did not constitute
a ready-made random-start feature. The usable onramp is the handoff between two
events:

```text
PlayerSpawnedInWorld(NewGame)
  -> validate exact lane
  -> persist Reserved
  -> select one native candidate
  -> retain world GUID + entity ID + candidate
  -> return without placement

first later GameUpdate
  -> revalidate lane, world, entity, observer
  -> perform atomic placement-semantic window
  -> begin bounded spatial verification
```

Placement inside the spawn handler was vulnerable to later vanilla spawn
finalization. Arbitrary delay was not a sufficient answer: it moved the
intervention away from vanilla finalization but widened the interval in which
player state and spatial context could drift. The onramp is therefore not “wait
some number of milliseconds.” It is “let the spawn callback return, enter the
first guarded update, and complete the causal measurement before returning.”

This is **tick-ordered, not tick-perfect**. The method does not guess a delay,
target a frame number, or depend on frame rate. The game supplies both lifecycle
signals: `PlayerSpawnedInWorld` announces the spawn event, and a later
`GameUpdate` supplies the post-callback onramp. The mod depends on their order,
not on how many milliseconds separate them. The atomic work then completes
inside that one update invocation before control returns to the player loop.

### 4.2 Exact atomic instruction sequence

The current implementation executes these statements in order inside the
placement branch of `OnGameUpdate`:

```text
semanticBefore = Capture(player)
player.SetPosition(candidate, true)
observer.SetPosition(candidate)
log(RELOC_PLACEMENT_CALLED)
semanticAfterPlacement = Capture(player)
if digest differs: clear pending, log changed, return
log(RELOC_SEMANTIC_UNCHANGED)
BeginPlacement(realtimeSinceStartup + 30 seconds)
return
```

The categorical placement log lies inside the measured interval. It is designed
not to read or mutate represented player state, but its presence is still an
instrumentation effect and is disclosed as such. The proof is not that literally
nothing executes between captures; it is that no later game-update callback is
allowed into the interval and the only intended player/spatial mutations are
the two reviewed native calls.

`BeginPlacement` changes only the private pending object: it stores the
monotonic deadline and flips `PlacementCalled`. It deliberately occurs after
semantic equality, preventing the later verifier from treating a semantically
failed placement as an active settling attempt.

### 4.3 State machine and persistence transaction

The persistent marker and volatile pending object serve different purposes:

```text
Persistent CVar                    Volatile pending
Absent (0)                         null
   | reserve + readback
Reserved (1) --------------------> {worldGuid, entityId, candidate}
   |                                 | atomic placement accepted
   |                                 v
   |                               {deadline, placementCalled, ticks}
   |                                 | spatial verifier accepted
   | complete + readback              v
Completed (2)                      null
```

Any failure after reservation clears `pending` but leaves Reserved. This is a
deliberate fail-closed transaction: a crash or ambiguous failure cannot silently
restore eligibility and produce a different random candidate on reload. The
marker has four interpreted states—Absent, Reserved, Completed, and Invalid.
Only Absent is eligible. Reserved, Completed, and malformed nonzero values are
all consumed.

The marker is written with the game-owned `EntityBuffs.AddCustomVar` path and
immediately read back. The artifact does not call `SetCustomVarNetwork` or
remove the marker. This Phase 1A result proves the local single-player path
only; it does not infer multiplayer replication semantics.

### 4.4 Why nearby approaches fail

| Approach | Failure mode |
| --- | --- |
| Place inside spawn callback | Vanilla finalization can overwrite the position. |
| Sleep for an arbitrary duration | Couples correctness to machine timing and permits state/context drift. |
| Compare semantics on later updates | Ticking stats, buffs, progression, and items can create false attribution. |
| Teleport or console command | Bypasses the reviewed native spawn path and introduces dev/command semantics. |
| Request or create chunks/observers | Expands mutation scope and can diverge from native ownership/lifecycle. |
| Reroll after failure | Converts ambiguity into repeated mutation and selection bias. |
| Mark Completed immediately after SetPosition | Confuses a call with verified spatial acceptance and persistence. |
| Log full state or coordinates | Improves diagnosis by sacrificing privacy and evidence minimization. |

The breakthrough is the composition of four constraints: post-spawn deferral,
same-callback semantic bracketing, existing-observer synchronization, and a
separate bounded read-only spatial verifier. Removing any one changes the claim.

### 4.5 Laboratory probe versus releasable architecture

The successful binary is intentionally a private proof instrument. Its
`TargetGuard` pins the installed assembly MVID, canonical local game root,
canonical local save root, `Navezgane`, the exact disposable game name, EAC off,
local-server authority, and single-player mode. These hard-coded values prevent
the mutation probe from wandering outside the authorized laboratory lane.

They are not the intended Nexus-facing configuration model. A distributable
artifact must replace owner-specific paths and the disposable target name with
a portable, validated policy handoff and an explicit compatibility matrix. It
must preserve the proven invariants: exact build gating, New Game-only
eligibility, reservation before selection, one native candidate, deferred
placement, same-callback semantic comparison, existing-observer ownership,
bounded verification, and persistent one-shot completion. The current DLL is
evidence for the mechanism, not a release candidate.

### 4.6 Official Fun Pimps modding context and permission boundary

The public record supports a careful statement that **this work uses a
developer-recognized modding lane**, not the broader statement that The Fun
Pimps has inspected or specifically approved this mod.

The strongest technical evidence is the Fun Pimps staff-authored
[V3.0 Dead Hot Summer release note](https://community.thefunpimps.com/threads/v3-0-dead-hot-summer-dev-diary.46879/).
Its modding section tells code-mod authors that they need reference only the
game's core `Assembly-CSharp.dll`, explains that the code is passed through a
code-publicizer process, and warns that overrides may need to be public. That
is direct, contemporary evidence that compiling a mod against the managed game
assembly and using its publicized code surface is an anticipated form of
modding. Phase 1A stays inside that technical lane: it ships its own assembly,
subscribes to exposed mod lifecycle events, and calls game-owned managed
methods. It does not patch or redistribute `Assembly-CSharp.dll`.

The institutional evidence points the same way. The Fun Pimps operates an
[official mod resource library](https://community.thefunpimps.com/resources/categories/7-days-to-die-mods.1/)
with categories that include gameplay mods, administration mods, tools, and
overhauls. Its [Official Modding Forum Policy](https://community.thefunpimps.com/threads/tfp-official-modding-forum-policy.4189/)
establishes rules for creators and users, permits free mod distribution on its
site subject to those rules, and requires authors to respect licenses,
permissions, attribution, and redistribution conditions. These are not the
actions of a publisher prohibiting all modification; they constitute an
officially administered mod ecosystem.

There is also a useful but lower-authority interpretation. In a 2021
[EULA-and-modding answer](https://community.thefunpimps.com/threads/help-with-understanding-the-eula-and-modding.24041/),
a Fun Pimps community moderator explained that a modified version is acceptable
when it is offered free, clearly identified as a mod, not made standalone, and
still requires an authorized copy of the base game. This is moderator guidance
on the official forum, not a new license, legal opinion, or project-specific
permission. The controlling EULA and current platform rules still apply.

#### What those sources establish

They establish that The Fun Pimps recognizes code mods, provides a managed-code
integration surface, hosts mods, and publishes conditions for distributing
them. They therefore support describing our technique as **ordinary managed
code modding applied with an unusually strict lifecycle and verification
method**. The exposed events and publicized managed methods are the onramp; the
atomic observation window is our safe way of combining them.

#### What those sources do not establish

None of the cited Fun Pimps materials names this project, reviews the
`SetPosition` call sequence, guarantees achievement behavior, approves every
possible use of publicized methods, or grants immunity from future API and
policy changes. “The Fun Pimps supports a managed-code modding lane” is
supported. “The Fun Pimps officially approved this exact atomic-relocation
implementation” would be unsupported unless they provide written confirmation.

Accordingly, a public release should:

1. remain free, non-standalone, and dependent on a licensed installation of
   *7 Days to Die*;
2. identify itself prominently as an unofficial mod and never imply Fun Pimps
   endorsement;
3. distribute only the project's original files and permitted dependencies,
   never the game's managed assemblies or extracted game assets;
4. disclose that this code mod requires launching without EAC, while neither
   bypassing nor tampering with EAC;
5. replace all laboratory paths and target identifiers with portable,
   validated release configuration;
6. preserve the source-to-binary audit trail, compatibility gate, fail-closed
   behavior, and rollback package; and
7. recheck the current EULA, Fun Pimps rules, and hosting-platform rules at the
   time of release.

This is a technical and documentary conclusion, not legal advice. If the
release needs the stronger sentence that The Fun Pimps has approved this exact
implementation, the appropriate evidence is direct written confirmation from
The Fun Pimps rather than inference from general mod support.

### 4.7 Launcher-to-runtime bridge

The successful Phase 1A probe establishes the runtime mechanism, while the
existing `0.0.7-preview` launcher establishes the player-facing policy
language. The production bridge between them should be intentionally narrow:
one versioned world-policy record travels from launcher to runtime, and one
minimal categorical outcome travels from runtime back to the launcher.

The normative behavior cases are maintained once in the `Canonical Policy
Eligibility Grid` in `2026-08-13_historical_random_start_plan.md`. This paper
explains the architecture and scientific reasoning; it does not duplicate that
grid. Implementations and experiments should cite its `PEG-*` case IDs.

```text
Player selects Standard or Random while the game is closed
                         |
                         v
Launcher validates the game, world, build, and requested policy
                         |
                         v
Launcher atomically saves one world-scoped policy record
                         |
                         v
Runtime loads and validates that record at the approved lifecycle boundary
             +-----------+-----------+
             |                       |
             v                       v
       Standard/BYPASSED       Random/ACTIVE
       vanilla remains         one proven atomic
       untouched               relocation attempt
             |                       |
             +-----------+-----------+
                         v
Runtime records a minimal categorical result
                         |
                         v
Launcher displays Bypassed, Completed, Failed, or Incompatible
```

This is a control-plane/data-plane separation. The launcher is the **control
plane**: it obtains informed player intent, validates context, and persists
policy. The runtime DLL is the **data plane**: it alone observes game lifecycle
events, calls the native selector, performs placement, and verifies the result.
The result channel is an evidence plane: it reports what happened without
granting the launcher authority over live game state.

| Component | Owns | Must not own |
| --- | --- | --- |
| Launcher GUI | World selection, Standard/Random intent, explanation, closed-game validation, policy save, and result display | Player placement, live callbacks, game-memory mutation, console commands, or direct invocation of relocation |
| Policy record | Versioned player intent and exact target/build binding | Runtime objects, coordinates, handles, executable instructions, or implicit defaults |
| Runtime DLL | Compatibility gate, lifecycle eligibility, one-shot reservation, native selection, atomic placement, verification, and categorical result | Dialogs, player prompting, speculative policy, rerolls, or GUI state |
| Result record/channel | Minimal state, reason category, artifact/build identity, and policy revision correlation | Raw save contents, coordinates, player identity, or a command path back into the game |

#### Policy contract

The release policy record should be a small, schema-validated data object. At
minimum it needs:

- schema and policy-format version;
- policy revision or nonce;
- compatible game-build identity;
- unambiguous world/save target identity;
- `Standard` or `Random` start type;
- only those optional safeguards whose runtime capabilities have separately
  passed their own gates; and
- an integrity digest covering the canonical record.

`Standard` is an explicit policy, not a missing record. It maps to
`BYPASSED`, causing no custom placement. `Random` maps to `ACTIVE`, making the
save eligible for the proven one-shot lifecycle path. A missing, malformed,
ambiguous, stale, unsupported, or build-mismatched record must fail closed; it
must never be interpreted as permission to relocate.

The launcher should write the policy only while the game is closed, using a
same-directory staged write, validation, atomic replacement, and immediate
readback. The preceding valid generation should remain available for bounded
rollback. This extends the two-version roll-forward/roll-back discipline used
during the laboratory work to the player-facing policy boundary.

#### Runtime consumption

The runtime must treat the policy as immutable input for a session. It should
validate the schema, build, exact target, revision, and mode before registering
an eligible attempt. It must not watch a mutable GUI object, accept mid-session
policy changes, or infer authorization from the mere presence of a file.

For `Standard`, the runtime records or exposes `BYPASSED` and returns without
selecting a candidate. For `Random`, it enters the already proven state
machine: eligibility, reservation, native candidate selection, deferred
placement, same-callback semantic comparison, bounded spatial verification,
and persistent completion. The GUI never calls `SetPosition`; the DLL never
asks the player a question.

#### Result contract

The current laboratory proof persists its authoritative one-shot marker inside
the game-managed player state. A production launcher must not casually parse or
rewrite save internals to obtain that marker. The release design therefore
needs a separately reviewed, read-only result projection—for example, a
runtime-produced sanitized status record or a bounded categorical log—from
which the launcher can display:

- `BYPASSED`: Standard was selected; vanilla behavior was left untouched;
- `RESERVED`: a Random attempt was claimed but has not completed;
- `COMPLETED`: placement and verification passed for the correlated policy;
- `FAILED`: a sanitized terminal reason was recorded with no retry; or
- `INCOMPATIBLE`: the build, target, schema, or runtime lane did not match.

The physical result-channel format is not yet authorized by the Phase 1A
mechanism proof. It must be specified, threat-modeled, and tested before the
launcher displays runtime outcomes as authoritative. Until then, the existing
categorical runtime evidence remains the source of truth.

#### Current implementation status

This bridge is the release architecture now made possible by the successful
mechanic; it is not yet implemented. The `0.0.7-preview` Apply action creates
only an in-memory preview snapshot, and the laboratory DLL still uses a pinned
private target rather than a portable policy handoff. Preserving those truthful
limitations prevents a polished frontend from being mistaken for a completed
integration.

The first implementation slice should support only `Standard/BYPASSED` and
`Random/ACTIVE`. Biome-hazard safeguards and starter-trader rerouting must stay
unwired or explicitly unavailable until their independent runtime mechanisms,
semantic protections, and persistence behavior pass the same evidence gates.

## 5. Variables and operational measurements

### Independent variable

The intervention is the reviewed pair `(P,O)`: one player-position call at the
single native candidate followed by one synchronization of the already-owned
observer to that candidate.

### Primary dependent variables

- categorical runtime reason sequence;
- equality of the two 64-bit semantic digests;
- completion-marker write/readback;
- bounded final-position agreement; and
- target presence and aggregate identity after normal exit.

### Protected outcomes

- game-managed tree aggregate;
- foreign-mod tree aggregate;
- foreign-save tree aggregate, excluding only the exact Phase 1A target;
- absence of forbidden compiled call sites; and
- absence of a second selection or placement on reload.

### Sanitization

Published runtime evidence contains fixed categorical reasons, artifact hashes,
file counts, byte counts, and aggregate digests. It excludes player identity,
world GUID, candidate coordinates, exact private semantic values, and raw save
contents. This permits outcome auditing without converting a private test into
an identity or location disclosure.

### 5.1 Digest construction in code

The digest is a 64-bit FNV-1a-style accumulator with offset basis
`14695981039346656037` and prime `1099511628211`. It is not a canonical FNV
serialization: integers and floats are incorporated bytewise, while strings
incorporate UTF-16 code units after a bytewise integer length. The project
compiles with overflow checking enabled, so the three digest `Add` overloads use
explicit `unchecked` blocks to preserve modulo-2^64 wrapping multiplication.
Compiled IL was separately checked for ordinary `mul` rather than
overflow-throwing multiplication.

The representation is structural, not a concatenated display string:

- integers contribute four shifted bytes;
- floats contribute the exact bytes returned by `BitConverter.GetBytes`;
- strings contribute a length and then each UTF-16 code unit;
- null collections contribute `-1`, while present collections contribute their
  lengths;
- inventory slots contribute their indexes, preventing position-insensitive
  item equivalence;
- item modifications and cosmetics are recursively represented to the bounded
  reviewed depth;
- quests retain journal order; and
- active buffs are copied and ordinally sorted by name before hashing, removing
  collection-enumeration order as an accidental source of inequality.

Represented fields are player health/game stage; stat health, stamina, food,
and water; progression level, next-level requirement, deficit, skill points,
and XP gain; toolbelt/backpack item structure and selected item properties;
quest identity/state/phase/objective summary; and active buff identity,
multiplier, and flags. Equality means equality of this representation. It does
not cover fields outside the reviewed inventory and cannot logically eliminate
the theoretical possibility of a 64-bit collision.

### 5.2 Native candidate and observer semantics

Candidate selection is exactly one call to the game-owned
`GetRandomSpawnPosition(world, null, 0, 0)`. The probe rejects undefined,
native-invalid, and out-of-bounds results but does not replace native selection
with arbitrary coordinate generation. Candidate identity is retained in
memory, never logged, and never recomputed.

The observer is obtained from `player.ChunkObserver`. A null observer is a
terminal failure. The probe calls `SetPosition` on that existing observer after
player placement because player and observer must agree on the spatial region
being observed. It never constructs, registers, removes, or explicitly requests
an observer. This keeps observer ownership with the game.

### 5.3 Later spatial acceptance

Semantic equality answers a synchronous state question; it does not prove the
destination is ready or that the player stayed there. The later verifier waits
at least two update callbacks, then checks only the candidate's containing
chunk. If absent, it waits read-only until a 30-second deadline derived from
`Time.realtimeSinceStartup`. This monotonic engine clock avoids wall-clock
changes and frame-count assumptions.

Once the containing chunk exists, the verifier calls
`CanPlayersSpawnAtPos(candidate, false)` exactly once, then requires Euclidean
distance from current player position to candidate to be at most `0.25` Unity
units. Only after those checks does it write/read-back Completed. Chunk timeout,
unsafe position, position mismatch, context loss, and completion failure have
distinct categorical outcomes and no retry.

### 5.4 Sanitized failure taxonomy

The logger accepts only 23 predefined reasons and emits at most 24 entries per
process. Unknown reasons collapse to `RELOC_INTERNAL_FAILURE`. Categories are:

- compatibility/target rejection;
- entity, marker, reservation, list, and candidate failures;
- observer and placement failures;
- semantic changed/unchanged;
- verification context, chunk timeout, safety, and position failures; and
- completion or internal failure.

No reason contains a coordinate, identity, semantic value, candidate value, or
digest. The categorical sequence is sufficient to identify the state-machine
edge without publishing private state.

## 6. Layered verification design

| Layer | Question | Method | Current result |
| --- | --- | --- | --- |
| Pure contract | Does the state machine fail closed for modeled inputs? | 25 deterministic cases | PASS |
| Source contract | Are required/forbidden calls and ordering present? | Static token, order, and call-count checks | PASS |
| Semantic harness | Do protected-tree comparison rules detect missing or changed evidence? | 7 deterministic cases | PASS |
| Build provenance | Does reviewed source produce a stable binary? | Two clean pinned Roslyn builds and SHA-256 comparison | PASS |
| Binary conformance | Does compiled IL retain reviewed call counts and exclusions? | Mono.Cecil method-level inspection | PASS |
| Malware screening | Is the exact staged/installed artifact flagged locally? | Microsoft Defender custom scan | PASS, not a security proof |
| Runtime guards | Does the old no-`A` target fail before placement? | Categorical live observation | PASS: `RELOC_TARGET_REJECTED` |
| Runtime intervention | Does the exact new target complete the reviewed sequence? | Instrumented owner-observed case | PASS once |
| Exit durability | Does the completed target persist after normal exit? | Aggregate-only snapshot | PASS for target presence |
| Reload idempotence | Does Completed prevent a second action? | Read-only reload | PENDING |
| Strict foreign-save preservation | Did every unrelated save remain byte-identical? | Baseline/post aggregate | NOT ESTABLISHED in mixed session |

This separation prevents one kind of evidence from impersonating another. A
deterministic build proves binary repeatability for recorded inputs, not runtime
correctness. Static call counts prove compiled structure, not player-visible
behavior. A visible relocation proves an outcome occurred, not that every
semantic invariant held; that claim depends on the instrumented digest and its
defined coverage.

### 6.1 Compiled-call conformance

Mono.Cecil inspection of both byte-identical atomic artifacts established:

- two `SemanticSnapshot.Capture` calls, both in `OnGameUpdate`;
- one `Entity.SetPosition` call;
- one existing `ChunkObserver.SetPosition` call;
- one `PendingPlacement.BeginPlacement(float)` call;
- one native random-selection call;
- one containing-chunk lookup;
- one native spawn-safety call;
- two `EntityBuffs.AddCustomVar` calls; and
- zero teleport, respawn, direct network-CVar mutation, explicit chunk request,
  observer add/remove, and spawn-handler mutation calls.

The binary evidence matters because source intent can diverge from the emitted
artifact through stale builds, conditional compilation, unexpected inputs, or
installation mistakes. Hash equality linked the inspected artifact to both
external builds, the staged payload, and the live DLL.

## 7. Provenance and chain of custody

The source aggregate is
`CDCDFA4022DB15FE5B50E2251E681F84C34E51962DBE3C27E73FDDBDD023CDEF`.
The two clean builds produced the same 15,360-byte DLL:

`632208686E0C5A2156DC27B32FD3579F80A0AC9E60171B262E1147AEEE8EFCE2`

The installed two-file payload aggregate is:

`4F5F5189E3F89CC259C39233FB5762529BE9CB178C3CE9508E94056E4641EAE6`

The compiler host, compiler, seven explicit references, source inputs,
switches, output inventory, MVID, DLL hash, payload hash, backup identity, and
live identity were recorded. The compiler used deterministic output, and the
binary was rebuilt twice in separate clean directories. This follows the
reproducible-build principle that source, tools, environment, procedure, and
comparison protocol must be identified. It is local provenance, not a signed
independent attestation: the current process does not satisfy SLSA's stronger
requirements for build-platform-generated, authenticated provenance.

## 8. Trial chronology and anomaly handling

The chronology is part of the result, not editorial debris:

1. The exact prior failed Phase 1A target was backed up and reset.
2. A stale Continue-menu entry remained visible even though its underlying
   reset directory was absent.
3. Selecting Continue produced one native
   `XUiC_ContinueGame.startGameCo` `NullReferenceException`. The probe emitted
   only `RELOC_READY`; no world loaded.
4. In the corrected client session, the older existing
   `HRS_Phase1_Test_001` target (no `A`) was opened first. It emitted
   `RELOC_TARGET_REJECTED`; no relocation ran.
5. A genuinely new Navezgane game named `HRS_Phase1A_Test_001` was created.
6. The exact target emitted the successful four-reason sequence, and the owner
   visually confirmed relocation.
7. The client exited normally. The completed target persisted with 77 files,
   20,815,822 bytes, and aggregate
   `8593ABDF5D4256F7C5EEFFB2D2E54C52AD27E2EDCCC88BFB8F13D5F642E2EB67`.
8. Game-managed and foreign-mod aggregates matched baseline. The broad
   foreign-save aggregate did not match because the no-`A` target was also
   opened/saved and root New Game metadata changed during the mixed session.

The wrong-target rejection is a useful negative control. The same mixed session
is also a protocol deviation. Both facts must be reported simultaneously; the
negative control does not erase the contaminated broad save comparison.

## 9. Causal reasoning

The initial semantic failure admitted at least two explanations:

- `E1`: placement synchronously changed a represented semantic value; or
- `E2`: ordinary engine updates changed a represented value before the later
  capture.

Installed-code analysis identified plausible `E2` paths in stat, buff, and
progression ticking. Moving the second measurement into the same callback
blocked later-update callbacks from entering the measurement interval while
holding digest coverage, candidate selection, placement call, observer call,
and later verifier constant. The subsequent `RELOC_SEMANTIC_UNCHANGED` result
is therefore evidence against `E1` for that exact execution and represented
field set.

It does not prove that `E1` is impossible in all executions. Nor does it prove
that unrepresented state is unchanged. The causal claim is:

> In one exact pinned execution, no field represented by the reviewed digest
> changed synchronously across the observed placement-plus-observer boundary.

That sentence is intentionally narrower than “relocation changes nothing.”

## 10. Threats to validity

### Construct validity

The digest is a proxy for gameplay-semantic preservation. It is comprehensive
relative to the reviewed field inventory, but an omitted field would be
invisible. Hash equality also assumes the digest implementation correctly and
deterministically represents each field. Collision is theoretically possible.

### Internal validity

Same-callback bracketing removes later callback drift but does not freeze all
threads or prove the absence of synchronous hidden side effects. The existing
observer synchronization is part of the intervention, so the result cannot
separate effects of player placement from effects of observer movement.

### External validity

The successful case is limited to V3.1.0 (b14), the pinned assemblies, Windows
x64, one machine, local single-player, Navezgane, EAC disabled, and one native
candidate. It cannot be generalized to dedicated servers, multiplayer,
different worlds, future builds, EAC-enabled execution, or arbitrary mod sets.

### Reliability and conclusion validity

One success establishes feasibility, not a failure rate. Earlier diagnostic
trials used different source artifacts and cannot be pooled as replications.
No inferential statistics are appropriate. Repetition with the frozen artifact
and predeclared stopping rules is required before making reliability claims.

### Observer and instrumentation effects

The probe changes control flow, computes a digest, and writes categorical logs.
Those operations may affect timing even if they do not intentionally change
gameplay state. A later production implementation should minimize and measure
this overhead.

### Protocol contamination

The no-`A` world was saved in the same session before the exact target. This
invalidates a strict whole-foreign-save before/after claim for that session.
The limitation is preserved rather than repaired retrospectively.

### Reproducibility limits

The proprietary game binaries cannot be redistributed by this project. Hashes
and procedures support verification by an authorized owner of the same build,
but do not make the full environment publicly self-contained. Provenance is
locally recorded and unsigned.

## 11. Replication protocol for the next evidence tier

The next isolated replication should be specified before launch:

1. Freeze the current source, DLL, payload, test scripts, and decision rules by
   cryptographic digest.
2. Back up and reset only `HRS_Phase1A_Test_001` after exact identity checks.
3. Confirm the no-`A` target will not be opened during the trial.
4. Capture a fresh aggregate baseline after Steam is authenticated and before
   launch.
5. Launch once through the pinned no-EAC path with a dedicated log.
6. Create only the exact Phase 1A New Game target.
7. Perform no intentional gameplay input after spawn.
8. Require the predeclared successful categorical sequence with no failure,
   mismatch, or internal-error reason.
9. Exit normally and capture the post snapshot.
10. Compare all protected aggregates and preserve discrepancies without
    reclassification.
11. Reload the completed target read-only and require a consumed/completed
    reason with zero candidate selection and zero placement.
12. Repeat as new independently labeled trials if estimating reliability;
    report every attempt and do not discard failures as setup noise unless the
    exclusion rule was written before execution.

For a stronger whitepaper, replicate the frozen artifact across several fresh
native candidates and, where legally and operationally possible, an independent
machine with the same pinned build. Cross-version and multiplayer studies must
be separate protocols with separate claims.

## 12. Whitepaper reporting rules

The final paper should distinguish:

- **observed** facts from inferred mechanisms;
- **verification** that specified requirements were implemented from
  **validation** that the player-facing result serves its intended use;
- feasibility from reliability;
- source, binary, runtime, and persistence evidence;
- planned trials from completed trials;
- clean replications from diagnostic iterations; and
- pass, fail, rejected, aborted, contaminated, and pending outcomes.

Every figure or result table should be regenerable from a named sanitized
artifact or script. Every binary claim should cite its cryptographic identity.
Every runtime claim should name the target, build lane, lifecycle, evidence
source, and acceptance rule. Deviations and anomalous trials belong in the main
method/results narrative, not only in footnotes.

## 13. Industry and research guidance consulted

- [The Fun Pimps, V3.0 Dead Hot Summer release notes — Modding](https://community.thefunpimps.com/threads/v3-0-dead-hot-summer-dev-diary.46879/):
  current staff guidance for managed-code mods, the core
  `Assembly-CSharp.dll` reference, and the code-publicizer compatibility
  surface.
- [The Fun Pimps, official 7 Days to Die mod resource library](https://community.thefunpimps.com/resources/categories/7-days-to-die-mods.1/):
  publisher-operated distribution infrastructure across gameplay, tool,
  administration, overhaul, and other mod categories.
- [The Fun Pimps, Official Modding Forum Policy](https://community.thefunpimps.com/threads/tfp-official-modding-forum-policy.4189/):
  creator/user rules covering free distribution, permissions, licenses,
  attribution, terms of use, and redistribution. This is a forum policy and
  should be read together with the current EULA.
- [The Fun Pimps forum, moderator answer on the EULA and modding](https://community.thefunpimps.com/threads/help-with-understanding-the-eula-and-modding.24041/):
  practical guidance that mods should be free, clearly identified as mods,
  non-standalone, and dependent on an authorized base-game copy; classified
  here as moderator guidance rather than project-specific approval or legal
  advice.
- [ACM SIGSOFT Empirical Standards for Software Engineering](https://www2.sigsoft.org/EmpiricalStandards/)
  and its [method-specific standards](https://www2.sigsoft.org/EmpiricalStandards/docs/standards):
  method identification, explicit data collection/analysis, validity criteria,
  evidence-linked conclusions, artifact packages, and limitation disclosure.
- [NASA Systems Engineering Handbook — Product Verification](https://www.nasa.gov/reference/5-3-product-verification/)
  and [V&V appendices](https://www.nasa.gov/reference/system-engineering-handbook-appendix/):
  requirement traceability, verification methods, test-article pedigree,
  environment/procedure recording, anomalies, corrective actions, assumptions,
  and lessons learned.
- [NIST SP 800-218, Secure Software Development Framework](https://csrc.nist.gov/pubs/sp/800/218/final):
  integrating executable-code testing, manual verification, and recorded secure
  development practices into the lifecycle.
- [Reproducible Builds planning guidance](https://reproducible-builds.org/docs/plans/):
  define the build environment, rebuild under a documented protocol, and use
  byte or hash comparison.
- [Microsoft deterministic build documentation](https://learn.microsoft.com/en-us/visualstudio/msbuild/common-msbuild-project-properties?view=visualstudio):
  identical compiler output for identical inputs via deterministic compilation.
- [SLSA build requirements](https://slsa.dev/spec/v1.2/build-requirements):
  provenance completeness, authenticity, accuracy, and build isolation; used
  here to state clearly what the local unsigned process does not yet provide.
- [Unity 2022.3 event-function execution order](https://docs.unity3d.com/ja/2022.3/Manual/ExecutionOrder.html):
  lifecycle context for per-frame updates and the limits of unspecified
  cross-object callback ordering.

## 14. Current conclusion

The breakthrough is scientifically meaningful because the correction changed
the measurement design, not merely the pass condition. It removed a known
temporal confound while retaining the semantic fields and fail-closed outcome.
The successful exact-target observation supports a narrow feasibility claim for
the pinned environment. The disciplined next step is not to broaden the claim;
it is to perform the pending persistence reload and then a clean, preregistered,
isolated replication of the frozen artifact.

## 15. Engineering lessons learned and product-integration method

### 15.1 Complete a vertical claim, not a collection of parts

The project reached a point where both ends existed separately: a truthful
player-facing preview and a successful guarded runtime mechanism. Neither end
alone is a product. A polished preview without a policy/runtime handoff is a
demonstration, while a private hard-coded probe without informed player intent
is a laboratory instrument. The next meaningful increment must connect them:

```text
manual exact game name
  -> Standard or Random intent
  -> validated immutable policy
  -> exact runtime target and first-arrival gate
  -> zero-action Standard or one atomic Random placement
  -> durable no-repeat marker
  -> sanitized categorical evidence
```

This chain is small enough to reason about and large enough to validate the
actual player promise. Completion requires evidence across every boundary,
not separate claims that the GUI opens and the DLL can move a player.

### 15.2 Standard is an active negative control

Standard is not merely a default label or a missing policy. It is an explicit
control case that must traverse policy validation and eligibility while
calling neither candidate selection nor placement. It tests whether the
bridge can carry informed intent without accidentally granting runtime
authority. Comparing Standard and Random also distinguishes bridge side
effects from the relocation intervention.

### 15.3 Exactly-once behavior must be state, not hope

"Only the first login" is too ambiguous for implementation. The invariant is:
act only on a genuinely new player's first eligible arrival in the exact game,
at most once for that player/game. Absent, Reserved, Completed, and Invalid
states turn that sentence into deterministic behavior. Reservation precedes
selection; a consumed attempt does not reroll; Completed survives reload; and
ordinary load, reconnect, death, respawn, duplicate callback, and continued
play are measured no-action paths.

The marker is therefore part of the mechanic, not bookkeeping added after a
successful warp. A relocation that works once but cannot prove non-repetition
is not complete.

### 15.4 Manual exact-name entry is deliberate scope control

Requiring the player to type the new-game name in the launcher and then use
that name in the game is temporarily less convenient than automatic discovery,
but it removes several unrelated problems from the first bridge: save
enumeration, ambiguous identity, existing-world mutation, concurrent indexing,
and broad target authority. Exact matching creates a simple positive case and
strong negative controls. Discovery can be added later without changing the
first-arrival invariant or the Standard/Random contract.

### 15.5 Fail closed while preserving the native path

The safest fallback is not an improvised repair. Missing, malformed, stale,
incompatible, or mismatched policy produces no reservation, selection, or
placement. Uncertainty after reservation produces a bounded consumed failure,
not another random roll. In both cases the system avoids repeated movement and
retains the game's ordinary behavior wherever the intervention has not begun.

This makes failure observable without making failure destructive. It also lets
the implementation AI continue diagnosing rejected cases in staged source and
tests instead of weakening guards to obtain a passing demonstration.

### 15.6 Separate planes reduce accidental authority

The launcher owns explanation, consent, exact target entry, and policy. The
runtime owns lifecycle facts, native selection, placement, verification, and
the authoritative marker. The result channel reports bounded categories but
does not become a command channel. This separation prevents the GUI from
calling live gameplay operations and prevents the DLL from inventing player
intent.

The boundary is also testable: the launcher can be exercised with pure schema
fixtures; runtime guards can be exercised without UI; and the end-to-end test
can correlate one policy revision with one runtime outcome.

### 15.7 Later features should consume the core, not redefine it

Trader continuity, biome safeguards, discovered-game targeting, multiplayer,
expanded coordinates, distance agency, drops, protection, and rooftops are
valuable, but each introduces a new authority or failure surface. Connecting
them before the basic bridge works would make failures harder to localize and
could turn optional ambitions into blockers for the foundational mechanic.

The recommended layering rule is monotonic: a later capability may consume
the stable core contract, but it may not weaken exactly-once eligibility,
change Standard's zero-action meaning, broaden target scope silently, or
invalidate a proven lower layer. If a later feature fails its gate, the last
proven lower layer remains usable.

### 15.8 Evidence and rollback are completion work

The project benefited from treating hashes, exact target names, categorical
logs, negative controls, backups, and recovery artifacts as part of the
mechanism-development loop. That discipline exposed the no-`A`/with-`A` target
mistake, preserved failed iterations, and limited the successful claim to what
the run actually demonstrated.

The same rule applies to the bridge. Its evidence packet must connect player
choice, policy bytes, runtime decision, marker transition, placement result,
reload behavior, and rollback. Documentation written afterward from memory is
not an adequate substitute.

### 15.9 Autonomy works best with a sharp completion boundary

A higher-level implementation AI can productively run source, build, test,
diagnosis, correction, retest, evidence, and documentation to completion when
the allowed paths, target, rollback, and acceptance gate are explicit.
Compile errors, failed fixtures, rejected inputs, and recoverable design flaws
are engineering work—not automatic reasons to stop.

Autonomy still has a real boundary. Human authentication or game operation,
unverified destructive targets, changed proprietary APIs, credentials/private
data, external publication, and irreconcilable product requirements require a
handoff. At those boundaries the AI should prepare the exact human action and
expected evidence, then resume the same vertical slice rather than broadening
scope.

### 15.10 Current synthesis

The most durable project spine is now:

> A player explicitly targets one new game, chooses Standard or Random, and a
> genuinely new player receives either the native start or one guarded atomic
> alternative start, exactly once, with a truthful recoverable record.

That is a coherent product increment before any later feature exists. It is
also a stable experimental platform: every future layer can be evaluated by
what new authority it adds, what new evidence it requires, and whether the
core invariant remains unchanged.

### 15.11 Capability and permission are separate engineering facts

The manager or implementation agent may be technically capable of inspecting
state, preparing a policy, validating a recovery point, or constructing a
launch handoff. None of those capabilities grants permission to perform the
next consequential action. Permission comes from an explicit product rule and,
where required, an immediate human gesture.

This distinction is especially important at the computer boundary. `Launch
Game` is visible and useful, but only the local person who opened the manager
may activate it. AI, timers, recovery paths, default focus, synthetic input,
and chained success callbacks cannot convert preparation into launch. Likewise,
the runtime may read an approved policy but cannot invent intent, and the
manager may explain the non-EAC requirement but cannot alter anti-cheat.

The result is agentic in engineering and conservative in operation: an agent
can continue through source, tests, evidence, and documentation, while the
user's machine and account remain under visible human control.

### 15.12 Capsule ownership makes reversibility measurable

The capsule analogy provides a finite answer to “what may this solution
change?” Ownership derives from a manifest entry and approved destination, not
proximity, naming resemblance, or assumed necessity. This converts removal and
recovery from broad cleanup guesses into verifiable inventory operations.

`Remove from Game` removes only validated Historical Random Start artifacts
deployed into the game. It does not uninstall an application from Windows,
remove shared Harmony/runtime layers, edit saves or worlds, or touch other
mods. The portable BAT/manager, notes, history, and audit evidence remain
because they are the management plane, not installed game payload. Deleting
that portable tooling is a separate manual user decision.

This wording is more than interface polish. It prevents an implementation
agent from widening a failed removal until the evidence appears clean. Unknown
or drifted objects remain in place and become a bounded review result.

### 15.13 Recovery history is evidence, not a promise every state works

Every attempt belongs in local history because failed, blocked, cancelled, and
superseded operations explain how the current state arose. Restore authority is
narrower. A snapshot is selectable only if it was known-good when captured and
passes immediate revalidation against the current capsule, policy schema, game
association, ownership inventory, and compatibility lane.

Recovery retains Default plus the five latest snapshot attempts. Failed or
stale attempts remain visible with a plain reason correlated to the diagnostic
log, but Restore is unavailable. `Restore to Default` always remains present
and disables custom policy without modifying saves, worlds, or game progress.

### 15.14 A quiet game process is the simplest safe mutation boundary

When a game client or server instance is running, the manager performs no
capsule-changing action. Read-only status, history, notes, and comparisons may
remain available. Changes are neither queued nor applied later. Steam activity
is not the mutation boundary; Steam is required only for the user launch.

This avoids live side-chain configuration, hidden deferred work, and crash-time
cleanup machinery. If the manager crashes, nothing acts. There is no watchdog,
service, tray process, remote-management analogue, or automatic repair loop.

### 15.15 Explanation is part of the safety contract

Minimalism does not mean withholding consequences. Essential state, blockers,
and the next useful action remain visible in the upper status area. Brief,
state-aware tooltips explain unfamiliar controls by outcome, and the same
meaning is available to keyboard and screen-reader users.

The project borrows sound principles from established interface guidance—clear
hierarchy, progressive disclosure, direct language, and accessibility—without
imitating another platform's appearance. Bit Wrecked retains its own taste and
adapts those principles to a portable Windows game-management workflow.

One vocabulary feeds button labels, status, tooltips, confirmations, notes,
history, and logs. Correlation IDs bind the plain-language account to technical
evidence so the user never has to translate several names for the same event.

### 15.16 Durable manifests reduce dependence on model memory

A large context window helps an agent reason across GUI, policy, runtime,
evidence, and recovery, but context size is not project memory. The routed
manifest, current-awareness document, decision grid, evidence packets, and
copy/state contracts are the durable memory. They let a fresh frontier model
and capable operator reconstruct intent without trusting an expiring chat.

The agent does not need unlimited autonomy or perfect recall. It needs enough
reasoning capacity to follow the manifest, test claims, preserve the user
demarcation, and continue until the documented completion gate is satisfied.
