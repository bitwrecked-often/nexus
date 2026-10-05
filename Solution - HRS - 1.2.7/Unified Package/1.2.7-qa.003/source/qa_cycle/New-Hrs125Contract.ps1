[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $LaneRoot,
    [Parameter(Mandatory = $true)] [ValidatePattern('^1\.2\.5-qa\.\d{3}$')] [string] $CandidateId,
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
    if (-not [IO.File]::Exists($file)) { throw "HRS125_REQUIRED_FILE_MISSING: $file" }
}
if ($build.schema -cne 'hrs-release-build/v1' -or $build.deterministicDoubleBuild -ne $true -or
    [string]$build.dllSha256 -cne (Get-HrsQaSha256 $dllPath) -or
    [string]$build.assemblyCSharpMvid -cne '7c57b7de-39a1-497d-bf48-8d5d1d4a1ff1') {
    throw 'HRS125_BUILD_IDENTITY_MISMATCH'
}
$assemblyHash = Get-HrsQaSha256 $assemblyPath
$harmonyHash = Get-HrsQaSha256 $harmonyPath
if ($assemblyHash -cne 'AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146' -or
    $harmonyHash -cne 'C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF') {
    throw 'HRS125_GAME_INPUT_CHANGED'
}
$sourceHashes = @($build.sourceHashes | ForEach-Object {
    $sourcePath = Resolve-HrsContainedFile $sourceRoot ([string]$_.path)
    $actual = Get-HrsQaSha256 $sourcePath
    if ($actual -cne [string]$_.sha256) { throw "HRS125_SOURCE_CHANGED: $($_.path)" }
    [pscustomobject][ordered]@{ path=[string]$_.path; sha256=$actual }
})
$poiSource = [IO.File]::ReadAllText((Join-Path $sourceRoot 'PlacedPoiResolver.cs'))
$allowlist = [regex]::Match($poiSource,
    'HashSet<string> Names\s*=\s*new HashSet<string>\(StringComparer\.Ordinal\)\s*\{(?<body>[^}]+)\}',
    [Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $allowlist.Success) { throw 'HRS125_POI_ALLOWLIST_MISSING' }
$names = @([regex]::Matches($allowlist.Groups['body'].Value,
    '"(?<name>[^\"]+)"') | ForEach-Object { $_.Groups['name'].Value })
if ($names.Count -ne 79 -or @($names | Sort-Object -CaseSensitive -Unique).Count -ne 79) {
    throw 'HRS125_POI_ALLOWLIST_NOT_79_UNIQUE'
}
$dllInfo = [IO.FileInfo]$dllPath
$modInfo = [IO.FileInfo]$modPath
$release = [pscustomobject][ordered]@{
    schema='hrs-release/v1'; product='Historical Random Start'; version='1.2.5'
    buildId='r125'; candidateId=$CandidateId
    releaseDate=[datetime]::UtcNow.ToString('yyyy-MM-dd'); sourceCommit=$SourceCommit
    laneStatus='candidate-development'
    sourceSnapshot=[pscustomobject][ordered]@{
        state='working-tree-snapshot'; runtimeSource='dev/src/runtime/main'; sourceHashes=$sourceHashes
    }
    supportedEnvironment=[pscustomobject][ordered]@{
        game='7 Days to Die'; gameVersion='V3.3.0 (b17)'; playMode='local-single-player'
        antiCheat='disabled'; assemblyCSharpMvid=[string]$build.assemblyCSharpMvid
        assemblyCSharpSha256=$assemblyHash; harmonySha256=$harmonyHash
    }
    # Compatibility policy documents player behavior. The exact environment
    # above remains the required target for this candidate's QA evidence.
    compatibility=[pscustomobject][ordered]@{
        policy='best-effort-runtime-hooks'; qaRequiresExactTestedBuild=$true
        unknownBuildAction='attempt-required-runtime-hooks'
        missingHookAction='leave-normal-start'; backwardCompatibilityCertified=$false
    }
    scope=[pscustomobject][ordered]@{
        selection='random-among-placed-world'; approvedPrefabNames=$names
        biomeSelection=@('Any','Chosen','Weighted'); policySchema='hrs-policy/v2'; policyFile='policy.v2.json'
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
    runtimeLog=[pscustomobject][ordered]@{ prefix='[HRS]'; version='1.2.5'; buildId='r125'; maximumEvents=64 }
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
foreach($index in @(2,3)) {
    $cases[$index] | Add-Member -NotePropertyName expectedSelection -NotePropertyValue 'Any'
    $cases[$index].expectedEvents=@('BIOME_SELECTED')+@($cases[$index].expectedEvents)
}
$cases[4] | Add-Member -NotePropertyName requiresPlacedTrader -NotePropertyValue $true
# Each independent world/method case stays pending until human-visible QA.
foreach ($world in @('Navezgane','RandomGen')) {
    foreach ($biome in @(@('Forest',3),@('BurntForest',9),@('Desert',5),@('Snow',1),@('Wasteland',8))) {
        $case=New-Case "HRS-BIOME-$world-$($biome[0])" "Chosen $($biome[0]) in $world" 'Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.' @('BIOME_SELECTED','POI_LANDING_COMPLETED','RELOCATION_COMPLETED') @('INTERNAL_FAILURE') @('runtime-events','result-summary','qa-observation') @('chosen-biome-arrival','requested-eligible-selected-completed-recorded','safe-ground-landing','trader-marker-usable')
        $case | Add-Member -NotePropertyName requiresPlacedIdentity -NotePropertyValue $true
        $case | Add-Member -NotePropertyName expectedWorldCategory -NotePropertyValue $world
        $case | Add-Member -NotePropertyName expectedSelection -NotePropertyValue 'Chosen'
        $case | Add-Member -NotePropertyName expectedChosenBiome -NotePropertyValue ([string]$biome[1])
        $cases+= $case
    }
    foreach($fixture in @('Mixed','ZeroExclusion','SinglePositive')) {
        $case=New-Case "HRS-BIOME-$world-Weighted-$fixture" "Weighted $fixture in $world" 'Use a distinct fresh exact Game Name for this weight fixture. Record configured weights and eligible/selected/final biome. This run covers only its named fixture.' @('BIOME_SELECTED','POI_LANDING_COMPLETED','RELOCATION_COMPLETED') @('INTERNAL_FAILURE') @('runtime-events','result-summary','qa-observation') @('requested-eligible-selected-completed-recorded',"weighted-$fixture")
        $case | Add-Member -NotePropertyName requiresPlacedIdentity -NotePropertyValue $true
        $case | Add-Member -NotePropertyName expectedWorldCategory -NotePropertyValue $world
        $case | Add-Member -NotePropertyName expectedSelection -NotePropertyValue 'Weighted'
        $case | Add-Member -NotePropertyName expectedWeightFixture -NotePropertyValue $fixture
        $cases+=$case
    }
    $cases+=(New-Case "HRS-BIOME-$world-Respawn" "Respawn and changed preference in $world" 'After a completed start, change the preference, reload, then die/respawn. No second HRS draw or placement.' @('RUNTIME_READY') @('BIOME_SELECTED','POI_ATTEMPT_SELECTED','PLACEMENT_CALLED') @('runtime-events','qa-observation') @('reload-no-relocation','respawn-no-relocation','changed-preference-no-second-start'))
}
$absentWeighted=New-Case 'HRS-BIOME-Weighted-AbsentRenormalized' 'Weighted absent eligible biome' 'On a suitable Navezgane or Random Gen world, give positive weight to a biome absent from the placed-POI eligible pool and another positive weight to an eligible biome. Record the eligible set, draw and safe arrival in one distinct run; if no suitable world is available, record Blocked.' @('BIOME_SELECTED','POI_LANDING_COMPLETED','RELOCATION_COMPLETED') @('INTERNAL_FAILURE') @('runtime-events','result-summary','qa-observation') @('absent-biome-excluded','requested-eligible-selected-completed-recorded')
$absentWeighted | Add-Member -NotePropertyName requiresPlacedIdentity -NotePropertyValue $true
$absentWeighted | Add-Member -NotePropertyName expectedSelection -NotePropertyValue 'Weighted'
$absentWeighted | Add-Member -NotePropertyName expectedWeightFixture -NotePropertyValue 'AbsentRenormalized'
$cases+=$absentWeighted
foreach($fallback in @('REQUESTED_BIOME_ABSENT','WEIGHTED_POOL_EMPTY','POI_SAFETY_EXHAUSTED','TRADER_POOL_EMPTY')) {
    $cases+=(New-Case "HRS-BIOME-$fallback" "Safe fallback: $fallback" 'On a suitable disposable world, observe this exact terminal reason and the ordinary-start fallback. Record missing fixture as Blocked, never as Pass. Preserve absent versus reserved marker semantics.' @($fallback) @('RELOCATION_COMPLETED') @('runtime-events','result-summary','qa-observation') @('ordinary-start-preserved','failure-not-completed','no-redraw-on-reload'))
}
$cases+=(New-Case 'HRS-BIOME-Manager' 'Saved biome selection and display scaling' 'Open the extracted customer START.bat. Check saved selection, cancel/commit weight edits, exact confirmation, keyboard navigation and readable controls at actual 100/150/200 percent display scaling.' @() @() @('qa-observation') @('saved-selection-restored','weight-cancel-discarded','weight-switch-retained','all-zero-blocked','confirmation-before-mutation','keyboard-access','scaling-100','scaling-150','scaling-200'))
$contract = [pscustomobject][ordered]@{
    schema='hrs-qa-contract/v1'; releaseVersion='1.2.5'
    candidateId=$CandidateId; requiredCases=$cases
}

$qaRoot = Join-Path $root 'dev/qa'
Write-HrsQaJson -Path (Join-Path $qaRoot 'rel.json') -Value $release
Write-HrsQaJson -Path (Join-Path $qaRoot 'cases.json') -Value $contract
Write-Output "1.2.5 contracts written for $CandidateId from exact build $($build.attempt)."
Write-Output "DLL SHA-256: $($release.artifacts[0].sha256)"
Write-Output "POI names: $($names.Count); required QA cases: $($cases.Count)"
