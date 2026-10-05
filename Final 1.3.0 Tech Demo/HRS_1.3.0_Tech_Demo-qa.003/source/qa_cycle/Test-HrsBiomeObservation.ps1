[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force

function Assert-Result([bool] $condition, [string] $label) {
    if (-not $condition) { throw "FAIL: $label" }
    Write-Output "PASS: $label"
}

$logFile = New-TemporaryFile
try {
    @'
INF [HRS] v=1.2.5 build=r125 reason=BIOME_SELECTED requested=Chosen:8:0:0:0:0:0 eligible=1,3,5,8,9 selected=8
INF [HRS] v=1.2.5 build=r125 reason=POI_ATTEMPT_SELECTED attempt=1 prefab=hotel_01 placedId=101 biome=8 origin=-40,47,300 size=30,14,24 rotation=1
INF [HRS] v=1.2.5 build=r125 reason=POI_RETRY
INF [HRS] v=1.2.5 build=r125 reason=POI_ATTEMPT_SELECTED attempt=2 prefab=hospital_01 placedId=102 biome=8 origin=-80,51,320 size=28,12,32 rotation=2
INF [HRS] v=1.2.5 build=r125 reason=CANDIDATE_SURFACE_SETTLED
INF [HRS] v=1.2.5 build=r125 reason=TRADER_ROUTE_SELECTED placedId=900 biome=8 crossBiome=0 origin=-100,51,330 size=24,10,24
INF [HRS] v=1.2.5 build=r125 reason=POI_LANDING_COMPLETED attempt=2 prefab=hospital_01 placedId=102 biome=8 position=-77.0,52.1,319.0
INF [HRS] v=1.2.5 build=r125 reason=RELOCATION_COMPLETED
'@ | Set-Content -LiteralPath $logFile.FullName -Encoding UTF8
    $events = @(Get-HrsQaRuntimeEvents -LogPath $logFile.FullName)
    $scope = [pscustomobject]@{
        selection = 'random-among-placed-world'
        worldCategories = @('Navezgane','RandomGen')
        minimumGeneratedWorldSize = 8192
        approvedPrefabNames = @('hotel_01','hospital_01')
        maxPoiAttempts = 5
        retryDelaySeconds = 3
        starterQuestId = 'quest_whiteRiverCitizen1'
    }
    $case = [pscustomobject]@{
        expectedSelection = 'Chosen'
        expectedChosenBiome = '8'
        expectedWorldCategory = 'RandomGen'
        requiresPlacedIdentity = $true
        requiresPlacedTrader = $true
    }
    $observation = [pscustomobject]@{
        schema = 'hrs-qa-observation/v2'
        worldCategory = 'RandomGen'
        worldName = 'Fixture County'
        gameName = 'HRS124_FIXTURE_01'
        worldSize = 8192
        landingResult = 'Safe'
        selectedPrefabName = 'hospital_01'
        placedInstanceId = '102'
        placedRotation = '2'
        startingBiome = '8'
        retryAttemptCount = 2
        selectedTraderPlacedId = '900'
        observedTraderBiome = '8'
        finalPosition = [pscustomobject]@{ x=-77.0; y=52.1; z=319.0 }
    }
    $valid = @(Test-HrsQaPlacedObservation -Events $events -Observation $observation -Scope $scope -Case $case)
    Assert-Result ($valid.Count -eq 0) 'two distinct same-biome attempts and placed trader agree with the log'

    $wrongWorld = $observation | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $wrongWorld.worldSize = 4096
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $events -Observation $wrongWorld -Scope $scope -Case $case) -contains 'WORLD_SIZE_OUTSIDE_RELEASE_SCOPE') 'undersized Random Gen world is rejected'

    $wrongPrefab = $observation | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $wrongPrefab.selectedPrefabName = 'hotel_01'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $events -Observation $wrongPrefab -Scope $scope -Case $case) -contains 'POI_LANDING_IDENTITY_MISMATCH') 'wrong final prefab is rejected'

    $wrongTrader = $observation | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $wrongTrader.selectedTraderPlacedId = '901'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $events -Observation $wrongTrader -Scope $scope -Case $case) -contains 'PLACED_TRADER_IDENTITY_MISMATCH') 'wrong placed trader is rejected'

    $wrongRetry = @($events | ForEach-Object { $_ | ConvertTo-Json -Depth 8 | ConvertFrom-Json })
    $wrongRetry[3].details.placedId = '101'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $wrongRetry -Observation $observation -Scope $scope -Case $case) -contains 'POI_RETRY_REUSED_INSTANCE') 'repeated placed instance is rejected'

    $wrongBiome = @($events | ForEach-Object { $_ | ConvertTo-Json -Depth 8 | ConvertFrom-Json })
    $wrongBiome[3].details.biome = '6'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $wrongBiome -Observation $observation -Scope $scope -Case $case) -contains 'POI_RETRY_BIOME_CHANGED') 'cross-biome retry is rejected'

    $wrongPosition = $observation | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $wrongPosition.finalPosition.x = -90.0
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $events -Observation $wrongPosition -Scope $scope -Case $case) -contains 'POI_LANDING_POSITION_MISMATCH') 'wrong landing position is rejected'

    Assert-Result ($events[0].details.selection -ceq 'Chosen' -and $events[0].details.eligible -ceq '1,3,5,8,9') 'sanitized draw fields survive evidence export'
    $case.expectedChosenBiome='1'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $events -Observation $observation -Scope $scope -Case $case) -contains 'BIOME_SELECTION_CHOSEN_MISMATCH') 'QA rejects incorrect chosen biome'
    $case.expectedChosenBiome='8'
    $withoutDraw=@($events | Select-Object -Skip 1)
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $withoutDraw -Observation $observation -Scope $scope -Case $case) -contains 'BIOME_SELECTION_EVIDENCE_MISSING') 'QA rejects missing draw evidence'

    $weightCase=$case | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $weightCase.PSObject.Properties.Remove('expectedChosenBiome')
    $weightCase.expectedSelection='Weighted'
    $weightCase | Add-Member -NotePropertyName expectedWeightFixture -NotePropertyValue 'Mixed'
    function New-WeightedEvents([int[]]$weights,[string]$eligible) {
        $copy=@($events | ForEach-Object { $_ | ConvertTo-Json -Depth 8 | ConvertFrom-Json })
        $copy[0].details.selection='Weighted'
        $copy[0].details.chosenBiome='0'
        $copy[0].details.weights=$weights
        $copy[0].details.eligible=$eligible
        return $copy
    }
    $mixed=New-WeightedEvents @(10,20,30,15,25) '1,3,5,8,9'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $mixed -Observation $observation -Scope $scope -Case $weightCase).Count -eq 0) 'distinct positive mixed weights pass their own fixture'
    $weightCase.expectedWeightFixture='ZeroExclusion'
    $zero=New-WeightedEvents @(0,20,20,20,40) '1,3,5,8,9'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $zero -Observation $observation -Scope $scope -Case $weightCase).Count -eq 0) 'eligible zero-weight exclusion passes its own fixture'
    $zeroSelected=New-WeightedEvents @(0,20,20,20,40) '1,3,5,8,9'
    $zeroSelected[0].details.selectedBiome='3'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $zeroSelected -Observation $observation -Scope $scope -Case $weightCase) -contains 'BIOME_SELECTION_WEIGHT_INVALID') 'selected zero-weight biome is rejected'
    $weightCase.expectedWeightFixture='SinglePositive'
    $single=New-WeightedEvents @(0,0,0,0,100) '1,3,5,8,9'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $single -Observation $observation -Scope $scope -Case $weightCase).Count -eq 0) 'single positive eligible biome passes its own fixture'
    $weightCase.expectedWeightFixture='AbsentRenormalized'
    $absent=New-WeightedEvents @(20,0,0,0,80) '1,5,8,9'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $absent -Observation $observation -Scope $scope -Case $weightCase).Count -eq 0) 'positive absent biome plus eligible weight passes renormalization fixture'
    foreach($other in @($mixed,$zero,$single)) {
        Assert-Result (@(Test-HrsQaPlacedObservation -Events $other -Observation $observation -Scope $scope -Case $weightCase) -contains 'BIOME_WEIGHT_FIXTURE_MISMATCH') 'another Weighted run cannot stand in for absent-renormalization evidence'
    }
} finally { Remove-Item -LiteralPath $logFile.FullName -Force }
