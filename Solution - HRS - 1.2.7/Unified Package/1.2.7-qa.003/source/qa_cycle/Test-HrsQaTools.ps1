[CmdletBinding()]
param([string] $LaneRoot = '')

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($LaneRoot)) {
    # The fixed-selector predecessor is a permanent negative regression fixture.
    $LaneRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'hrs_1.0.1'
}
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
$passed = 0

function Assert-HrsQa {
    param([bool] $Condition, [string] $Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:passed++
    Write-Output "PASS: $Name"
}

$scripts = Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Extension -in @('.ps1','.psm1') }
foreach ($script in $scripts) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors)
    Assert-HrsQa ($errors.Count -eq 0) "$($script.Name) parses"
}

$validation = Test-HrsQaRelease -LaneRoot $LaneRoot
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'ARTIFACT_IDENTITY' | Where-Object severity -eq 'Pass').Count -eq 1) 'verified artifacts match release record'
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'MODINFO_VERSION' | Where-Object severity -eq 'Pass').Count -eq 1) 'ModInfo version matches release record'
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'RUNTIME_LOG_IDENTITY' | Where-Object severity -eq 'Pass').Count -eq 1) 'runtime identity matches release record'
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'TRADER_CONTRACT' | Where-Object severity -eq 'Pass').Count -eq 1) 'trader and starter-quest markers remain present'
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'SPAWN_SELECTOR_FIXED' | Where-Object severity -eq 'Error').Count -eq 1) 'readiness gate detects fixed one-point selector'

$contract = Read-HrsQaJson -Path (Get-HrsQaLanePaths -LaneRoot $LaneRoot).ContractPath
Assert-HrsQa (@($contract.requiredCases).Count -eq 9) 'QA contract has all required cases'

