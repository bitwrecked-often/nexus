[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $LaneRoot,
    [Parameter(Mandatory = $true)] [ValidatePattern('^1\.2\.4-qa\.\d{3}$')] [string] $CandidateId,
    [Parameter(Mandatory = $true)] [ValidatePattern('^[0-9a-f]{40}$')] [string] $SourceCommit,
    [Parameter(Mandatory = $true)] [string] $GameRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force

$paths = Get-HrsQaLanePaths -LaneRoot $LaneRoot
$root = $paths.LaneRoot
$registry = Read-HrsQaJson (Join-Path $PSScriptRoot 'candidate-registry.json')
if (@($registry.records | Where-Object { [string]$_.candidateId -ceq $CandidateId }).Count) {
    throw 'HRS_CANDIDATE_ID_ALREADY_EXPORTED'
}
$buildRelative = "dev/builds/$CandidateId/build-record.json"
$buildPath = Resolve-HrsContainedFile $root $buildRelative
$build = Read-HrsQaJson $buildPath
$dllPath = Join-Path $paths.PayloadRoot 'd0163.dll'
$modPath = Join-Path $paths.PayloadRoot 'ModInfo.xml'
$sourceRoot = Join-Path $root 'dev/src/runtime/main'
$game = [IO.Path]::GetFullPath($GameRoot)
$assemblyPath = Join-Path $game '7DaysToDie_Data/Managed/Assembly-CSharp.dll'
$harmonyPath = Join-Path $game 'Mods/0_TFP_Harmony/0Harmony.dll'
foreach ($file in @($buildPath,$dllPath,$modPath,$assemblyPath,$harmonyPath)) {
    if (-not [IO.File]::Exists($file)) { throw "HRS124_REQUIRED_FILE_MISSING: $file" }
}
if ($build.schema -cne 'hrs-release-build/v1' -or $build.deterministicDoubleBuild -ne $true -or
    [string]$build.dllSha256 -cne (Get-HrsQaSha256 $dllPath) -or
    [string]$build.assemblyCSharpMvid -cne '8576eaa1-7f2c-44dc-ba1b-e8b275a8aa62') {
    throw 'HRS124_BUILD_IDENTITY_MISMATCH'
}
$assemblyHash = Get-HrsQaSha256 $assemblyPath
$harmonyHash = Get-HrsQaSha256 $harmonyPath
if ($assemblyHash -cne '6EE089021F507A57767D494A8C5D9A5D379088558A768C618580519C59FF8090' -or
    $harmonyHash -cne 'C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF') {
    throw 'HRS124_GAME_INPUT_CHANGED'
}
$sourceHashes = @($build.sourceHashes | ForEach-Object {
    $sourcePath = Resolve-HrsContainedFile $sourceRoot ([string]$_.path)
    $actual = Get-HrsQaSha256 $sourcePath
    if ($actual -cne [string]$_.sha256) { throw "HRS124_SOURCE_CHANGED: $($_.path)" }
    [pscustomobject][ordered]@{ path=[string]$_.path; sha256=$actual }
})
$poiSource = [IO.File]::ReadAllText((Join-Path $sourceRoot 'PlacedPoiResolver.cs'))
$allowlist = [regex]::Match($poiSource,
    'HashSet<string> Names\s*=\s*new HashSet<string>\(StringComparer\.Ordinal\)\s*\{(?<body>[^}]+)\}',
    [Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $allowlist.Success) { throw 'HRS124_POI_ALLOWLIST_MISSING' }
$names = @([regex]::Matches($allowlist.Groups['body'].Value,
    '"(?<name>[^\"]+)"') | ForEach-Object { $_.Groups['name'].Value })
if ($names.Count -ne 79 -or @($names | Sort-Object -CaseSensitive -Unique).Count -ne 79) {
    throw 'HRS124_POI_ALLOWLIST_NOT_79_UNIQUE'
}
$dllInfo = [IO.FileInfo]$dllPath
$modInfo = [IO.FileInfo]$modPath
$release = [pscustomobject][ordered]@{
    schema='hrs-release/v1'; product='Historical Random Start'; version='1.2.4'
    buildId='r124'; candidateId=$CandidateId
    releaseDate=[datetime]::UtcNow.ToString('yyyy-MM-dd'); sourceCommit=$SourceCommit
    laneStatus='candidate-development'
    sourceSnapshot=[pscustomobject][ordered]@{
        state='working-tree-snapshot'; runtimeSource='dev/src/runtime/main'; sourceHashes=$sourceHashes
    }
    supportedEnvironment=[pscustomobject][ordered]@{
        game='7 Days to Die'; gameVersion='V3.3.0 (b14)'; playMode='local-single-player'
        antiCheat='disabled'; assemblyCSharpMvid=[string]$build.assemblyCSharpMvid
        assemblyCSharpSha256=$assemblyHash; harmonySha256=$harmonyHash
    }
    scope=[pscustomobject][ordered]@{
        selection='random-among-placed-world'; approvedPrefabNames=$names
        worldCategories=@('Navezgane','RandomGen'); minimumGeneratedWorldSize=8192
        maxPoiAttempts=5; retryDelaySeconds=3
        landing='runtime terrain resolution, clearance and grounded settling'
        traderRoutingScope='same-biome-then-nearest-placed-fallback'
        starterQuestId='quest_whiteRiverCitizen1'; starterQuestPhase=1
        oneShotRelocation=$true; standardModeUnchanged=$true
    }
    artifacts=@(
        [pscustomobject][ordered]@{ path='dev/verified/main/d0163.dll'; bytes=[UInt64]$dllInfo.Length; sha256=(Get-HrsQaSha256 $dllPath); assemblyName='d0163'; assemblyVersion='0.0.0.0' },
        [pscustomobject][ordered]@{ path='dev/verified/main/ModInfo.xml'; bytes=[UInt64]$modInfo.Length; sha256=(Get-HrsQaSha256 $modPath) }
    )
    build=[pscustomobject][ordered]@{
        candidateId=$CandidateId; recordPath=$buildRelative
        recordSha256=(Get-HrsQaSha256 $buildPath)
        deterministicDoubleBuild=$true; status='built-from-current-lane'
    }
    package=[pscustomobject][ordered]@{ archivePath=''; archiveSha256=''; status='not-exported' }
    runtimeLog=[pscustomobject][ordered]@{ prefix='[HRS]'; version='1.2.4'; buildId='r124'; maximumEvents=64 }
    releaseRules=[pscustomobject][ordered]@{
        immutableAfterQaStart=$true; promoteExactTestedBytes=$true
        qaMayRepairCandidate=$false; evidenceRequiredForApproval=$true
    }
}

function New-Case($id,$title,$requirement,$expected,$forbidden,$evidence,$checks) {
    return [pscustomobject][ordered]@{
        id=$id; title=$title; requirement=$requirement
        expectedEvents=@($expected); forbiddenEvents=@($forbidden)
        requiredEvidence=@($evidence); requiredChecks=@($checks); status='Pending'
    }
}
$cases = @(
    (New-Case 'HRS-QA-001' 'Customer package identity' 'Install the exact extracted candidate with the manager; match environment, installed hashes and ownership.' @() @() @('release-validation','package-inventory','installed-after','environment','qa-observation') @('fresh-install-verified','game-environment-matches')),
    (New-Case 'HRS-QA-002' 'Standard-mode control' 'Fresh named Standard save keeps the ordinary start and does not mutate trader routing.' @('RUNTIME_READY','STANDARD_BYPASS') @('POI_ATTEMPT_SELECTED','PLACEMENT_CALLED','TRADER_ROUTE_SELECTED') @('runtime-events','result-summary','qa-observation') @('standard-spawn-unchanged')),
    (New-Case 'HRS-QA-003A' 'Navezgane placed-world landing' 'Fresh Random Navezgane save lands safely at an approved placed prefab, with matching dynamic identity.' @('POI_ATTEMPT_SELECTED','POI_LANDING_COMPLETED','RELOCATION_COMPLETED') @('INTERNAL_FAILURE') @('runtime-events','result-summary','qa-observation') @('fresh-character','safe-ground-landing','semantic-state-preserved')),
    (New-Case 'HRS-QA-003B' 'Random Gen placed-world landing' 'Fresh Random save on a generated world of at least 8K lands safely at an approved placed prefab, with matching dynamic identity.' @('POI_ATTEMPT_SELECTED','POI_LANDING_COMPLETED','RELOCATION_COMPLETED') @('INTERNAL_FAILURE') @('runtime-events','result-summary','qa-observation') @('fresh-character','safe-ground-landing','semantic-state-preserved')),
    (New-Case 'HRS-QA-004' 'Placed trader route' 'From a fresh landing, follow the marker to the logged real placed trader, in the final biome or the recorded cross-biome fallback.' @('POI_ATTEMPT_SELECTED','TRADER_ROUTE_SELECTED','POI_LANDING_COMPLETED') @('INTERNAL_FAILURE') @('runtime-events','qa-observation') @('real-placed-trader-reached','trader-marker-usable')),
    (New-Case 'HRS-QA-005' 'Intro and ordinary work' 'Finish or retry the intro with the real trader and accept ordinary Tier 1 work.' @() @() @('qa-observation') @('intro-quest-completed-or-reoffered','vanilla-jobs-resume')),
    (New-Case 'HRS-QA-006' 'One-shot reload' 'After a fresh-process Continue, preserve the landing and quest without another HRS placement.' @('RUNTIME_READY') @('POI_ATTEMPT_SELECTED','PLACEMENT_CALLED') @('runtime-events','qa-observation') @('reload-no-relocation','quest-state-preserved')),
    (New-Case 'HRS-QA-007' 'Arrival protection boundary' 'Compare protection off/on, protected reload, and a later biome hazard with disposable saves.' @() @() @('qa-observation') @('protection-off-hazards-active','protection-on-starting-family','protection-restored-on-reload','later-biome-hazards-active')),
    (New-Case 'HRS-QA-008' 'Owned removal' 'Remove only HRS-owned files while preserving saves, settings and unrelated mods.' @() @() @('rollback-receipt','qa-observation') @('owned-removal','unrelated-files-preserved','saves-preserved')),
    (New-Case 'HRS-QA-009' 'Owned upgrade' 'Upgrade an owned prior installation and verify exact candidate hashes and preserved user state.' @() @() @('installed-before','installed-after','qa-observation') @('owned-upgrade','candidate-hashes-match','saves-preserved')),
    (New-Case 'HRS-QA-010' 'Manager identity rejection' 'A disposable altered package and unknown install footprint are rejected without overwriting game files.' @() @() @('installed-before','installed-after','qa-observation') @('tampered-package-blocked','unknown-install-blocked')),
    (New-Case 'HRS-QA-011' 'Exact Game Name guard' 'Starting a different fresh Game Name leaves a safe vanilla start with no HRS placement.' @('RUNTIME_READY','GAME_NAME_MISMATCH') @('POI_ATTEMPT_SELECTED','PLACEMENT_CALLED') @('runtime-events','result-summary','qa-observation') @('name-mismatch-no-warp'))
)
foreach ($index in @(2,3,4)) {
    $cases[$index] | Add-Member -NotePropertyName requiresPlacedIdentity -NotePropertyValue $true
}
$cases[2] | Add-Member -NotePropertyName expectedWorldCategory -NotePropertyValue 'Navezgane'
$cases[3] | Add-Member -NotePropertyName expectedWorldCategory -NotePropertyValue 'RandomGen'
$cases[4] | Add-Member -NotePropertyName requiresPlacedTrader -NotePropertyValue $true
$contract = [pscustomobject][ordered]@{
    schema='hrs-qa-contract/v1'; releaseVersion='1.2.4'
    candidateId=$CandidateId; requiredCases=$cases
}

$qaRoot = Join-Path $root 'dev/qa'
Write-HrsQaJson -Path (Join-Path $qaRoot 'rel.json') -Value $release
Write-HrsQaJson -Path (Join-Path $qaRoot 'cases.json') -Value $contract
Write-Output "1.2.4 contracts written for $CandidateId from exact build $($build.attempt)."
Write-Output "DLL SHA-256: $($release.artifacts[0].sha256)"
Write-Output "POI names: $($names.Count); required QA cases: $($cases.Count)"
