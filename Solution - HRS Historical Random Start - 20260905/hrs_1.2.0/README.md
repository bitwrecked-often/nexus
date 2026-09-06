# Historical Random Start 1.2.0 — development lane

Use `START.bat` to open the functional manager.

Everything required for normal use starts through `START.bat`. Development
source, tests, evidence, history, generated output, and the legacy preview are
kept under the collapsed `dev` folder so they do not clutter the user-facing
root.

This lane begins from the certified `1.1.0` baseline and is intentionally
marked development-only. Its planned scope is promotion of the 171-location
controlled survivor set, same-biome/zone nearest-trader routing with a bounded
fail-closed native-objective path, and independently testable arrival-biome
danger suppression.

Until those features are implemented and verified, runtime behavior remains
the inherited `1.1.0` production baseline: one game-owned random draw between
NG01 and NG02. Copying QA evidence into this lane does not make full-catalog
points player-selectable.

The lane preserves one-shot relocation, safe-landing verification, optional
protection from the initial snow-biome hazard, and nearest opening-trader
routing that follows the relocated player instead of forcing the Pine Forest
trader.

Optional Random-start safeguard: check `Protect the arrival biome hazard` to
suppress the snow hazard for the relocated NG01 character. This snow-first QA
proof does not disable enemies, weather, temperature, ordinary damage, or
hazards in other biomes. Leave it unchecked for fully vanilla biome hazards.

The opening-trader feature was proven end to end in `HRS_TRADER_006`: relocation,
normal tutorial completion, nearest-trader selection, native objective update,
and one-time route completion all succeeded without fallback.

Inherited release notes: [1.1.0 release manifest](dev/docs/n0236.md).

Nexus base-build evidence and remaining promotion gates:
[Nexus evidence baseline](dev/docs/n0240.md).

1.2.0 scope, opening artifact identity, and implementation order:
[1.2.0 development-lane manifest](dev/docs/n0241.md).

Five-game arrival-biome protection and same-zone trader matrix:
[biome/trader integration manifest](dev/docs/n0242.md).

Chronological feature history, failed approaches, framework adaptations, and
the reasons each implementation method evolved:
[development story and framework-adaptation record](dev/docs/n0243.md).

Inherited QA and DEV handoff: [1.1.0 DEV and QA status](dev/docs/n0237.md).

Release identity, acceptance cases, and evidence capture:
[QA cycle records](dev/qa/README.md).

Engineering history: [0.0.8.1 to 0.1.0 development log](dev/docs/n0233.md).

Spawn-pool scouting and new-AI resumption:
[AI context handoff](dev/scouting/AI_CONTEXT_HANDOFF.md).

QA-only deterministic full-POI placement-health screening:
[carousel contract and commands](dev/docs/n0238.md).