$twoPointCatalog = @'
private static readonly int[] ApprovedPointIndices = { 0, 1 };
new CuratedStartPoint("NG01", "Snow one", -1, 80, 1),
new CuratedStartPoint("NG02", "Snow two", -2, 80, 2),
int approvedSlot = world.GetGameRandom().RandomRange(ApprovedPointIndices.Length);
int pointIndex = ApprovedPointIndices[approvedSlot];
'@
$twoPointScope = @(
    [pscustomobject]@{ id = 'NG01' },
    [pscustomobject]@{ id = 'NG02' }
)
$spawnValid = @(Test-HrsQaSpawnScope -Catalog $twoPointCatalog -ApprovedPoints $twoPointScope -Selection 'random-among-approved')
Assert-HrsQa ($spawnValid.Count -eq 1 -and $spawnValid[0].severity -eq 'Pass') 'spawn validator accepts matching two-point scope'
$spawnMismatch = @(Test-HrsQaSpawnScope -Catalog $twoPointCatalog -ApprovedPoints @(
    [pscustomobject]@{ id = 'NG01' }, [pscustomobject]@{ id = 'NG03' }
) -Selection 'random-among-approved')
Assert-HrsQa (@($spawnMismatch | Where-Object { $_.code -eq 'SPAWN_SELECTOR_SCOPE' -and $_.severity -eq 'Error' }).Count -eq 1) 'spawn validator rejects an unexpected declared point'
$spawnDuplicate = @(Test-HrsQaSpawnScope -Catalog ($twoPointCatalog -replace '\{ 0, 1 \}', '{ 0, 0 }') -ApprovedPoints $twoPointScope -Selection 'random-among-approved')
Assert-HrsQa (@($spawnDuplicate | Where-Object { $_.code -eq 'SPAWN_SELECTOR_SCOPE' -and $_.severity -eq 'Error' }).Count -eq 1) 'spawn validator rejects duplicate selected indices'
$malformed = @(Test-HrsQaSpawnScope -Catalog ($twoPointCatalog -replace '\{ 0, 1 \}', '{ 0 1 }') -ApprovedPoints $twoPointScope -Selection 'random-among-approved')
Assert-HrsQa (@($malformed | Where-Object severity -eq 'Error').Count -gt 0) 'spawn validator rejects malformed index lists'
$fullCatalog = @(Test-HrsQaSpawnScope -Catalog ($twoPointCatalog.Replace('RandomRange(ApprovedPointIndices.Length)','RandomRange(Points.Length)')) -ApprovedPoints $twoPointScope -Selection 'random-among-approved')
Assert-HrsQa (@($fullCatalog | Where-Object severity -eq 'Error').Count -gt 0) 'spawn validator rejects full-catalog RNG'
$badIndex = @(Test-HrsQaSpawnScope -Catalog ($twoPointCatalog.Replace('ApprovedPointIndices[approvedSlot]','ApprovedPointIndices[0]')) -ApprovedPoints $twoPointScope -Selection 'random-among-approved')
Assert-HrsQa (@($badIndex | Where-Object severity -eq 'Error').Count -gt 0) 'spawn validator rejects fixed index mapping'
$spawnOutOfRange = @(Test-HrsQaSpawnScope -Catalog ($twoPointCatalog -replace '\{ 0, 1 \}', '{ 0, 9 }') -ApprovedPoints $twoPointScope -Selection 'random-among-approved')
Assert-HrsQa (@($spawnOutOfRange | Where-Object { $_.code -eq 'SPAWN_SELECTOR_SCOPE' -and $_.severity -eq 'Error' }).Count -eq 1) 'spawn validator rejects an out-of-range index'
$eightyPointLines = (0..79 | ForEach-Object { 'new CuratedStartPoint("P{0}", "Point {0}", {0}, 80, {0}),' -f $_ }) -join "`n"
$eightyIndexList = (0..79) -join ', '
$eightyCatalog = @"
private static readonly int[] ApprovedPointIndices = { $eightyIndexList };
$eightyPointLines
int approvedSlot = world.GetGameRandom().RandomRange(ApprovedPointIndices.Length);
int pointIndex = ApprovedPointIndices[approvedSlot];
"@
$eightyScope = @(0..79 | ForEach-Object { [pscustomobject]@{ id = 'P' + $_ } })
$spawnEighty = @(Test-HrsQaSpawnScope -Catalog $eightyCatalog -ApprovedPoints $eightyScope -Selection 'random-among-approved')
Assert-HrsQa ($spawnEighty.Count -eq 1 -and $spawnEighty[0].severity -eq 'Pass') 'spawn validator accepts a matching 80-point scope'
$commentedWrongSelector = "// world.GetGameRandom().RandomRange(ApprovedPointIndices.Length);`n" + ($eightyCatalog -replace 'RandomRange\(ApprovedPointIndices.Length\)', 'RandomRange(1)')
$spawnCommentedWrong = @(Test-HrsQaSpawnScope -Catalog $commentedWrongSelector -ApprovedPoints $eightyScope -Selection 'random-among-approved')
Assert-HrsQa (@($spawnCommentedWrong | Where-Object { $_.code -eq 'SPAWN_SELECTOR_APPROVED' -and $_.severity -eq 'Error' }).Count -eq 1) 'spawn validator rejects a commented expected selector with a fixed draw'
$onePointDrawCatalog = $eightyCatalog -replace 'RandomRange\(ApprovedPointIndices.Length\)', 'RandomRange(1)'
$spawnOnePointDraw = @(Test-HrsQaSpawnScope -Catalog $onePointDrawCatalog -ApprovedPoints $eightyScope -Selection 'random-among-approved')
Assert-HrsQa (@($spawnOnePointDraw | Where-Object { $_.code -eq 'SPAWN_SELECTOR_APPROVED' -and $_.severity -eq 'Error' }).Count -eq 1) 'spawn validator rejects a fixed one-point draw'
$reserveCatalog = @'
private static readonly int[] ApprovedPointIndices = { 0, 1 };
new CuratedStartPoint("P0", "Point 0", 0, 80, 0),
new CuratedStartPoint("P1", "Point 1", 1, 80, 1),
new CuratedStartPoint("RESERVE", "Reserve", 2, 80, 2),
int approvedSlot = world.GetGameRandom().RandomRange(ApprovedPointIndices.Length);
int pointIndex = ApprovedPointIndices[approvedSlot];
'@
$reserveScope = @([pscustomobject]@{ id = 'P0' }, [pscustomobject]@{ id = 'P1' })
$reserveValidation = @(Test-HrsQaSpawnScope -Catalog $reserveCatalog -ApprovedPoints $reserveScope -Selection 'random-among-approved')
Assert-HrsQa ($reserveValidation.Count -eq 1 -and $reserveValidation[0].severity -eq 'Pass') 'reserve catalog entries do not expand declared release scope'

