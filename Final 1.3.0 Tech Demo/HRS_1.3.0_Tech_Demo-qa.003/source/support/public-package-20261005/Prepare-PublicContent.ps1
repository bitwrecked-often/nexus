[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$PublicContentRoot,
    [string]$RepoRoot = '',
    [ValidateSet('1.3.0-qa.003')][string]$CandidateId = '1.3.0-qa.003',
    [string]$FocusedEvidenceDirectory = 'hrs_1.3.0_Tech_Demo/dev/qa/ux-return-20261005/focused-final',
    [string]$ManagerReviewEvidencePath = 'hrs_1.3.0_Tech_Demo/dev/qa/ux-return-20261005/manager-review-final/verification.json',
    [string]$NativeEventLoopEvidenceDirectory = 'hrs_1.3.0_Tech_Demo/dev/qa/native-event-loop-20261005/run-005',
    [string[]]$CallbackEvidencePaths = @(),
    [string[]]$AdditionalEvidencePaths = @(),
    [string[]]$ApprovedImagePaths = @(),
    [string]$PresentationDeltaReceiptPath = ''
)

# Windows PowerShell 5.1 source deliberately uses ASCII only. Reader-facing
# Markdown is copied from UTF-8 authoring files, never embedded as PS literals.
# This prepares reviewable content only. It neither reserves nor exports a
# candidate, changes a registry, touches a game, or grants QA/release approval.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$utf8 = New-Object Text.UTF8Encoding($false)
$oldSha = '8527F11CAAFF4173AB9880FD906E9E7DF4F6C56E45E2B81098F5688C94B27881'
if(!$RepoRoot){$RepoRoot = Join-Path $PSScriptRoot '../../../../'}
$repo = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\','/')
$lane = Join-Path $repo 'hrs_1.3.0_Tech_Demo'
$scratch = [IO.Path]::GetFullPath((Join-Path $lane 'dev/tmp')).TrimEnd('\','/')
$output = [IO.Path]::GetFullPath($PublicContentRoot).TrimEnd('\','/')
$sourcePrefix = 'source/hrs_1.3.0_Tech_Demo/'
$copies = New-Object 'Collections.Generic.List[object]'
$sourceInputs = New-Object 'Collections.Generic.List[object]'
$linkTargets = New-Object 'Collections.Generic.List[object]'
$destinations = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$exclusions = '(^|/)(bin|obj|tmp|out|state|fixture-bin|fixture-obj|HistoricalRandomStart_State|local-runs|privatecaptures|private-captures|runtime-source)(/|$)'

function Get-Sha([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()}
function Assert-NoReparse([string]$Path){
    $walk = [IO.Path]::GetFullPath($Path)
    while($walk){
        if(Test-Path -LiteralPath $walk){
            if((Get-Item -LiteralPath $walk -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){
                throw 'Input/output uses a reparse point; use an ordinary local directory.'
            }
        }
        # The owner-selected workspace is the containment authority. Reject
        # linked inputs beneath it, while allowing its existing OneDrive
        # Documents ancestor (a cloud reparse folder above the workspace).
        if($walk -ieq $repo){break}
        $parent = Split-Path -Parent $walk
        if($parent -eq $walk){break}
        $walk = $parent
    }
}
function Get-SafeRelative([string]$Relative){
    $r = $Relative.Replace('\','/')
    if(!$r -or $r.StartsWith('/') -or $r.Contains(':') -or $r -match '(^|/)(\.|\.\.)(/|$)' -or $r -match '[\x00-\x1f]'){
        throw 'Unsafe relative content path.'
    }
    return $r
}
function Resolve-RepoInput([string]$Relative){
    $r = Get-SafeRelative $Relative
    $p = [IO.Path]::GetFullPath((Join-Path $repo $r))
    if(!$p.StartsWith($repo+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Input escaped DEV repository.'}
    Assert-NoReparse $p
    if(!(Test-Path -LiteralPath $p -PathType Leaf)){throw 'Required public input missing: '+$r}
    return $p
}
function Resolve-Output([string]$Relative){
    $r = Get-SafeRelative $Relative
    if(!$destinations.Add($r)){throw 'Duplicate public content path: '+$r}
    $p = [IO.Path]::GetFullPath((Join-Path $output $r))
    if(!$p.StartsWith($output+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Content escaped output directory.'}
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $p))
    return $p
}
function Get-PathPattern([string]$Path){
    return '(?i)'+((@($Path.TrimEnd('\','/') -split '[\\/]') | ForEach-Object{[regex]::Escape($_)}) -join '[\\/]+')
}
$pathRules = @(
    [pscustomobject]@{pattern=(Get-PathPattern $repo);token='<DEV_REPO>'},
    [pscustomobject]@{pattern=(Get-PathPattern ([IO.Path]::GetTempPath()));token='<DEV_TEMP>'},
    [pscustomobject]@{pattern=(Get-PathPattern ([Environment]::GetFolderPath('UserProfile')));token='<DEV_HOME>'},
    [pscustomobject]@{pattern='(?i)[A-Z]:[\\/]+Users[\\/]+[^\\/\s"''<>]+';token='<DEV_HOME>'}
)
function Copy-PublicFile {
    param([string]$Relative,[string]$To,[string]$Scope,[switch]$ProjectText,[switch]$NormalizeLinks)
    $from = Resolve-RepoInput $Relative
    $originalSha = Get-Sha $from
    $target = Resolve-Output $To
    $redactions = 0
    if($ProjectText){
        $body = [IO.File]::ReadAllText($from)
        foreach($rule in $pathRules){
            $redactions += [regex]::Matches($body,$rule.pattern).Count
            $body = [regex]::Replace($body,$rule.pattern,$rule.token)
        }
        [IO.File]::WriteAllText($target,$body,$utf8)
    }else{[IO.File]::Copy($from,$target,$false)}
    if((Get-Sha $from) -cne $originalSha){throw 'Input changed during preparation: '+$Relative}
    if([IO.Path]::GetExtension($target) -ieq '.json'){
        [void]([IO.File]::ReadAllText($target) | ConvertFrom-Json)
    }
    $record = [pscustomobject][ordered]@{
        source=$Relative.Replace('\','/');path=$To.Replace('\','/');scope=$Scope
        originalSha256=$originalSha;publicSha256=(Get-Sha $target)
        bytes=(Get-Item -LiteralPath $target).Length;privatePathRedactions=$redactions
        repositoryLinkDestinationsRemoved=0;portableLinkDestinationsRewritten=0;exactBytes=((Get-Sha $target) -ceq $originalSha)
    }
    [void]$copies.Add($record)
    [void]$sourceInputs.Add([pscustomobject]@{relative=$Relative;sha256=$originalSha})
    if($NormalizeLinks){[void]$linkTargets.Add([pscustomobject]@{target=$target;record=$record})}
}
function Copy-Lane([string]$Relative,[switch]$ProjectText,[switch]$NormalizeLinks){
    Copy-PublicFile ('hrs_1.3.0_Tech_Demo/'+$Relative) ($sourcePrefix+$Relative) 'Current 1.3.0 corresponding source/development input' -ProjectText:$ProjectText -NormalizeLinks:$NormalizeLinks
}
function Copy-LaneTree([string]$Relative){
    $start = Join-Path $lane (Get-SafeRelative $Relative)
    Assert-NoReparse $start
    if(!(Test-Path -LiteralPath $start -PathType Container)){throw 'Required source directory missing: '+$Relative}
    $queue = New-Object 'Collections.Generic.Queue[string]'
    $queue.Enqueue($start)
    while($queue.Count -gt 0){
        foreach($item in @(Get-ChildItem -LiteralPath $queue.Dequeue() -Force)){
            $r = $item.FullName.Substring($lane.Length+1).Replace('\','/')
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Source tree contains a reparse point: '+$r}
            if($r -match $exclusions){continue}
            if($item.PSIsContainer){$queue.Enqueue($item.FullName);continue}
            if($item.Name -ieq 'native-build-record.private.json'){continue}
            if($item.Extension -in @('.dll','.exe','.pdb','.zip')){throw 'Unexpected generated/proprietary binary in source tree: '+$r}
            # JSON vectors/recipes and all executable source retain exact bytes.
            $prose = $item.Extension -in @('.md','.txt')
            Copy-Lane $r -ProjectText:$prose -NormalizeLinks:($item.Extension -ieq '.md')
        }
    }
}
function Copy-Evidence([string]$Relative,[string]$To){
    $ext = [IO.Path]::GetExtension($Relative)
    if($ext -notin @('.json','.md','.txt','.xml','.diff')){throw 'Evidence must be an explicit text receipt/document.'}
    if($Relative.Replace('\','/') -match $exclusions -or $Relative -match 'native-build-record\.private|/qa-review/|privatecaptures'){
        throw 'Private/generated evidence input rejected.'
    }
    Copy-PublicFile $Relative $To 'Current bounded DEV evidence; independent customer QA and live campaign remain Pending' -ProjectText -NormalizeLinks:($ext -ieq '.md')
}
function Assert-ManagerReceipt([string]$Relative,[string]$ManagerSha){
    $v = [IO.File]::ReadAllText((Resolve-RepoInput $Relative)) | ConvertFrom-Json
    if($v.status -cne 'Pass' -or $v.sourceSha256 -notin $acceptedManagerEvidenceHashes){throw 'Manager receipt is neither current nor covered by the verified presentation-only delta: '+$Relative}
}

Assert-NoReparse $repo
Assert-NoReparse $output
if(!$output.StartsWith($scratch+'\',[StringComparison]::OrdinalIgnoreCase) -or $output -ieq $scratch){
    throw 'PublicContentRoot must be a new descendant of hrs_1.3.0_Tech_Demo/dev/tmp.'
}
if(Test-Path -LiteralPath $output){throw 'PublicContentRoot already exists; choose a fresh name.'}
$rel = [IO.File]::ReadAllText((Resolve-RepoInput 'hrs_1.3.0_Tech_Demo/dev/qa/rel.json')) | ConvertFrom-Json
$cases = [IO.File]::ReadAllText((Resolve-RepoInput 'hrs_1.3.0_Tech_Demo/dev/qa/cases.json')) | ConvertFrom-Json
if($rel.candidateId -cne $CandidateId -or $rel.version -cne '1.3.0' -or $rel.buildId -cne 'r130' -or
   $cases.candidateId -cne $CandidateId -or $cases.releaseVersion -cne '1.3.0' -or
   @($cases.requiredCases).Count -ne 46 -or @($cases.requiredCases | Where-Object{$_.status -cne 'Pending'}).Count -ne 0){
    throw 'Current 1.3.0 identity/46-Pending contract changed; reconcile before preparing content.'
}
if(@($rel.sourceSnapshot.sourceHashes).Count -ne 15){throw 'Expected fifteen runtime source pins.'}
foreach($pin in $rel.sourceSnapshot.sourceHashes){
    if((Get-Sha (Resolve-RepoInput ('hrs_1.3.0_Tech_Demo/dev/src/runtime/main/'+$pin.path))) -cne $pin.sha256){throw 'Runtime source pin mismatch: '+$pin.path}
}
foreach($artifact in $rel.artifacts){
    $p = Resolve-RepoInput ('hrs_1.3.0_Tech_Demo/'+$artifact.path)
    if((Get-Sha $p) -cne $artifact.sha256 -or (Get-Item -LiteralPath $p).Length -ne $artifact.bytes){throw 'Qualified runtime artifact mismatch.'}
}
if((Get-Sha (Resolve-RepoInput ('hrs_1.3.0_Tech_Demo/'+$rel.build.recordPath))) -cne $rel.build.recordSha256){throw 'Public qualified build record mismatch.'}
$managerSha = Get-Sha (Resolve-RepoInput 'hrs_1.3.0_Tech_Demo/dev/ui/p0158.ps1')
$acceptedManagerEvidenceHashes = @($managerSha)
$presentationDelta = $null
if($PresentationDeltaReceiptPath){
    $presentationDelta = [IO.File]::ReadAllText((Resolve-RepoInput $PresentationDeltaReceiptPath)) | ConvertFrom-Json
    if($presentationDelta.schema -cne 'hrs-manager-label-only-carry/v1' -or
       $presentationDelta.status -cne 'Pass' -or $presentationDelta.sourceSha256 -cne $managerSha -or
       $presentationDelta.expectedTransformedManagerSha256 -cne $managerSha -or
       $presentationDelta.baselineManagerSha256 -cne '5C522439354FEF0E6C370D5C92C99DE74D5453BD2B8F34B432A5394EDD18073D' -or
       $presentationDelta.baselineArchiveSha256 -cne '48AD02DF397917C95E7BD27422C030910860824F9B11CE152258DA47FB68DE45' -or
       !$presentationDelta.managerLabelOnlyEquality -or !$presentationDelta.recipeLabelOnlyEquality -or
       !$presentationDelta.recipeToolingLabelOnlyEquality -or !$presentationDelta.embeddingCurrent -or !$presentationDelta.nativeLabelPass){
        throw 'Presentation-only evidence carry requires the exact sealed baseline, current source and verified label/embedding delta.'
    }
    $baselineArchive = Resolve-RepoInput 'qa_cycle/candidates/HRS_1.3.0_Tech_Demo-qa.002.zip'
    if((Get-Sha $baselineArchive) -cne $presentationDelta.baselineArchiveSha256){throw 'Presentation baseline archive changed.'}
    if((Get-Sha (Resolve-RepoInput 'hrs_1.3.0_Tech_Demo/dev/tools/NativeGraphics/recipes/bitwrecked-quiet.json')) -cne $presentationDelta.recipeSha256 -or
       (Get-Sha (Resolve-RepoInput 'hrs_1.3.0_Tech_Demo/dev/tools/NativeGraphics/Recipes.psm1')) -cne $presentationDelta.recipesModuleSha256 -or
       (Get-Sha (Resolve-RepoInput 'hrs_1.3.0_Tech_Demo/dev/tools/NativeGraphics/NativeControls.cs')) -cne $presentationDelta.controlsSha256){throw 'Presentation recipe/tooling source changed after its exact delta check.'}
    $acceptedManagerEvidenceHashes += $presentationDelta.baselineManagerSha256
}
foreach($receipt in @(
    ($FocusedEvidenceDirectory+'/verification.json'),
    $ManagerReviewEvidencePath,
    ($NativeEventLoopEvidenceDirectory+'/verification.json')
)){Assert-ManagerReceipt $receipt $managerSha}
foreach($name in @('README.md','START.bat','LICENSE.md','BUILD-FROM-SOURCE.md','START-HERE.md','QA-RUNBOOK.md','HISTORY.md','LORE.md','EVIDENCE.md','.gitattributes')){
    [void](Resolve-RepoInput ('hrs_1.3.0_Tech_Demo/dev/qa/public-package-20261005/templates/'+$name))
}
$oldPath = Resolve-RepoInput 'qa_cycle/candidates/1.2.7-qa.003.zip'
if((Get-Sha $oldPath) -cne $oldSha){throw 'Original frozen 1.2.7-qa.003 archive checksum mismatch.'}

$zip = [IO.Compression.ZipFile]::OpenRead($oldPath)
try{
    $entries = New-Object 'Collections.Generic.Dictionary[string,object]' ([StringComparer]::OrdinalIgnoreCase)
    foreach($entry in $zip.Entries){
        if(!$entry.Name){throw 'Unexpected directory entry in frozen archive.'}
        $n = Get-SafeRelative $entry.FullName
        if($entries.ContainsKey($n)){throw 'Frozen archive contains a duplicate normalized path.'}
        $entries.Add($n,$entry)
    }
    if(!$entries.ContainsKey('distribution-manifest.json')){throw 'Historical distribution manifest missing.'}
    $reader = New-Object IO.StreamReader($entries['distribution-manifest.json'].Open())
    try{$manifest = $reader.ReadToEnd() | ConvertFrom-Json}finally{$reader.Dispose()}
    if($manifest.candidateId -cne '1.2.7-qa.003' -or @($manifest.files).Count -ne ($entries.Count-1)){throw 'Historical archive membership does not match its manifest.'}
    $members = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach($file in $manifest.files){
        $n = Get-SafeRelative $file.path
        if(!$members.Add($n) -or !$entries.ContainsKey($n) -or $entries[$n].Length -ne $file.bytes){throw 'Historical member mismatch: '+$n}
        $stream = $entries[$n].Open(); $sha = [Security.Cryptography.SHA256]::Create()
        try{$hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}finally{$sha.Dispose();$stream.Dispose()}
        if($hash -cne $file.sha256){throw 'Historical member hash mismatch: '+$n}
    }
    [void][IO.Directory]::CreateDirectory($output)
    foreach($file in $manifest.files){
        $n = $file.path.Replace('\','/')
        $to = ''
        if($n.StartsWith('source/hrs_1.2.7/',[StringComparison]::Ordinal) -or $n.StartsWith('history/',[StringComparison]::Ordinal)){$to = $n}
        elseif($n.StartsWith('evidence/',[StringComparison]::Ordinal)){$to = 'evidence/prior-1.2.7/'+$n.Substring(9)}
        elseif($n -in @('docs/HISTORY.md','docs/LORE.md')){$to = 'history/prior-public-index-1.2.7/'+[IO.Path]::GetFileName($n)}
        elseif($n -ceq 'release_templates/LICENSE-GPL-3.0-or-later.txt'){$to = $n}
        if(!$to){continue}
        $target = Resolve-Output $to
        $stream = $entries[$n].Open(); $writer = [IO.File]::Open($target,[IO.FileMode]::CreateNew)
        try{$stream.CopyTo($writer)}finally{$writer.Dispose();$stream.Dispose()}
        if((Get-Sha $target) -cne $file.sha256){throw 'Historical byte preservation failed: '+$n}
        [void]$copies.Add([pscustomobject][ordered]@{
            source=('frozen-1.2.7-qa.003.zip:'+ $n);path=$to;scope='Previously public historical record/source; original scope and bytes preserved'
            originalSha256=$file.sha256;publicSha256=$file.sha256;bytes=$file.bytes
            privatePathRedactions=0;repositoryLinkDestinationsRemoved=0;portableLinkDestinationsRewritten=0;exactBytes=$true
        })
    }
}finally{$zip.Dispose()}

foreach($tree in @('dev/src/runtime/main','dev/src/launcher','dev/ui','dev/tools/NativeGraphics','dev/tests')){Copy-LaneTree $tree}
foreach($r in @('START.bat','README.md','LICENSE.md','LANE_README.md','BASELINE_PROVENANCE.json','dev/BUILD_SETUP_FOUNDATION.md',
    'dev/src/runtime/p0143.ps1','dev/src/runtime/p0143-b17-probe.ps1','dev/qa/POLICY_V2_VECTORS.json',
    'dev/verified/main/d0163.dll','dev/verified/main/ModInfo.xml','dev/qa/rel.json','dev/qa/cases.json',
    'dev/qa/QA_BUNDLE_READINESS.md',('dev/builds/'+$CandidateId+'/build-record.json'))){
    $ext = [IO.Path]::GetExtension($r)
    $project = $ext -ieq '.md' -or $r -in @('BASELINE_PROVENANCE.json','dev/qa/rel.json','dev/qa/cases.json',('dev/builds/'+$CandidateId+'/build-record.json'))
    Copy-Lane $r -ProjectText:$project -NormalizeLinks:($ext -ieq '.md')
}
$licenseTarget = Resolve-Output ($sourcePrefix+'release_templates/LICENSE-GPL-3.0-or-later.txt')
[IO.File]::Copy((Join-Path $output 'release_templates/LICENSE-GPL-3.0-or-later.txt'),$licenseTarget,$false)
[void]$copies.Add([pscustomobject][ordered]@{
    source='frozen-1.2.7-qa.003.zip:release_templates/LICENSE-GPL-3.0-or-later.txt';path=($sourcePrefix+'release_templates/LICENSE-GPL-3.0-or-later.txt')
    scope='Complete GPL version 3 license text';originalSha256=(Get-Sha $licenseTarget);publicSha256=(Get-Sha $licenseTarget)
    bytes=(Get-Item -LiteralPath $licenseTarget).Length;privatePathRedactions=0;repositoryLinkDestinationsRemoved=0;portableLinkDestinationsRewritten=0;exactBytes=$true
})
Copy-PublicFile 'HRS_1.3.0_TECH_DEMO_WORK_MANIFEST.md' 'docs/DEV-1.3.0-TECH-DEMO.md' 'Current owner-directed development scope/resume record' -ProjectText -NormalizeLinks
foreach($r in @('AGENTS.md','CURRENT_BASELINE.md','CURRENT_RELEASE.json','DEVELOPMENT_CYCLE_DOCTRINE.md',
    'HRS_DEV_QA_NEXUS_WORKFLOW.md','.agents/skills/hrs-qa-bundle/SKILL.md')){
    Copy-PublicFile $r ('source/support/current-dev-guidance/'+$r) 'Current DEV entry/doctrine; public-release map remains its preserved earlier identity' -ProjectText -NormalizeLinks:([IO.Path]::GetExtension($r) -ieq '.md')
}
foreach($f in @(Get-ChildItem -LiteralPath (Join-Path $repo 'qa_cycle') -File -Force)){
    if($f.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'qa_cycle source is linked.'}
    if($f.Extension -notin @('.ps1','.psm1','.md')){continue}
    Copy-PublicFile ('qa_cycle/'+$f.Name) ('source/qa_cycle/'+$f.Name) 'Current generic candidate/QA workflow source; no registry, archives or generated workspaces' -ProjectText:($f.Extension -ieq '.md') -NormalizeLinks:($f.Extension -ieq '.md')
}
foreach($name in @('README.md','START.bat','LICENSE.md','BUILD-FROM-SOURCE.md','START-HERE.md','QA-RUNBOOK.md','.gitattributes')){
    Copy-PublicFile ('hrs_1.3.0_Tech_Demo/dev/qa/public-package-20261005/templates/'+$name) $name 'Current UTF-8 public entry/documentation authoring source'
}
foreach($pair in @(@('HISTORY.md','docs/HISTORY.md'),@('LORE.md','docs/LORE.md'),@('EVIDENCE.md','evidence/README.md'))){
    Copy-PublicFile ('hrs_1.3.0_Tech_Demo/dev/qa/public-package-20261005/templates/'+$pair[0]) $pair[1] 'Current UTF-8 public historical/evidence scope index'
}
# The recipe itself and its authoring templates are corresponding build tools.
foreach($r in @('Prepare-PublicContent.ps1','Verify-PublicCandidate.ps1','Prepare-FinalSnapshot.ps1','New-Candidate002.ps1','New-Candidate003.ps1')){
    Copy-PublicFile ('hrs_1.3.0_Tech_Demo/dev/qa/public-package-20261005/'+$r) ('source/support/public-package-20261005/'+$r) 'Public-content recipe source; authenticated historical archive and DEV receipts remain inputs'
}
foreach($f in @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'templates') -File -Force)){
    if($f.Extension -notin @('.md','.bat') -and $f.Name -cne '.gitattributes'){continue}
    Copy-PublicFile ('hrs_1.3.0_Tech_Demo/dev/qa/public-package-20261005/templates/'+$f.Name) ('source/support/public-package-20261005/templates/'+$f.Name) 'Public authoring templates (UTF-8 Markdown, exact source bytes)'
}
foreach($r in @('dev/qa/runtime-chain-20261005/Test-MutationDetection.ps1','dev/qa/intake-20261005/Qualify-Build.ps1','dev/qa/intake-20261005/Verify-Preservation.ps1')){Copy-Lane $r}

$evidencePairs = @(
    @('runtime-chain-20261005/WORK.md','runtime-chain/WORK.md'),
    @('runtime-chain-20261005/run-002/verification.json','runtime-chain/run-002/verification.json'),
    @('runtime-chain-20261005/run-002/fixture-cases.json','runtime-chain/run-002/fixture-cases.json'),
    @('runtime-chain-20261005/run-002/fixture-build.txt','runtime-chain/run-002/fixture-build.txt'),
    @('runtime-chain-20261005/mutations-003/verification.json','runtime-chain/mutations-003/verification.json'),
    @('policy-chain-20261005/verification.json','policy-chain/verification.json'),
    @('policy-chain-20261005/invalid-writer/writer-invalid-fixtures.json','policy-chain/writer-invalid-fixtures.json'),
    @('packaging-tools-20261005/unified-verification.json','packaging-tools/unified-verification.json'),
    @('packaging-tools-20261005/legacy-tools-verification.json','packaging-tools/legacy-tools-verification.json'),
    @('packaging-tools-20261005/edition-verification.json','packaging-tools/edition-verification.json'),
    @('packaging-tools-20261005/WORK.md','packaging-tools/WORK.md'),
    @('intake-20261005/build-qualification.json','build/build-qualification.json'),
    @('intake-20261005/preservation-verification.json','intake/preservation-verification.json')
)
foreach($pair in $evidencePairs){Copy-Evidence ('hrs_1.3.0_Tech_Demo/dev/qa/'+$pair[0]) ('evidence/current/'+$pair[1])}
foreach($name in @('verification.json','assertions.json','geometry.json','output.txt')){
    Copy-Evidence ($FocusedEvidenceDirectory+'/'+$name) ('evidence/current/manager/focused/'+$name)
}
Copy-Evidence $ManagerReviewEvidencePath 'evidence/current/manager/review-repairs/verification.json'
if($PresentationDeltaReceiptPath){
    $deltaDirectory=(Split-Path -Parent $PresentationDeltaReceiptPath).Replace('\','/')
    foreach($deltaName in @('verification.json','assertions.json','native-loop-receipt.json','manager.diff','recipe.diff','recipe-tooling.diff')){
        Copy-Evidence ($deltaDirectory+'/'+$deltaName) ('evidence/current/manager/presentation-delta/'+$deltaName)
    }
}
foreach($name in @('verification.json','native-events.json','native-errors.json','output.txt')){
    Copy-Evidence ($NativeEventLoopEvidenceDirectory+'/'+$name) ('evidence/current/native-event-loop/'+$name)
}
foreach($r in $CallbackEvidencePaths){
    $from=Resolve-RepoInput $r
    if([IO.Path]::GetExtension($r) -ieq '.json'){
        $rows=@([IO.File]::ReadAllText($from) | ConvertFrom-Json)
        foreach($row in $rows){
            if($row.PSObject.Properties['sourceSha256'] -and $row.sourceSha256 -notin $acceptedManagerEvidenceHashes){throw 'Callback receipt is outside the verified presentation-only carry: '+$r}
            if($row.PSObject.Properties['sourceAfterSha256'] -and $row.sourceAfterSha256 -notin $acceptedManagerEvidenceHashes){throw 'Callback source is outside the verified presentation-only carry: '+$r}
        }
    }
    if($r.Replace('\','/') -notmatch '/callbacks[^/]*/(.+)$'){throw 'Callback evidence must belong to an explicit callback evidence directory.'}
    Copy-Evidence $r ('evidence/current/manager/callbacks/'+(Get-SafeRelative $Matches[1]))
}
foreach($mutation in @('completed-return-branch-disabled','protection-opt-out-guard-removed','failed-trader-filter-restoration-removed')){
    foreach($name in @('verification.json','fixture-cases.json','fixture-build.txt')){
        Copy-Evidence ('hrs_1.3.0_Tech_Demo/dev/qa/runtime-chain-20261005/mutations-003/'+$mutation+'/results/'+$name) ('evidence/current/runtime-chain/mutations-003/'+$mutation+'/results/'+$name)
    }
}
foreach($name in @('INTAKE.md','intake-verification.json')){
    Copy-Evidence ('hrs_1.2.7/dev/qa/qa-final-intake-20261005/'+$name) ('evidence/current/intake/'+$name)
}
foreach($name in @('DEV-TODO.md','HUMAN-TEST.md','DEV-WORKSTATION.md')){
    Copy-Evidence ('QA Return Final 20261005/dev-handoff/hrs-1.2.7-qa.003-review/'+$name) ('evidence/current/qa-return/'+$name)
}
foreach($r in $AdditionalEvidencePaths){
    $n = Get-SafeRelative $r
    $prefix='hrs_1.3.0_Tech_Demo/dev/qa/'
    $relative=if($n.StartsWith($prefix,[StringComparison]::Ordinal)){$n.Substring($prefix.Length)}else{$n}
    Copy-Evidence $n ('evidence/current/additional/'+$relative)
}
foreach($r in $ApprovedImagePaths){
    $n = Get-SafeRelative $r
    if(!$n.StartsWith('hrs_1.3.0_Tech_Demo/dev/qa/',[StringComparison]::Ordinal) -or [IO.Path]::GetExtension($n) -notin @('.png','.jpg','.jpeg')){
        throw 'Approved images must be explicitly inspected current-lane QA images.'
    }
    if($n -match $exclusions){throw 'Private/generated image rejected.'}
    Copy-PublicFile $n ('evidence/current/inspected-images/'+$n.Substring('hrs_1.3.0_Tech_Demo/dev/qa/'.Length)) 'Visually inspected bounded DEV UI capture; no human/display/gameplay acceptance inferred'
}

# Map the original DEV location to its included public destination. Current
# prose may refer across lanes/QA directories; preserve a useful portable link
# whenever that exact input has a public counterpart. Historical source and
# records are not rewritten, including their original historical link gaps.
$publicBySource = New-Object 'Collections.Generic.Dictionary[string,string]' ([StringComparer]::OrdinalIgnoreCase)
foreach($record in $copies){
    $origin=$record.source
    if($origin.StartsWith('frozen-1.2.7-qa.003.zip:source/hrs_1.2.7/',[StringComparison]::Ordinal)){
        $origin=$origin.Substring('frozen-1.2.7-qa.003.zip:source/'.Length)
    }elseif($origin.StartsWith('frozen-1.2.7-qa.003.zip:',[StringComparison]::Ordinal)){continue}
    $origin=[IO.Path]::GetFullPath((Join-Path $repo $origin))
    if(!$publicBySource.ContainsKey($origin)){$publicBySource.Add($origin,[IO.Path]::GetFullPath((Join-Path $output $record.path)))}
}
$historicalOrigins=@(
    @('hrs_1.2.3/HOW_THIS_WAS_MADE.md','history/HOW_THIS_WAS_MADE.md'),
    @('hrs_1.2.4/VERSION_NOTES.md','history/versions/1.2.4.md'),
    @('hrs_1.2.5/VERSION_NOTES.md','history/versions/1.2.5.md'),
    @('HRS_BIOME_SELECTION_DEV_MANIFEST.md','history/versions/BIOME-SELECTION.md'),
    @('HRS_1.2.6_TRADER_NOTICE_DEV_MANIFEST.md','history/versions/TRADER-NOTICE.md'),
    @('HRS_1.2.6_UX_POLISH_WORK_MANIFEST.md','history/versions/NATIVE-UX-1.2.6.md'),
    @('HRS_1.2.7_LANE_WORK_MANIFEST.md','history/versions/DEV-1.2.7.md')
)
foreach($f in @(Get-ChildItem -LiteralPath (Join-Path $output 'history/origins') -File)){
    $historicalOrigins+=,@(('hrs_0.0.8.1/dev/docs/'+$f.Name),('history/origins/'+$f.Name))
}
foreach($pair in $historicalOrigins){
    $origin=[IO.Path]::GetFullPath((Join-Path $repo $pair[0]))
    $target=[IO.Path]::GetFullPath((Join-Path $output $pair[1]))
    if((Test-Path -LiteralPath $target -PathType Leaf) -and !$publicBySource.ContainsKey($origin)){$publicBySource.Add($origin,$target)}
}
foreach($item in $linkTargets){
    $body = [IO.File]::ReadAllText($item.target)
    $sourcePath=[IO.Path]::GetFullPath((Join-Path $repo $item.record.source))
    $linkMatches = [regex]::Matches($body,'\[([^\]]+)\]\(([^)]+)\)')
    for($i=$linkMatches.Count-1;$i -ge 0;$i--){
        $m=$linkMatches[$i];$raw=$m.Groups[2].Value.Trim('<','>')
        if($raw -match '^(https?://|mailto:|#)'){continue}
        $parts=$raw.Split([char]'#',2);$uri=[Uri]::UnescapeDataString($parts[0])
        $fragment='';if($parts.Count -gt 1){$fragment='#'+$parts[1]}
        $valid=$false
        try{
            $resolved=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $item.target) $uri))
            $valid=$resolved.StartsWith($output+'\',[StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolved)
            if(!$valid){
                $original=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $sourcePath) $uri))
                if($publicBySource.ContainsKey($original)){
                    $baseUri=New-Object Uri(((Split-Path -Parent $item.target).TrimEnd('\','/')+'\'))
                    $targetUri=New-Object Uri($publicBySource[$original])
                    $newUri=$baseUri.MakeRelativeUri($targetUri).ToString()+$fragment
                    $replacement='['+$m.Groups[1].Value+']('+$newUri+')'
                    $body=$body.Remove($m.Index,$m.Length).Insert($m.Index,$replacement)
                    $item.record.portableLinkDestinationsRewritten++
                    $valid=$true
                }
            }
        }catch{$valid=$false}
        if(!$valid){
            $body=$body.Remove($m.Index,$m.Length).Insert($m.Index,$m.Groups[1].Value)
            $item.record.repositoryLinkDestinationsRemoved++
        }
    }
    [IO.File]::WriteAllText($item.target,$body,$utf8)
    $item.record.publicSha256=Get-Sha $item.target
    $item.record.bytes=(Get-Item -LiteralPath $item.target).Length
    $item.record.exactBytes=($item.record.publicSha256 -ceq $item.record.originalSha256)
}
# Reject privacy leaks in exact code/history as well as projected documents.
# Executable source bytes are never silently rewritten to achieve privacy.
foreach($f in @(Get-ChildItem -LiteralPath $output -Recurse -File -Force)){
    if($f.Extension -in @('.md','.json','.txt','.xml','.diff','.ps1','.psm1','.cs','.csproj','.bat','.cmd')){
        $body=[IO.File]::ReadAllText($f.FullName)
        if($body -match '(?i)[A-Z]:[\\/]+Users[\\/]+[^\\/\s"''<>]+'){
            throw 'Private user path remains in public text; inspect input rather than alter executable/history bytes: '+$f.FullName.Substring($output.Length+1)
        }
        if($f.Extension -ieq '.json'){[void]($body | ConvertFrom-Json)}
    }
}
foreach($inputRecord in $sourceInputs){
    if((Get-Sha (Resolve-RepoInput $inputRecord.relative)) -cne $inputRecord.sha256){throw 'Input drifted before content snapshot completed: '+$inputRecord.relative}
}
if((Get-Sha $oldPath) -cne $oldSha){throw 'Historical archive changed during preparation.'}
$projection = [ordered]@{
    schema='hrs-public-projection/v2';candidateId=$CandidateId;releaseVersion='1.3.0';edition='Tech Demo'
    preparedUtc=[DateTime]::UtcNow.ToString('o');historicalArchiveSha256=$oldSha
    historicalArchiveCandidate='1.2.7-qa.003';managerSourceSha256=$managerSha
    managerEvidenceHashes=$acceptedManagerEvidenceHashes
    managerEvidenceScope=if($PresentationDeltaReceiptPath){'Earlier source-bound manager checks remain original receipts. Their behavior evidence is carried only through the explicit label-only presentation delta; current rendering is separately checked. No fresh callback or customer QA pass is inferred.'}else{'Manager evidence receipts bind directly to current source.'}
    policy='Executable source/current runtime and all prior public historical bytes preserved exactly. Current prose/JSON evidence projects private paths; current prose rewrites included counterparts to portable links and removes unavailable repository-link destinations. Original/public hashes record every copied input.'
    independentQa='Pending';requiredCases=46;liveCampaign='Pending';exported=$false
    files=@($copies.ToArray() | Sort-Object path)
}
$projectionPath=Resolve-Output 'evidence/PUBLIC-PROJECTION.json'
[IO.File]::WriteAllText($projectionPath,($projection | ConvertTo-Json -Depth 30)+[Environment]::NewLine,$utf8)
$contentFiles=@(Get-ChildItem -LiteralPath $output -Recurse -File -Force | ForEach-Object{
    [pscustomobject][ordered]@{path=$_.FullName.Substring($output.Length+1).Replace('\','/');bytes=$_.Length;sha256=(Get-Sha $_.FullName)}
} | Sort-Object path)
$contentManifest=[ordered]@{
    schema='hrs-public-content-manifest/v2';candidateId=$CandidateId;releaseVersion='1.3.0'
    scope='Prepared public-content subset only; excludes this manifest and later exporter-owned customer/context/tools/distribution manifest/receipt. The final outer distribution manifest authenticates the complete archive.'
    files=$contentFiles
}
$manifestPath=Resolve-Output 'evidence/PUBLIC-CONTENT-MANIFEST.json'
[IO.File]::WriteAllText($manifestPath,($contentManifest | ConvertTo-Json -Depth 20)+[Environment]::NewLine,$utf8)
[pscustomobject][ordered]@{
    schema='hrs130-public-content-preparation/v1';status='Pass';candidateId=$CandidateId
    publicContentRoot=$output;historicalArchiveSha256=$oldSha;managerSourceSha256=$managerSha
    preparedFiles=($contentFiles.Count+1);copiedInputs=$copies.Count
    exactCopiedInputs=@($copies | Where-Object{$_.exactBytes}).Count
    projectedCopiedInputs=@($copies | Where-Object{!$_.exactBytes}).Count
    projectionSha256=(Get-Sha $projectionPath);contentManifestSha256=(Get-Sha $manifestPath)
    independentQa='Pending';requiredCases=46;liveCampaign='Pending';candidateReserved=$false;candidateExported=$false
}
