[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$gameRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$ownedMod = Join-Path $gameRoot 'Mods\mod_DEV'
$targetSave = Join-Path $env:APPDATA '7DaysToDie\Saves\Navezgane\HRS_Phase1_Test_001'
$settingsPath = Join-Path $env:APPDATA '7DaysToDie\launchersettings.json'
$expected = @{
    'devprobe.dll' = '7E235FC8A3F22275B4BBE5B7B511678C4147D4EB4F20CF8E5E4BFF5124977C8A'
    'ModInfo.xml' = '39CD88B7A0C0D2928B81374399AD77FE28178A67C5B7669FAB3F4FBA5CBCBFC8'
}

if (Get-Process -Name '7DaysToDie*' -ErrorAction SilentlyContinue) { throw 'Game is already running.' }
if (-not (Get-Process -Name 'steam' -ErrorAction SilentlyContinue)) { throw 'Steam is not running.' }
if (-not (Test-Path -LiteralPath $targetSave -PathType Container)) { throw 'Exact target save is missing.' }
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
if ([bool]$settings.DefaultRunConfig.UseEAC) { throw 'EAC is not disabled.' }
$files = @(Get-ChildItem -LiteralPath $ownedMod -Force -File)
if ($files.Count -ne 2) { throw 'Owned Mod payload does not contain exactly two files.' }
foreach ($name in $expected.Keys) {
    $path = Join-Path $ownedMod $name
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $expected[$name]) {
        throw "Owned Mod hash mismatch: $name"
    }
}

$gameExe = Join-Path $gameRoot '7DaysToDie.exe'
$logRoot = Join-Path $env:APPDATA '7DaysToDie\logs'
$stamp = [DateTime]::UtcNow.ToString('yyyy-MM-dd__HH-mm-ss')
$logPath = Join-Path $logRoot "output_log_client__phase1_loadedgame__$stamp.txt"
$arguments = @('-force-d3d11', '-nogs', '-noeac', '-logfile', $logPath)

Write-Output 'PHASE1_LOADEDGAME_PREFLIGHT=PASS'
Write-Output "PHASE1_LOG=$logPath"
Start-Process -FilePath $gameExe -ArgumentList $arguments -WorkingDirectory $gameRoot