$tempRoot = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), 'hrs-qa-tools-' + [guid]::NewGuid().ToString('N'))
[void][System.IO.Directory]::CreateDirectory($tempRoot)
try {
    $cycleLane = Join-Path $tempRoot 'hrs_1.0.2'
    $cyclePayload = Join-Path $cycleLane 'dev\verified\main'
    [void][System.IO.Directory]::CreateDirectory($cyclePayload)
    $sourcePayload = Join-Path ([System.IO.Path]::GetFullPath($LaneRoot)) 'dev\verified\main'
    [System.IO.File]::Copy((Join-Path $sourcePayload 'd0163.dll'), (Join-Path $cyclePayload 'd0163.dll'), $false)
    [System.IO.File]::Copy((Join-Path $sourcePayload 'ModInfo.xml'), (Join-Path $cyclePayload 'ModInfo.xml'), $false)
    $cycleModInfo = Join-Path $cyclePayload 'ModInfo.xml'
    $cycleModInfoText = [System.IO.File]::ReadAllText($cycleModInfo).Replace('1.0.1', '1.0.2')
    [System.IO.File]::WriteAllText($cycleModInfo, $cycleModInfoText, (New-Object System.Text.UTF8Encoding($false)))
    $newCycleScript = Join-Path $PSScriptRoot 'New-HrsCycle.ps1'
    [void](& $newCycleScript -LaneRoot $cycleLane -TemplateLaneRoot $LaneRoot -Version 1.0.2 -BuildId r102 -SourceCommit ('a' * 40))
    $newRelease = Read-HrsQaJson -Path (Join-Path $cycleLane 'dev\qa\rel.json')
    $newContract = Read-HrsQaJson -Path (Join-Path $cycleLane 'dev\qa\cases.json')
    Assert-HrsQa ([string]$newRelease.version -ceq '1.0.2' -and [string]$newRelease.buildId -ceq 'r102') 'new cycle initializes release identity'
    Assert-HrsQa ([string]$newContract.releaseVersion -ceq '1.0.2') 'new cycle initializes QA contract identity'
    Assert-HrsQa ([string]$newRelease.artifacts[0].sha256 -ceq (Get-HrsQaSha256 -Path (Join-Path $cyclePayload 'd0163.dll'))) 'new cycle computes artifact identity'

    $identityLane = Join-Path $tempRoot 'identity-fixtures'
    Copy-Item -LiteralPath $LaneRoot -Destination $identityLane -Recurse
    $identityReleasePath = Join-Path $identityLane 'dev\qa\rel.json'
    $identityRelease = Read-HrsQaJson -Path $identityReleasePath
    $identityRelease.artifacts[0].sha256 = ('0' * 64) -join ''
    Write-HrsQaJson -Path $identityReleasePath -Value $identityRelease
    $alteredValidation = Test-HrsQaRelease -LaneRoot $identityLane
    Assert-HrsQa (@($alteredValidation.findings | Where-Object { $_.code -eq 'ARTIFACT_HASH' }).Count -eq 1 -and
        @($alteredValidation.findings | Where-Object { $_.code -eq 'ARTIFACT_IDENTITY' -and $_.severity -eq 'Pass' }).Count -eq 0) 'artifact hash failure cannot emit identity PASS'

    $identityRelease = Read-HrsQaJson -Path $identityReleasePath
    $identityRelease.artifacts[0].path = 'dev/verified/main/missing.dll'
    Write-HrsQaJson -Path $identityReleasePath -Value $identityRelease
    $missingValidation = Test-HrsQaRelease -LaneRoot $identityLane
    Assert-HrsQa (@($missingValidation.findings | Where-Object { $_.code -eq 'ARTIFACT_MISSING' }).Count -eq 1 -and
        @($missingValidation.findings | Where-Object { $_.code -eq 'ARTIFACT_IDENTITY' -and $_.severity -eq 'Pass' }).Count -eq 0) 'missing artifact cannot emit identity PASS'

    $identityRelease = Read-HrsQaJson -Path $identityReleasePath
    $identityRelease.artifacts[1].path = $identityRelease.artifacts[0].path
    Write-HrsQaJson -Path $identityReleasePath -Value $identityRelease
    $duplicateValidation = Test-HrsQaRelease -LaneRoot $identityLane
    Assert-HrsQa (@($duplicateValidation.findings | Where-Object { $_.code -eq 'ARTIFACT_DUPLICATE' }).Count -eq 1 -and
        @($duplicateValidation.findings | Where-Object { $_.code -eq 'ARTIFACT_IDENTITY' -and $_.severity -eq 'Pass' }).Count -eq 0) 'duplicate artifact path cannot emit identity PASS'

    $identityRelease = Read-HrsQaJson -Path $identityReleasePath
    $identityRelease.artifacts[0].path = '../escape.dll'
    Write-HrsQaJson -Path $identityReleasePath -Value $identityRelease
    $unsafeValidation = Test-HrsQaRelease -LaneRoot $identityLane
    Assert-HrsQa (@($unsafeValidation.findings | Where-Object { $_.code -eq 'ARTIFACT_PATH' }).Count -eq 1 -and
        @($unsafeValidation.findings | Where-Object { $_.code -eq 'ARTIFACT_IDENTITY' -and $_.severity -eq 'Pass' }).Count -eq 0) 'unsafe artifact path cannot emit identity PASS'

    $startScript = Join-Path $PSScriptRoot 'Start-HrsQaRun.ps1'
    $qaStartBlocked = $false
    try { [void](& $startScript -CaseId HRS-QA-001 -Mode NotApplicable -LaneRoot $LaneRoot -RunRoot $tempRoot) }
    catch { $qaStartBlocked = $_.Exception.Message -like 'HRS_RELEASE_NOT_READY_FOR_QA*' }
    Assert-HrsQa $qaStartBlocked 'QA run start is blocked while readiness errors remain'
    $startOutput = @(& $startScript -CaseId HRS-QA-001 -Mode NotApplicable -LaneRoot $LaneRoot -RunRoot $tempRoot -AllowDevelopmentGap)
    $runPathLine = @($startOutput | Where-Object { $_ -like 'Evidence path:*' })
    Assert-HrsQa ($runPathLine.Count -eq 1) 'DEV evidence run starts'
    $runPath = ([string]$runPathLine[0]).Substring('Evidence path:'.Length).Trim()
    Assert-HrsQa ([System.IO.File]::Exists((Join-Path $runPath 'session.local.json'))) 'local session is retained outside export'

    $observationScript = Join-Path $PSScriptRoot 'Record-HrsQaObservation.ps1'
    [void](& $observationScript -RunPath $runPath -SelectedPointId NG01 -FinalX -1528 -FinalY 74 -FinalZ 1700 -LandingResult Safe -SelectedTraderPlacement TP02 -QuestDestinationResult Confirmed -StarterQuestProgression Works)
    $observation = Read-HrsQaJson -Path (Join-Path $runPath 'qa-observation.json')
    Assert-HrsQa ([string]$observation.expectedNearestTraderPlacement -ceq 'TP02' -and $observation.nearestTraderMatches -eq $true) 'observation calculates and confirms nearest trader'

    $exportScript = Join-Path $PSScriptRoot 'Export-HrsQaRun.ps1'
    [void](& $exportScript -RunPath $runPath -Outcome Pass -Kind DEV -Notes 'Automated tooling test.')
    $zipPath = $runPath + '.zip'
    Assert-HrsQa ([System.IO.File]::Exists($zipPath)) 'evidence ZIP is created'

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try { $entryNames = @($zip.Entries | ForEach-Object { $_.FullName }) }
    finally { $zip.Dispose() }
    Assert-HrsQa ($entryNames -cnotcontains 'session.local.json') 'private local session is excluded from ZIP'
    Assert-HrsQa ($entryNames -ccontains 'release-validation.json') 'release validation is included'
    Assert-HrsQa ($entryNames -ccontains 'evidence-manifest.json') 'evidence manifest is included'
    Assert-HrsQa ($entryNames -ccontains 'qa-result.json') 'QA result is included'
    Assert-HrsQa ($entryNames -ccontains 'qa-observation.json') 'bounded QA observation is included'

    $completeScript = Join-Path $PSScriptRoot 'Complete-HrsQaCycle.ps1'
    [void](& $completeScript -Decision Reject -LaneRoot $LaneRoot -RunRoot $tempRoot -ApproverRole ReleaseOwner -Notes 'Automated tooling test rejection.')
    $decisionFiles = @(Get-ChildItem -LiteralPath (Join-Path $tempRoot '1.0.1') -File -Filter 'cycle-*.json')
    Assert-HrsQa ($decisionFiles.Count -eq 1) 'cycle rejection record is created'
    $approvalBlocked = $false
    try { [void](& $completeScript -Decision Approve -LaneRoot $LaneRoot -RunRoot $tempRoot -ApproverRole ReleaseOwner) }
    catch { $approvalBlocked = $_.Exception.Message -like 'HRS_QA_APPROVAL_BLOCKED*' }
    Assert-HrsQa $approvalBlocked 'cycle approval is blocked by readiness and missing QA cases'
    # Simulate pre-candidate-schema QA evidence. These records remain in tempRoot.
    $legacyOutput = @(& $startScript -CaseId HRS-QA-001 -Mode NotApplicable -LaneRoot $LaneRoot -RunRoot $tempRoot -AllowDevelopmentGap)
    $legacyPath = ([string]@($legacyOutput | Where-Object { $_ -like 'Evidence path:*' })[0]).Substring(14).Trim()
    $legacyRun = Read-HrsQaJson (Join-Path $legacyPath 'run.json')
    $legacyRun.phase = 'QA'
    foreach ($property in @('candidateId','candidateArchiveSha256','contractSha256')) { $legacyRun.PSObject.Properties.Remove($property) }
    Write-HrsQaJson (Join-Path $legacyPath 'run.json') $legacyRun
    $emptyLog = Join-Path $tempRoot 'legacy-empty.log'
    [IO.File]::WriteAllText($emptyLog,'')
    [void](& $exportScript -RunPath $legacyPath -Outcome Pass -Kind QA -LogPath $emptyLog -Notes 'Synthetic legacy schema fixture')
    [void](& $completeScript -Decision Reject -LaneRoot $LaneRoot -RunRoot $tempRoot)
    $latestDecision = @(Get-ChildItem -LiteralPath (Join-Path $tempRoot '1.0.1') -Filter 'cycle-*.json' | Sort-Object LastWriteTimeUtc -Descending)[0]
    $decision = Read-HrsQaJson $latestDecision.FullName
    Assert-HrsQa (@($decision.coverage | Where-Object { $_.caseId -ceq 'HRS-QA-001' -and $_.covered }).Count -eq 1) 'legacy evidence without candidate fields remains eligible'

    $legacyOutput = @(& $startScript -CaseId HRS-QA-003A -Mode Random -LaneRoot $LaneRoot -RunRoot $tempRoot -AllowDevelopmentGap)
    $legacyPath = ([string]@($legacyOutput | Where-Object { $_ -like 'Evidence path:*' })[0]).Substring(14).Trim()
    $legacyRun = Read-HrsQaJson (Join-Path $legacyPath 'run.json')
    $legacyObs = [pscustomobject]@{schema='hrs-qa-observation/v1';runId=$legacyRun.runId;caseId=$legacyRun.caseId;selectedPointId='NG02';landingResult='Safe'}
    Write-HrsQaJson (Join-Path $legacyPath 'qa-observation.json') $legacyObs
    [void](& $exportScript -RunPath $legacyPath -Outcome Pass -Kind DEV -LogPath $emptyLog)
    $legacyResult = Read-HrsQaJson (Join-Path $legacyPath 'qa-result.json')
    Assert-HrsQa (@($legacyResult.observationIssues) -contains 'HISTORICAL_POINT_NOT_OBSERVED') 'historical point mismatch is rejected'
}
finally {
    $resolvedTemp = [System.IO.Path]::GetFullPath($tempRoot)
    $systemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedTemp.StartsWith($systemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and
        [System.IO.Directory]::Exists($resolvedTemp)) {
        [System.IO.Directory]::Delete($resolvedTemp, $true)
    }
}

Write-Output "HRS QA-cycle tooling tests passed: $passed/$passed"
