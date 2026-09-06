# Historical Random Start development-cycle doctrine

Status: governing development and test-selection method  
Effective: 2026-08-30

## Central rule

Ask the system before changing the system.

For Historical Random Start, "the system" means the evidence available from
the source, package identity, release contracts, automated checks, runtime
logs, and direct observation in the game. Discussion produces hypotheses and
test designs; evidence decides what becomes a change.

This rule prevents an attractive idea, a plausible coordinate, or a successful
DEV shortcut from being mistaken for release proof.

## Decision dialogue

Each meaningful development proposal is challenged in this order:

1. **What do we like about it?** Identify its value, leverage, simplicity, and
   what it makes cheaper or easier to test.
2. **What do we not like about it?** Identify hidden cost, delayed integration,
   false confidence, scaling limits, and brittle assumptions.
3. **What is the next smallest useful move?** Choose the cheapest observation
   or experiment that can change the decision.
4. **What can the system answer directly?** Prefer inspection, logs, a focused
   test, or an in-game observation over speculation.
5. **What does that evidence prove—and not prove?** State the boundary before
   acting on it.
6. **What is the correct work order now?** Scout, implement, integrate,
   certify, and release only as far as the evidence supports.

This is a repeatable engineering review, not a requirement that every thought
become a meeting. A short recorded exchange is enough when the risk is small.

## How the current cycle reached this rule

1. QA found that the loaded DLL identity did not agree with the package notes,
   even though the intended DLL functionality was present.
2. Repository and package inspection separated a packaging-identification
   defect from a gameplay defect.
3. Version `1.0.1` synchronized the package, manager pins, metadata, runtime-log
   identity, notes, and artifact fingerprints while preserving `1.0.0` as the
   failed-candidate record.
4. The changelog, QA contract, evidence capture, and rollback process were made
   repeatable so later teams can see what should work, why, and against which
   exact bytes.
5. The release gate then asked the source and contract another question. It
   found that `1.0.1` remains fixed to NG01, so it cannot certify the requested
   random NG01/NG02 behavior.
6. The next discussion compared going deeper on two points with going wider to
   more candidate points.
7. The useful part of width was cheap discovery: many locations can be viewed
   quickly without performing the full trader and quest flow at every one.
8. The risks were delayed integration, oversized batches, broad fixes for
   unrelated problems, and treating a coordinate catalog as a release-ready
   spawn pool.
9. The next smallest useful move became direct in-game location scouting at
   street level—not another gameplay change.
10. That sequence exposed the general method: ask the system, record its
    answer, and change only what the answer supports.

## Evidence classes

### Discovery evidence

Discovery answers whether a candidate deserves implementation work. Use a
disposable scouting save with creative/developer movement, flight, god mode, or
invulnerability as necessary.

Every such record must say:

> DEV scouting only — flight/invulnerability enabled; not live spawn or
> survival proof.

Discovery evidence may accept, adjust, or reject a candidate. It cannot prove
the real relocation path, safe landing, survival safety, trader selection,
starter-quest routing, persistence, or release readiness.

### Implementation evidence

Implementation evidence comes from source inspection, static checks, harnesses,
and bounded DEV runs. A deterministic DEV selector may force one candidate so
failures are reproducible. It does not prove that the release randomizer chooses
correctly or fairly.

### Release evidence

Release evidence runs against one exact immutable candidate under its canonical
release and QA contracts. It proves only the named cases, environment, and
artifact digests recorded for that run. The process is defined in
`qa_cycle/README.md` and the routing rules in
`HRS_DEV_QA_NEXUS_WORKFLOW.md`.

## Spawn-candidate state model

Every candidate has exactly one current state:

```text
Catalogued -> Scouted -> Accepted -> Certified -> Released
                        |          |
                        +-> Adjust +-> Rejected
```

- **Catalogued:** proposed coordinates; not yet observed.
- **Scouted:** observed in the game and documented.
- **Accepted:** suitable enough to justify implementation and focused testing.
- **Adjust:** promising, but its anchor or conditions must change.
- **Rejected:** unsuitable; retain the reason to prevent rediscovery.
- **Certified:** passed the required deterministic and integration checks.
- **Released:** included in the exact QA-approved release bytes.

