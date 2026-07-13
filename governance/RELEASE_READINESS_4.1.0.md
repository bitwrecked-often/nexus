# 4.1.0 Release-Readiness Review

## Decision Summary

The `4.1.0` primary Windows graphical package is ready for owner review before
candidate work. Repository preparation is complete and validated. No real
candidate has been staged or built, and no publication action has occurred.

This review authorizes nothing by itself. P4 begins only after the owner accepts
this planning set.

## Exact Identity

| Fact | Prepared value |
| --- | --- |
| Solution | `7DTD 3.0 Wasteland Animal Population Tuning` |
| Version | `4.1.0` (`4.1.0-dev` workspace projection) |
| Edition | `windows-gui` primary |
| Development source | `develop/4.1.0` commit `789f7c8ebc29eea72d27d05b31626eee729a60b4` |
| Planned filename | `7DTD_WastelandAnimalPopulationTuning-4.1.0-windows-gui.zip` |
| Runtime mod/folder ID | `BitWrecked_7DTD_WastelandAnimalPopulationTuning` |
| License | `GPL-3.0-or-later` |
| Current lifecycle | Development; unreleased; non-publishable |

The actual future release-source commit must be recorded in generated
acceptance/provenance evidence after all in-archive projections are finalized.
It must not be self-referenced inside the commit that it identifies.

## Exact Primary Package Contents

The package contract has three visible extracted-root entries and exactly eight
files:

```text
README_FIRST.txt
7DTD_WastelandAnimalTuning.bat
Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/spawning.xml
Support_Files_Do_Not_Edit/LICENSE.txt
Support_Files_Do_Not_Edit/CHANGELOG.md
```

Avatar/publishing art, upload notes, advanced command-line tools, maintainers'
validator, raw QA material, and historical ZIPs are excluded.

## Guarantees Proven Offline

- Full offline gate: `25 passed, 0 failed` on commit `789f7c8`.
- All 32 raw Git blobs in the owner-approved source baseline match their SHA-256
  record.
- Frozen BAT, XML tuning, and GPL bytes are unchanged.
- GUI and `ModInfo.xml` differ from the baseline only by the declared `4.1.0`
  version and official-repository metadata substitutions.
- The exact eight-file mapping, edition set, version surfaces, GPL routes,
  development state, and historical-artifact registry are machine-enforced.
- A disposable clean clone completed real primary staging from raw clean-`HEAD`
  Git blob bytes using one atomic version-root move.
- That staging test produced only the exact tree and working evidence: no ZIP,
  no `final-upload`, no work debris, and no changed historical artifact.
- Reparse-path, traversal, dirty-tree, stale-output, repeat-run, false-public-state,
  swapped-file, invented-hash, and redirected-historical-registry cases fail
  closed.
- The three immutable `4.0.1` ZIP hashes still match:
  - Full package: `52E32D5CC0A0E8D073BB421AEB2BB681D744FEE0F9E5985551EEDB15F8B96901`
  - No-scripts: `96F0796845DBE53773B445C364CB66A46CD046C1519ED778BFDE3BD066008DA5`
  - Vortex: `BC64A2F71B09395D62DF3BC6482C5299756F063C10C87B454D7850548BC25485`

These are source, contract, and packaging-infrastructure guarantees. They are
not a substitute for live game, Nexus, Vortex, accessibility, or served-file
evidence.

## Compatibility And Operational Boundary

- Owner-observed environment: Windows 11, Steam client installation.
- Exact game build: not retained; remains unverified.
- Dedicated server, non-Steam Windows, Linux/Proton, EAC, overhaul, and Vortex
  compatibility: not claimed by the primary package.
- Console: unsupported because the wrapper requires Windows BAT, PowerShell,
  and Windows Forms.
- Runtime source inspection shows no network use, telemetry, elevation request,
  compiled payload, registry persistence, service, scheduled task, save/world
  edit, or game-executable patch.
- The tool writes the owned mod folder and, only when the user requests optional
  cap management, backs up and updates `serverconfig.xml`. Install, remove,
  backup, restore, and limitations are described in the customer README.

## Deliberately Blocked Or Deferred

- `no-scripts` remains blocked because the frozen static XML is vanilla-equivalent
  and no owner-authorized meaningful static outcome exists.
- `vortex` remains blocked pending a GPL-complete exact candidate and a recorded
  import-through-removal audit.
- First GitHub Actions execution is pending after push; workflow presence is not
  a passing-run claim.
- Root/governance license scope, private security/conduct contacts, `CODEOWNERS`,
  and unverified live GitHub protection settings remain separate honest gates.
- Main-branch lifecycle, merge method, merge/tag order, and exact future tag
  naming require an owner decision before public release work.
- Final in-archive changelog date/state and any other release projections must be
  frozen before the one candidate build.

## Owner Gate And Next Controlled Slice

Owner acceptance of this review permits P4 to prepare one exact `windows-gui`
candidate cycle. P4 must:

1. finalize and freeze all in-archive release projections;
2. stage exact bytes from the clean approved source commit;
3. build twice with the declared deterministic archive policy;
4. compare digests, extract, inspect, and validate the exact archive;
5. record checksum, sorted inventory, provenance, rollback, and acceptance;
6. promote only the accepted ZIP to ignored `final-upload`.

Even a successful P4 does not authorize merge to `main`, a tag, GitHub Release,
Nexus upload, served-file change, or hiding/archiving `4.0.1`.
