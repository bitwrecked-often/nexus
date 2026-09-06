[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$gameRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$ownedMod = Join-Path $gameRoot 'Mods\BitWrecked_HistoricalRandomStart_DEV'
$saveRoot = Join-Path $env:APPDATA '7DaysToDie\Saves'
$targetSave = Join-Path $saveRoot 'Navezgane\HRS_Phase1_Test_001'
$launcherSettings = Join-Path $env:APPDATA '7DaysToDie\launchersettings.json'

$expected = @{
    'BitWrecked.HistoricalRandomStart.DevProbe.dll' = '7E235FC8A3F22275B4BBE5B7B511678C4147D4EB4F20CF8E5E4BFF5124977C8A'
    'ModInfo.xml' = '39CD88B7A0C0D2928B81374399AD77FE28178A67C5B7669FAB3F4FBA5CBCBFC8'
}

$failures = New-Object System.Collections.Generic.List[string]
if (Get-Process -Name '7DaysToDie*' -ErrorAction SilentlyContinue) {
    $failures.Add('GAME_ALREADY_RUNNING')
}
if (-not (Test-Path -LiteralPath $ownedMod -PathType Container)) {
    $failures.Add('OWNED_MOD_MISSING')
} else {
    $files = @(Get-ChildItem -LiteralPath $ownedMod -Force -File)
    if ($files.Count -ne 2) { $failures.Add('OWNED_MOD_FILE_COUNT') }
    foreach ($name in $expected.Keys) {
        $path = Join-Path $ownedMod $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $failures.Add("OWNED_MOD_FILE_MISSING:$name")
        } elseif ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $expected[$name]) {
            $failures.Add("OWNED_MOD_HASH_MISMATCH:$name")
        }
    }
}
if (Test-Path -LiteralPath $targetSave) { $failures.Add('TARGET_SAVE_ALREADY_EXISTS') }
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
Write-Output 'PASS OWNED_MOD_EXACT_TWO_FILE_PAYLOAD'
Write-Output 'PASS OWNED_MOD_HASHES'
Write-Output 'PASS TARGET_SAVE_ABSENT'
Write-Output 'PASS EAC_DISABLED_LAUNCHER_SETTING'
Write-Output 'PHASE1_FIRST_LOAD_PREFLIGHT=PASS'
