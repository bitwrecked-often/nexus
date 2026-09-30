[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $RunPath,
    [string] $SelectedPointId = 'NotObserved',
    [double] $FinalX = [double]::NaN,
    [double] $FinalY = [double]::NaN,
    [double] $FinalZ = [double]::NaN,
    [ValidateSet('Safe', 'Unsafe', 'NotObserved', 'NotApplicable')] [string] $LandingResult = 'NotObserved',
    [string] $SelectedTraderPlacement = 'NotObserved',
    [string] $StartingBiome = 'NotObserved',
    [string] $ObservedTraderBiome = 'NotObserved',
    [string] $WorldCategory = 'NotObserved',
    [string] $WorldName = 'NotObserved',
    [string] $GameName = 'NotObserved',
    [int] $WorldSize = 0,
    [string] $SelectedPrefabName = 'NotObserved',
    [string] $PlacedInstanceId = 'NotObserved',
    [string] $PlacedRotation = 'NotObserved',
    [int] $RetryAttemptCount = 0,
    [string] $SelectedTraderPlacedId = 'NotObserved',
    [string[]] $ConfirmedChecks = @(),
    [ValidateSet('Confirmed', 'NotConfirmed', 'NotObserved', 'NotApplicable')] [string] $QuestDestinationResult = 'NotObserved',
    [ValidateSet('Works', 'Failed', 'NotObserved', 'NotApplicable')] [string] $StarterQuestProgression = 'NotObserved',
    [ValidateSet('NoRelocation', 'RelocatedAgain', 'NotObserved', 'NotApplicable')] [string] $ReloadResult = 'NotObserved'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force

$path = [System.IO.Path]::GetFullPath($RunPath)
$run = Assert-HrsFrozenRun -RunPath $path
$release = Read-HrsQaJson -Path (Join-Path $path 'release.json')
if ([string]$run.status -cne 'Started') { throw 'HRS_QA_OBSERVATION_RUN_NOT_ACTIVE' }
$placedWorld = [string]$release.scope.selection -ceq 'random-among-placed-world'

$reviewedTraders = @()
$contract = Read-HrsQaJson (Join-Path $path 'qa-contract.json')
$case = @($contract.requiredCases | Where-Object { $_.id -ceq $run.caseId })[0]
$allowedChecks = @()
if ($case.PSObject.Properties.Name -contains 'requiredChecks') { $allowedChecks = @($case.requiredChecks) }
foreach ($check in $ConfirmedChecks) { if ($allowedChecks -cnotcontains $check) { throw 'HRS_UNKNOWN_CHECK' } }
if (-not $placedWorld) {
    $approvedPointIds = @($release.scope.approvedSpawnPoints | ForEach-Object { [string]$_.id })
    if ($SelectedPointId -notin @('NotObserved', 'NotApplicable') -and
        $approvedPointIds -notcontains $SelectedPointId) {
        throw "HRS_QA_OBSERVATION_POINT_NOT_APPROVED: $SelectedPointId"
    }
    $reviewedTraders = @($release.scope.reviewedTraderPlacements)
    if ($StartingBiome -notin @('NotObserved','NotApplicable') -and
        $release.scope.PSObject.Properties.Name -contains 'traderRoutingScope') {
        if (@($reviewedTraders | ForEach-Object { $_.biome }) -cnotcontains $StartingBiome) { throw 'HRS_UNKNOWN_BIOME' }
        if ($SelectedTraderPlacement -notin @('NotObserved','NotApplicable')) {
            $selected = @($reviewedTraders | Where-Object { $_.id -ceq $SelectedTraderPlacement })[0]
            if ($ObservedTraderBiome -cne $selected.biome) { throw 'HRS_TRADER_BIOME_CONTRADICTION' }
        }
    }
    if ($SelectedTraderPlacement -notin @('NotObserved', 'NotApplicable')) {
        if (@($reviewedTraders | ForEach-Object { [string]$_.id }) -notcontains $SelectedTraderPlacement) {
            throw "HRS_QA_OBSERVATION_TRADER_NOT_REVIEWED: $SelectedTraderPlacement"
        }
    }
}
else {
    if ($RetryAttemptCount -lt 0 -or $RetryAttemptCount -gt [int]$release.scope.maxPoiAttempts) {
        throw 'HRS_QA_OBSERVATION_RETRY_COUNT_INVALID'
    }
}

$hasPosition = -not [double]::IsNaN($FinalX) -and -not [double]::IsNaN($FinalY) -and -not [double]::IsNaN($FinalZ)
$nanCount = 0
foreach ($coordinate in @($FinalX, $FinalY, $FinalZ)) {
    if ([double]::IsNaN($coordinate)) { $nanCount++ }
}
if ($nanCount -ne 0 -and $nanCount -ne 3) { throw 'HRS_QA_OBSERVATION_POSITION_INCOMPLETE' }
if ($hasPosition -and ([double]::IsInfinity($FinalX) -or [double]::IsInfinity($FinalY) -or [double]::IsInfinity($FinalZ))) {
    throw 'HRS_QA_OBSERVATION_POSITION_INVALID'
}

$expectedTrader = ''
$expectedDistance = $null
if ($hasPosition -and -not $placedWorld) {
    $best = [double]::MaxValue
    $traderCandidates = $reviewedTraders
    if ($release.scope.PSObject.Properties.Name -contains 'traderRoutingScope' -and
        [string]$release.scope.traderRoutingScope -ceq 'same-starting-biome' -and
        $StartingBiome -notin @('NotObserved', 'NotApplicable')) {
        $traderCandidates = @($reviewedTraders | Where-Object {
            [string]$_.biome -ceq $StartingBiome
        })
    }
    foreach ($trader in $traderCandidates) {
        $dx = [double]$trader.x - $FinalX
        $dz = [double]$trader.z - $FinalZ
        $distance = [Math]::Sqrt($dx * $dx + $dz * $dz)
        if ($distance -lt $best) {
            $best = $distance
            $expectedTrader = [string]$trader.id
        }
    }
    $expectedDistance = [Math]::Round($best, 2)
}
$nearestMatches = $null
if (-not [string]::IsNullOrEmpty($expectedTrader) -and
    $SelectedTraderPlacement -notin @('NotObserved', 'NotApplicable')) {
    $nearestMatches = [string]::Equals($expectedTrader, $SelectedTraderPlacement, [System.StringComparison]::Ordinal)
}

$observation = [pscustomobject][ordered]@{
    schema = $(if ($placedWorld) { 'hrs-qa-observation/v2' } else { 'hrs-qa-observation/v1' })
    runId = [string]$run.runId
    caseId = [string]$run.caseId
    observedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    selectedPointId = $SelectedPointId
    finalPosition = $(if ($hasPosition) { [pscustomobject][ordered]@{ x=$FinalX; y=$FinalY; z=$FinalZ } } else { $null })
    landingResult = $LandingResult
    selectedTraderPlacement = $SelectedTraderPlacement
    startingBiome = $StartingBiome
    observedTraderBiome = $ObservedTraderBiome
    expectedNearestTraderPlacement = $expectedTrader
    expectedNearestTraderDistanceMeters = $expectedDistance
    nearestTraderMatches = $nearestMatches
    questDestinationResult = $QuestDestinationResult
    starterQuestProgression = $StarterQuestProgression
    reloadResult = $ReloadResult
    confirmedChecks = @($ConfirmedChecks)
}
if ($placedWorld) {
    $observation | Add-Member -NotePropertyName worldCategory -NotePropertyValue $WorldCategory
    $observation | Add-Member -NotePropertyName worldName -NotePropertyValue $WorldName
    $observation | Add-Member -NotePropertyName gameName -NotePropertyValue $GameName
    $observation | Add-Member -NotePropertyName worldSize -NotePropertyValue $WorldSize
    $observation | Add-Member -NotePropertyName selectedPrefabName -NotePropertyValue $SelectedPrefabName
    $observation | Add-Member -NotePropertyName placedInstanceId -NotePropertyValue $PlacedInstanceId
    $observation | Add-Member -NotePropertyName placedRotation -NotePropertyValue $PlacedRotation
    $observation | Add-Member -NotePropertyName retryAttemptCount -NotePropertyValue $RetryAttemptCount
    $observation | Add-Member -NotePropertyName selectedTraderPlacedId -NotePropertyValue $SelectedTraderPlacedId
}
Write-HrsQaJson -Path (Join-Path $path 'qa-observation.json') -Value $observation
Write-Output "QA observation recorded for $($run.runId)"
if (-not [string]::IsNullOrEmpty($expectedTrader)) {
    Write-Output "Expected nearest trader placement: $expectedTrader ($expectedDistance m)"
}
