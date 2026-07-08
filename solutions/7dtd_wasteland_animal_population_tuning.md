# 7DTD 3.0 Wasteland Animal Population Tuning

Date: 2026-07-05
Status: Verified reusable solution packet
Scope: Wasteland open-world animal roll weighting
Version: 2.0.0

## Intent

Provide a Windows 11 / Steam / 7 Days to Die 3.0-era XML modlet that lets users tune Wasteland animal roll weights without removing animals from the game.

This is population tuning, not direct spawn-timer editing. The live `spawning.xml` routes Wasteland animal rolls to entity groups, and this solution changes the weighted choices inside those groups.

## Product Files

Package root:

```text
_game_dev_ai_tracking/solutions/7dtd_wasteland_animal_population_tuning_files/
```

Full Windows package:

```text
Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_FullPackage.zip
```

Changelog:

```text
CHANGELOG.md
```

Vortex / mod-manager package:

```text
Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip
```

Modlet folder:

```text
BitWrecked_7DTD_WastelandAnimalPopulationTuning/
+-- ModInfo.xml
+-- Config/
    +-- entitygroups.xml
```

## Vortex Shape

Vortex-style installs should receive the modlet-only zip. It must contain the modlet folder at archive root, with `ModInfo.xml` directly inside:

```text
BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml
BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml
```

Do not wrap the Vortex package in the GUI installer folder.

## Live Evidence

Verified live `Data/Config/entitygroups.xml` uses this shape:

```xml
<e n="animalDireWolf" p="2" />
```

Correct XPath target shape:

```text
/e[@n='animalDireWolf']/@p
```

Do not drift this package to:

```text
/entity[@name='animalDireWolf']/@prob
```

## Live Wasteland Animal Baseline

Verified groups:

```text
EnemyAnimalsWasteland
EnemyAnimalsWastelandNight
```

Verified animal weights:

```text
Dire wolf: day 2, night 4
Snake: day 10
Zombie bear: day 5, night 10
Zombie dog: day 15
Zombie vulture: day 5
```

## ModInfo.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xml>
  <Name value="BitWrecked_7DTD_WastelandAnimalPopulationTuning"/>
  <DisplayName value="7DTD 3.0 Wasteland Animal Population Tuning"/>
  <Description value="Adjusts Wasteland animal roll weights without removing animals from the game."/>
  <Author value="Bit Wrecked"/>
  <Version value="2.0.0"/>
  <Website value=""/>
</xml>
```

## Validation

Run from the game root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File _game_dev_ai_tracking\solutions\7dtd_wasteland_animal_population_tuning_files\Support_Files_Do_Not_Edit\validate_and_package.ps1 -RebuildZip
```

Expected result:

```text
PASS: 7DTD 3.0 Wasteland Animal Population Tuning modlet is valid for this live install.
```

The harness checks:

- modlet folder shape
- XML parse
- `ModInfo.xml` metadata
- live Wasteland spawn routes
- patch XPath matches live `Data/Config/entitygroups.xml`
- locked `e/n/p` XPath shape
- full package zip contents
- Vortex modlet zip contents

## Player-Facing Summary

Use this wording:

```text
This is a small XML-only 7 Days to Die modlet for Windows 11 / Steam / current 3.0-era installs. It lets you tune Wasteland animal roll weights. Animals stay in the game; selected animals just roll less or more often.

Normal users should download the full package, read README_FIRST.txt, and run 7DTD_WastelandAnimalTuning.bat. The full package keeps technical files inside Support_Files_Do_Not_Edit. Vortex users should use the VortexModlet zip.
```

## Limits

This changes Wasteland open-world animal rolls.

It does not change:

- POI sleeper animals
- quest-triggered spawns
- blood moon hordes
- zombie spawn rates
- other biomes
- someone else's multiplayer server unless installed server-side
