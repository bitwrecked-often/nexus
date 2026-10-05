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
INF [HRS] v=1.2.4 build=r124 reason=POI_ATTEMPT_SELECTED attempt=1 prefab=hotel_01 placedId=101 biome=8 origin=-40,47,300 size=30,14,24 rotation=1
INF [HRS] v=1.2.4 build=r124 reason=POI_RETRY
INF [HRS] v=1.2.4 build=r124 reason=POI_ATTEMPT_SELECTED attempt=2 prefab=hospital_01 placedId=102 biome=8 origin=-80,51,320 size=28,12,32 rotation=2
INF [HRS] v=1.2.4 build=r124 reason=CANDIDATE_SURFACE_SETTLED
INF [HRS] v=1.2.4 build=r124 reason=TRADER_ROUTE_SELECTED placedId=900 biome=8 crossBiome=0 origin=-100,51,330 size=24,10,24
INF [HRS] v=1.2.4 build=r124 reason=POI_LANDING_COMPLETED attempt=2 prefab=hospital_01 placedId=102 biome=8 position=-77.0,52.1,319.0
INF [HRS] v=1.2.4 build=r124 reason=RELOCATION_COMPLETED
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
    $wrongRetry[2].details.placedId = '101'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $wrongRetry -Observation $observation -Scope $scope -Case $case) -contains 'POI_RETRY_REUSED_INSTANCE') 'repeated placed instance is rejected'

    $wrongBiome = @($events | ForEach-Object { $_ | ConvertTo-Json -Depth 8 | ConvertFrom-Json })
    $wrongBiome[2].details.biome = '6'
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $wrongBiome -Observation $observation -Scope $scope -Case $case) -contains 'POI_RETRY_BIOME_CHANGED') 'cross-biome retry is rejected'

    $wrongPosition = $observation | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $wrongPosition.finalPosition.x = -90.0
    Assert-Result (@(Test-HrsQaPlacedObservation -Events $events -Observation $wrongPosition -Scope $scope -Case $case) -contains 'POI_LANDING_POSITION_MISMATCH') 'wrong landing position is rejected'

    # Exercise the real recorder and exporter, not only the pure comparison.
    $outRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../hrs_1.2.4/dev/out'))
    $fixtureRoot = [IO.Path]::GetFullPath((Join-Path $outRoot ('placed-observation-fixture-' + [guid]::NewGuid().ToString('N'))))
    if (-not $fixtureRoot.StartsWith($outRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture path escaped the intended output root.' }
    try {
        $lane = Join-Path $fixtureRoot 'lane'
        $qa = Join-Path $lane 'dev/qa'
        [void][IO.Directory]::CreateDirectory($qa)
        $release = [pscustomobject]@{
            schema = 'hrs-release/v1'
            version = '1.2.4'
            buildId = 'r124'
            sourceCommit = ('0' * 40)
            supportedEnvironment = [pscustomobject]@{ assemblyCSharpMvid = '00000000-0000-0000-0000-000000000000' }
            scope = $scope
            artifacts = @()
            runtimeLog = [pscustomobject]@{ version='1.2.4'; buildId='r124' }
        }
        $caseRecord = [pscustomobject]@{
            id = 'HRS-QA-003B'
            title = 'Placed-world fixture'
            requirement = 'Dynamic identity agrees with the log.'
            expectedEvents = @('POI_ATTEMPT_SELECTED','POI_LANDING_COMPLETED','RELOCATION_COMPLETED')
            forbiddenEvents = @('INTERNAL_FAILURE')
            requiredEvidence = @('runtime-events','qa-observation')
            status = 'Pending'
            expectedWorldCategory = 'RandomGen'
            requiresPlacedIdentity = $true
            requiresPlacedTrader = $true
        }
        $qaContract = [pscustomobject]@{
            schema = 'hrs-qa-contract/v1'
            releaseVersion = '1.2.4'
            requiredCases = @($caseRecord)
        }
        Write-HrsQaJson -Path (Join-Path $qa 'rel.json') -Value $release
        Write-HrsQaJson -Path (Join-Path $qa 'cases.json') -Value $qaContract
        [IO.File]::WriteAllText($logFile.FullName, '')
        $start = @(& (Join-Path $PSScriptRoot 'Start-HrsQaRun.ps1') -CaseId 'HRS-QA-003B' `
            -Mode Random -LaneRoot $lane -RunRoot (Join-Path $fixtureRoot 'runs') `
            -LogPath $logFile.FullName -AllowDevelopmentGap 3>$null)
        $pathLine = @($start | Where-Object { $_ -like 'Evidence path:*' })
        Assert-Result ($pathLine.Count -eq 1) 'placed-world fixture starts through the real QA run command'
        $runPath = ([string]$pathLine[0]).Substring('Evidence path:'.Length).Trim()
        [IO.File]::WriteAllLines($logFile.FullName, @(
            'INF [HRS] v=1.2.4 build=r124 reason=POI_ATTEMPT_SELECTED attempt=1 prefab=hotel_01 placedId=101 biome=8 origin=-40,47,300 size=30,14,24 rotation=1',
            'INF [HRS] v=1.2.4 build=r124 reason=POI_RETRY',
            'INF [HRS] v=1.2.4 build=r124 reason=POI_ATTEMPT_SELECTED attempt=2 prefab=hospital_01 placedId=102 biome=8 origin=-80,51,320 size=28,12,32 rotation=2',
            'INF [HRS] v=1.2.4 build=r124 reason=TRADER_ROUTE_SELECTED placedId=900 biome=8 crossBiome=0 origin=-100,51,330 size=24,10,24',
            'INF [HRS] v=1.2.4 build=r124 reason=POI_LANDING_COMPLETED attempt=2 prefab=hospital_01 placedId=102 biome=8 position=-77.0,52.1,319.0',
            'INF [HRS] v=1.2.4 build=r124 reason=RELOCATION_COMPLETED'
        ))
        [void](& (Join-Path $PSScriptRoot 'Record-HrsQaObservation.ps1') -RunPath $runPath `
            -WorldCategory RandomGen -WorldName 'Fixture County' -GameName HRS124_FIXTURE_01 `
            -WorldSize 8192 -SelectedPrefabName hospital_01 -PlacedInstanceId 102 `
            -PlacedRotation 2 -StartingBiome 8 -RetryAttemptCount 2 `
            -SelectedTraderPlacedId 900 -ObservedTraderBiome 8 -LandingResult Safe `
            -FinalX -77.0 -FinalY 52.1 -FinalZ 319.0)
        [void](& (Join-Path $PSScriptRoot 'Export-HrsQaRun.ps1') -RunPath $runPath `
            -Outcome Pass -Kind DEV -LogPath $logFile.FullName)
        $qaResult = Read-HrsQaJson -Path (Join-Path $runPath 'qa-result.json')
        Assert-Result ([string]$qaResult.automatedEventAssessment -ceq 'Consistent') 'real QA exporter accepts matching dynamic world and placement evidence'

        foreach ($scenario in @('wrong-world','wrong-prefab','wrong-trader','wrong-retry')) {
            [IO.File]::WriteAllText($logFile.FullName, '')
            $nextStart = @(& (Join-Path $PSScriptRoot 'Start-HrsQaRun.ps1') -CaseId 'HRS-QA-003B' `
                -Mode Random -LaneRoot $lane -RunRoot (Join-Path $fixtureRoot 'runs') `
                -LogPath $logFile.FullName -AllowDevelopmentGap 3>$null)
            $nextLine = @($nextStart | Where-Object { $_ -like 'Evidence path:*' })
            $nextPath = ([string]$nextLine[0]).Substring('Evidence path:'.Length).Trim()
            $nextLines = @(
                'INF [HRS] v=1.2.4 build=r124 reason=POI_ATTEMPT_SELECTED attempt=1 prefab=hotel_01 placedId=101 biome=8 origin=-40,47,300 size=30,14,24 rotation=1',
                'INF [HRS] v=1.2.4 build=r124 reason=POI_RETRY',
                'INF [HRS] v=1.2.4 build=r124 reason=POI_ATTEMPT_SELECTED attempt=2 prefab=hospital_01 placedId=102 biome=8 origin=-80,51,320 size=28,12,32 rotation=2',
                'INF [HRS] v=1.2.4 build=r124 reason=TRADER_ROUTE_SELECTED placedId=900 biome=8 crossBiome=0 origin=-100,51,330 size=24,10,24',
                'INF [HRS] v=1.2.4 build=r124 reason=POI_LANDING_COMPLETED attempt=2 prefab=hospital_01 placedId=102 biome=8 position=-77.0,52.1,319.0',
                'INF [HRS] v=1.2.4 build=r124 reason=RELOCATION_COMPLETED'
            )
            $recordArgs = @{
                RunPath = $nextPath; WorldCategory = 'RandomGen'; WorldName = 'Fixture County'
                GameName = 'HRS124_FIXTURE_01'; WorldSize = 8192
                SelectedPrefabName = 'hospital_01'; PlacedInstanceId = '102'
                PlacedRotation = '2'; StartingBiome = '8'; RetryAttemptCount = 2
                SelectedTraderPlacedId = '900'; ObservedTraderBiome = '8'
                LandingResult = 'Safe'; FinalX = -77.0; FinalY = 52.1; FinalZ = 319.0
            }
            switch ($scenario) {
                'wrong-world' { $recordArgs.WorldSize = 4096 }
                'wrong-prefab' { $recordArgs.SelectedPrefabName = 'hotel_01' }
                'wrong-trader' { $recordArgs.SelectedTraderPlacedId = '901' }
                'wrong-retry' { $nextLines[2] = $nextLines[2].Replace('placedId=102','placedId=101') }
            }
            [IO.File]::WriteAllLines($logFile.FullName, $nextLines)
            [void](& (Join-Path $PSScriptRoot 'Record-HrsQaObservation.ps1') @recordArgs)
            [void](& (Join-Path $PSScriptRoot 'Export-HrsQaRun.ps1') -RunPath $nextPath `
                -Outcome Fail -Kind DEV -LogPath $logFile.FullName)
            $nextResult = Read-HrsQaJson -Path (Join-Path $nextPath 'qa-result.json')
            Assert-Result ([string]$nextResult.automatedEventAssessment -ceq 'Mismatch') "real QA exporter rejects $scenario evidence"
        }
    }
    finally {
        if ([IO.Directory]::Exists($fixtureRoot)) {
            Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
        }
    }
}
finally { Remove-Item -LiteralPath $logFile.FullName -Force }
