[CmdletBinding()]
param([string] $LaneRoot)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($LaneRoot)) {
    $LaneRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'hrs_1.2.4'
}
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
$sourceRoot = Join-Path $LaneRoot 'dev/src/runtime/main'
$poi = [IO.File]::ReadAllText((Join-Path $sourceRoot 'PlacedPoiResolver.cs'))
$trader = [IO.File]::ReadAllText((Join-Path $sourceRoot 'PlacedTraderResolver.cs'))
$pending = [IO.File]::ReadAllText((Join-Path $sourceRoot 'c0185.cs'))
$runtime = [IO.File]::ReadAllText((Join-Path $sourceRoot 'c0167.cs'))
$log = [IO.File]::ReadAllText((Join-Path $sourceRoot 'c0217.cs'))
$allowlist = [regex]::Match($poi,
    'HashSet<string> Names\s*=\s*new HashSet<string>\(StringComparer\.Ordinal\)\s*\{(?<body>[^}]+)\}',
    [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $allowlist.Success) { throw 'Fixture allowlist missing.' }
$names = @([regex]::Matches($allowlist.Groups['body'].Value,
    '"(?<name>[^"]+)"') | ForEach-Object { $_.Groups['name'].Value })

function Check([bool] $condition, [string] $label) {
    if (-not $condition) { throw "FAIL: $label" }
    Write-Output "PASS: $label"
}
function Validate($poiText, $traderText, $pendingText, $runtimeText,
    $logText, $contractNames, $maxAttempts, $retrySeconds) {
    return @(Test-HrsQaPlacedWorldScope -PoiSource $poiText `
        -TraderSource $traderText -PendingSource $pendingText `
        -RuntimeSource $runtimeText -LogSource $logText `
        -ApprovedPrefabNames $contractNames -MaxPoiAttempts $maxAttempts `
        -RetryDelaySeconds $retrySeconds -StarterQuestId 'quest_whiteRiverCitizen1')
}

$valid = Validate $poi $trader $pending $runtime $log $names 5 3
Check (@($valid | Where-Object severity -eq 'Error').Count -eq 0 -and
    @($valid | Where-Object severity -eq 'Pass').Count -eq 5) 'current placed-world source and contract agree'
$mismatch = Validate $poi $trader $pending $runtime $log @($names | Where-Object { $_ -cne 'hotel_01' }) 5 3
Check (@($mismatch | Where-Object code -eq 'PLACED_POI_ALLOWLIST' |
    Where-Object severity -eq 'Error').Count -eq 1) 'contract omitting a prefab is rejected'
$wrongApi = Validate ($poi.Replace('decorator.GetWorldPrefabs(placed)',
    'decorator.GetPOIPrefabs(placed)')) $trader $pending $runtime $log $names 5 3
Check (@($wrongApi | Where-Object code -eq 'PLACED_POI_SOURCE' |
    Where-Object severity -eq 'Error').Count -eq 1) 'quest-tagged prefab API is rejected'
$wrongLimit = Validate $poi $trader $pending $runtime $log $names 6 3
Check (@($wrongLimit | Where-Object code -eq 'PLACED_POI_RETRY' |
    Where-Object severity -eq 'Error').Count -eq 1) 'retry contract drift is rejected'
$wrongTrader = Validate $poi ($trader.Replace('instance.prefab.bTraderArea',
    'false')) $pending $runtime $log $names 5 3
Check (@($wrongTrader | Where-Object code -eq 'PLACED_TRADER_SOURCE' |
    Where-Object severity -eq 'Error').Count -eq 1) 'trader placement filter drift is rejected'
$missingIdentity = Validate $poi $trader $pending $runtime ($log.Replace(
    'reason=POI_LANDING_COMPLETED', 'reason=LANDING_WITHOUT_IDENTITY')) $names 5 3
Check (@($missingIdentity | Where-Object code -eq 'PLACED_IDENTITY_LOG' |
    Where-Object severity -eq 'Error').Count -eq 1) 'missing landing identity evidence is rejected'

$outRoot = [IO.Path]::GetFullPath((Join-Path $LaneRoot 'dev/out'))
$fixture = [IO.Path]::GetFullPath((Join-Path $outRoot ('placed-gate-fixture-' +
    [guid]::NewGuid().ToString('N'))))
if (-not $fixture.StartsWith($outRoot + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture path escaped output root.' }
try {
    $fixtureSource = Join-Path $fixture 'dev/src/runtime/main'
    $fixtureQa = Join-Path $fixture 'dev/qa'
    [void][IO.Directory]::CreateDirectory($fixtureSource)
    [void][IO.Directory]::CreateDirectory($fixtureQa)
    foreach ($file in @('PlacedPoiResolver.cs','PlacedTraderResolver.cs',
        'c0185.cs','c0167.cs','c0217.cs')) {
        [IO.File]::Copy((Join-Path $sourceRoot $file),
            (Join-Path $fixtureSource $file))
    }
    $scope = [pscustomobject]@{
        selection = 'random-among-placed-world'
        approvedPrefabNames = $names
        worldCategories = @('Navezgane','RandomGen')
        minimumGeneratedWorldSize = 8192
        maxPoiAttempts = 5
        retryDelaySeconds = 3
        starterQuestId = 'quest_whiteRiverCitizen1'
    }
    $release = [pscustomobject]@{
        schema = 'hrs-release/v1'
        version = '1.2.4'
        buildId = 'r124'
        sourceCommit = ('0' * 40)
        supportedEnvironment = [pscustomobject]@{
            assemblyCSharpMvid = '8576eaa1-7f2c-44dc-ba1b-e8b275a8aa62'
        }
        scope = $scope
        artifacts = @()
        runtimeLog = [pscustomobject]@{
            version = '1.2.4'
            buildId = 'r124-dev-i-exp33b14'
        }
    }
    $caseIds = @('HRS-QA-001','HRS-QA-002','HRS-QA-003A',
        'HRS-QA-003B','HRS-QA-004','HRS-QA-005','HRS-QA-006',
        'HRS-QA-007','HRS-QA-008')
    $cases = [pscustomobject]@{
        schema = 'hrs-qa-contract/v1'
        releaseVersion = '1.2.4'
        requiredCases = @($caseIds | ForEach-Object {
            [pscustomobject]@{ id = $_ }
        })
    }
    Write-HrsQaJson -Path (Join-Path $fixtureQa 'rel.json') -Value $release
    Write-HrsQaJson -Path (Join-Path $fixtureQa 'cases.json') -Value $cases
    $gate = Test-HrsQaRelease -LaneRoot $fixture
    Check (-not $gate.readyForQa -and
        @($gate.findings | Where-Object {
            $_.code -like 'PLACED_*' -and $_.severity -eq 'Pass'
        }).Count -eq 7) 'release gate executes the placed-world branch without accepting an unbuilt fixture'
    $scope.minimumGeneratedWorldSize = 4096
    Write-HrsQaJson -Path (Join-Path $fixtureQa 'rel.json') -Value $release
    $undersized = Test-HrsQaRelease -LaneRoot $fixture
    Check (@($undersized.findings | Where-Object {
        $_.code -eq 'PLACED_WORLD_SIZE' -and $_.severity -eq 'Error'
    }).Count -eq 1) 'release gate rejects a generated-world claim below 8K'
    $scope.minimumGeneratedWorldSize = 8192
    $scope.approvedPrefabNames = @($names | Where-Object { $_ -cne 'hotel_01' })
    Write-HrsQaJson -Path (Join-Path $fixtureQa 'rel.json') -Value $release
    $drift = Test-HrsQaRelease -LaneRoot $fixture
    Check (@($drift.findings | Where-Object {
        $_.code -eq 'PLACED_POI_ALLOWLIST' -and $_.severity -eq 'Error'
    }).Count -eq 1) 'release gate rejects an omitted prefab name'
}
finally {
    if ([IO.Directory]::Exists($fixture)) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}
