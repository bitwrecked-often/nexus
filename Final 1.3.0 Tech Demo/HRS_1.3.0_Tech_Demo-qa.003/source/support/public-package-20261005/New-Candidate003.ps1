[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$ExpectedManagerSha256
)

# Candidate 003 changes the visible Game Name label. Reuse the authenticated
# current-version build byte for byte, preserve the sealed 001/002 exports and
# current 002 contracts, and bind the new manager separately. No runtime build,
# game write, candidate reservation/export, or independent QA pass occurs here.
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$ExpectedManagerSha256=$ExpectedManagerSha256.ToUpperInvariant()
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..')).TrimEnd('\','/')
$lane=Join-Path $repo 'hrs_1.3.0_Tech_Demo'
$releasePath=Join-Path $lane 'dev/qa/rel.json'
$contractPath=Join-Path $lane 'dev/qa/cases.json'
$managerPath=Join-Path $lane 'dev/ui/p0158.ps1'
$recipePath=Join-Path $lane 'dev/tools/NativeGraphics/recipes/bitwrecked-quiet.json'
$checkpoint=Join-Path $PSScriptRoot 'candidate-002-checkpoint'
$receiptPath=Join-Path $PSScriptRoot 'candidate-003-build-reuse.json'
$newBuildRelative='dev/builds/1.3.0-qa.003/build-record.json'
$newBuild=Join-Path $lane $newBuildRelative
$buildSha='01CE59B48AEB3DE6A21010206320B84883BAB34A8F04D640C01A4F4FC9BBEB0F'
$dllSha='6E143C99DB7519A4D42B047225E7ADBB1C8D3009EFD8E4E18DCA154719316D32'
$xmlSha='896451F71AF3B2BF45E09924CBEAD606E0BA2950FD18E1D50B22FE0ACACF69A6'
$utf8=New-Object Text.UTF8Encoding($false)