An accepted coordinate is not certified, and a certified source change is not
released until QA approves the packaged bytes.

## Street-level scouting contract

Candidate starts model cities from the player's ordinary street level. For each
candidate:

- assign a stable point ID;
- record world/map identity and X/Y/Z as observed;
- treat X/Z as the authored anchor;
- derive final Y at runtime from terrain or surface height plus the standing
  offset—never apply one global hard-coded Y to all points;
- capture a player-view screenshot at the proposed landing location;
- capture a map screenshot showing its wider placement;
- note biome, city or district, street/surface type, clearance, nearby water,
  roofs, POIs, cliffs, traffic obstacles, and immediate threats;
- identify the expected nearest trader as a hypothesis for later verification;
- turn flight off and land before the street-level image when practical; and
- record `Accept`, `Adjust`, or `Reject` with a short reason.

Invulnerability can hide environmental damage, debuffs, or enemy pressure.
Manual travel to a location proves visibility and geometry only; it does not
prove that the mod can warp a fresh character there safely.

## Breadth and depth

Use a funnel rather than choosing only breadth or only depth:

```text
Scout a small batch widely
-> group findings by mechanism
-> fix only bounded common mechanisms
-> run an integration checkpoint
-> continue scouting
-> certify the finalists deeply
```

Scout three or four candidates per batch. This is large enough to compare
locations and small enough to diagnose a regression. Do not spend the full
trader, starter-quest, persistence, reload, and rollback cost on weak candidates.
Do not defer all integration until a large coordinate list is complete.

The expected nearest trader may be calculated or inspected during discovery.
The live trader choice and starter-quest route must still be tested on
representative candidates during integration and on the final release pool
during certification.

## Grouping and fixing findings

Group failures by mechanism, not merely by location:

- landing height, surface detection, or clearance;
- water, roof, POI, cliff, or collision placement;
- biome exposure, temperature, or debuff behavior;
- trader selection and distance comparison;
- starter-quest routing;
- save, reload, and one-shot persistence; and
- packaging, identity, install, and rollback.

Fix a shared mechanism only when multiple observations support the same cause.
Do not introduce a global biome/debuff exemption or broad landing workaround to
rescue one weak point. Prefer adjusting or rejecting that point when the defect
is local.

## Ordered next work

1. Create or use a disposable scouting save.
2. Enable only the DEV movement and protection needed to inspect locations.
3. Visit proposed street-level anchors and collect the scouting record.
4. Mark each candidate `Accept`, `Adjust`, or `Reject`.
5. Complete one batch of three or four before expanding the list.
6. Add deterministic DEV selection for accepted candidates in a new version
   lane; do not rewrite the preserved `1.0.1` baseline.
7. Run fast fresh-character warp and safe-landing checks for each accepted
   candidate.
8. Group failures, diagnose their causes, and make only bounded fixes.
9. Run a representative trader and starter-quest integration checkpoint before
   starting the next batch.
10. Repeat the scouting and checkpoint cycle until the candidate pool is
    sufficient.
11. Build a new immutable candidate containing only certified points.
12. Run full release QA for random selection, every certified landing class,
    trader and quest behavior, persistence/reload, package identity, install,
    evidence export, and rollback.
13. Promote only the exact bytes QA approved.

`1.0.1` remains the fixed-NG01 packaging-identification repair and historical
baseline. Two-point randomness or a wider spawn pool belongs to a later lane.

Current implementation update: `1.1.0` is the later lane for two-point NG01/
NG02 randomness. The wider six-certified-points-per-zone pool remains a
separate evidence-gated expansion.

## Cycle guardrails

- Define the question before collecting evidence.
- Record both the favorable case and the objection.
- Prefer the smallest experiment capable of disproving the assumption.
- Label DEV cheats, forced selectors, and manual movement in every observation.
- Preserve rejected candidates and failed packages with their reasons.
- Keep discovery, implementation, and release claims separate.
- Recheck integrated behavior after each small batch.
- Never promote labels, notes, or rebuilt equivalents in place of tested bytes.
- When evidence conflicts with the plan, change the plan.
