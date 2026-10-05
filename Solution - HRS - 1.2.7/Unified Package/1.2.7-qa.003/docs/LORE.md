# The Bit Wrecked story

The project began as Historical Random Start — Alpha 6 Method, exploring how
a fresh character could arrive somewhere surprising while the ordinary game
remained a protected baseline. The original reasoning called for controls that
felt simple and playful, with the serious integration checks kept underneath.
Those are recorded design intentions, not a claim that an old Alpha version's
exact implementation was reproduced.

The early native-placement experiment found that moving a player inside the
spawn event could conflict with the game's own startup. The successful onramp
was a later game-update callback: capture gameplay state, make one native
placement call, compare that state immediately, then verify the landing. That
became the foundation for the exact Game Name bridge, one fresh-character
start, durable completion evidence and later biome/trader layers.

The present public name, New Player Random Start, makes that purpose easier to
recognize. Bit Wrecked's supplied picture-only face remains the visual identity;
the manager uses a quiet light surface, small orange highlights and native
controls. Its larger contrast recipe is available in the graphics workbench
for release-card studies.

The original [build story](../history/HOW_THIS_WAS_MADE.md) closes with the
project's continuity rule:

> PRESERVE THE STATE.
> LEAVE THE TRAIL.
> WE WALK FROM HERE.

That trail is supplied here for everyone who wants to inspect, learn from or
extend the work. [The original reasoning](../history/origins/n0010.md),
[native-onramp paper](../history/origins/n0192.md) and
[history index](HISTORY.md) provide the full context. This page summarizes
existing project history; it adds no fictional game lore or untested feature.
