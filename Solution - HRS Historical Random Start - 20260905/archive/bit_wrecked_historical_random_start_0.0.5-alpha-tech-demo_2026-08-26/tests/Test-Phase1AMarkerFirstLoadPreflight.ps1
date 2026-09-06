[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$gameRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$ownedMod = Join-Path $gameRoot 'Mods\BitWrecked_HistoricalRandomStart_PHASE1A_DEV'
$payload = 'C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\payload-0.0.1-dev-addcustomvar'
$targetSave = Join-Path $env:APPDATA '7DaysToDie\Saves\Navezgane\HRS_Phase1A_Test_001'
$launcherSettings = Join-Path $env:APPDATA '7DaysToDie\launchersettings.json'
$assemblyCSharp = Join-Path $gameRoot '7DaysToDie_Data\Managed\Assembly-CSharp.dll'

$expected = @{
    'BitWrecked.HistoricalRandomStart.Phase1A.MarkerProbe.dll' = 'C3505D1838B8E2A7114485D0D08C023D3CFE6278FDDBD71D81FCB7D628A3B393'
    'ModInfo.xml' = '0F7B261BDDE9F7F780882F0BB36937C0E20A46AC06EAF27B8A53E4E4E8337657'
}

$failures = New-Object System.Collections.Generic.List[string]
if (Get-Process -Name '7DaysToDie*' -ErrorAction SilentlyContinue) {
    $failures.Add('GAME_ALREADY_RUNNING')
}
foreach ($root in @($ownedMod, $payload)) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        $failures.Add("ROOT_MISSING:$root")
        continue
    }
    $files = @(Get-ChildItem -LiteralPath $root -Force -File)
    if ($files.Count -ne 2) { $failures.Add("FILE_COUNT:$root") }
    foreach ($name in $expected.Keys) {
        $path = Join-Path $root $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $failures.Add("FILE_MISSING:$name")
        } elseif ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $expected[$name]) {
            $failures.Add("HASH_MISMATCH:$name")
        }
    }
}
if (Test-Path -LiteralPath $targetSave) { $failures.Add('TARGET_SAVE_ALREADY_EXISTS') }
if ((Get-FileHash -LiteralPath $assemblyCSharp -Algorithm SHA256).Hash -ne
    'B13862E30D8B28F42B83FE6A36BF074D155A6C43164E7B0797A6E4F77BD7DEA3') {
    $failures.Add('ASSEMBLY_CSHARP_MISMATCH')
}
if (-not (Test-Path -LiteralPath $launcherSettings -PathType Leaf)) {
    $failures.Add('LAUNCHER_SETTINGS_MISSING')
} else {
    $settings = Get-Content -LiteralPath $launcherSettings -Raw | ConvertFrom-Json
    if ([bool]$settings.DefaultRunConfig.UseEAC) { $failures.Add('EAC_NOT_DISABLED') }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output "FAIL $_" }
    exit 1
}

Write-Output 'PASS GAME_CLOSED'
Write-Output 'PASS OWNED_AND_EXTERNAL_PAYLOADS_EXACT'
Write-Output 'PASS BUILD_FINGERPRINT'
Write-Output 'PASS TARGET_SAVE_ABSENT'
Write-Output 'PASS EAC_DISABLED_LAUNCHER_SETTING'
Write-Output 'PHASE1A_MARKER_FIRST_LOAD_OPERATIONAL_PREFLIGHT=PASS'
