[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $LaneRoot,
    [Parameter(Mandatory = $true)] [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+-qa\.[0-9]{3}$')] [string] $CandidateId,
    [Parameter(Mandatory = $true)] [ValidatePattern('^[0-9a-f]{40}$')] [string] $SourceCommit
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force

$root = [System.IO.Path]::GetFullPath($LaneRoot).TrimEnd('\','/')
$registry = Read-HrsQaJson (Join-Path $PSScriptRoot 'candidate-registry.json')
if (@($registry.records | Where-Object { $_.candidateId -ceq $CandidateId }).Count) { throw 'HRS_CANDIDATE_ID_ALREADY_EXPORTED' }
$source = Join-Path $root 'dev\src\runtime\main'
$catalogPath = Join-Path $source 'c0213.cs'
$runtimePath = Join-Path $source 'c0167.cs'
$logPath = Join-Path $source 'c0217.cs'
$payload = Join-Path $root 'dev\verified\main'
$releasePath = Join-Path $root 'dev\qa\rel.json'
$contractPath = Join-Path $root 'dev\qa\cases.json'
$buildRecordPath = Resolve-HrsContainedFile $root ("dev/builds/$CandidateId/build-record.json")
$buildRecordDigest = Get-HrsQaSha256 $buildRecordPath
foreach ($path in @($catalogPath, $runtimePath, $logPath,
        (Join-Path $payload 'd0163.dll'), (Join-Path $payload 'ModInfo.xml'))) {
    if (-not [System.IO.File]::Exists($path)) { throw "HRS123_REQUIRED_FILE_MISSING: $path" }
}

$catalog = [System.IO.File]::ReadAllText($catalogPath)
$pointMatches = [regex]::Matches($catalog, 'new CuratedStartPoint\("([^"]+)",\s*"([^"]+)",\s*(-?\d+),\s*(-?\d+),\s*(-?\d+)\)')
$points = @($pointMatches | ForEach-Object {
    [pscustomobject][ordered]@{
        id = [string]$_.Groups[1].Value
        description = [string]$_.Groups[2].Value
        x = [int]$_.Groups[3].Value
        y = [int]$_.Groups[4].Value
        z = [int]$_.Groups[5].Value
    }
})
$arrayMatch = [regex]::Match($catalog, 'ApprovedPointIndices\s*=\s*\{(?<values>[^}]*)\}', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $arrayMatch.Success) { throw 'HRS123_SELECTOR_ALLOWLIST_MISSING' }
$indices = @([regex]::Matches($arrayMatch.Groups['values'].Value, '-?\d+') | ForEach-Object { [int]$_.Value })
if ($indices.Count -ne 80 -or @($indices | Sort-Object -Unique).Count -ne 80) { throw 'HRS123_SELECTOR_SCOPE_NOT_80_UNIQUE_INDICES' }
$approved = @($indices | ForEach-Object {
    if ($_ -lt 0 -or $_ -ge $points.Count) { throw "HRS123_SELECTOR_INDEX_OUT_OF_RANGE: $_" }
    $point = $points[$_]
    [pscustomobject][ordered]@{
        id = $point.id
        description = $point.description
        x = $point.x
        y = $point.y
        z = $point.z
        catalogIndex = $_
    }
})
if (@($approved.id | Where-Object { $_ -match '^NG0[1-9]$|^NG1[0-2]$' }).Count -gt 0) { throw 'HRS123_SURVEY_POINT_SELECTED' }

$artifactDll = Join-Path $payload 'd0163.dll'
$artifactMod = Join-Path $payload 'ModInfo.xml'
$dllInfo = New-Object System.IO.FileInfo($artifactDll)
$modInfo = New-Object System.IO.FileInfo($artifactMod)
$runtimeHash = Get-HrsQaSha256 -Path $artifactDll
$modHash = Get-HrsQaSha256 -Path $artifactMod
$sourceFiles = @('c0140.cs','c0147.cs','c0167.cs','c0181.cs','c0184.cs','c0185.cs','PolicyV1.cs','ResultV1.cs','c0213.cs','c0217.cs','c0218.cs')
$sourceHashes = @($sourceFiles | ForEach-Object { [pscustomobject][ordered]@{ path = $_; sha256 = Get-HrsQaSha256 -Path (Join-Path $source $_) } })
$traders = @(
    [pscustomobject][ordered]@{ id='TP01'; biome='desert'; x=971; z=-1536; sourceX=941; sourceZ=-1566; sizeX=60; sizeZ=60 },
    [pscustomobject][ordered]@{ id='TP02'; biome='snow'; x=-927; z=1747; sourceX=-957; sourceZ=1717; sizeX=60; sizeZ=60 },
    [pscustomobject][ordered]@{ id='TP03'; biome='burnt_forest'; x=220; z=-114; sourceX=190; sourceZ=-144; sizeX=60; sizeZ=60 },
    [pscustomobject][ordered]@{ id='TP04'; biome='wasteland'; x=-1556; z=-1185; sourceX=-1586; sourceZ=-1215; sizeX=60; sizeZ=60 },
    [pscustomobject][ordered]@{ id='TP05'; biome='pine_forest'; x=458; z=674; sourceX=428; sourceZ=644; sizeX=60; sizeZ=60 }
)
$release = [pscustomobject][ordered]@{
    schema='hrs-release/v1'; product='Historical Random Start'; version='1.2.3'; buildId='r123'; candidateId=$CandidateId
    releaseDate=[datetime]::UtcNow.ToString('yyyy-MM-dd'); sourceCommit=$SourceCommit; laneStatus='candidate-development'
    sourceSnapshot=[pscustomobject][ordered]@{ state='working-tree-snapshot'; runtimeSource='dev/src/runtime/main'; sourceHashes=$sourceHashes }
    supportedEnvironment=[pscustomobject][ordered]@{ game='7 Days to Die'; gameVersion='V3.2 (b9)'; world='Navezgane'; playMode='local-single-player'; antiCheat='disabled'; assemblyCSharpMvid='229796d0-95ca-4662-b426-1a6f1f1596ed' }
    scope=[pscustomobject][ordered]@{
        approvedSpawnPoints=$approved; selection='random-among-approved'; landing='runtime terrain resolution and safe-landing verification';
        nearestTraderRouting=$true; traderRoutingScope='same-starting-biome'; starterQuestId='quest_whiteRiverCitizen1'; starterQuestPhase=1;
        reviewedTraderPlacements=$traders; oneShotRelocation=$true; standardModeUnchanged=$true
    }
    artifacts=@(
        [pscustomobject][ordered]@{ path='dev/verified/main/d0163.dll'; bytes=[UInt64]$dllInfo.Length; sha256=$runtimeHash; assemblyName='d0163'; assemblyVersion='0.0.0.0' },
        [pscustomobject][ordered]@{ path='dev/verified/main/ModInfo.xml'; bytes=[UInt64]$modInfo.Length; sha256=$modHash }
    )
    build=[pscustomobject][ordered]@{ candidateId=$CandidateId; recordPath="dev/builds/$CandidateId/build-record.json"; recordSha256=$buildRecordDigest; deterministicDoubleBuild=$true; status='built-from-current-lane' }
    package=[pscustomobject][ordered]@{ archivePath=''; archiveSha256=''; status='not-exported' }
    runtimeLog=[pscustomobject][ordered]@{ prefix='[HRS]'; version='1.2.3'; buildId='r123'; maximumEvents=32 }
    releaseRules=[pscustomobject][ordered]@{ immutableAfterQaStart=$true; promoteExactTestedBytes=$true; qaMayRepairCandidate=$false; evidenceRequiredForApproval=$true }
}
$pointIds = @($approved | ForEach-Object { [string]$_.id })
$cases = @(
    [pscustomobject][ordered]@{ id='HRS-QA-001'; title='Package identity'; requirement='Every candidate artifact, version label, runtime identity and manager pin agrees with the 1.2.3 contract.'; expectedEvents=@(); requiredEvidence=@('release-validation','package-inventory'); status='Pending' },
    [pscustomobject][ordered]@{ id='HRS-QA-002'; title='Standard-mode control'; requirement='Standard mode preserves normal spawn and performs no HRS relocation or trader mutation.'; expectedEvents=@('RUNTIME_READY','STANDARD_BYPASS'); forbiddenEvents=@('PLACEMENT_CALLED','TRADER_ROUTE_SELECTED'); requiredEvidence=@('runtime-events','result-summary'); status='Pending' },
    [pscustomobject][ordered]@{ id='HRS-QA-003A'; title='Random landing sample A'; requirement='A fresh Random game selects one declared production point and completes safe one-shot relocation.'; expectedEvents=@('RUNTIME_READY','PLACEMENT_CALLED','SEMANTIC_UNCHANGED','RELOCATION_COMPLETED'); forbiddenEvents=@('TRADER_ROUTE_FALLBACK','INTERNAL_FAILURE'); expectedPointIds=$pointIds; requiredEvidence=@('runtime-events','result-summary','installed-after','qa-observation'); status='Pending' },
    [pscustomobject][ordered]@{ id='HRS-QA-003B'; title='Random landing sample B'; requirement='A second fresh Random game selects one declared production point and completes safe one-shot relocation.'; expectedEvents=@('RUNTIME_READY','PLACEMENT_CALLED','SEMANTIC_UNCHANGED','RELOCATION_COMPLETED'); forbiddenEvents=@('TRADER_ROUTE_FALLBACK','INTERNAL_FAILURE'); expectedPointIds=$pointIds; requiredEvidence=@('runtime-events','result-summary','installed-after','qa-observation'); status='Pending' },
    [pscustomobject][ordered]@{ id='HRS-QA-004'; title='Same-starting-biome trader routing'; requirement='The opening trader is selected from the starting biome by planar distance.'; expectedEvents=@('TRADER_ROUTE_READY','TRADER_ROUTE_RESERVED','TRADER_ROUTE_SELECTED','TRADER_ROUTE_COMPLETED'); forbiddenEvents=@('TRADER_ROUTE_FALLBACK'); traderRoutingScope='same-starting-biome'; requiredEvidence=@('runtime-events','qa-observation'); status='Pending' },
    [pscustomobject][ordered]@{ id='HRS-QA-005'; title='Intro quest continuation'; requirement='The starter quest and intro buried supplies objective remain in the stored starting biome, then vanilla progression continues.'; expectedEvents=@('TRADER_ROUTE_QUEST_SEEN','TRADER_ROUTE_SELECTED','TRADER_ROUTE_COMPLETED','INTRO_ROUTE_FILTER_APPLIED'); forbiddenEvents=@('TRADER_ROUTE_FALLBACK'); requiredEvidence=@('runtime-events','qa-observation'); status='Pending' },
    [pscustomobject][ordered]@{ id='HRS-QA-006'; title='Reload is one-shot'; requirement='Reloading an already relocated character does not relocate again or replace completed state.'; expectedEvents=@('RUNTIME_READY'); requiredEvidence=@('runtime-events','qa-observation'); status='Pending' },
    [pscustomobject][ordered]@{ id='HRS-QA-007'; title='Arrival protection boundary'; requirement='The selected protection setting affects recognized starting-biome hazard families and does not claim later-biome immunity.'; expectedEvents=@('RUNTIME_READY'); requiredEvidence=@('runtime-events','qa-observation'); status='Pending' },
    [pscustomobject][ordered]@{ id='HRS-QA-008'; title='Removal rollback'; requirement='Owned HRS files can be removed without deleting unrelated files.'; expectedEvents=@(); requiredEvidence=@('rollback-receipt'); status='Pending' },
    [pscustomobject][ordered]@{ id='HRS-QA-009'; title='Existing-user upgrade'; requirement='The candidate manager upgrades an owned older HRS installation and verifies the candidate hashes.'; expectedEvents=@(); requiredEvidence=@('installed-before','installed-after','result-summary'); status='Pending' }
)
$contract = [pscustomobject][ordered]@{ schema='hrs-qa-contract/v1'; releaseVersion='1.2.3'; candidateId=$CandidateId; requiredCases=$cases }
$checks = @{
    'HRS-QA-001'=@('fresh-install-verified','game-environment-matches')
    'HRS-QA-002'=@('standard-spawn-unchanged')
    'HRS-QA-003A'=@('fresh-character','safe-ground-landing')
    'HRS-QA-003B'=@('second-fresh-character','safe-ground-landing')
    'HRS-QA-004'=@('opening-trader-same-starting-biome')
    'HRS-QA-005'=@('intro-quest-starting-biome','vanilla-jobs-resume')
    'HRS-QA-006'=@('reload-no-relocation','trader-route-resumes')
    'HRS-QA-007'=@('protection-off-hazards-active','protection-on-starting-family','protection-restored-on-reload','later-biome-hazards-active')
    'HRS-QA-008'=@('owned-removal','unrelated-files-preserved','saves-preserved')
    'HRS-QA-009'=@('old-owned-version-observed','candidate-installed-verified','settings-preserved')
}
foreach ($case in $cases) {
    $case | Add-Member -NotePropertyName requiredChecks -NotePropertyValue $checks[$case.id]
    $case.requiredEvidence = @($case.requiredEvidence) + @('qa-observation','environment')
}
$contract.requiredCases += [pscustomobject]@{
    id='HRS-QA-010'; title='Identity failure is blocked'
    requirement='A tampered disposable package and unknown installation are rejected without overwriting game files.'
    expectedEvents=@(); requiredEvidence=@('qa-observation','installed-before','installed-after','environment')
    requiredChecks=@('tampered-package-blocked','unknown-installation-preserved'); status='Pending'
}
Write-HrsQaJson -Path $releasePath -Value $release
Write-HrsQaJson -Path $contractPath -Value $contract
Write-Output "Created 1.2.3 release and QA contracts for $CandidateId"
Write-Output "Runtime SHA256: $runtimeHash"
Write-Output "Selected points: $($approved.Count)"
