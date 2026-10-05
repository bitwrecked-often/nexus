[CmdletBinding(DefaultParameterSetName = 'CurrentGame')]
param(
    [Parameter(Mandatory = $true)] [string] $LaneRoot,
    [Parameter(Mandatory = $true)] [ValidatePattern('^1\.2\.6-qa\.\d{3}$')] [string] $CandidateId,
    [Parameter(Mandatory = $true)] [ValidatePattern('^[0-9a-f]{40}$')] [string] $SourceCommit,
    [Parameter(Mandatory = $true, ParameterSetName = 'CurrentGame')] [string] $GameRoot,
    [Parameter(Mandatory = $true, ParameterSetName = 'QualifiedReuse')] [string] $ReuseCandidateArchive
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
foreach ($file in @($buildPath,$dllPath,$modPath)) {
    if (-not [IO.File]::Exists($file)) { throw "HRS126_REQUIRED_FILE_MISSING: $file" }
}
if ($build.schema -cne 'hrs-release-build/v1' -or $build.deterministicDoubleBuild -ne $true -or
    [string]$build.dllSha256 -cne (Get-HrsQaSha256 $dllPath) -or
    [string]$build.assemblyCSharpMvid -cne '7c57b7de-39a1-497d-bf48-8d5d1d4a1ff1') {
    throw 'HRS126_BUILD_IDENTITY_MISMATCH'
}
$assemblyPin = 'AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146'
$harmonyPin = 'C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF'
$buildStatus = 'built-from-current-lane'
$reuseProvenance = $null

function Read-Hrs126ZipJson {
    param([string]$ArchivePath, [string]$EntryPath, [string]$ExpectedHash)
    $zip = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $matches = @($zip.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq $EntryPath })
        if ($matches.Count -ne 1 -or (Get-HrsStreamHash $matches[0].Open()) -cne $ExpectedHash) {
            throw "HRS126_REUSE_ENTRY_DIGEST: $EntryPath"
        }
        $reader = New-Object IO.StreamReader($matches[0].Open())
        try { return ($reader.ReadToEnd() | ConvertFrom-Json) }
        finally { $reader.Dispose() }
    }
    finally { $zip.Dispose() }
}

