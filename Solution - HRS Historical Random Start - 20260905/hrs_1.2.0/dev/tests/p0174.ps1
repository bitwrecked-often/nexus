$ErrorActionPreference = 'Stop'

$sourceRoot = Join-Path $PSScriptRoot '..\src\runtime\reloc'
$files = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.cs' -File | Sort-Object Name)
if ($files.Count -ne 7) { throw "Expected exactly 7 C# files; found $($files.Count)." }
$text = ($files | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"

$forbidden = @(
    '.Teleport(', '.Respawn(', 'SetCustomVarNetwork(', 'RemoveCustomVar(',
    'Harmony', 'System.Net', 'System.Diagnostics.Process', 'File.Write',
    'Directory.Delete', 'Console', 'GetRandomSpawnPositionMinMaxToPosition',
    'LastVerificationTick', 'RELOC_VERIFICATION_FAILED',
    'AddChunkObserver(', 'RemoveChunkObserver(', 'RequestChunk(',
    'IsChunkAreaLoaded(', 'attempt.SemanticBefore',
    'SemanticSnapshot semanticAfter ='
)
foreach ($token in $forbidden) {
    if ($text.Contains($token)) { throw "Forbidden source token found: $token" }
}

$required = @(
    'RespawnType.NewGame', 'IsSinglePlayer', 'IsServer', 'EACEnabled',
    'HRS_Phase1A_Test_001', 'bitwrecked_hrs_state_v1',
    'GetRandomSpawnPosition(world, null, 0, 0)',
    'world.GetChunkFromWorldPos(',
    'World.worldToBlockPos(attempt.Candidate)',
    'CanPlayersSpawnAtPos(attempt.Candidate, false)',
    'pending = new PendingPlacement(worldGuid, data.EntityId, candidate.position)',
    'RELOC_PLACEMENT_DEFERRED', 'if (!attempt.PlacementCalled)',
    'ChunkManager.ChunkObserver observer = player.ChunkObserver',
    'player.SetPosition(attempt.Candidate, true)',
    'observer.SetPosition(attempt.Candidate)', 'RELOC_OBSERVER_UNAVAILABLE',
    'SemanticSnapshot semanticAfterPlacement = SemanticSnapshot.Capture(player)',
    'semanticAfterPlacement.Digest != semanticBefore.Digest',
    'attempt.BeginPlacement(',
    'Vector3.Distance(player.GetPosition(), attempt.Candidate)',
    'FirstVerificationTick = 2', 'VerificationWindowSeconds = 30f',
    'RequiredStableVerificationSamples = 2', 'player.onGround',
    'attempt.ObserveVerificationSample(groundedAndWithinTolerance,',
    'Time.realtimeSinceStartup + VerificationWindowSeconds',
    'Time.realtimeSinceStartup < attempt.VerificationDeadline',
    'RELOC_VERIFY_CONTEXT_FAILED', 'RELOC_VERIFY_CHUNK_TIMEOUT',
    'RELOC_VERIFY_UNSAFE', 'RELOC_VERIFY_POSITION_MISMATCH',
    'MarkerStore.TryComplete(player)',
    'SemanticSnapshot.Capture(player)', 'RELOC_SEMANTIC_UNCHANGED',
    'RELOC_SEMANTIC_CHANGED'
)
foreach ($token in $required) {
    if (-not $text.Contains($token)) { throw "Required source token missing: $token" }
}

function Assert-CallCount([string] $pattern, [int] $expected, [string] $label) {
    $actual = [regex]::Matches($text, $pattern).Count
    if ($actual -ne $expected) { throw "$label call count $actual; expected $expected." }
}
Assert-CallCount 'GetRandomSpawnPosition\s*\(' 1 'native selection'
Assert-CallCount 'player\.SetPosition\s*\(' 1 'player placement'
Assert-CallCount 'observer\.SetPosition\s*\(' 1 'existing observer synchronization'
Assert-CallCount 'AddCustomVar\s*\(' 2 'marker write'
Assert-CallCount 'GetChunkFromWorldPos\s*\(' 1 'containing-chunk readiness'
Assert-CallCount 'CanPlayersSpawnAtPos\s*\(' 1 'post-placement safety'
Assert-CallCount 'Time\.realtimeSinceStartup' 3 'monotonic realtime sampling'
Assert-CallCount 'SemanticSnapshot\.Capture\s*\(' 2 'atomic semantic capture'

$semantic = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0218.cs') -Raw
if ([regex]::Matches($semantic, '\bunchecked\s*\{').Count -ne 3) {
    throw 'All three semantic digest Add overloads must use explicit unchecked blocks.'
}

$handler = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0211.cs') -Raw
$reserve = $handler.IndexOf('MarkerStore.TryReserve(player)')
$select = $handler.IndexOf('GetRandomSpawnPosition(world, null, 0, 0)')
$defer = $handler.IndexOf('pending = new PendingPlacement(worldGuid, data.EntityId, candidate.position)')
$place = $handler.IndexOf('player.SetPosition(attempt.Candidate, true)')
$observer = $handler.IndexOf('observer.SetPosition(attempt.Candidate)')
$semanticBefore = $handler.IndexOf('SemanticSnapshot semanticBefore = SemanticSnapshot.Capture(player)')
$placementCalled = $handler.IndexOf('ProbeLog.Write("RELOC_PLACEMENT_CALLED")')
$semanticAfterPlacement = $handler.IndexOf('SemanticSnapshot semanticAfterPlacement = SemanticSnapshot.Capture(player)')
$semanticUnchanged = $handler.IndexOf('ProbeLog.Write("RELOC_SEMANTIC_UNCHANGED")')
$beginPlacement = $handler.IndexOf('attempt.BeginPlacement(')
$laterTick = $handler.IndexOf('attempt.Ticks < FirstVerificationTick')
$deadline = $handler.IndexOf('Time.realtimeSinceStartup < attempt.VerificationDeadline')
$chunkReady = $handler.IndexOf('world.GetChunkFromWorldPos(')
$safe = $handler.IndexOf('world.CanPlayersSpawnAtPos(attempt.Candidate, false)')
$distance = $handler.IndexOf('Vector3.Distance(player.GetPosition(), attempt.Candidate)')
$stable = $handler.IndexOf('attempt.ObserveVerificationSample(groundedAndWithinTolerance,')
$complete = $handler.IndexOf('MarkerStore.TryComplete(player)')
if (-not (0 -le $reserve -and $reserve -lt $select -and $select -lt $defer -and $defer -lt $semanticBefore -and
    $semanticBefore -lt $place -and $place -lt $observer -and $observer -lt $placementCalled -and
    $placementCalled -lt $semanticAfterPlacement -and $semanticAfterPlacement -lt $semanticUnchanged -and
    $semanticUnchanged -lt $beginPlacement -and $beginPlacement -lt $laterTick -and
    $laterTick -lt $chunkReady -and $chunkReady -lt $deadline -and $deadline -lt $safe -and
    $safe -lt $distance -and $distance -lt $stable -and $stable -lt $complete)) {
    throw 'Required reserve -> select -> defer -> atomic semantic-before/place/observer/after -> begin -> later verify -> complete order failed.'
}

$spawnStart = $handler.IndexOf('private static void OnPlayerSpawned')
$updateStart = $handler.IndexOf('private static void OnGameUpdate')
$spawnHandler = $handler.Substring($spawnStart, $updateStart - $spawnStart)
if ($spawnHandler.Contains('player.SetPosition(') -or $spawnHandler.Contains('observer.SetPosition(') -or
    $spawnHandler.Contains('SemanticSnapshot.Capture(')) {
    throw 'Spawn handler must only reserve/select/defer; mutation and semantic capture belong to GameUpdate.'
}

[xml]$modInfo = Get-Content -LiteralPath (Join-Path $sourceRoot 'ModInfo.xml') -Raw
if ($modInfo.xml.Name.value -ne 'BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV' -or
    $modInfo.xml.Name.value -notmatch '^[0-9a-zA-Z_\-]+$') {
    throw 'Relocation ModInfo internal Name is invalid.'
}
if ($modInfo.xml.SkipWithAntiCheat.value -ne 'true') { throw 'SkipWithAntiCheat must be true.' }

Write-Output 'PHASE1A_RELOCATION_STATIC_SUMMARY pass=1 fail=0 csFiles=7 selectCalls=1 placeCalls=1'
