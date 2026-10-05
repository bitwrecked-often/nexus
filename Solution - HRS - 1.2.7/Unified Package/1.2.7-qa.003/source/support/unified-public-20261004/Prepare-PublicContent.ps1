[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [ValidateSet('1.2.7-qa.003')][string]$CandidateId='1.2.7-qa.003'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..')).TrimEnd('\','/')
$lane=Join-Path $repo 'hrs_1.2.7'
$output=[IO.Path]::GetFullPath($OutputPath).TrimEnd('\','/')
$allowed=[IO.Path]::GetFullPath((Join-Path $lane 'dev/tmp')).TrimEnd('\','/')+'\'
if(!$output.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)){
    throw 'OutputPath must be a new directory beneath hrs_1.2.7/dev/tmp.'
}
if(Test-Path -LiteralPath $output){throw 'Preserve existing public-content output: '+$output}
$rel=Get-Content -LiteralPath (Join-Path $lane 'dev/qa/rel.json') -Raw|ConvertFrom-Json
$cases=Get-Content -LiteralPath (Join-Path $lane 'dev/qa/cases.json') -Raw|ConvertFrom-Json
$buildPath=Join-Path $lane ('dev/builds/'+$CandidateId+'/build-record.json')
if($rel.candidateId -cne $CandidateId -or $cases.candidateId -cne $CandidateId -or
    $cases.requiredCases.Count -ne 46 -or @($cases.requiredCases|Where-Object{$_.status -cne 'Pending'}).Count -ne 0 -or
    !(Test-Path -LiteralPath $buildPath -PathType Leaf)){
    throw 'The new candidate contracts/build record and 46 independent Pending cases must exist first.'
}
function Get-ContentHash([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
foreach($entry in $rel.sourceSnapshot.sourceHashes){
    if((Get-ContentHash (Join-Path $lane ('dev/src/runtime/main/'+$entry.path))) -cne $entry.sha256){
        throw 'Current runtime source differs from the new candidate contract: '+$entry.path
    }
}

$transferPath=Join-Path $repo 'qa_cycle/handoffs/HRS_1.2.7-qa.002-QA-transfer.zip'
$transferRecordPath=Join-Path $lane 'dev/qa/review-repairs-20261004/packaging/transfer-verification.json'
$transferRecord=Get-Content -LiteralPath $transferRecordPath -Raw|ConvertFrom-Json
if($transferRecord.status -cne 'Pass' -or $transferRecord.candidateId -cne '1.2.7-qa.002' -or
    (Get-ContentHash $transferPath) -cne $transferRecord.sha256){throw 'Sealed historical transfer identity changed.'}
$historicalRoot=$transferRecord.independentWorkspace
if(!(Test-Path -LiteralPath (Join-Path $historicalRoot 'transfer-manifest.json') -PathType Leaf)){
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $extractRoot=Join-Path ([IO.Path]::GetTempPath()) ('hrs-public-history-'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($extractRoot)
    $zip=[IO.Compression.ZipFile]::OpenRead($transferPath)
    try{
        foreach($entry in $zip.Entries){
            $normalized=$entry.FullName.Replace('\','/')
            if(!$normalized.StartsWith('qa-127-002/',[StringComparison]::Ordinal) -or
                $normalized -match '(^|/)\.\.(/|$)' -or $normalized.Contains(':')){
                throw 'Historical transfer contains an unsafe archive path.'
            }
        }
    }finally{$zip.Dispose()}
    [IO.Compression.ZipFile]::ExtractToDirectory($transferPath,$extractRoot)
    $historicalRoot=Join-Path $extractRoot 'qa-127-002'
}
$historicalRoot=[IO.Path]::GetFullPath($historicalRoot).TrimEnd('\','/')
$historicalManifestPath=Join-Path $historicalRoot 'transfer-manifest.json'
if((Get-ContentHash $historicalManifestPath) -cne $transferRecord.transferManifestSha256){
    throw 'Historical independent-extraction manifest changed.'
}
$historicalManifest=Get-Content -LiteralPath $historicalManifestPath -Raw|ConvertFrom-Json
foreach($entry in $historicalManifest.files){
    $path=[IO.Path]::GetFullPath((Join-Path $historicalRoot $entry.path))
    if(!$path.StartsWith($historicalRoot+'\',[StringComparison]::OrdinalIgnoreCase) -or
        !(Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -ne $entry.bytes -or
        (Get-ContentHash $path) -cne $entry.sha256){throw 'Historical transfer extraction drift: '+$entry.path}
}

[void][IO.Directory]::CreateDirectory($output)
$utf8=New-Object Text.UTF8Encoding($false)
$copies=New-Object 'Collections.Generic.List[object]'
function Resolve-ContentPath([string]$Relative){
    if($Relative.Contains(':') -or $Relative -match '(^|[\\/])\.\.([\\/]|$)'){
        throw 'Unsafe public-content path: '+$Relative
    }
    $path=[IO.Path]::GetFullPath((Join-Path $output $Relative))
    if(!$path.StartsWith($output+'\',[StringComparison]::OrdinalIgnoreCase)){
        throw 'Public content escaped output root.'
    }
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
    return $path
}
function Get-PathPattern([string]$Path){
    return '(?i)'+((@($Path.TrimEnd('\','/') -split '[\\/]')|ForEach-Object{[regex]::Escape($_)}) -join '[\\/]+')
}
$pathRules=@(
    [pscustomobject]@{pattern=(Get-PathPattern $repo);token='<DEV_REPO>'},
    [pscustomobject]@{pattern=(Get-PathPattern ([IO.Path]::GetTempPath()));token='<DEV_TEMP>'},
    [pscustomobject]@{pattern=(Get-PathPattern ([Environment]::GetFolderPath('UserProfile')));token='<DEV_HOME>'},
    [pscustomobject]@{pattern='(?i)[A-Z]:[\\/]+Users[\\/]+[^\\/\s"''<>]+';token='<DEV_HOME>'}
)
function Copy-PublicFile {
    param([string]$From,[string]$To,[string]$SourceId,[string]$Scope,
          [switch]$ProjectText,[switch]$StripRepositoryLinks,[switch]$RootBuildGuide)
    if(!(Test-Path -LiteralPath $From -PathType Leaf)){throw 'Required public input missing: '+$SourceId}
    $target=Resolve-ContentPath $To
    if(Test-Path -LiteralPath $target){throw 'Duplicate public-content path: '+$To}
    $redactions=0;$linksRemoved=0;$guideLinks=0
    if($ProjectText){
        $text=[IO.File]::ReadAllText($From)
        foreach($rule in $pathRules){
            $matches=[regex]::Matches($text,$rule.pattern)
            $redactions+=$matches.Count
            $text=[regex]::Replace($text,$rule.pattern,$rule.token)
        }
        if($StripRepositoryLinks){
            $pattern='\[([^\]]+)\]\((?!https?://)[^)]+\)'
            $linksRemoved=[regex]::Matches($text,$pattern).Count
            $text=[regex]::Replace($text,$pattern,'$1')
        }
        if($RootBuildGuide){
            $text=$text.Replace('(../source/','(source/').Replace('(HISTORY.md)','(docs/HISTORY.md)').Replace('(LORE.md)','(docs/LORE.md)')
            $guideLinks=3
        }
        [IO.File]::WriteAllText($target,$text,$utf8)
    }else{[IO.File]::Copy($From,$target,$false)}
    if([IO.Path]::GetExtension($target) -ieq '.json'){
        [void](Get-Content -LiteralPath $target -Raw|ConvertFrom-Json)
    }
    [void]$copies.Add([pscustomobject][ordered]@{
        source=$SourceId;path=$To;scope=$Scope;originalSha256=(Get-ContentHash $From)
        publicSha256=(Get-ContentHash $target);bytes=(Get-Item -LiteralPath $target).Length
        privatePathRedactions=$redactions;repositoryLinkDestinationsRemoved=$linksRemoved
        portableGuideLinksAdjusted=$guideLinks;exactBytes=((Get-ContentHash $From) -ceq (Get-ContentHash $target))
    })
}
function Copy-LaneFile([string]$Relative,[switch]$ProjectText){
    Copy-PublicFile (Join-Path $lane $Relative) ('source/hrs_1.2.7/'+$Relative) ('hrs_1.2.7/'+$Relative) 'Current corresponding source/development input' -ProjectText:$ProjectText
}

# Preserve current corresponding source exactly, including all relative imports.
foreach($directory in @('dev/src/runtime/main','dev/src/launcher','dev/ui','dev/tools/NativeGraphics','dev/tests')){
    foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $lane $directory) -Recurse -File -Force)){
        $relative=$file.FullName.Substring($lane.Length+1).Replace('\','/')
        if($relative -match '(^|/)(bin|obj|tmp|out|HistoricalRandomStart_State)(/|$)'){continue}
        Copy-LaneFile $relative
    }
}
foreach($relative in @('START.bat','README.md','LICENSE.md','LANE_README.md',
    'dev/BUILD_SETUP_FOUNDATION.md','dev/src/runtime/p0143.ps1','dev/src/runtime/p0143-b17-probe.ps1',
    'dev/qa/POLICY_V2_VECTORS.json','dev/verified/main/d0163.dll','dev/verified/main/ModInfo.xml')){
    Copy-LaneFile $relative
}
foreach($relative in @('dev/qa/rel.json','dev/qa/cases.json',('dev/builds/'+$CandidateId+'/build-record.json'))){
    Copy-LaneFile $relative -ProjectText
}
$gpl='archive/bit_wrecked_mod_framework_template/release_templates/LICENSE-GPL-3.0-or-later.txt'
foreach($to in @('release_templates/LICENSE-GPL-3.0-or-later.txt','source/hrs_1.2.7/release_templates/LICENSE-GPL-3.0-or-later.txt')){
    Copy-PublicFile (Join-Path $repo $gpl) $to $gpl 'Complete existing GPL version 3 license text'
}

# Current reader-facing guide/index pages are supplied authoring sources.
foreach($name in @('BUILD-FROM-SOURCE.md','HISTORY.md','LORE.md')){
    Copy-PublicFile (Join-Path $PSScriptRoot $name) ('docs/'+$name) ('hrs_1.2.7/dev/qa/unified-public-20261004/'+$name) 'Current public documentation' -ProjectText
}
Copy-PublicFile (Join-Path $PSScriptRoot 'BUILD-FROM-SOURCE.md') 'BUILD-FROM-SOURCE.md' 'hrs_1.2.7/dev/qa/unified-public-20261004/BUILD-FROM-SOURCE.md' 'Current public build guide with root-relative links' -ProjectText -RootBuildGuide

foreach($name in @('changes.md','n0008.md','n0009.md','n0010.md','n0138.md','n0192.md','n0226.md','n0227.md','n0230.md','n0231.md')){
    $source='hrs_0.0.8.1/dev/docs/'+$name
    Copy-PublicFile (Join-Path $repo $source) ('history/origins/'+$name) $source 'Historical original design/rationale; superseded for current behavior' -ProjectText -StripRepositoryLinks
}
$history=@(
    @('hrs_1.2.3/HOW_THIS_WAS_MADE.md','history/HOW_THIS_WAS_MADE.md'),
    @('hrs_1.2.4/VERSION_NOTES.md','history/versions/1.2.4.md'),
    @('hrs_1.2.5/VERSION_NOTES.md','history/versions/1.2.5.md'),
    @('HRS_BIOME_SELECTION_DEV_MANIFEST.md','history/versions/BIOME-SELECTION.md'),
    @('HRS_1.2.6_TRADER_NOTICE_DEV_MANIFEST.md','history/versions/TRADER-NOTICE.md'),
    @('HRS_1.2.6_UX_POLISH_WORK_MANIFEST.md','history/versions/NATIVE-UX-1.2.6.md'),
    @('HRS_1.2.7_LANE_WORK_MANIFEST.md','history/versions/DEV-1.2.7.md')
)
foreach($pair in $history){
    Copy-PublicFile (Join-Path $repo $pair[0]) $pair[1] $pair[0] 'Versioned development narrative with original scope' -ProjectText -StripRepositoryLinks
}

# Preserve generic release/QA workflow source as well as the runtime source.
# Registry, locks, frozen archives and generated workspaces are not source inputs.
foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $repo 'qa_cycle') -File -Force)){
    if($file.Extension -notin @('.ps1','.psm1','.md')){continue}
    Copy-PublicFile $file.FullName ('source/qa_cycle/'+$file.Name) ('qa_cycle/'+$file.Name) 'Current generic packaging/QA tool source'
}
foreach($name in @('Prepare-PublicContent.ps1','Verify-PreparedSource.ps1','Extend-PublicContent.ps1','Verify-PublicCandidate.ps1')){
    Copy-PublicFile (Join-Path $PSScriptRoot $name) ('source/support/unified-public-20261004/'+$name) ('hrs_1.2.7/dev/qa/unified-public-20261004/'+$name) 'Current public-content preparation/verification source; original DEV inputs remain external'
}
$newEvidence=@(
    @('hrs_1.2.7/dev/qa/unified-public-package-20261004/tool-verification.json','evidence/qa003/tools/tool-verification.json'),
    @('hrs_1.2.7/dev/qa/unified-public-package-20261004/legacy-tool-verification.json','evidence/qa003/tools/legacy-tool-verification.json'),
    @('hrs_1.2.7/dev/qa/unified-public-package-20261004/TOOLS.md','evidence/qa003/tools/TOOLS.md')
)
foreach($pair in $newEvidence){
    Copy-PublicFile (Join-Path $repo $pair[0]) $pair[1] $pair[0] 'Current candidate-003 generic-tool verification; bounded DEV fixture evidence' -ProjectText -StripRepositoryLinks:([IO.Path]::GetExtension($pair[0]) -ieq '.md')
}
foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'prepared-source-r002') -Recurse -File -Force)){
    $relative=$file.FullName.Substring((Join-Path $PSScriptRoot 'prepared-source-r002').Length+1).Replace('\','/')
    if($relative -match '(^|/)(fixture-bin|fixture-obj|bin|obj)(/|$)' -or $file.Extension -notin @('.json','.txt')){continue}
    Copy-PublicFile $file.FullName ('evidence/qa003/prepared-source/'+$relative) ('hrs_1.2.7/dev/qa/unified-public-20261004/prepared-source-r002/'+$relative) 'Current supplied-source-layout verification; bounded DEV fixture evidence' -ProjectText
}

# Authenticate and project historical supporting evidence, without nested ZIPs,
# executable fixtures, old customer/context/tools or private manager state.
$reviewRoot=Join-Path $historicalRoot 'review'
$pngs=0
foreach($file in @(Get-ChildItem -LiteralPath $reviewRoot -Recurse -File -Force)){
    $relative=$file.FullName.Substring($reviewRoot.Length+1).Replace('\','/')
    if($relative -match '^(test-sources|review-tools|native-graphics|history/foundation-20260821)/' -or
        $relative -in @('README.md','BUILD_SETUP_FOUNDATION.md','DEV-WORK-MANIFEST.md','LANE-README.md','QA-BUNDLE-READINESS.md')){continue}
    if($file.Extension -notin @('.json','.md','.txt','.png','.xml')){continue}
    if($file.Extension -ieq '.png'){
        $safe=$relative -match '^history/native-ux126-dev/geometry/integrated/geometry-' -or
              $relative -match '^review-repairs/callbacks-final/[^/]+/[^/]+/[^/]+\.png$' -or
              $relative -ceq 'history/qa126-sizing-failures/ui-sizing/09-real-drag-wheel-bottom.png' -or
              $relative -ceq 'customer-manager-smoke.png'
        if(!$safe){continue}
        $pngs++
    }
    $text=$file.Extension -in @('.json','.md','.txt','.xml')
    Copy-PublicFile $file.FullName ('evidence/qa002/'+$relative) ('sealed-1.2.7-qa.002-transfer:review/'+$relative) 'Historical candidate-002/earlier supporting evidence; independent QA remains Pending' -ProjectText:$text -StripRepositoryLinks:($file.Extension -ieq '.md')
}
$readme=@'
# Public review evidence

qa003 holds current packaging/source DEV proof: 40 focused unified-package
tool assertions, the preserved generic workflow/branding/QA regressions, and
the supplied source layout's exact pinned deterministic rebuild, design check,
compiled-policy checks, 26 manager assertions and 20 runtime scenarios.
These qualify the new tooling/source handoff within their recorded scope;
they do not pass independent customer QA. Final archive extraction/checksum
verification happens after this immutable evidence snapshot and is recorded
outside the ZIP.

The same archive gives every audience these records. qa002 retains the
repaired predecessor's supporting evidence with its original candidate/source
identity. Its review-repairs records include 20 runtime scenarios, 26 focused
manager assertions, 97 final callback scenarios, compiled-policy checks and
qualified build/package checks. Earlier failed attempts are preserved rather
than silently replaced. These are bounded DEV results, not independent gameplay,
Windows display/accessibility or newcomer QA passes for this new package.

qa002/history/qa126-sizing-failures preserves the original failed 1.2.6 sizing
report and sequences. The safely inspected wheel-bottom screenshot is included;
other old desktop captures are not copied. qa002/history/native-ux126-dev retains
the complete historical four-profile synthetic geometry matrix and its 28
native fixture captures. API/Form.Scale checks are separate from physical
Windows DPI and mouse retests. Current fixture screenshots use disposable fake
installations and names. No game DLLs, saves, raw private logs or manager recovery
state are included here.

Original text evidence is projected only to replace private workstation paths
with <DEV_REPO>, <DEV_TEMP> or <DEV_HOME>, and to remove nonportable repository
Markdown link destinations. Original sealed evidence remains unchanged in the
repository. PUBLIC-PROJECTION.json identifies each original/public hash and
transformation count. Paths, hashes and failed results remain inspectable;
portable projections are never represented as byte-identical sealed originals.

The main entry and current frozen contracts/tools govern this new candidate.
All 46 independent customer QA cases remain Pending. Publication follows QA
and recorded approval, with the entire approved public ZIP unchanged.
'@
[IO.File]::WriteAllText((Resolve-ContentPath 'evidence/README.md'),$readme+"`r`n",$utf8)
$privacyMatches=New-Object 'Collections.Generic.List[string]'
foreach($file in @(Get-ChildItem -LiteralPath $output -Recurse -File -Force)){
    if($file.Extension -notin @('.json','.md','.txt','.ps1','.psm1','.cs','.csproj','.xml','.bat','.cmd')){continue}
    $text=[IO.File]::ReadAllText($file.FullName)
    if($text -match '(?i)[A-Z]:[\\/]+Users[\\/]+'){
        [void]$privacyMatches.Add($file.FullName.Substring($output.Length+1).Replace('\','/'))
    }
}
if($privacyMatches.Count){throw 'Private owner paths remain in public content: '+($privacyMatches.ToArray()-join ', ')}
$projection=[pscustomobject][ordered]@{
    schema='hrs-public-content-projection/v1';candidateId=$CandidateId
    preparedUtc=[DateTime]::UtcNow.ToString('o');historicalTransferCandidate='1.2.7-qa.002'
    historicalTransferSha256=$transferRecord.sha256
    historicalTransferManifestSha256=$transferRecord.transferManifestSha256
    originalSealedFilesChanged=0;privateOwnerPathMatches=0;includedPngCaptures=$pngs
    privatePathRedactions=(@($copies|Measure-Object privatePathRedactions -Sum))[0].Sum
    transformations='Path-only privacy projections and recorded removal/adaptation of nonportable Markdown links. Current code, assets and existing full GPL text retain exact bytes.'
    copies=$copies.ToArray()
}
[IO.File]::WriteAllText((Resolve-ContentPath 'evidence/PUBLIC-PROJECTION.json'),($projection|ConvertTo-Json -Depth 8)+"`r`n",$utf8)
$files=@(Get-ChildItem -LiteralPath $output -Recurse -File -Force|Sort-Object FullName|ForEach-Object{
    [pscustomobject]@{path=$_.FullName.Substring($output.Length+1).Replace('\','/');bytes=$_.Length;sha256=(Get-ContentHash $_.FullName)}
})
$manifest=[pscustomobject][ordered]@{
    schema='hrs-prepared-public-content/v1';candidateId=$CandidateId;files=$files
    excludes='Proprietary game/Harmony/toolchain inputs, nested ZIPs, executable test fixtures, saves, raw private logs, manager state, generated bin/obj/tmp/out trees.'
}
[IO.File]::WriteAllText((Resolve-ContentPath 'evidence/PUBLIC-CONTENT-MANIFEST.json'),($manifest|ConvertTo-Json -Depth 6)+"`r`n",$utf8)
[pscustomobject]@{status='Pass';candidateId=$CandidateId;outputPath=$output;files=$files.Count+1;sourceCopies=$copies.Count;privatePathRedactions=$projection.privatePathRedactions;pngCaptures=$pngs;privateOwnerPathMatches=0;originalSealedFilesChanged=0}
