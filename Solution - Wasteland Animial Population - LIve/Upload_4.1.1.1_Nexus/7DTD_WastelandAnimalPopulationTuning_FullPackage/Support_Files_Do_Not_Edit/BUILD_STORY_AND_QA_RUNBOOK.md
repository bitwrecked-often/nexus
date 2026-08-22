# 7DTD Wasteland Animal Population Tuning - Build Story And QA Runbook

Copyright (C) 2026 Bit Wrecked
SPDX-License-Identifier: GPL-3.0-or-later

This file explains how the mod and helper app came together: brick by brick, bug by bug. It is written for maintainers, curious users, and upload-site reviewers who want to understand what the package does and why it exists.

## Original Problem

The Wasteland in 7 Days to Die has a strong identity: danger, pressure, ugly surprises, and the occasional "why is there a bear here" moment.

The goal was not to erase that identity. The goal was control:

- make Wasteland animals calmer for permadeath or low-stress worlds
- keep vanilla values available as a baseline
- make selected animals rarer without flattening the whole biome
- make the Wasteland denser for challenge worlds
- provide an absurd ceiling for content creators, server events, and people with brave hardware
- keep the mod XML-only
- keep the installer understandable to normal Windows users

## Brick 1: Find The Live Game Shape

The first rule was to follow the current live XML, not old memory.

The current 7DTD 3.0-era Wasteland animal groups use compact `e/n/p` XML:

```text
EnemyAnimalsWasteland
EnemyAnimalsWastelandNight
```

Baseline values are read from the live game XML:

```text
EnemyAnimalsWasteland:
- animalSnake: 10
- animalZombieVulture: 5
- animalZombieDog: 15
- animalZombieBear: 5
- animalDireWolf: 2
- none: 50

EnemyAnimalsWastelandNight:
- animalDireWolf: 4
- animalZombieBear: 10
- none: 60
```

The Wasteland open-world spawn routes are:

```text
EnemyAnimalsWasteland:
- maxcount: 1
- respawndelay: 0.9,1.575,1.215,0.9,0.585,0.315

EnemyAnimalsWastelandNight:
- maxcount: 1
- respawndelay: 0.6,1.05,0.81,0.6,0.39,0.21
```

Those strings matter. The decimals are preserved exactly at Default.

## Brick 2: Start With XML-Only Safety

The modlet was built around plain XML patch files:

```text
ModInfo.xml
Config/entitygroups.xml
Config/spawning.xml
```

No compiled payload was added:

- no EXE
- no DLL
- no Harmony patch
- no hidden updater
- no network downloader
- no game executable patcher

The full package includes Windows helper scripts, but the game-facing mod remains XML-only.

## Brick 3: Make The Slider Mean Something Clear

The tuning levels are:

```text
Absent
Sparse
Default
Dense
Absurd
```

The middle position is `Default`.

Default means "match the live game baseline." It does not mean "no animals."
Default still writes generated mod XML. Removing the mod deletes that XML and
returns the affected routes to the game's effective default XML configuration.

The generated level matrix was QA checked in a sandbox:

```text
Absent:
- animal weights: 0
- day none: 999
- extra routes: 0

Sparse:
- snake 5, vulture 2.5, dog 7.5, bear day 2.5, wolf day 1
- wolf night 2, bear night 5
- day none: 75
- extra routes: 0

Default:
- snake 10, vulture 5, dog 15, bear day 5, wolf day 2
- wolf night 4, bear night 10
- day none: 50
- extra routes: 0

Dense:
- snake 30, vulture 15, dog 45, bear day 15, wolf day 6
- wolf night 12, bear night 30
- day none: 12.5
- extra routes: 7

Absurd:
- snake 80, vulture 40, dog 120, bear day 40, wolf day 16
- wolf night 32, bear night 80
- day none: 0
- extra routes: 21
```

## Brick 4: Discover That Bigger Numbers Alone Were Not Enough

Raising animal weights helped, but the Wasteland still had a practical ceiling because the original biome route count stayed small.

Dense and Absurd therefore gained extra selected-animal route handles with `bw_` IDs. These are appended only for high-pressure settings:

```text
Dense: 1 extra route per selected animal time bucket
Absurd: 3 extra routes per selected animal time bucket
```

This made high settings visibly different in game instead of only mathematically different in XML.

## Brick 4.5: Retune Sparse After Field Testing

Field testing found that Remove Mod returned Wasteland animal behavior to normal and that an installed Default mod matched the live baseline values.

The previous Sparse curve used a quarter-strength animal factor:

```text
0.25x
```

That made low-base animals such as dire wolves and zombie bears feel closer to "almost gone" than "less common." Sparse was retuned to:

