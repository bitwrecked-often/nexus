[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $RunPath,
    [ValidateSet('NG01', 'NG02', 'NotObserved', 'NotApplicable')] [string] $SelectedPointId = 'NotObserved',
    [double] $FinalX = [double]::NaN,
    [double] $FinalY = [double]::NaN,
    [double] $FinalZ = [double]::NaN,
    [ValidateSet('Safe', 'Unsafe', 'NotObserved', 'NotApplicable')] [string] $LandingResult = 'NotObserved',
    [ValidateSet('TP01', 'TP02', 'TP03', 'TP04', 'TP05', 'NotObserved', 'NotApplicable')] [string] $SelectedTraderPlacement = 'NotObserved',
    [ValidateSet('Confirmed', 'NotConfirmed', 'NotObserved', 'NotApplicable')] [string] $QuestDestinationResult = 'NotObserved',
    [ValidateSet('Works', 'Failed', 'NotObserved', 'NotApplicable')] [string] $StarterQuestProgression = 'NotObserved',
    [ValidateSet('NoRelocation', 'RelocatedAgain', 'NotObserved', 'NotApplicable')] [string] $ReloadResult = 'NotObserved'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force

$path = [System.IO.Path]::GetFullPath($RunPath)
$run = Read-HrsQaJson -Path (Join-Path $path 'run.json')
$release = Read-HrsQaJson -Path (Join-Path $path 'release.json')
if ([string]$run.status -cne 'Started') { throw 'HRS_QA_OBSERVATION_RUN_NOT_ACTIVE' }

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
if ($hasPosition) {
    $best = [double]::MaxValue
    foreach ($trader in @($release.scope.reviewedTraderPlacements)) {
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
    schema = 'hrs-qa-observation/v1'
    runId = [string]$run.runId
    caseId = [string]$run.caseId
    observedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    selectedPointId = $SelectedPointId
    finalPosition = $(if ($hasPosition) { [pscustomobject][ordered]@{ x=$FinalX; y=$FinalY; z=$FinalZ } } else { $null })
    landingResult = $LandingResult
    selectedTraderPlacement = $SelectedTraderPlacement
    expectedNearestTraderPlacement = $expectedTrader
    expectedNearestTraderDistanceMeters = $expectedDistance
    nearestTraderMatches = $nearestMatches
    questDestinationResult = $QuestDestinationResult
    starterQuestProgression = $StarterQuestProgression
    reloadResult = $ReloadResult
}
Write-HrsQaJson -Path (Join-Path $path 'qa-observation.json') -Value $observation
Write-Output "QA observation recorded for $($run.runId)"
if (-not [string]::IsNullOrEmpty($expectedTrader)) {
    Write-Output "Expected nearest trader placement: $expectedTrader ($expectedDistance m)"
}
