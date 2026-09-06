[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$preflight = Join-Path $PSScriptRoot 'Test-Phase1FirstLoadPreflight.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $preflight
if ($LASTEXITCODE -ne 0) { throw 'Phase 1 first-load preflight failed.' }

$gameRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$gameExe = Join-Path $gameRoot '7DaysToDie.exe'
$logRoot = Join-Path $env:APPDATA '7DaysToDie\logs'
$stamp = [DateTime]::UtcNow.ToString('yyyy-MM-dd__HH-mm-ss')
$logPath = Join-Path $logRoot "output_log_client__phase1__$stamp.txt"
$arguments = @('-force-d3d11', '-nogs', '-noeac', '-logfile', $logPath)

Write-Output "PHASE1_LOG=$logPath"
Write-Output 'Starting the visible game client. Do not use an existing save.'
Start-Process -FilePath $gameExe -ArgumentList $arguments -WorkingDirectory $gameRoot
