$ErrorActionPreference = 'Stop'

$sourceRoot = Join-Path $PSScriptRoot '..\src\runtime\marker'
$files = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.cs' -File | Sort-Object Name)
if ($files.Count -ne 5) { throw "Expected exactly 5 C# files; found $($files.Count)." }

$text = ($files | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
$forbidden = @(
    'GetRandomSpawnPosition', 'GetSpawnPointList', 'SetPosition', '.Teleport(',
    '.Respawn(', 'Harmony', 'System.Net', 'System.Diagnostics.Process',
    'File.Write', 'Directory.Delete', 'RemoveCustomVar', 'Completed = 2f'
)
foreach ($token in $forbidden) {
    if ($text.Contains($token)) { throw "Forbidden source token found: $token" }
}

$required = @(
    'RespawnType.NewGame', 'IsSinglePlayer', 'IsServer', 'EACEnabled',
    'RespawnType.LoadedGame', 'MARKER_RELOAD_RESERVED',
    'HRS_Phase1A_Test_001', 'bitwrecked_hrs_state_v1',
    'AddCustomVar(Name, 1f)',
    'Read(player) == MarkerState.Reserved'
)
foreach ($token in $required) {
    if (-not $text.Contains($token)) { throw "Required source token missing: $token" }
}

$handler = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0180.cs') -Raw
$loadedIndex = $handler.IndexOf('data.RespawnType == RespawnType.LoadedGame')
$newGameIndex = $handler.IndexOf('data.RespawnType != RespawnType.NewGame')
$reserveIndex = $handler.IndexOf('MarkerStateStore.TryReserveAndReadBack(player)')
if (-not (0 -le $loadedIndex -and $loadedIndex -lt $newGameIndex -and $newGameIndex -lt $reserveIndex)) {
    throw 'Lifecycle ordering is not read-only LoadedGame -> NewGame gate -> reservation.'
}
if ([regex]::Matches($text, 'AddCustomVar\s*\(').Count -ne 1) {
    throw 'Expected exactly one local-and-synchronized marker write call site.'
}
if ([regex]::Matches($text, 'SetCustomVarNetwork\s*\(').Count -ne 0) {
    throw 'Direct network-send helper use is prohibited.'
}

$marker = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0181.cs') -Raw
$readIndex = $marker.IndexOf('if (Read(player) != MarkerState.Absent)')
$writeIndex = $marker.IndexOf('AddCustomVar(Name, 1f)')
$verifyIndex = $marker.IndexOf('Read(player) == MarkerState.Reserved')
if (-not (0 -le $readIndex -and $readIndex -lt $writeIndex -and $writeIndex -lt $verifyIndex)) {
    throw 'Marker reserve ordering is not guard -> write -> read-back.'
}

[xml]$modInfo = Get-Content -LiteralPath (Join-Path $sourceRoot 'ModInfo.xml') -Raw
if ($modInfo.xml.Name.value -ne 'mod_PHASE1A_DEV') {
    throw 'Internal ModInfo Name does not match the exact owned token.'
}
if ($modInfo.xml.Name.value -notmatch '^[0-9a-zA-Z_\-]+$') {
    throw 'Internal ModInfo Name violates the installed game token grammar.'
}
if ($modInfo.xml.SkipWithAntiCheat.value -ne 'true') { throw 'SkipWithAntiCheat must be true.' }

Write-Output 'PHASE1A_MARKER_STATIC_SUMMARY pass=1 fail=0 csFiles=5 relocationCalls=0'
