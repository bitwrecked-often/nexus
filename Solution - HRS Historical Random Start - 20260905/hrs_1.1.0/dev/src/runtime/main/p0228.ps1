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
Assert-Count 'AddCustomVar\s*\(' 7 'marker/protection/trader-route write call'
Assert-Count 'SemanticSnapshot\.Capture\s*\(' 2 'semantic capture call'
Assert-Count 'GetChunkFromWorldPos\s*\(' 2 'readiness/search containing chunk call'
Assert-Count 'CanPlayersSpawnAtPos\s*\(' 1 'native safety call'

$main = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0167.cs') -Raw
$catalog = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0213.cs') -Raw
$compatibility = Get-Content -LiteralPath (Join-Path $sourceRoot 'c0147.cs') -Raw
$buildRecipe = Get-Content -LiteralPath (Join-Path $sourceRoot '..\p0143.ps1') -Raw
if (-not $compatibility.Contains('229796d0-95ca-4662-b426-1a6f1f1596ed') -or
    -not $buildRecipe.Contains('229796d0-95ca-4662-b426-1a6f1f1596ed')) {
    throw 'Release runtime and build recipe do not share the current game MVID pin.'
}
$catalogPoints = [regex]::Matches($catalog,
    'new CuratedStartPoint\("(NG\d{2})",\s*"([^"]+)",\s*(-?\d+),\s*(-?\d+),\s*(-?\d+)\)')
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
    $y = [int]$match.Groups[4].Value
    $z = [int]$match.Groups[5].Value
    if ([math]::Abs($x) -gt 2500 -or [math]::Abs($z) -gt 2500) {
        throw "Survey anchor $($match.Groups[1].Value) is too close to the map boundary."
    }
    if ($y -lt 0 -or $y -gt 300) {
        throw "Survey anchor $($match.Groups[1].Value) has an invalid catalog elevation."
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
    'new Vector3(point.X, point.Y + 1f, point.Z)',
    'world.IsPositionInBounds(resolved)',
    'pointIndex < 0', 'pointIndex >= Points.Length')) {
    if (-not $catalog.Contains($required)) {
        throw "Navezgane resolver requirement missing: $required"
    }
}
$selectorStart = $catalog.IndexOf('internal static bool TrySelect(')
if (-not $catalog.Contains(
    'private static readonly int[] ApprovedPointIndices = { 0, 1 };')) {
    throw 'The explicit NG01/NG02 approved selection pool is missing.'
}
foreach ($required in @(
    'new CuratedStartPoint("NG01", "Perishton snow city", -1528, 80, 1700)',
    'new CuratedStartPoint("NG02", "Remote snow edge", -2100, 218, 2100)',
    'if (string.Equals(pointId, "NG01", StringComparison.Ordinal)) return 8;',
    'searchRadius > LandingSearchRadius')) {
    if (-not $catalog.Contains($required)) {
        throw "Perishton reviewed-street requirement missing: $required"
    }
}
foreach ($required in @(
    'world.GetGameRandom().RandomRange(',
    'ApprovedPointIndices.Length',
    'int pointIndex = ApprovedPointIndices[approvedSlot];',
    'return TryResolve(world, pointIndex, out candidate, out pointId);')) {
    if ($selectorStart -lt 0 -or $catalog.IndexOf($required, $selectorStart) -lt 0) {
        throw "Navezgane random selector requirement missing: $required"
    }
}
if ($catalog.Contains('SurveyPointIndex') -or
    $catalog.Contains('world.GetGameRandom().RandomRange(Points.Length)')) {
    throw 'Release selection is fixed or unexpectedly enables the full survey pool.'
}
if ([regex]::Matches($catalog,
    'world\.GetGameRandom\(\)\.RandomRange\s*\(').Count -ne 1) {
    throw 'Approved-point selection must consume exactly one game-owned RNG draw.'
}
$resolverStart = $catalog.IndexOf('internal static bool TryResolve(')
$guardIndex = $catalog.IndexOf('GamePrefs.GetString(EnumGamePrefs.GameWorld)', $resolverStart)
$resolvedIndex = $catalog.IndexOf('new Vector3(point.X, point.Y + 1f, point.Z)', $resolverStart)
$boundsIndex = $catalog.IndexOf('world.IsPositionInBounds(resolved)', $resolverStart)
$assignIndex = $catalog.IndexOf('candidate = resolved;', $resolverStart)
if (-not (0 -le $resolverStart -and $resolverStart -lt $guardIndex -and
    $guardIndex -lt $resolvedIndex -and $resolvedIndex -lt $boundsIndex -and
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
$primeBegin = $main.IndexOf('attempt.BeginPrimeDelay(')
$primeWait = $main.IndexOf('Time.realtimeSinceStartup < attempt.PrimeDeadline')
$safeResolve = $main.IndexOf('NavezganeStartCatalog.TryFindSafeLanding(world,')
$lift = $main.IndexOf('safeLanding += Vector3.up * SecondLandingLift')
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
    $chunkReady -lt $primeBegin -and $primeBegin -lt $primeWait -and
    $primeWait -lt $safeResolve -and $safeResolve -lt $lift -and $lift -lt $adopt -and
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
foreach ($required in @('RequiredStableVerificationSamples = 3',
    'PrimeDelaySeconds = 2f', 'SecondLandingLift = 2f', 'player.onGround',
    'HorizontalDistance(observedPosition, attempt.Candidate) <=',
    'Math.Abs(observedPosition.y - attempt.CatalogGroundY) <=',
    'attempt.AdoptSettledPosition(observedPosition)',
    'Time.realtimeSinceStartup < attempt.VerificationDeadline')) {
    if (-not $main.Contains($required)) { throw "Settling verification requirement missing: $required" }
}
if ($catalog.Contains('world.GetHeight(') -or
    [regex]::Matches($catalog, 'world\.GetTerrainHeight\s*\(').Count -ne 1 -or
    -not $catalog.Contains('Math.Abs(terrainY - point.Y) > MaximumTerrainDelta')) {
    throw 'Loaded release landing does not use bounded terrain height.'
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
foreach ($required in @('bitwrecked_hrs_starter_trader_route_v1',
    'TraderRouteState.Pending', 'TraderRouteState.Reserved',
    'TraderRouteState.Completed', 'player.QuestAccepted += OnQuestAccepted;',
    'ObservePendingTraderRoute()', 'player.QuestJournal.quests',
    'player.QuestJournal.OwnerPlayer',
    'StringComparison.OrdinalIgnoreCase',
    'TRADER_ROUTE_WAIT_TRADERS',
    'quest_whiteRiverCitizen1', 'quest.CurrentPhase != 1',
    'candidate.Phase == 1', 'candidate.ID, "trader"',
    'MarkerStore.TryReserveTraderRoute(player)',
    'TrySelectNavezganeTrader(player, out traderLocation,',
    'new Vector3(-957f, 76f, 1717f)', 'ObjectiveGoto objective',
    'objective.biomeFilterType = BiomeFilterTypes.AnyBiome',
    'objective.SetLocation(traderLocation, traderSize)',
    'player.QuestJournal.RefreshQuest(quest)',
    'MarkerStore.TryCompleteTraderRoute(player)')) {
    if (-not $text.Contains($required)) {
        throw "Nearest-trader requirement missing: $required"
    }
}
foreach ($forbiddenTraderAction in @('.ResetQuest(', '.RemoveQuest(',
    '.ForceRemoveQuest(', '.CompleteQuest(', '.AddQuest(')) {
    if ($text.Contains($forbiddenTraderAction)) {
        throw "Forbidden trader-route quest action found: $forbiddenTraderAction"
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
    'CANDIDATE_PRIME_WAIT', 'CANDIDATE_ADJUSTED',
    'CANDIDATE_SURFACE_SETTLED')) {
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

$manifestPath = Join-Path $sourceRoot 'j0219.json'
$sourceManifest = [System.IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
$manifestEntries = @($sourceManifest.entries)
if ($manifestEntries.Count -ne 14) {
    throw "Release source manifest entry count is $($manifestEntries.Count); expected 14."
}
$aggregateLines = New-Object System.Collections.Generic.List[string]
foreach ($entry in $manifestEntries) {
    $relative = [string]$entry.path
    if ([System.IO.Path]::IsPathRooted($relative) -or
        [System.IO.Path]::GetFileName($relative) -cne $relative -or
        $relative -ceq 'j0219.json') {
        throw "Unsafe release source manifest path: $relative"
    }
    $entryPath = Join-Path $sourceRoot $relative
    if (-not [System.IO.File]::Exists($entryPath)) {
        throw "Release source manifest file is missing: $relative"
    }
    $entryInfo = New-Object System.IO.FileInfo($entryPath)
    $entryHash = (Get-FileHash -LiteralPath $entryPath -Algorithm SHA256).Hash
    if ([UInt64]$entry.bytes -ne [UInt64]$entryInfo.Length -or
        -not [string]::Equals([string]$entry.sha256, $entryHash,
            [StringComparison]::Ordinal)) {
        throw "Release source manifest drifted: $relative"
    }
    [void]$aggregateLines.Add(('{0}|{1}|{2}' -f
        $relative, $entryInfo.Length, $entryHash))
}
$aggregateBytes = [Text.Encoding]::UTF8.GetBytes(
    [string]::Join("`n", $aggregateLines.ToArray()))
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $aggregate = ([BitConverter]::ToString(
        $sha.ComputeHash($aggregateBytes))).Replace('-', '')
}
finally { $sha.Dispose() }
if (-not [string]::Equals($aggregate,
    [string]$sourceManifest.aggregateSha256, [StringComparison]::Ordinal)) {
    throw 'Release source manifest aggregate drifted.'
}

$metadataVersion = $modInfo.SelectSingleNode('/xml/Version').GetAttribute('value')
if (-not [string]::Equals([string]$sourceManifest.artifactVersion,
    $metadataVersion, [StringComparison]::Ordinal)) {
    throw 'Release source manifest version does not match ModInfo.xml.'
}
$verifiedRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $sourceRoot '..\..\..\verified\main'))
$verifiedDll = Join-Path $verifiedRoot 'd0163.dll'
$verifiedModInfo = Join-Path $verifiedRoot 'ModInfo.xml'
foreach ($verified in @($verifiedDll, $verifiedModInfo)) {
    if (-not [System.IO.File]::Exists($verified)) {
        throw "Verified release artifact is missing: $verified"
    }
}
$artifactInfo = New-Object System.IO.FileInfo($verifiedDll)
$artifactHash = (Get-FileHash -LiteralPath $verifiedDll -Algorithm SHA256).Hash
if ([UInt64]$sourceManifest.expectedArtifact.bytes -ne
        [UInt64]$artifactInfo.Length -or
    -not [string]::Equals(
        [string]$sourceManifest.expectedArtifact.sha256,
        $artifactHash, [StringComparison]::Ordinal)) {
    throw 'Release source manifest expected artifact drifted.'
}
$artifactAssembly = [Reflection.Assembly]::LoadFile($verifiedDll)
if (-not [string]::Equals(
    [string]$sourceManifest.expectedArtifact.mvid,
    $artifactAssembly.ManifestModule.ModuleVersionId.ToString(),
    [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Release source manifest artifact MVID drifted.'
}
if ((Get-FileHash -LiteralPath (Join-Path $sourceRoot 'ModInfo.xml') -Algorithm SHA256).Hash -cne
    (Get-FileHash -LiteralPath $verifiedModInfo -Algorithm SHA256).Hash) {
    throw 'Source and verified ModInfo.xml differ.'
}

Write-Output 'HRS_RELEASE_SOURCE_STATIC_SUMMARY pass=1 fail=0 csFiles=11 surveyPoints=12 selectCalls=1 placeCalls=1 resultAuthorityReads=0'
