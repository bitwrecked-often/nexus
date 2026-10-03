[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $RunPath,
    [Parameter(Mandatory = $true)] [ValidateSet('Pass', 'Fail', 'Blocked')] [string] $Outcome,
    [ValidateSet('QA', 'DEV', 'Rollback')] [string] $Kind = 'QA',
    [string] $Notes = '',
    [string] $LogPath = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force

$path = [System.IO.Path]::GetFullPath($RunPath).TrimEnd('\','/')
if (-not [System.IO.Directory]::Exists($path)) { throw 'HRS_QA_RUN_MISSING' }
$sessionPath = Join-Path $path 'session.local.json'
$session = Read-HrsQaJson -Path $sessionPath
$run = Assert-HrsFrozenRun -RunPath $path
if ($run.status -cne 'Started' -or (Test-Path -LiteralPath ($path + '.zip'))) { throw 'HRS_RUN_ALREADY_EXPORTED' }
if ($run.phase -ceq 'DEV' -and $Kind -cne 'DEV') { throw 'HRS_DEV_EVIDENCE_CANNOT_BECOME_QA' }
$contract = Read-HrsQaJson -Path (Join-Path $path 'qa-contract.json')
$release = Read-HrsQaJson -Path (Join-Path $path 'release.json')
$placedWorld = [string]$release.scope.selection -ceq 'random-among-placed-world'
$case = @($contract.requiredCases | Where-Object { [string]$_.id -ceq [string]$run.caseId })
if ($case.Count -ne 1) { throw 'HRS_QA_CASE_UNKNOWN' }

$effectiveLog = if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
    Get-HrsQaLatestLog -ExplicitPath $LogPath
} else {
    Get-HrsQaLatestLog
}
if ([string]::IsNullOrWhiteSpace($effectiveLog)) { $effectiveLog = [string]$session.logPath }
$skipHrs = 0
if (-not [string]::IsNullOrWhiteSpace($effectiveLog) -and
    [string]::Equals($effectiveLog, [string]$session.logPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    $skipHrs = [int]$session.baselineHrsCount
}
$events = @(Get-HrsQaRuntimeEvents -LogPath $effectiveLog -SkipHrsLines $skipHrs)
Write-HrsQaJson -Path (Join-Path $path 'runtime-events.json') -Value ([pscustomobject][ordered]@{
    schema = 'hrs-runtime-events/v1'
    sourceLogName = $(if ([string]::IsNullOrWhiteSpace($effectiveLog)) { '' } else { [System.IO.Path]::GetFileName($effectiveLog) })
    events = $events
})

$history = @(Get-HrsQaHistoryEvents -HistoryPath ([string]$session.historyPath) -SkipLines ([int]$session.historyBaseline))
Write-HrsQaJson -Path (Join-Path $path 'manager-history.json') -Value ([pscustomobject][ordered]@{
    schema = 'hrs-manager-history-export/v1'
    events = $history
})

$inventoryLane = if ($run.PSObject.Properties.Name -contains 'candidateId' -and $run.candidateId) { $path } else { [string]$session.laneRoot }
$installedAfter = Get-HrsQaInstalledInventory -LaneRoot $inventoryLane -GameRoot ([string]$session.gameRoot)
Write-HrsQaJson -Path (Join-Path $path 'installed-after.json') -Value $installedAfter
Write-HrsQaJson -Path (Join-Path $path 'result-summary.json') -Value (Get-HrsQaResultSummary -InstalledInventory $installedAfter -GameRoot ([string]$session.gameRoot))

$observedNames = @($events | ForEach-Object { [string]$_.event })
$missing = @()
foreach ($expected in @($case[0].expectedEvents)) {
    if ($observedNames -cnotcontains [string]$expected) { $missing += [string]$expected }
}
$expectedOrderValid = $true
$searchFrom = 0
foreach ($expected in @($case[0].expectedEvents)) {
    $foundAt = -1
    for ($index = $searchFrom; $index -lt $observedNames.Count; $index++) {
        if ([string]::Equals([string]$observedNames[$index], [string]$expected, [System.StringComparison]::Ordinal)) {
            $foundAt = $index
            break
        }
    }
    if ($foundAt -lt 0) { $expectedOrderValid = $false; break }
    $searchFrom = $foundAt + 1
}
$forbidden = @()
if ($case[0].PSObject.Properties.Name -contains 'forbiddenEvents') {
    foreach ($item in @($case[0].forbiddenEvents)) {
        if ($observedNames -ccontains [string]$item) { $forbidden += [string]$item }
    }
}
$observationIssues = @()
foreach ($event in $events) {
    if ($event.version -cne $run.releaseVersion -or $event.buildId -cne $run.releaseBuildId) { $observationIssues += 'RUNTIME_IDENTITY_MISMATCH' }
}
$observationPath = Join-Path $path 'qa-observation.json'
$observation = $null
if ([System.IO.File]::Exists($observationPath)) {
    try {
        $observation = Read-HrsQaJson -Path $observationPath
        $expectedObservationSchema = if ($placedWorld) { 'hrs-qa-observation/v2' } else { 'hrs-qa-observation/v1' }
        if ([string]$observation.schema -cne $expectedObservationSchema -or
            [string]$observation.runId -cne [string]$run.runId -or
            [string]$observation.caseId -cne [string]$run.caseId) {
            $observationIssues += 'OBSERVATION_IDENTITY'
        }
    }
    catch { $observationIssues += 'OBSERVATION_INVALID' }
}
switch ([string]$run.caseId) {
    'HRS-QA-003A' {
        if ($null -eq $observation -or [string]$observation.landingResult -cne 'Safe') { $observationIssues += 'SAFE_LANDING_NOT_OBSERVED' }
    }
    'HRS-QA-003B' {
        if ($null -eq $observation -or [string]$observation.landingResult -cne 'Safe') { $observationIssues += 'SAFE_LANDING_NOT_OBSERVED' }
    }
    'HRS-QA-004' {
        if (-not $placedWorld -and ($null -eq $observation -or $observation.nearestTraderMatches -ne $true)) {
            $observationIssues += 'NEAREST_TRADER_NOT_PROVEN'
        }
    }
    'HRS-QA-005' {
        if ($null -eq $observation -or [string]$observation.questDestinationResult -cne 'Confirmed') { $observationIssues += 'QUEST_DESTINATION_NOT_CONFIRMED' }
        if ($null -eq $observation -or [string]$observation.starterQuestProgression -cne 'Works') { $observationIssues += 'STARTER_QUEST_NOT_PROVEN' }
    }
    'HRS-QA-006' {
        if ($null -eq $observation -or [string]$observation.reloadResult -cne 'NoRelocation') { $observationIssues += 'ONE_SHOT_RELOAD_NOT_PROVEN' }
    }
    'HRS-QA-008' {
        if ([string]$installedAfter.state -cne 'NotInstalled') { $observationIssues += 'CLEAN_REMOVAL_NOT_PROVEN' }
    }
}
if ($placedWorld) {
    if ($case[0].PSObject.Properties.Name -contains 'requiresPlacedIdentity' -and
        $case[0].requiresPlacedIdentity -eq $true) {
        $observationIssues += @(Test-HrsQaPlacedObservation -Events $events `
            -Observation $observation -Scope $release.scope -Case $case[0])
    }
}
else {
    $declaredPointIds = @()
    $historicalPointIds = @($case[0].expectedEvents | ForEach-Object { if ([string]$_ -match '^NG\d+$') { [string]$_ } })
    if ($historicalPointIds.Count -eq 1 -and ($null -eq $observation -or [string]$observation.selectedPointId -cne $historicalPointIds[0])) {
        $observationIssues += 'HISTORICAL_POINT_NOT_OBSERVED'
    }
    if ($case[0].PSObject.Properties.Name -contains 'expectedPointIds') {
        $declaredPointIds = @($case[0].expectedPointIds | ForEach-Object { [string]$_ })
        if ($null -eq $observation -or $declaredPointIds -notcontains [string]$observation.selectedPointId) {
            $observationIssues += 'DECLARED_POINT_NOT_OBSERVED'
        }
    }
    if ($null -ne $observation -and
        [string]$observation.selectedPointId -notin @('NotObserved', 'NotApplicable')) {
        $releasePointIds = @($release.scope.approvedSpawnPoints | ForEach-Object { [string]$_.id })
        if ($releasePointIds -notcontains [string]$observation.selectedPointId) {
            $observationIssues += 'POINT_OUTSIDE_RELEASE_SCOPE'
        }
    }
}
if ($null -ne $observation -and
    $case[0].PSObject.Properties.Name -contains 'traderRoutingScope' -and
    [string]$case[0].traderRoutingScope -ceq 'same-starting-biome') {
    if ([string]$observation.startingBiome -in @('NotObserved', 'NotApplicable', '')) {
        $observationIssues += 'STARTING_BIOME_NOT_RECORDED'
    }
    if ([string]$observation.observedTraderBiome -in @('NotObserved', 'NotApplicable', '')) {
        $observationIssues += 'TRADER_BIOME_NOT_RECORDED'
    }
    elseif ([string]$observation.startingBiome -cne [string]$observation.observedTraderBiome) {
        $observationIssues += 'TRADER_BIOME_MISMATCH'
    }
}
if ($case[0].PSObject.Properties.Name -contains 'requiredChecks') {
    foreach ($check in $case[0].requiredChecks) {
        if ($null -eq $observation -or $observation.PSObject.Properties.Name -notcontains 'confirmedChecks' -or
            @($observation.confirmedChecks) -cnotcontains $check) { $observationIssues += ('CHECK_NOT_CONFIRMED:'+ $check) }
    }
}
if ($case[0].PSObject.Properties.Name -contains 'requiredChecks' -and $run.caseId -in @('HRS-QA-001','HRS-QA-009')) {
    foreach ($artifact in $release.artifacts) {
        $name = [IO.Path]::GetFileName($artifact.path)
        $installed = @($installedAfter.files | Where-Object { $_.path -ceq $name })
        if ($installed.Count -ne 1 -or $installed[0].sha256 -cne $artifact.sha256) { $observationIssues += 'INSTALLED_CANDIDATE_NOT_PROVEN' }
    }
}
$automatedStatus = if ($missing.Count -eq 0 -and $forbidden.Count -eq 0 -and $expectedOrderValid -and $observationIssues.Count -eq 0) { 'Consistent' } else { 'Mismatch' }
$completedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$result = [pscustomobject][ordered]@{
    schema = 'hrs-qa-result/v1'
    runId = [string]$run.runId
    caseId = [string]$run.caseId
    kind = $Kind
    declaredOutcome = $Outcome
    automatedEventAssessment = $automatedStatus
    expectedEventOrderValid = $expectedOrderValid
    missingExpectedEvents = $missing
    observedForbiddenEvents = $forbidden
    observationIssues = $observationIssues
    notes = $Notes
    completedUtc = $completedUtc
}
Write-HrsQaJson -Path (Join-Path $path 'qa-result.json') -Value $result

if ($Kind -eq 'Rollback' -or [string]$run.caseId -ceq 'HRS-QA-008') {
    $before = Read-HrsQaJson -Path (Join-Path $path 'installed-before.json')
    $rollback = [pscustomobject][ordered]@{
        schema = 'hrs-rollback-receipt/v1'
        runId = [string]$run.runId
        beforeState = [string]$before.state
        afterState = [string]$installedAfter.state
        cleanRemovalObserved = ([string]$installedAfter.state -ceq 'NotInstalled')
        declaredOutcome = $Outcome
        completedUtc = $completedUtc
    }
    Write-HrsQaJson -Path (Join-Path $path 'rollback-receipt.json') -Value $rollback
}

foreach ($required in @($case[0].requiredEvidence)) {
    if (-not (Test-Path -LiteralPath (Resolve-HrsContainedFile $path ($required+'.json')))) { throw "HRS_REQUIRED_EVIDENCE: $required" }
}
$run.status = 'Completed'
$run | Add-Member -NotePropertyName completedUtc -NotePropertyValue $completedUtc -Force
$run | Add-Member -NotePropertyName declaredOutcome -NotePropertyValue $Outcome -Force
Write-HrsQaJson -Path (Join-Path $path 'run.json') -Value $run

$summary = @(
    '# Historical Random Start QA evidence',
    '',
    ('- Run: ' + [string]$run.runId),
    ('- Release: ' + [string]$run.releaseVersion + ' / ' + [string]$run.releaseBuildId),
    ('- Case: ' + [string]$run.caseId + ' - ' + [string]$case[0].title),
    "- Kind: $Kind",
    "- Declared outcome: $Outcome",
    "- Automated event assessment: $automatedStatus",
    "- Started: $($run.startedUtc)",
    "- Completed: $completedUtc",
    '',
    '## Requirement',
    '',
    [string]$case[0].requirement,
    '',
    '## Event comparison',
    '',
    "- Missing expected events: $(if ($missing.Count -eq 0) { 'none' } else { $missing -join ', ' })",
    "- Expected event order valid: $expectedOrderValid",
    "- Observed forbidden events: $(if ($forbidden.Count -eq 0) { 'none' } else { $forbidden -join ', ' })",
    "- Observation issues: $(if ($observationIssues.Count -eq 0) { 'none' } else { $observationIssues -join ', ' })",
    '',
    '## QA notes',
    '',
    $(if ([string]::IsNullOrWhiteSpace($Notes)) { 'No notes supplied.' } else { $Notes }),
    '',
    'Tool-generated fields exclude usernames, full source paths, save contents, and unrestricted game-log text. QA notes are included verbatim and must be sanitized by the tester.'
) -join "`n"
[System.IO.File]::WriteAllText((Join-Path $path 'qa-summary.md'), $summary + "`n", (New-Object System.Text.UTF8Encoding($false)))

$manifest = New-HrsQaEvidenceManifest -RunPath $path
Write-HrsQaJson -Path (Join-Path $path 'evidence-manifest.json') -Value $manifest

$zipPath = $path + '.zip'
if ([System.IO.File]::Exists($zipPath)) { throw 'HRS_QA_ZIP_ALREADY_EXISTS' }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in Get-ChildItem -LiteralPath $path -Recurse -File | Where-Object { $_.Name -cne 'session.local.json' }) {
        $relative = $file.FullName.Substring($path.Length).TrimStart('\','/').Replace('\','/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive,
            $file.FullName,
            $relative,
            [System.IO.Compression.CompressionLevel]::Optimal
        )
    }
}
finally { $archive.Dispose() }

Write-Output "QA evidence exported: $zipPath"
Write-Output "SHA-256: $(Get-HrsQaSha256 -Path $zipPath)"
Write-Output "Event assessment: $automatedStatus"
