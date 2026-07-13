# 7DTD 3.0 Wasteland Animal Population Tuning

- Intended version: `4.1.0`
- Lifecycle: Development / Unreleased
- Primary audience: casual Windows players
- Primary edition: `windows-gui`
- Runtime mod ID: `BitWrecked_7DTD_WastelandAnimalPopulationTuning`
- License: `GPL-3.0-or-later`

## Current Product Contract

This solution uses one readable Windows wrapper to compose selected Wasteland
animal tuning inputs into one XML modlet. The primary package provides the BAT
launcher, PowerShell GUI source, modlet XML source, first-read guide, changelog,
and complete GPL text.

The owner has accepted the current runtime, gameplay, GUI, install/remove,
animal-cap, backup/restore, and XML behavior as the QA-frozen technical baseline
for copy-forward preparation. `4.1.0` work is limited to release identity,
documentation, licensing, exact packaging, non-mutating validation, and evidence
unless the owner explicitly reopens technical behavior.

## Authoritative Files

- Release and edition contract:
  `7dtd_wasteland_animal_population_tuning_files/release-manifest.json`
- Customer first-read guide:
  `7dtd_wasteland_animal_population_tuning_files/README_FIRST.txt`
- Player/release history:
  `7dtd_wasteland_animal_population_tuning_files/Support_Files_Do_Not_Edit/CHANGELOG.md`
- Frozen technical payload root:
  `7dtd_wasteland_animal_population_tuning_files/`
- Baseline evidence:
  `../evidence/baselines/7dtd_wasteland_animal_population_tuning/4.1.0/`

Legacy package metadata, technical manifests, release notes, upload notes, and
the three committed ZIPs are `4.0.1` historical evidence. They do not define the
new package.

## Primary Package Shape

The primary `windows-gui` edition is built only from the eight exact mappings in
the release manifest. Its extracted root contains:

```text
README_FIRST.txt
7DTD_WastelandAnimalTuning.bat
Support_Files_Do_Not_Edit/
```

The support folder contains only the GUI PowerShell source, three modlet XML
files, complete GPL text, and changelog. Assets, advanced command-line tools,
the legacy validator, publishing material, raw QA records, upload notes, and
historical archives are excluded.

## Supported Claims

- Owner-observed environment: Windows 11 with a Steam client installation.
- Target: the retained 7DTD 3.0-era XML shape.
- Exact tested game build: not retained; therefore unverified in release data.
- Dedicated server, non-Steam Windows, Linux, console, Vortex, EAC, overhaul,
  and overlapping-mod compatibility: not claimed without separate evidence.

The actual game modlet is XML-only. The customer package also contains readable
BAT and PowerShell source for the wrapper. It uses no network or telemetry and
does not patch the game executable, directly edit `Data/Config`, or edit saves.

## Safe Offline Check

From the repository root, use PowerShell 7.4 or later:

```powershell
pwsh -NoProfile -File tools/release/Invoke-NexusPackage.ps1 `
  -ManifestPath solutions/7dtd_wasteland_animal_population_tuning_files/release-manifest.json `
  -Action Validate
```

This check is offline and read-only. It does not launch the GUI, read a game
installation, rebuild a ZIP, stage a candidate, promote a file, or publish.

Never run the legacy validator's `-RebuildZip` mode. Its historical defaults
target the three immutable `4.0.1` artifact paths.

## Optional Editions

- `no-scripts` is deferred because its frozen XML is vanilla-equivalent while a
  supported tuning edition must provide a meaningful, accurately described
  outcome.
- `vortex` is blocked until a GPL-complete exact candidate passes a recorded
  Vortex install-through-removal audit.

Neither optional edition may borrow the primary GUI package's capabilities or
support state.

## Publication Boundary

Repository validation and staging do not authorize a tag, GitHub Release, Nexus
upload, served-file change, or archival of `4.0.1`. Those remain explicit owner
actions after the release-readiness review.