```text
animal weights: 0.50x
route delay: 1.75x
none weight: 1.50x
```

Dense and Absurd were intentionally left unchanged because the top end felt useful for high-pressure testing and content-creator chaos.

## Brick 5: Add Scan And Verification

The tool gained `Scan Values` and post-install verification so the user can see what is installed.

Verification checks:

- selected animal weights
- Wasteland `none` weights
- Wasteland route `maxcount`
- Wasteland route `respawndelay`
- appended pressure routes
- selected-animal route count
- Brutal Science animal cap state when enabled

This was added because screenshots and gut feel are useful, but XML proof is better.

## Brick 6: Add The Brutal Science Cap

Dense and Absurd can ask the game to create more animal pressure than the default server/world cap allows.

The tool now has:

```text
Brutal Science: lift global animal cap
```

When enabled, it sets:

```text
serverconfig.xml MaxSpawnedAnimals = 999
```

Before changing that file, the tool creates a timestamped backup beside `serverconfig.xml`.

`Restore Global Limit Only` replaces `serverconfig.xml` with the newest matching
Bit Wrecked animal-cap backup and verifies `MaxSpawnedAnimals` afterward.

This is intentionally a dangerous option. It can stress hardware, servers, saves, and judgment. It is useful for testing and extreme play. It should not be treated as a normal default.

## Brick 7: Fix The Launcher/Testing Environment

During live testing, the game launcher failed with a Windows elevation-related launch error.

The test environment was corrected by removing a Windows compatibility `RUNASADMIN` flag that caused the launcher to fail. Graphics Jobs was also checked because launcher settings can affect repeatable testing.

This was not part of the mod package; it was part of making the local test machine behave.

## Brick 8: Capture The Proof

Timed screenshot bursts were used to build the public screenshot story.

Useful proof shots included:

```text
Default UI: centered baseline
Scan/Verify: installed XML proof
Absurd verification: 21 extra selected-animal route handles
Absurd gameplay: bears, fire, vulture swarm, death/respawn evidence
```

The strongest Absurd evidence came from the 2-second capture burst after raising pressure and testing in live Wasteland gameplay.

## Bug: Default Respawn Delay Precision

QA found that Default respawn delays were being passed through a decimal formatter.

That changed exact live values:

```text
1.575 -> 1.58
1.215 -> 1.22
0.585 -> 0.58
```

Even tiny timing changes can matter when game spawn systems combine route timing, player state, entity caps, biome rules, and other runtime math.

Fix:

```text
Default density now returns the live respawndelay string unchanged.
```

The validation harness now fails if packaged Default XML drifts from the live game baseline.

## Bug: One-Upload Package Reality

The original packaging plan produced:

```text
FullPackage.zip
VortexModlet.zip
```

That is technically nice, but some mod sites allow only one file.

Decision:

```text
Upload the full package when only one package is allowed.
```

The full package contains everything:

- GUI tuning tool
- helper scripts
- docs
- license files
- XML modlet folder

Manual and mod-manager users can still install only:

```text
BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

into:

```text
7 Days To Die/Mods
```

## Bug: Possible Antivirus Or Vortex Warning

The full package includes `.bat` and `.ps1` helper scripts.

Some upload scanners flag scripts heuristically because scripts can copy, remove, or edit files. In this package, those scripts are readable helper scripts used to:

- launch the GUI tool
- copy the XML modlet folder
- remove the XML modlet folder
- scan installed values
- optionally back up and edit `serverconfig.xml` for Brutal Science
- optionally restore `serverconfig.xml` from the newest Bit Wrecked animal-cap backup

The README explains this so users and site reviewers can make an informed decision.

## Current QA Runbook

Before a public upload:

1. Run the GUI smoke test:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\_game_dev_ai_tracking\solutions\7dtd_wasteland_animal_population_tuning_files\Support_Files_Do_Not_Edit\7DTD_WastelandAnimalPopulationTuning_Tool.ps1" -SmokeTest
```

