$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$sourceRoot = $PSScriptRoot
$csharp = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.cs' -File | Sort-Object Name)
if ($csharp.Count -ne 11) { throw "Expected exactly 11 release C# files; found $($csharp.Count)." }
$text = ($csharp | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"

$forbidden = @(
    'Harmony', 'System.Net', 'System.Diagnostics.Process', '.Teleport(', '.Respawn(',
    'SetCustomVarNetwork(', 'RemoveCustomVar(', 'AddChunkObserver(',
    'RemoveChunkObserver(', 'RequestChunk(', 'Directory.Delete(', 'File.WriteAll',
    'HRS_Phase1A_Test_001', 'C:\Users\', 'C:\Program Files'
)
foreach ($token in $forbidden) {
    if ($text.Contains($token)) { throw "Forbidden release source token found: $token" }
}

function Assert-Count([string] $Pattern, [int] $Expected, [string] $Label) {
    $actual = [regex]::Matches($text, $Pattern).Count
    if ($actual -ne $Expected) { throw "$Label count $actual; expected $Expected." }
}

Assert-Count 'GetRandomSpawnPosition\s*\(' 1 'native selector call'
Assert-Count 'player\.SetPosition\s*\(' 3 'player placement/adjustment/restore call'
Assert-Count 'observer\.SetPosition\s*\(' 3 'observer synchronization/adjustment/restore call'
Assert-Count 'AddCustomVar\s*\(' 4 'marker/protection write call'
Assert-Count 'SemanticSnapshot\.Capture\s*\(' 2 'semantic capture call'
Assert-Count 'GetChunkFromWorldPos\s*\(' 2 'readiness/search containing chunk call'
Assert-Count 'CanPlayersSpawnAtPos\s*\(' 1 'native safety call'

$main = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0167.cs') -Raw
$catalog = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0213.cs') -Raw
$catalogPoints = [regex]::Matches($catalog,
    'new CuratedStartPoint\("(NG\d{2})",\s*"([^"]+)",\s*(-?\d+),\s*(-?\d+)\)')
if ($catalogPoints.Count -ne 12) {
    throw "Expected 12 Navezgane survey anchors; found $($catalogPoints.Count)."
}
$ids = @($catalogPoints | ForEach-Object { $_.Groups[1].Value })
if (@($ids | Sort-Object -Unique).Count -ne 12 -or
    $ids[0] -cne 'NG01' -or $ids[11] -cne 'NG12') {
    throw 'Navezgane survey anchor IDs are not unique and contiguous.'
}
foreach ($match in $catalogPoints) {
    $x = [int]$match.Groups[3].Value
    $z = [int]$match.Groups[4].Value
    if ([math]::Abs($x) -gt 2500 -or [math]::Abs($z) -gt 2500) {
        throw "Survey anchor $($match.Groups[1].Value) is too close to the map boundary."
    }
}
foreach ($required in @('Perishton snow city', 'National Forest',
    'Western lake island', 'Diersville outskirts', 'Desert canyon',
    'Departure', 'Gravestown', 'Southern frontier')) {
    if (-not $catalog.Contains('"' + $required + '"')) {
        throw "Navezgane experience missing: $required"
    }
}
if (-not $catalog.Contains('return (CuratedStartPoint[])Points.Clone();')) {
    throw 'Navezgane survey catalog does not protect its owned point array.'
}
foreach ($required in @(
    'GamePrefs.GetString(EnumGamePrefs.GameWorld)',
    'string.Equals(', 'StringComparison.Ordinal',
    'world.GetHeight(point.X, point.Z)', 'terrainY + 1f',
    'float.IsNaN(terrainY)', 'float.IsInfinity(terrainY)',
    'world.IsPositionInBounds(resolved)',
    'pointIndex < 0', 'pointIndex >= Points.Length')) {
    if (-not $catalog.Contains($required)) {
        throw "Navezgane resolver requirement missing: $required"
    }
}
$selectorStart = $catalog.IndexOf('internal static bool TrySelect(')
if (-not $catalog.Contains('private const int SurveyPointIndex = 0;')) {
    throw 'Perishton survey index NG01 is missing.'
}
foreach ($required in @(
    'new CuratedStartPoint("NG01", "Perishton snow city", -1528, 1700)',
    'if (string.Equals(pointId, "NG01", StringComparison.Ordinal)) return 8;',
    'searchRadius > LandingSearchRadius')) {
    if (-not $catalog.Contains($required)) {
        throw "Perishton reviewed-street requirement missing: $required"
    }
}
foreach ($required in @('int pointIndex = SurveyPointIndex;',
    'return TryResolve(world, pointIndex, out candidate, out pointId);')) {
    if ($selectorStart -lt 0 -or $catalog.IndexOf($required, $selectorStart) -lt 0) {
        throw "Navezgane random selector requirement missing: $required"
    }
}
if ($catalog.Contains('world.GetGameRandom().RandomRange(Points.Length)')) {
    throw 'Controlled-location survey build unexpectedly enables the full random pool.'
}
$resolverStart = $catalog.IndexOf('internal static bool TryResolve(')
$guardIndex = $catalog.IndexOf('GamePrefs.GetString(EnumGamePrefs.GameWorld)', $resolverStart)
$heightIndex = $catalog.IndexOf('world.GetHeight(point.X, point.Z)', $resolverStart)
$boundsIndex = $catalog.IndexOf('world.IsPositionInBounds(resolved)', $resolverStart)
$assignIndex = $catalog.IndexOf('candidate = resolved;', $resolverStart)
if (-not (0 -le $resolverStart -and $resolverStart -lt $guardIndex -and
    $guardIndex -lt $heightIndex -and $heightIndex -lt $boundsIndex -and
    $boundsIndex -lt $assignIndex)) {
    throw 'Navezgane resolver world/height/bounds/admission order failed.'
}
$denial = $main.IndexOf('RuntimeEnvironmentGuard.DenialReason(sessionPolicy, data)')
$loaded = $main.IndexOf('data.RespawnType == RespawnType.LoadedGame')
$newGame = $main.IndexOf('data.RespawnType != RespawnType.NewGame')
$standard = $main.IndexOf('if (sessionPolicy.IsStandard)')
$resolve = $main.IndexOf('World world = GameManager.Instance.World')
$reserve = $main.IndexOf('MarkerStore.TryReserve(player)')
$consume = $main.IndexOf('sessionAttemptConsumed = true;')
$select = $main.IndexOf('GetRandomSpawnPosition(world, null, 0, 0)')
$curatedSelect = $main.IndexOf('NavezganeStartCatalog.TrySelect(world, out candidatePosition,')
$defer = $main.IndexOf('pending = new PendingPlacement(')
$semanticBefore = $main.IndexOf('SemanticSnapshot semanticBefore = SemanticSnapshot.Capture(player)')
$place = $main.IndexOf('player.SetPosition(attempt.Candidate, true)')
$observer = $main.IndexOf('observer.SetPosition(attempt.Candidate)')
$chunkReady = $main.IndexOf('world.GetChunkFromWorldPos(')
$safeResolve = $main.IndexOf('NavezganeStartCatalog.TryFindSafeLanding(world,')
$adopt = $main.IndexOf('attempt.AdoptSafeCandidate(safeLanding)')
$adjustPlayer = $main.IndexOf('player.SetPosition(safeLanding, true)')
$adjustObserver = $main.IndexOf('observer.SetPosition(safeLanding)')
$restorePlayer = $main.IndexOf('player.SetPosition(failed.OriginalPosition, true)')
$restoreObserver = $main.IndexOf('observer.SetPosition(failed.OriginalPosition)')
$semanticAfter = $main.IndexOf('SemanticSnapshot semanticAfterPlacement =')
$begin = $main.IndexOf('attempt.BeginPlacement(')
$stable = $main.IndexOf('attempt.ObserveVerificationSample(groundedAndWithinTolerance,')
$complete = $main.IndexOf('MarkerStore.TryComplete(player)')
if (-not (0 -le $denial -and $denial -lt $loaded -and $loaded -lt $newGame -and
    $newGame -lt $standard -and $standard -lt $resolve -and $resolve -lt $reserve -and
    $reserve -lt $consume -and $consume -lt $curatedSelect -and
    $curatedSelect -lt $select -and $select -lt $defer -and
    $defer -lt $semanticBefore -and $semanticBefore -lt $place -and
    $place -lt $observer -and $observer -lt $semanticAfter -and
    $semanticAfter -lt $begin -and $begin -lt $chunkReady -and
    $chunkReady -lt $safeResolve -and $safeResolve -lt $adopt -and
    $adopt -lt $adjustPlayer -and $adjustPlayer -lt $adjustObserver -and
    $adjustObserver -lt $stable -and $stable -lt $complete -and
    $complete -lt $restorePlayer -and $restorePlayer -lt $restoreObserver)) {
    throw 'Release denial/Standard/reserve/select/defer/atomic placement/complete order failed.'
}
$runtimeLog = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0217.cs') -Raw
foreach ($id in 1..12 | ForEach-Object { 'NG{0:D2}' -f $_ }) {
    if (-not $runtimeLog.Contains('"' + $id + '"')) {
        throw "Sanitized runtime candidate event missing: $id"
    }
}
foreach ($required in @('RequiredStableVerificationSamples = 2', 'player.onGround',
    'Vector3.Distance(player.GetPosition(), attempt.Candidate) <=',
    'Time.realtimeSinceStartup < attempt.VerificationDeadline')) {
    if (-not $main.Contains($required)) { throw "Settling verification requirement missing: $required" }
}
foreach ($required in @('ProtectArrivalBiome', 'bitwrecked_hrs_biome_v1',
    'TryEnableSnowProtection', 'ReadSnowProtection',
    '"buffSnow_Hazard"', '"buffSnow_Hazard_Over"',
    '"buffSnow_Hazard_Recover"', '"buffSnow_Hazard01"',
    '"buffSnow_Hazard02"', '"$SnowHazardTimerMax"',
    'string.Equals(attempt.PointId, "NG01", StringComparison.Ordinal)')) {
    if (-not $text.Contains($required)) {
        throw "Snow-first protection requirement missing: $required"
    }
}
if ([regex]::Matches($main, 'sessionAttemptConsumed\s*=\s*true').Count -ne 1 -or
    -not $main.Contains('if (sessionAttemptConsumed) return;')) {
    throw 'Session result overwrite suppression is incomplete.'
}
foreach ($required in @('candidatePosition, player.GetPosition()',
    'failed.PlacementCalled', 'failed.OriginalPosition',
    'player.SetPosition(failed.OriginalPosition, true)',
    'observer.SetPosition(failed.OriginalPosition)',
    'CANDIDATE_LOAD_REQUESTED', 'CANDIDATE_LOAD_RESTORED',
    'CANDIDATE_ADJUSTED')) {
    if (-not $main.Contains($required) -and -not $text.Contains($required)) {
        throw "Pre-placement candidate-load requirement missing: $required"
    }
}

$standardEnd = $main.IndexOf('World world = GameManager.Instance.World', $standard)
$standardBlock = $main.Substring($standard, $standardEnd - $standard)
foreach ($token in @('MarkerStore.', 'GetRandomSpawnPosition', 'SetPosition(')) {
    if ($standardBlock.Contains($token)) { throw "Standard branch contains forbidden action: $token" }
}

$loadedStart = $main.IndexOf('private static void ObserveLoadedMarker')
$loadedEnd = $main.IndexOf('private static void OnGameUpdate', $loadedStart)
$loadedBlock = $main.Substring($loadedStart, $loadedEnd - $loadedStart)
foreach ($token in @('TryReserve', 'TryComplete', 'AddCustomVar', 'GetRandomSpawnPosition', 'SetPosition(')) {
    if ($loadedBlock.Contains($token)) { throw "LoadedGame observer mutates or selects: $token" }
}
if (-not $loadedBlock.Contains('MarkerStore.Read(player)')) {
    throw 'LoadedGame observer does not project the persisted marker.'
}

$writer = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0140.cs') -Raw
if ([regex]::Matches($writer, 'File\.ReadAllBytes\(paths\.ResultPath\)').Count -ne 1) {
    throw 'Result readback must occur exactly once inside AtomicResultWriter.'
}
foreach ($file in $csharp | Where-Object Name -ne 'c0140.cs') {
    $body = Get-Content -LiteralPath $file.FullName -Raw
    if ($body -match 'ReadAll(Bytes|Text).*Result|Read.*result\.v1\.json') {
        throw "Result appears to be read as authority in $($file.Name)."
    }
}
foreach ($required in @('FileMode.CreateNew', 'FileOptions.WriteThrough', 'File.Replace(',
    'Guid.NewGuid().ToString("N")', 'BytesEqual(bytes, readback)')) {
    if (-not $writer.Contains($required)) { throw "Atomic result requirement missing: $required" }
}

$policy = Get-Content -LiteralPath (Join-Path $sourceRoot 'PolicyV1.cs') -Raw
foreach ($required in @('MaximumBytes = 4096', 'new UTF8Encoding(false, true)',
    'PolicyV1.SchemaName + "\n"', 'enabled ? "true" : "false"',
    'Serialize(candidate), json', 'NormalizationForm.FormC')) {
    if (-not $policy.Contains($required)) { throw "Canonical policy requirement missing: $required" }
}

$launcherCore = Join-Path $sourceRoot '..\..\launcher\m0161.psm1'
if (-not (Test-Path -LiteralPath $launcherCore -PathType Leaf)) {
    throw 'Launcher core contract is missing.'
}
$launcherText = Get-Content -LiteralPath $launcherCore -Raw
$result = Get-Content -LiteralPath (Join-Path $sourceRoot 'ResultV1.cs') -Raw
foreach ($reason in @(
    'STANDARD_BYPASS', 'PLACEMENT_DEFERRED', 'RELOCATION_COMPLETED',
    'BUILD_MISMATCH', 'RUNTIME_LANE_UNCONFIRMED', 'POLICY_MISSING',
    'POLICY_REJECTED', 'GAME_NAME_MISMATCH', 'NOT_SERVER',
    'EXECUTION_REJECTED', 'LIFECYCLE_REJECTED', 'ENTITY_UNRESOLVED',
    'MARKER_API_UNAVAILABLE', 'MARKER_CONSUMED', 'MARKER_INVALID',
    'RESERVATION_FAILED', 'SPAWN_LIST_UNAVAILABLE', 'CANDIDATE_UNDEFINED',
    'CANDIDATE_INVALID', 'CANDIDATE_OUT_OF_BOUNDS', 'OBSERVER_UNAVAILABLE',
    'PLACEMENT_FAILED', 'SEMANTIC_CHANGED', 'VERIFY_CONTEXT_FAILED',
    'VERIFY_CHUNK_TIMEOUT', 'VERIFY_UNSAFE', 'VERIFY_POSITION_MISMATCH',
    'COMPLETION_FAILED', 'INTERNAL_FAILURE')) {
    if (-not $launcherText.Contains("'$reason'")) { throw "Launcher reason missing: $reason" }
    if (-not $result.Contains('"' + $reason + '"')) { throw "Runtime reason missing: $reason" }
}
if (-not $result.Contains('0000000000000000000000000000000000000000000000000000000000000000')) {
    throw 'Revision-zero result digest sentinel is missing.'
}

Import-Module -Name $launcherCore -Force
$vectorPath = Join-Path $sourceRoot 'j0148.json'
$vectors = [System.IO.File]::ReadAllText($vectorPath,
    (New-Object System.Text.UTF8Encoding($false, $true))) | ConvertFrom-Json
foreach ($vector in $vectors.policyVectors) {
    $generated = New-HrsPolicy -Revision ([UInt64]$vector.revision) -GameName ([string]$vector.gameName) `
        -Mode ([string]$vector.mode) -WrittenUtc ([datetime]$vector.writtenUtc)
    $generatedJson = ConvertTo-HrsPolicyJson -Policy $generated
    if ($generated.policyDigest -cne [string]$vector.policyDigest -or
        $generatedJson -cne [string]$vector.canonicalJson) {
        throw "Launcher/runtime policy vector drifted at revision $($vector.revision)."
    }
}
if ([UInt64]$vectors.zeroRevisionResult.policyRevision -ne 0 -or
    [string]$vectors.zeroRevisionResult.policyDigest -cne ('0' * 64)) {
    throw 'Revision-zero result vector is invalid.'
}

[xml]$modInfo = Get-Content -LiteralPath (Join-Path $sourceRoot 'ModInfo.xml') -Raw
if ($modInfo.SelectSingleNode('/xml/Name').GetAttribute('value') -ne 'BitWrecked_HistoricalRandomStart') {
    throw 'Release ModInfo internal name is invalid.'
}
if ($modInfo.SelectSingleNode('/xml/SkipWithAntiCheat').GetAttribute('value') -ne 'true') {
    throw 'Release ModInfo must skip with anti-cheat.'
}

Write-Output 'HRS_RELEASE_SOURCE_STATIC_SUMMARY pass=1 fail=0 csFiles=11 surveyPoints=12 selectCalls=1 placeCalls=1 resultAuthorityReads=0'