if ($PSCmdlet.ParameterSetName -ceq 'QualifiedReuse') {
    # Authenticate frozen inputs, rather than substituting today's game DLLs or
    # claiming a new build. The original route still requires its exact inputs.
    $archive = [IO.Path]::GetFullPath($ReuseCandidateArchive)
    $candidate = Read-HrsQaJson ($archive + '.receipt.json')
    if (@('1.2.6-qa.001','1.2.6-qa.002') -cnotcontains [string]$candidate.candidateId) {
        throw 'HRS126_REUSE_REQUIRES_QUALIFIED_126_BASELINE'
    }
    $qualifiedRecord = Get-HrsRegistryRecord ([string]$candidate.candidateId)
    $check = Test-HrsCandidateArchive $archive $qualifiedRecord.candidateId `
        $qualifiedRecord.releaseRecordSha256 $qualifiedRecord.contractSha256
    if (-not $check.valid) { throw ('HRS126_REUSE_CANDIDATE: ' + ($check.errors -join ',')) }
    $receipt = $check.receipt
    $companion = $archive + '.companion.zip'
    if ((Get-HrsQaSha256 $companion) -cne [string]$receipt.companionSha256) {
        throw 'HRS126_REUSE_COMPANION_DIGEST'
    }
    $context = Read-HrsVerifiedZip $companion 'context-manifest.json' @() '' $receipt.contextManifestSha256
    if ([string]$context.schema -cne 'hrs-qa-context/v1' -or
        [string]$context.candidateId -cne [string]$receipt.candidateId) {
        throw 'HRS126_REUSE_CONTEXT_IDENTITY'
    }
    $frozenRelease = Read-Hrs126ZipJson $companion 'dev/qa/rel.json' $receipt.releaseRecordSha256
    if ([string]$frozenRelease.schema -cne 'hrs-release/v1' -or
        [string]$frozenRelease.version -cne '1.2.6' -or
        [string]$frozenRelease.buildId -cne 'r126' -or
        [string]$frozenRelease.candidateId -cne [string]$receipt.candidateId -or
        [string]$frozenRelease.supportedEnvironment.gameVersion -cne 'V3.3.0 (b17)' -or
        [string]$frozenRelease.supportedEnvironment.assemblyCSharpMvid -cne '7c57b7de-39a1-497d-bf48-8d5d1d4a1ff1' -or
        [string]$frozenRelease.supportedEnvironment.assemblyCSharpSha256 -cne $assemblyPin -or
        [string]$frozenRelease.supportedEnvironment.harmonySha256 -cne $harmonyPin -or
        [string]$frozenRelease.sourceSnapshot.runtimeSource -cne 'dev/src/runtime/main') {
        throw 'HRS126_REUSE_RELEASE_IDENTITY'
    }
    $frozenBuildPath = [string]$frozenRelease.build.recordPath
    [void](Resolve-HrsContainedFile $env:TEMP $frozenBuildPath)
    $frozenBuild = Read-Hrs126ZipJson $companion $frozenBuildPath $receipt.buildRecordSha256
    if ((Get-HrsQaSha256 $buildPath) -cne [string]$receipt.buildRecordSha256 -or
        [string]$frozenRelease.build.recordSha256 -cne [string]$receipt.buildRecordSha256 -or
        [string]$frozenBuild.schema -cne 'hrs-release-build/v1' -or
        $frozenBuild.deterministicDoubleBuild -ne $true -or
        [string]$frozenBuild.attempt -cne [string]$receipt.buildAttempt -or
        [string]$frozenBuild.dllSha256 -cne [string]$receipt.runtimeSha256 -or
        [string]$frozenBuild.assemblyCSharpMvid -cne [string]$frozenRelease.supportedEnvironment.assemblyCSharpMvid) {
        throw 'HRS126_REUSE_BUILD_IDENTITY'
    }
    foreach ($payload in @(
        [pscustomobject]@{ path='dev/verified/main/d0163.dll'; sha256=[string]$receipt.runtimeSha256; actual=$dllPath },
        [pscustomobject]@{ path='dev/verified/main/ModInfo.xml'; sha256=[string]$receipt.modInfoSha256; actual=$modPath }
    )) {
        $packageFile = @($check.manifest.files | Where-Object { [string]$_.path -ceq $payload.path })
        $releaseFile = @($frozenRelease.artifacts | Where-Object { [string]$_.path -ceq $payload.path })
        if ($packageFile.Count -ne 1 -or $releaseFile.Count -ne 1 -or
            [string]$packageFile[0].sha256 -cne $payload.sha256 -or
            [string]$releaseFile[0].sha256 -cne $payload.sha256 -or
            (Get-HrsQaSha256 $payload.actual) -cne $payload.sha256) {
            throw "HRS126_REUSE_PAYLOAD_IDENTITY: $($payload.path)"
        }
    }
    $frozenSources = @($frozenBuild.sourceHashes)
    $releaseSources = @($frozenRelease.sourceSnapshot.sourceHashes)
    $actualSources = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Filter '*.cs')
    if ($frozenSources.Count -ne 15 -or $releaseSources.Count -ne $frozenSources.Count -or
        @($frozenBuild.sourceFiles).Count -ne $frozenSources.Count -or
        $actualSources.Count -ne $frozenSources.Count -or
        @($frozenSources.path | Sort-Object -CaseSensitive -Unique).Count -ne $frozenSources.Count) {
        throw 'HRS126_REUSE_SOURCE_SET'
    }
    foreach ($source in $frozenSources) {
        $releaseSource = @($releaseSources | Where-Object { [string]$_.path -ceq [string]$source.path })
        $contextSource = @($context.files | Where-Object {
            [string]$_.path -ceq ('dev/src/runtime/main/' + [string]$source.path)
        })
        $actualSource = Resolve-HrsContainedFile $sourceRoot ([string]$source.path)
        if (@($frozenBuild.sourceFiles | Where-Object { [string]$_ -ceq [string]$source.path }).Count -ne 1 -or
            $releaseSource.Count -ne 1 -or $contextSource.Count -ne 1 -or
            [string]$releaseSource[0].sha256 -cne [string]$source.sha256 -or
            [string]$contextSource[0].sha256 -cne [string]$source.sha256 -or
            (Get-HrsQaSha256 $actualSource) -cne [string]$source.sha256) {
            throw "HRS126_REUSE_SOURCE_IDENTITY: $($source.path)"
        }
    }
    $assemblyReference = @($frozenBuild.references | Where-Object { [string]$_.name -ceq 'Assembly-CSharp.dll' })
    $harmonyReference = @($frozenBuild.references | Where-Object { [string]$_.name -ceq '0Harmony.dll' })
    if ($assemblyReference.Count -ne 1 -or $harmonyReference.Count -ne 1 -or
        [string]$assemblyReference[0].sha256 -cne $assemblyPin -or
        [string]$harmonyReference[0].sha256 -cne $harmonyPin) {
        throw 'HRS126_REUSE_REFERENCE_IDENTITY'
    }
    $assemblyHash = [string]$assemblyReference[0].sha256
    $harmonyHash = [string]$harmonyReference[0].sha256
    $buildStatus = 'reused-qualified-build'
    $reuseProvenance = [pscustomobject][ordered]@{
        schema='hrs-qualified-build-reuse/v1'; candidateId=[string]$receipt.candidateId
        archiveSha256=[string]$receipt.archiveSha256; receiptSha256=[string]$qualifiedRecord.receiptSha256
        companionSha256=[string]$receipt.companionSha256; contextManifestSha256=[string]$receipt.contextManifestSha256
        releaseRecordSha256=[string]$receipt.releaseRecordSha256; contractSha256=[string]$receipt.contractSha256
        buildRecordPath=$frozenBuildPath; buildRecordSha256=[string]$receipt.buildRecordSha256
        buildAttempt=[string]$receipt.buildAttempt
        note='Reused the authenticated deterministic build unchanged. No rebuild or current installed-game verification is claimed; independent QA still requires the pinned b17 environment.'
    }
}
else {
    $game = [IO.Path]::GetFullPath($GameRoot)
    $assemblyPath = Join-Path $game '7DaysToDie_Data/Managed/Assembly-CSharp.dll'
    $harmonyPath = Join-Path $game 'Mods/0_TFP_Harmony/0Harmony.dll'
    foreach ($file in @($assemblyPath,$harmonyPath)) {
        if (-not [IO.File]::Exists($file)) { throw "HRS126_REQUIRED_FILE_MISSING: $file" }
    }
    $assemblyHash = Get-HrsQaSha256 $assemblyPath
    $harmonyHash = Get-HrsQaSha256 $harmonyPath
}
if ($assemblyHash -cne 'AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146' -or
    $harmonyHash -cne 'C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF') {
    throw 'HRS126_GAME_INPUT_CHANGED'
}
$sourceHashes = @($build.sourceHashes | ForEach-Object {
    $sourcePath = Resolve-HrsContainedFile $sourceRoot ([string]$_.path)
    $actual = Get-HrsQaSha256 $sourcePath
    if ($actual -cne [string]$_.sha256) { throw "HRS126_SOURCE_CHANGED: $($_.path)" }
    [pscustomobject][ordered]@{ path=[string]$_.path; sha256=$actual }
})
$poiSource = [IO.File]::ReadAllText((Join-Path $sourceRoot 'PlacedPoiResolver.cs'))
$allowlist = [regex]::Match($poiSource,
    'HashSet<string> Names\s*=\s*new HashSet<string>\(StringComparer\.Ordinal\)\s*\{(?<body>[^}]+)\}',
    [Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $allowlist.Success) { throw 'HRS126_POI_ALLOWLIST_MISSING' }
$names = @([regex]::Matches($allowlist.Groups['body'].Value,
    '"(?<name>[^\"]+)"') | ForEach-Object { $_.Groups['name'].Value })
if ($names.Count -ne 79 -or @($names | Sort-Object -CaseSensitive -Unique).Count -ne 79) {
    throw 'HRS126_POI_ALLOWLIST_NOT_79_UNIQUE'
}
$dllInfo = [IO.FileInfo]$dllPath
$modInfo = [IO.FileInfo]$modPath
$release = [pscustomobject][ordered]@{
    schema='hrs-release/v1'; product='Historical Random Start'; version='1.2.6'
    buildId='r126'; candidateId=$CandidateId
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
        managerNotice=[pscustomobject][ordered]@{
            verifiedPostApplyAcknowledgement=$true
            randomFirstSessionWarning=$true
            standardWarningOmitted=$true
            safeLogoutBoundary='Journey to Settlement trader marker'
            earlyLogoutRouteIssue='documented-known-issue'
        }
    }
    artifacts=@(
        [pscustomobject][ordered]@{ path='dev/verified/main/d0163.dll'; bytes=[UInt64]$dllInfo.Length; sha256=(Get-HrsQaSha256 $dllPath); assemblyName='d0163'; assemblyVersion='0.0.0.0' },
        [pscustomobject][ordered]@{ path='dev/verified/main/ModInfo.xml'; bytes=[UInt64]$modInfo.Length; sha256=(Get-HrsQaSha256 $modPath) }
    )
    build=[pscustomobject][ordered]@{
        candidateId=$CandidateId; recordPath=$buildRelative
        recordSha256=(Get-HrsQaSha256 $buildPath)
        deterministicDoubleBuild=$true; status=$buildStatus
    }
    package=[pscustomobject][ordered]@{ archivePath=''; archiveSha256=''; status='not-exported' }
    runtimeLog=[pscustomobject][ordered]@{ prefix='[HRS]'; version='1.2.6'; buildId='r126'; maximumEvents=64 }
    releaseRules=[pscustomobject][ordered]@{
        immutableAfterQaStart=$true; promoteExactTestedBytes=$true
        qaMayRepairCandidate=$false; evidenceRequiredForApproval=$true
    }
}
if ($null -ne $reuseProvenance) {
    $release.build | Add-Member -NotePropertyName reuseProvenance -NotePropertyValue $reuseProvenance
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
    (New-Case 'HRS-QA-008' 'Owned removal and availability' 'Check read-only removal availability for owned, absent, unowned and unknown installations. Confirmed Uninstall repeats ownership and process checks, removes only HRS-owned files and preserves saves, settings and unrelated mods. Manual Restore is absent; Uninstall does not reverse a saved landing or quest.' @() @() @('installed-before','installed-after','rollback-receipt','qa-observation') @('owned-removal','unrelated-files-preserved','saves-preserved','absent-removal-unavailable','unowned-removal-unavailable','unknown-removal-unavailable','removal-cancel-no-write','removal-final-checks','manual-restore-absent')),
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
$cases+=(New-Case 'HRS-BIOME-Manager' 'Saved biome selection, native presentation and accessibility' 'Open the extracted customer START.bat. Check independent Standard/Random and Any/Chosen/Weighted radio groups, exact saved-policy restoration, stable disabled picker/editor positions, cancel/commit weight edits, exact confirmation, compact header, readable 10pt state badge, outlined actions, visible focus and native Tab/arrows/Space/Enter/Escape. At actual primary 100/150/200/225 percent and secondary 300 percent Windows display scaling, verify narrow/maximized reachability, OS High Contrast, Narrator names/states and native popups. Component scaling simulations do not qualify actual display profiles.' @() @() @('environment','qa-observation') @('saved-selection-restored','weight-cancel-discarded','weight-switch-retained','all-zero-blocked','confirmation-before-mutation','keyboard-access','scaling-100','scaling-150','scaling-200','scaling-225','secondary-scaling-300','rounded-actions-readable','weights-dialog-readable','focus-disabled-readable','os-high-contrast','narrator-controls','scroll-reachability','native-popups-readable','independent-native-radio-groups','selection-load-batched','dependent-controls-stable','compact-header-readable','status-badge-readable'))
$cases+=(New-Case 'HRS-UX-OPERATIONS' 'Operation guards and automatic recovery' 'Use the exact extracted customer manager in disposable installations. During confirmed Apply, readback, Settings Applied acknowledgement and Uninstall, attempt duplicate/conflicting actions and activation refresh. Measure operation duration. Verify safe induced write failures recover prior installation bytes; uncertain recovery preserves backup/diagnostic and blocks Launch. Selection-only changes write nothing. Steam availability changes Launch without changing verified configuration state.' @() @() @('installed-before','installed-after','qa-observation') @('busy-before-mutation','duplicate-apply-blocked','conflicting-uninstall-blocked','busy-through-readback','busy-through-acknowledgement','busy-cleared-safely','operation-duration-recorded','verified-recovery-bytes','uncertain-recovery-backup-retained','failed-apply-launch-blocked','selection-only-no-write','steam-independent-applied-state'))
$cases+=(New-Case 'HRS-UX-COPY' 'Confirmation and truthful outcome copy' 'Check Standard and Any/Chosen/Weighted with protection off/on. Exact Game Name, method/biome/weights and protection agree in confirmation, saved policy and acknowledgement. Standard omits Random fallback/trader warning; Random uses conditional fallback and the exact first-session notice. Test safe native default/Enter/Escape/window-close behavior on the actual host. Rejection, verified recovery and uncertain recovery show their specific next action without false success.' @() @() @('installed-before','installed-after','qa-observation') @('exact-summary-agreement','standard-omits-random-copy','random-any-protection-off-on','random-chosen-protection-off-on','random-weighted-protection-off-on','conditional-fallback-copy','safe-confirmation-default','native-dismissal-contract','cancel-no-write','rejection-copy-truthful','verified-recovery-copy-truthful','uncertain-recovery-copy-truthful'))
$cases+=(New-Case 'HRS-UX-GEOMETRY' 'Returned sizing defects and user sizing' 'Reproduce HRS-UX-001 repeated selection/editor switching including the original 150 percent sequence; outer width never cumulatively shrinks. Reproduce HRS-UX-002 near screen bottom and after monitor changes; final outer bounds fit the current monitor work area. Reproduce HRS-UX-003 genuine minimum resize/scroll at actual 100/150/200/225 percent including the original 200 percent sequence, selection changes and dialog returns; every action, Help and Game details is reachable. Intentional user resize, normal restoration and maximize/minimize survive refresh.' @() @() @('environment','qa-observation') @('outer-width-stable','work-area-bounds','minimum-scroll-all-controls','editor-return-scroll-settled','user-size-preserved','maximize-minimize-preserved','monitor-move-qualified'))
$cases+=(New-Case 'HRS-UX-HELP' 'Discoverable setup help' 'From the compact extracted manager, find Help using keyboard and Narrator. Read the exact Game Name/world distinction, equal-chance/weight meaning, preview/eligibility/safety limits, protection boundary, Apply then acknowledgement then separate Launch, one-time landing and the first Random session trader-marker boundary. Help opens without install/removal/launch writes and remains reachable at supported real scales.' @() @() @('qa-observation') @('help-discoverable','help-keyboard-reachable','help-narrator-reachable','help-game-name-world','help-weight-meaning','help-protection-limits','help-operation-order','help-trader-boundary','help-no-mutation'))
$cases+=(New-Case 'HRS-UX-NEWCOMER' 'Scoped newcomer usability review' 'Observe one new user with the exact newly extracted customer package and realistic fresh-save goals without coaching. Record task comprehension, ordinary Help use, assistance and confusion, Apply/acknowledgement/Launch understanding, and the Random first-session boundary. Keep observations and targeted retests attached to this candidate; prototype or developer familiarity is not a substitute.' @() @() @('environment','qa-observation') @('uncoached-task-observed','help-use-observed','assistance-confusion-recorded','operation-order-understood','game-name-world-understood','trader-boundary-understood','targeted-retests-recorded'))
$cases+=(New-Case 'HRS-QA-TRADER-NOTICE' 'Post-Apply trader-session notice' 'From the extracted manager, verify the saved policy precedes Settings Applied. Random Any, Chosen, and Weighted show the first-session warning; Standard omits it. Launch stays disabled until OK and requires running Steam.' @() @() @('qa-observation','installed-after') @('policy-readback-before-popup','random-any-notice','random-chosen-notice','random-weighted-notice','standard-omits-notice','launch-gate'))
$cases+=(New-Case 'HRS-QA-TRADER-FIRST-SESSION' 'Uninterrupted first trader assignment' 'In a fresh Random save, complete opening tasks in the same session until Journey to Settlement assigns a trader marker. Record the route decision before any logout; the trader visit can occur later.' @('TRADER_ROUTE_SELECTED','TRADER_ROUTE_COMPLETED') @('INTERNAL_FAILURE') @('runtime-events','qa-observation') @('opening-tasks-same-session','destination-marker-before-logout','route-completed'))
$cases+=(New-Case 'HRS-QA-TRADER-EARLY-LOGOUT' 'Known early-logout route limitation' 'In a separate disposable Random save, exit before trader assignment and return. Record whether the landing persists and which destination appears; a Pine Forest marker is the documented known limitation, not proof that the runtime issue is repaired.' @() @() @('runtime-events','qa-observation') @('logout-before-assignment','landing-persists-on-return','return-destination-recorded'))
$cases+=(New-Case 'HRS-QA-TRADER-POST-ASSIGNMENT' 'Trader marker survives return before visit' 'After assignment but before visiting the trader, exit and return. Verify the same assigned destination remains. A lost marker blocks release.' @() @() @('runtime-events','qa-observation') @('assignment-before-logout','same-marker-on-return'))
$cases+=(New-Case 'HRS-QA-TRADER-CROSS-BIOME' 'Legitimate cross-biome trader fallback' 'In a world with no usable trader in the landing biome, verify the logged route selects a real placed trader in another biome. Record a missing natural fixture as Blocked.' @('TRADER_ROUTE_SELECTED','TRADER_ROUTE_COMPLETED') @('INTERNAL_FAILURE') @('runtime-events','qa-observation') @('local-trader-unavailable','placed-cross-biome-trader','marker-matches-selected-trader'))
$contract = [pscustomobject][ordered]@{
    schema='hrs-qa-contract/v1'; releaseVersion='1.2.6'
    candidateId=$CandidateId; requiredCases=$cases
}

$qaRoot = Join-Path $root 'dev/qa'
Write-HrsQaJson -Path (Join-Path $qaRoot 'rel.json') -Value $release
Write-HrsQaJson -Path (Join-Path $qaRoot 'cases.json') -Value $contract
Write-Output "1.2.6 contracts written for $CandidateId from exact build $($build.attempt)."
Write-Output "DLL SHA-256: $($release.artifacts[0].sha256)"
Write-Output "POI names: $($names.Count); required QA cases: $($cases.Count)"