2. Run the package validator:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\_game_dev_ai_tracking\solutions\7dtd_wasteland_animal_population_tuning_files\Support_Files_Do_Not_Edit\validate_and_package.ps1" -RebuildZip
```

3. Confirm the validator reports:

```text
PASS: 7DTD 3.0 Wasteland Animal Population Tuning modlet is valid for this live install.
```

4. Upload:

```text
Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_FullPackage.zip
```

## Current Known Non-Blockers

The remaining tracked `TBD` items are screenshot/story slots, not code blockers:

- All Animals / Lesser
- All Animals / More
- Dire Wolf / Lesser
- Zombie Bear / Lesser
- Mixed Tuning

Those are for a better public gallery. The current app logic and package validation are not blocked by them.

## Design Principle

This tool should let the user choose the Wasteland they want:

```text
peaceful enough to breathe
vanilla enough to compare
sharp enough to respect
absurd enough to become a story
```

The app should be honest about the consequences, especially when the user asks it to do dangerous science.

## Appendix A: Issues, Methods, And Guardrails

This appendix is the nerd layer. It explains the meaningful problems we hit, how we reasoned through them, and what guardrails were added so the same class of problem is harder to repeat.

No source code is included here. The goal is a readable technical digest for people who want confidence in the package.

### Issue: Old Assumptions About Game XML

Problem:

7 Days to Die XML shape changes across versions. Old examples and memory can point at the wrong node names, wrong attributes, or wrong spawn groups.

Method:

We treated the installed game files as the authority. The live `entitygroups.xml` and `spawning.xml` files were inspected first, then the mod was shaped around the current Wasteland animal groups.

What we learned:

The current Wasteland animal selection uses `EnemyAnimalsWasteland` and `EnemyAnimalsWastelandNight`. The compact row shape is `e` entries with `n` and `p` attributes.

Guardrail:

The validator checks that the mod still targets the live XPath shape. If the game updates and the target paths no longer exist, validation fails instead of silently shipping a broken mod.

### Issue: Default Must Mean Baseline, Not Guesswork

Problem:

The word `Default` is easy to misuse. It can mean "no UI changes selected," "install vanilla-like XML," or "remove the mod." Those are related but not identical.

Method:

We separated the ideas:

- an unchecked installed animal is pending uninstall to game defaults; an
  unchecked animal not currently installed receives no generated change
- Default slider values mean live game baseline values
- Remove Mod deletes the owned mod folder and returns affected routes to the
  game's effective default XML configuration; it does not restore serverconfig.xml

What we learned:

Installing Default XML can be useful for proofing, but it is still an installed mod. For clean vanilla comparison, removing the mod is the clearest test.

Guardrail:

The README now explains this distinction. The tool also starts with no animals selected, so the first state is no changes selected rather than accidentally installing a full default patch.

### Issue: Tiny Decimal Changes Can Matter

Problem:

During QA, Default spawn timing values were numerically close but not exact. Some decimals were rounded when the generator formatted them.

Why this matters:

Spawn systems are layered. Timing strings can combine with player level, gamestage, chunk state, biome rules, caps, and runtime selection. Even if a rounded value looks harmless to a human, Default should not reinterpret the game.

Method:

A sandbox install generated all five slider levels and compared the Default output against live game values.

What we learned:

Default animal weights matched, but Default `respawndelay` strings had been rounded in a few places.

Guardrail:

Default density now preserves the live `respawndelay` strings exactly. The validator also fails if packaged Default XML drifts from live values.

### Issue: Bigger Weights Did Not Create Enough Visible Pressure

Problem:

Raising animal weights made the animal-selection pool nastier, but it did not fully solve high-pressure gameplay. The Wasteland still had only a small number of base animal routes trying to spawn things.

Method:

We tested high values in live gameplay, then compared visible results against the XML. When the ceiling felt too low, the design moved from weight-only tuning to route pressure tuning.

What we learned:

Weights and route count solve different parts of the problem. Weights decide what gets picked when a route rolls an animal. Routes influence how many opportunities the game has to roll.

Guardrail:

Dense and Absurd can append selected-animal pressure routes with Bit Wrecked `bw_` IDs. Lower settings do not append extra routes, keeping gentle tuning conservative.

### Issue: Global Animal Cap Can Hide The High End

Problem:

Even with high pressure routes, the world can stop adding animals if the global animal cap is reached.

Method:

We identified `MaxSpawnedAnimals` in `serverconfig.xml` as a separate throttle from biome route XML.

What we learned:

Raising route pressure does not guarantee more animals if the global cap blocks new spawns. Likewise, raising the cap alone does not create animals; it only removes a ceiling when routes are already pushing.

Guardrail:

The tool includes an explicit global-limit checkbox instead of changing the cap
silently. It warns the user, backs up and writes `serverconfig.xml`, verifies the
new value, and reports whether the cap changed or was already lifted. The
restore state replaces serverconfig.xml from the newest matching Bit Wrecked
backup and verifies the restored value.

Brutal Science does not create animals by itself. It removes the global animal cap throttle so eligible spawn routes have more room to keep animals active. Vanilla despawn, timer, and cleanup behavior still exists, but Dense/Absurd plus a lifted cap can still build serious pressure over time in loaded Wasteland areas.

### Issue: Dangerous Options Need Honest Language

Problem:

The tool can intentionally produce extreme Wasteland pressure. Hiding that behind polite bland wording would be less safe, not more safe.

Method:

The UI and docs describe the high-risk setting directly while keeping the tone useful.

What we learned:

Users need to know when they are leaving normal tuning and entering stress-test territory.

Guardrail:

Brutal Science is opt-in, visibly labeled, and protected by a confirmation dialog. The success message reports what happened to the cap.

### Issue: Scanner And Mod-Manager Warnings

Problem:

The full package includes readable Windows helper scripts. Antivirus and upload scanners often treat scripts as suspicious because scripts can change files.

Method:

We separated the technical truth from the scanner behavior:

- the game mod is XML-only
- the full package includes helper scripts
- the helper scripts copy/remove the modlet and optionally edit `serverconfig.xml`
- scanner warnings may be heuristic rather than proof of malware

What we learned:

Trust improves when the package explains why a warning might happen before the user has to wonder.

Guardrail:

The README explains the warning risk in detail. The package also states what is not included: no EXE, no DLL, no Harmony patch, no downloader, no hidden updater, no game executable patcher.

### Issue: One Upload Slot

Problem:

The build process can create a full package and a modlet-only package, but some upload sites allow only one file.

Method:

We decided the full package should be the upload of record when only one package is allowed.

What we learned:

One file should contain everything a normal user needs, while still allowing manual/mod-manager users to install just the modlet folder.

Guardrail:

The README, publishing copy, and package metadata now say to upload the full package when only one upload is allowed.

### Issue: The User Needs Proof, Not Just A Button

Problem:

Without scan and verification, the user cannot easily tell whether the installed XML matches the UI.

Method:

The tool gained a scan path and an install verification path.

What we learned:

Verification messages are part of the product. They turn "I hope the mod installed" into "these are the installed animal values."

Guardrail:

Install and scan reports include animal mix, density, pressure route count, and cap status when relevant.

### Issue: Screenshots Need A Story

Problem:

Raw screenshots can be dramatic but confusing. A mod page needs a sequence: baseline, proof, tuning range, extreme result.

Method:

Timed burst capture runs were used while changing settings and testing in live Wasteland gameplay.

What we learned:

The best public proof was not only the most chaotic frame. It was the frame that showed setting, environment, and consequence clearly.

Guardrail:

The live capture tracker keeps screenshot candidates, story purpose, and status. Remaining `TBD` entries are content slots, not engineering blockers.

### Issue: Launcher/Test Machine State Can Masquerade As Mod Failure

Problem:

The local launcher failed during testing because of machine-specific Windows compatibility state.

Method:

The launch error was investigated separately from the mod XML. The local compatibility flag and launcher settings were corrected so testing could continue.

What we learned:

Not every failure near a mod is caused by the mod. Test-machine state can create false leads.

Guardrail:

Launcher/test-machine fixes were kept out of the shipped mod package. The mod package stays focused on the XML modlet and helper tool.

### Issue: Validation Should Fail Loudly

Problem:

It is easy for package structure, XML paths, or baseline values to drift while iterating quickly.

Method:

A validation harness was built to check the package before upload.

What it checks:

- mod folder shape
- XML parsing
- metadata presence
- live XPath targets
- exact Default baseline values
- pressure-route attributes
- `e/n/p` target shape
- license guardrails
- full package zip shape
- extracted full package top-level shape
- extracted full package GUI smoke test
- modlet-only zip shape

Guardrail:

The upload zips are rebuilt by the same validation flow. If validation fails, the package should not be uploaded.

### Issue: The App Needed To Stay Small

Problem:

It would be easy to overbuild this into a broad 7DTD editor.

Method:

The scope stayed narrow: Wasteland open-world animal population tuning.

What is intentionally not changed:

- POI sleeper placement
- quest-triggered spawns
- blood moon hordes
- zombies in general
- animals in other biomes
- save files
- game executables

Guardrail:

README and verification text repeat the scope. The XML targets are limited to Wasteland animal groups and Wasteland animal routes.

### Practical Test Method Summary

The project used several kinds of testing:

- live XML inspection to discover current game structure
- sandbox generation to test all slider levels without touching the live game
- exact baseline comparison for Default
- GUI smoke testing to catch load-time UI failures
- package validation to catch missing files and wrong zip shape
- live gameplay capture to verify high-end pressure is visible in the world
- scan/verify dialogs to prove installed values match selected values

The result is not just "it worked once." The result is a repeatable release path.

### Final Guardrail Philosophy

The tool is allowed to be playful. The Wasteland is allowed to get ridiculous.

But the package should always be clear about:

- what it changes
- what it does not change
- when a setting is dangerous
- how to remove it
- how to verify it
- how to compare against vanilla
- why a scanner might complain
- what file should be uploaded

That is the deal: wild knobs, sober proof.