function Get-Sha([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()}
function Assert-OrdinaryPath([string]$Path){
    $p=[IO.Path]::GetFullPath($Path)
    if($p -ine $repo -and !$p.StartsWith($repo+'\',[StringComparison]::OrdinalIgnoreCase)){
        throw 'Candidate bookkeeping input/output escaped the authorized DEV repository.'
    }
    while($p){
        if((Test-Path -LiteralPath $p) -and ((Get-Item -LiteralPath $p -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){
            throw 'Use ordinary local input/output paths, without reparse points.'
        }
        # The owner explicitly selected this DEV repo. OneDrive cloud metadata
        # above that boundary is not a link inside the candidate workspace.
        if($p -ieq $repo){break}
        $next=Split-Path -Parent $p
        if($next -eq $p){break}
        $p=$next
    }
}
function Get-ArchiveEntrySha([string]$Archive,[string]$Relative){
    $z=[IO.Compression.ZipFile]::OpenRead($Archive)
    try{
        $entries=@($z.Entries | Where-Object{$_.FullName.Replace('\','/') -ceq $Relative})
        if($entries.Count -ne 1){throw 'Missing/duplicate authenticated prior archive entry: '+$Relative}
        $stream=$entries[0].Open();$sha=[Security.Cryptography.SHA256]::Create()
        try{return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}
        finally{$sha.Dispose();$stream.Dispose()}
    }finally{$z.Dispose()}
}
foreach($p in @($repo,$releasePath,$contractPath,$managerPath,$recipePath,$checkpoint,$receiptPath,$newBuild)){Assert-OrdinaryPath $p}
foreach($p in @($checkpoint,$receiptPath,(Split-Path -Parent $newBuild))){
    if(Test-Path -LiteralPath $p){throw 'Preserve existing checkpoint/receipt/build directory; this helper requires a fresh candidate-003 transition.'}
}
$registryPath=Join-Path $repo 'qa_cycle/candidate-registry.json'
$registrySha=Get-Sha $registryPath
$registry=[IO.File]::ReadAllText($registryPath) | ConvertFrom-Json
if(@($registry.records | Where-Object{$_.candidateId -ceq '1.3.0-qa.003'}).Count){throw 'Candidate 003 is already reserved; preserve that identity.'}
$preserved=@()
foreach($pin in @(
    [pscustomobject]@{id='1.3.0-qa.001';sha='1E6DA4C88682508FD74E6A83011D74A86BD90B26C5CFAAFEC0EDB5A5FDC97ADC'},
    [pscustomobject]@{id='1.3.0-qa.002';sha='48AD02DF397917C95E7BD27422C030910860824F9B11CE152258DA47FB68DE45'}
)){
    $record=@($registry.records | Where-Object{$_.candidateId -ceq $pin.id})
    if($record.Count -ne 1 -or $record[0].status -cne 'exported-awaiting-live-qa' -or $record[0].archiveSha256 -cne $pin.sha){
        throw 'Prior exported registry identity changed: '+$pin.id
    }
    $archiveRelative='qa_cycle/candidates/HRS_1.3.0_Tech_Demo-qa.'+$pin.id.Split('.')[-1]+'.zip'
    $archive=Join-Path $repo $archiveRelative
    $exportReceipt=$archive+'.receipt.json'
    Assert-OrdinaryPath $archive;Assert-OrdinaryPath $exportReceipt
    if((Get-Sha $archive) -cne $pin.sha -or (Get-Sha $exportReceipt) -cne $record[0].receiptSha256){throw 'Prior frozen archive/receipt changed: '+$pin.id}
    $preserved+=,[pscustomobject][ordered]@{candidateId=$pin.id;archivePath=$archiveRelative;archiveSha256=$pin.sha;receiptSha256=$record[0].receiptSha256}
}
$oldArchive=Join-Path $repo 'qa_cycle/candidates/HRS_1.3.0_Tech_Demo-qa.002.zip'
$oldRegistry=@($registry.records | Where-Object{$_.candidateId -ceq '1.3.0-qa.002'})[0]
$oldReleaseSha=Get-Sha $releasePath
$oldCasesSha=Get-Sha $contractPath
if($oldReleaseSha -cne $oldRegistry.releaseRecordSha256 -or $oldCasesSha -cne $oldRegistry.contractSha256){
    throw 'Current candidate-002 contracts drifted from its authenticated export.'
}
$release=[IO.File]::ReadAllText($releasePath) | ConvertFrom-Json
$cases=[IO.File]::ReadAllText($contractPath) | ConvertFrom-Json
if($release.candidateId -cne '1.3.0-qa.002' -or $release.version -cne '1.3.0' -or $release.buildId -cne 'r130' -or
   $release.build.candidateId -cne '1.3.0-qa.002' -or $release.build.recordSha256 -cne $buildSha -or
   $cases.candidateId -cne '1.3.0-qa.002' -or $cases.releaseVersion -cne '1.3.0' -or
   @($cases.requiredCases).Count -ne 46 -or @($cases.requiredCases | Where-Object{$_.status -cne 'Pending'}).Count -ne 0 -or
   $release.presentation.edition -cne 'Tech Demo' -or $release.presentation.managerReleaseLabel -cne 'Tech Demo | 1.3.0'){
    throw 'Unexpected current runtime/presentation/46-Pending identity.'
}
$oldBuild=Join-Path $lane $release.build.recordPath
Assert-OrdinaryPath $oldBuild
if((Get-Sha $oldBuild) -cne $buildSha -or
   (Get-ArchiveEntrySha $oldArchive 'source/hrs_1.3.0_Tech_Demo/dev/builds/1.3.0-qa.002/build-record.json') -cne $buildSha){
    throw 'Qualified current-version build record no longer matches candidate 002.'
}
$build=[IO.File]::ReadAllText($oldBuild) | ConvertFrom-Json
if(!$build.deterministicDoubleBuild -or @($build.sourceHashes).Count -ne 15 -or @($build.references).Count -ne 8 -or
   $build.dllSha256 -cne $dllSha -or $build.dllBytes -ne 77312 -or
   $build.assemblyCSharpMvid -cne $release.supportedEnvironment.assemblyCSharpMvid){throw 'Incomplete or changed qualified build.'}
foreach($pin in $build.sourceHashes){
    $source=Join-Path $lane ('dev/src/runtime/main/'+$pin.path)
    Assert-OrdinaryPath $source
    $relPin=@($release.sourceSnapshot.sourceHashes | Where-Object{$_.path -ceq $pin.path})
    if((Get-Sha $source) -cne $pin.sha256 -or $relPin.Count -ne 1 -or $relPin[0].sha256 -cne $pin.sha256){throw 'Runtime source changed: '+$pin.path}
}
if(@($release.sourceSnapshot.sourceHashes).Count -ne 15){throw 'Runtime source snapshot is not fifteen files.'}
foreach($artifact in $release.artifacts){
    $source=Join-Path $lane $artifact.path
    Assert-OrdinaryPath $source
    if((Get-Sha $source) -cne $artifact.sha256 -or (Get-Item -LiteralPath $source).Length -ne $artifact.bytes){throw 'Qualified runtime artifact changed.'}
}
if((Get-Sha (Join-Path $lane 'dev/verified/main/d0163.dll')) -cne $dllSha -or
   (Get-Sha (Join-Path $lane 'dev/verified/main/ModInfo.xml')) -cne $xmlSha){throw 'Qualified DLL/XML identity changed.'}
$oldManagerSha=Get-ArchiveEntrySha $oldArchive 'source/hrs_1.3.0_Tech_Demo/dev/ui/p0158.ps1'
if((Get-Sha $managerPath) -cne $ExpectedManagerSha256 -or $oldManagerSha -ceq $ExpectedManagerSha256){throw 'New manager is not the explicitly selected stable revision.'}
$managerText=[IO.File]::ReadAllText($managerPath)
$recipe=[IO.File]::ReadAllText($recipePath) | ConvertFrom-Json
$recipeSha=Get-Sha $recipePath
if([regex]::Matches($managerText,'(?m)^\s*\$gameLabel\.Text\s*=\s*''Game Name''\s*$').Count -ne 1 -or
   $recipe.copy.manager.gameNameLabel -cne 'Game Name' -or
   $managerText -notmatch '\$gameLabel\.Text\s*=\s*if\s*\(' -or
   $managerText -match '\$gameLabel\.Text\s*=\s*''Game Name for your save'''){
    throw 'Base and recipe-driven native labels must use Game Name, with the compatible fallback retained.'
}
# No manager pin exists in this runtime build schema: keep its authenticated
# bytes unchanged and bind the changed manager in this separate reuse receipt.
if((Get-Sha $registryPath) -cne $registrySha -or (Get-Sha $releasePath) -cne $oldReleaseSha -or
   (Get-Sha $contractPath) -cne $oldCasesSha -or (Get-Sha $managerPath) -cne $ExpectedManagerSha256 -or
   (Get-Sha $recipePath) -cne $recipeSha){throw 'Input drifted before the candidate transition.'}
[void][IO.Directory]::CreateDirectory($checkpoint)
[IO.File]::Copy($releasePath,(Join-Path $checkpoint 'rel.json'),$false)
[IO.File]::Copy($contractPath,(Join-Path $checkpoint 'cases.json'),$false)
[IO.File]::Copy($oldBuild,(Join-Path $checkpoint 'build-record.json'),$false)
[void][IO.Directory]::CreateDirectory((Split-Path -Parent $newBuild))
[IO.File]::Copy($oldBuild,$newBuild,$false)
$release.candidateId='1.3.0-qa.003'
$release.build.candidateId='1.3.0-qa.003'
$release.build.recordPath=$newBuildRelative
$cases.candidateId='1.3.0-qa.003'
[IO.File]::WriteAllText($releasePath,($release | ConvertTo-Json -Depth 40)+[Environment]::NewLine,$utf8)
[IO.File]::WriteAllText($contractPath,($cases | ConvertTo-Json -Depth 40)+[Environment]::NewLine,$utf8)
$receipt=[ordered]@{
    schema='hrs-qualified-current-build-reuse/v2';status='Pass';candidateId='1.3.0-qa.003';preparedUtc=[DateTime]::UtcNow.ToString('o')
    originCandidateId='1.3.0-qa.001';previousCandidateId='1.3.0-qa.002';preservedExports=$preserved
    originBuildRecord=$build.attempt;qualifiedBuildRecordSha256=(Get-Sha $newBuild)
    newBuildRecordPath=$newBuildRelative;newBuildRecordExactBytes=$true
    runtimeSha256=$dllSha;runtimeBytes=77312;modInfoSha256=$xmlSha;runtimeSourcesUnchanged=$true;runtimeSourceCount=15
    referenceCount=8;referencePinsPreserved=$true;compilerPins=$build.compiler;deterministicDoubleBuildInherited=$true
    managerSourceUnchanged=$false;previousManagerSourceSha256=$oldManagerSha;managerSourceSha256=$ExpectedManagerSha256
    recipeSourceSha256=$recipeSha
    runtimeRebuiltForThisPresentationChange=$false;runtimeLogIdentity='v=1.3.0 build=r130';edition='Tech Demo';gameNameLabel='Game Name'
    preservedContractCheckpoint='candidate-002-checkpoint';previousReleaseRecordSha256=$oldReleaseSha;previousContractSha256=$oldCasesSha
    releaseRecordSha256=(Get-Sha $releasePath);contractSha256=(Get-Sha $contractPath);caseRequirementsUnchanged=$true;independentCasesPending=46
    reason='Owner shortened the visible Game Name label. New manager snapshot is separately authenticated; qualified 1.3.0 runtime/build/reference/compiler bytes and all case requirements are reused unchanged.'
    independentGameplayQaPassed=$false;gameEnvironmentQualificationChanged=$false;candidateReserved=$false;candidateExported=$false
}
[IO.File]::WriteAllText($receiptPath,($receipt | ConvertTo-Json -Depth 15)+[Environment]::NewLine,$utf8)
if((Get-Sha $newBuild) -cne $buildSha -or (Get-Sha $managerPath) -cne $ExpectedManagerSha256 -or (Get-Sha $recipePath) -cne $recipeSha -or
   (Get-Sha $registryPath) -cne $registrySha){throw 'Candidate bookkeeping finished with input drift; stop before export and inspect the preserved checkpoint.'}
[pscustomobject]$receipt
