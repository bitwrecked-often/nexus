# Build from the supplied source

The same public package gives QA, players and future contributors the manager,
runtime source, graphics recipes, test sources and project evidence. Open the
package's main START entry to use the mod. The source directory is a development
copy; it is not another installation option.

## Inputs

- Windows PowerShell 5.1 Desktop, available with Windows. Use `powershell.exe`,
  not `pwsh`, for the native UI, graphics and pinned runtime builder.
- The recorded .NET host and Roslyn compiler, already installed at
  `C:\Program Files\dotnet\dotnet.exe` and
  `C:\Program Files\dotnet\sdk\10.0.401\Roslyn\bincore\csc.dll`.
  Their exact SHA-256 values are recorded in the build record and builder.
- A legally obtained 7 Days to Die v3.3.0 b17 installation or reference root.
  It must contain `7DaysToDie.exe`, the seven named DLLs under
  `7DaysToDie_Data\Managed`, and `Mods\0_TFP_Harmony\0Harmony.dll`.
  Game files, Harmony binaries, SDK and compiler are external inputs; they are
  not supplied in this package.

The authenticated Assembly-CSharp SHA-256 is
`AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146`,
with MVID `7c57b7de-39a1-497d-bf48-8d5d1d4a1ff1`. Harmony SHA-256 is
`C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF`,
with MVID `7b787fec-e12a-47a6-8027-108671090713`.
The supplied build record authenticates all eight references. A different game
build is not an interchangeable reproducibility input. Keep the pins intact;
support for another build requires a separately recorded development change.

## Reproduce the runtime

Work in a disposable, writable local copy. Keep the original public archive
unchanged. Close the game before building. From the extracted package root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\source\hrs_1.2.7\dev\src\runtime\p0143.ps1 -GameRoot 'C:\Games\7 Days To Die'
```

The builder compiles the fifteen named runtime files twice with C# 7.3,
optimization, overflow checking, warnings as errors and deterministic output.
Both DLLs must match. It writes a fresh unique attempt under the source copy's
`dev\out` and staging inputs under `dev\tmp`; `j0144.json` records compiler,
references, source hashes, DLL length and SHA-256. It does not install the mod,
alter game files or launch the game. Compare the produced DLL with the public
release contract's runtime hash. A local rebuild does not become a QA-approved
release or replace the archive being reviewed.

## Native presentation

The real manager's embedded design is generated from the editable Quiet recipe
and `NativeControls.cs`. The complete graphics workbench is supplied and uses
Windows PowerShell, WinForms, .NET Framework and System.Drawing.

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\source\hrs_1.2.7\dev\tools\NativeGraphics\Sync-ManagerDesign.ps1 -Check
```

Open `source\hrs_1.2.7\dev\tools\NativeGraphics\Open-Workbench.cmd` to explore
and export recipe variations. The workbench changes preview state only. After
changing a recipe or controls source in a working copy, run the Sync tool
without `-Check`, then check the actual manager layout and callbacks. Keep the
Game Name bridge, runtime eligibility and recovery contracts intact.

## Reusable tests

The supplied source tree retains the relative paths used by its tests and
includes the same verified HRS DLL and ModInfo under `dev\verified\main`.
These are the project's own files; no game DLL is supplied. The included
`dev\qa\POLICY_V2_VECTORS.json` is the seven-vector input.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\source\hrs_1.2.7\dev\tests\Test-CompiledPolicy.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\source\hrs_1.2.7\dev\tests\Test-PolicyV2.ps1
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\source\hrs_1.2.7\dev\tests\Test-ManagerReviewRepairs.ps1 -EvidenceRoot 'C:\HRS Dev\manager-review-new'
```

The focused runtime fixture compiles nine actual runtime sources against the
supplied controlled engine/resolver seams. Its project targets .NET 10 and
uses an existing .NET SDK; no proprietary game assembly is needed for it.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\source\hrs_1.2.7\dev\tests\Test-RuntimeReviewRepairs.ps1 -EvidenceRoot 'C:\HRS Dev\runtime-review-new'
```

Use a new evidence folder for each attempt. `RuntimeRepairHarness.csproj`,
`Program.cs` and `Stubs.cs` are included. The manager fixture uses inert
temporary installations and actual callback bodies with controlled selections,
process observations and confirmation results. These are DEV checks; they do
not pass independent gameplay, actual Windows DPI, Narrator or newcomer QA.

The historical full callback replay and ownership suites are also included as
source. `Test-ManagerCallbackWiring.ps1` currently expects the user's own game
Assembly-CSharp at the documented Steam path, and its upgrade, migration and
failure cases additionally expect the historical 1.2.4 HRS payload. The
ownership suite accepts `-OldPayloadRoot` and otherwise expects the 1.2.6 HRS
payload. Those older payloads and proprietary game references are not bundled.
Provide those documented external inputs in an isolated DEV checkout before
running the relevant suites. Do not run development injections against a QA
installation or present them as customer QA results.

The complete generic release/QA scripts are included under `source\qa_cycle`,
including the unified-package verifier and candidate exporter. Public-content
preparation and verification helpers are under `source\support`. These retain
their DEV-checkout source and documented inputs; reconstruct the corresponding
DEV layout and provide its preserved historical records before rerunning a
content-preparation helper. The archive's main QA tools/runbook provide the
direct workflow for reviewing this frozen package. New source/tool checks are
indexed under `evidence\qa003`; old candidate evidence remains under
`evidence\qa002` with its original scope.

## Read before extending it

[The current setup foundation](../source/hrs_1.2.7/dev/BUILD_SETUP_FOUNDATION.md)
explains the exact Game Name bridge: one active policy can be written before a
world exists; world-name lookup and genuinely fresh-character eligibility are
separate runtime decisions. [History](HISTORY.md) and [the project story](LORE.md)
index the original reasoning and its evidence limits. Source is GPL-3.0-or-later;
the complete license is supplied. Branding is the owner's supplied Bit Wrecked
artwork; the license grants no rights to the game or other third-party assets.
