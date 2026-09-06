# Historical Random Start 1.2.1

Use `START.bat` to open the Historical Random Start manager.

Everything required for normal use starts through `START.bat`. Development
source, tests, evidence, history, generated output, and QA material remain under
the `dev` folder so the user-facing root stays simple.

Historical Random Start provides two primary start modes:

- Standard
- Random

Random uses the tested Historical Random Start placement flow while preserving
the normal game progression path.

An optional Random-start safeguard is also available:

`Protect the arrival biome hazard`

This option is intended only to protect the initial relocated character from the
arrival-biome hazard used in the tested start flow. It does not disable enemies,
weather, temperature, ordinary damage, or hazards in other biomes.

The release preserves one-shot relocation behavior:

- relocation occurs only for the matching new game
- the start is not rerolled on normal reload
- later save loads do not repeat the initial relocation transaction
- normal progression remains available after arrival

The opening trader path follows the relocated player rather than forcing the
default Pine Forest route.

For normal use, start here:

`START.bat`

Additional technical, QA, security, and development records are retained in the
repository for transparency and verification.
