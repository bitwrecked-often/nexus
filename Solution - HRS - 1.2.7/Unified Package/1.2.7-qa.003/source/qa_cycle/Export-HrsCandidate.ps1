[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$LaneRoot,
      [Parameter(Mandatory=$true)][ValidatePattern('^\d+\.\d+\.\d+-qa\.\d{3}$')][string]$CandidateId,
      [Parameter(Mandatory=$true)][string]$OutputPath,
      [string]$PublicContentRoot='')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
$paths=Get-HrsQaLanePaths $LaneRoot
$release=Read-HrsQaJson $paths.ReleasePath
$contract=Read-HrsQaJson $paths.ContractPath
if ($CandidateId -cnotmatch ('^'+[regex]::Escape([string]$release.version)+'-qa\.\d{3}$')) { throw 'HRS_CANDIDATE_VERSION_MISMATCH' }
$customerFolder=Get-HrsCustomerFolder ([string]$release.version)
$unifiedPublic = ![string]::IsNullOrWhiteSpace($PublicContentRoot)
$customerFiles=if($unifiedPublic){@(Get-HrsCustomerFiles -CandidateId $CandidateId -UnifiedPublic)}else{@(Get-HrsCustomerFiles -CandidateId $CandidateId)}
if($unifiedPublic){
    $publicInputs=[IO.Path]::GetFullPath($PublicContentRoot)
    if(!(Test-Path -LiteralPath $publicInputs -PathType Container)){throw 'HRS_PUBLIC_INPUTS_MISSING'}
    foreach($required in @('START.bat','README.md','START-HERE.md','BUILD-FROM-SOURCE.md','release_templates/LICENSE-GPL-3.0-or-later.txt')){
        if(!(Test-Path -LiteralPath (Resolve-HrsContainedFile $publicInputs $required) -PathType Leaf)){throw ('HRS_PUBLIC_REQUIRED_INPUT: '+$required)}
    }
    foreach($file in @(Get-ChildItem -LiteralPath $publicInputs -Recurse -File -Force)){
        $relative=$file.FullName.Substring($publicInputs.Length+1).Replace('\','/')
        [void](Resolve-HrsContainedFile $publicInputs $relative)
        if($relative -match '^(customer|context|tools)/' -or $relative -in @('distribution-manifest.json','public-package-receipt.json')){throw 'HRS_PUBLIC_RESERVED_INPUT'}
        if($file.Name -match '^(Assembly-CSharp|0Harmony|UnityEngine.*|mscorlib|netstandard|System(?:\.Core)?|LogLibrary)\.dll$|^7DaysToDie.*\.exe$'){throw 'HRS_GAME_REFERENCE_IN_PUBLIC_INPUTS'}
    }
}
if ($release.candidateId -cne $CandidateId -or $contract.candidateId -cne $CandidateId) { throw 'HRS_CANDIDATE_ID_MISMATCH' }
$gate=Test-HrsQaRelease $LaneRoot
if (-not $gate.readyForQa) { throw 'HRS_RELEASE_NOT_READY_FOR_EXPORT' }
$buildPath=Resolve-HrsContainedFile $paths.LaneRoot $release.build.recordPath
$build=Read-HrsQaJson $buildPath
if ((Get-HrsQaSha256 $buildPath) -cne $release.build.recordSha256) { throw 'HRS_BUILD_RECORD_DIGEST' }
if ($build.deterministicDoubleBuild -ne $true -or $build.dllSha256 -cne $release.artifacts[0].sha256) { throw 'HRS_BUILD_RECORD_MISMATCH' }
if (@($build.sourceHashes).Count -ne @($release.sourceSnapshot.sourceHashes).Count) { throw 'HRS_BUILD_SOURCE_SET' }
foreach ($source in $release.sourceSnapshot.sourceHashes) {
    $match=@($build.sourceHashes | Where-Object { $_.path -ceq $source.path })
    $actual=Get-HrsQaSha256 (Resolve-HrsContainedFile (Join-Path $paths.LaneRoot 'dev/src/runtime/main') $source.path)
    if ($match.Count -ne 1 -or $match[0].sha256 -cne $actual -or $source.sha256 -cne $actual) { throw 'HRS_BUILD_SOURCE_DRIFT' }
}
if ($build.assemblyCSharpMvid -cne $release.supportedEnvironment.assemblyCSharpMvid) { throw 'HRS_BUILD_GAME_IDENTITY' }
$harmony=@($build.references | Where-Object { $_.name -ceq '0Harmony.dll' })
# Input fingerprints describe the existing build; game DLLs are never bundled.
if ($harmony.Count -ne 1 -or $harmony[0].sha256 -cne 'C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF') { throw 'HRS_BUILD_HARMONY_IDENTITY' }
$destination=[IO.Path]::GetFullPath($OutputPath)
if ([IO.Path]::GetExtension($destination) -cne '.zip') { throw 'HRS_EXPORT_REQUIRES_ZIP' }
foreach ($suffix in @('','.receipt.json','.companion.zip','.partial.zip','.stage')) {
    if (Test-Path -LiteralPath ($destination+$suffix)) { throw 'HRS_EXPORT_DESTINATION_EXISTS' }
}
$registryPath=Join-Path $PSScriptRoot 'candidate-registry.json'
$lock=[IO.File]::Open(($registryPath+'.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try {
    $registry=Read-HrsQaJson $registryPath
    if ($registry.schema -cne 'hrs-candidate-registry/v1') { throw 'HRS_REGISTRY_SCHEMA' }
    if (@($registry.records | Where-Object { $_.candidateId -ceq $CandidateId }).Count) { throw 'HRS_CANDIDATE_ID_ALREADY_EXPORTED' }
    $reservation=[pscustomobject]@{candidateId=$CandidateId;status='reserved';archiveSha256=''}
    $registry.records=@($registry.records)+$reservation
    Write-HrsQaJson $registryPath $registry
    $stage=$destination+'.stage'
    $public=Join-Path $stage 'public'
    if($unifiedPublic){
        [void][IO.Directory]::CreateDirectory($public)
        foreach($file in @(Get-ChildItem -LiteralPath $publicInputs -Recurse -File -Force)){
            $relative=$file.FullName.Substring($publicInputs.Length+1).Replace('\','/')
            $to=Resolve-HrsContainedFile $public $relative
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
            [IO.File]::Copy($file.FullName,$to,$false)
        }
    }
    $customer=if($unifiedPublic){Join-Path $public ('customer/'+$customerFolder)}else{Join-Path $stage $customerFolder}
    [void][IO.Directory]::CreateDirectory($customer)
    foreach ($relative in $customerFiles) {
        $from=if($unifiedPublic -and $relative -ceq 'release_templates/LICENSE-GPL-3.0-or-later.txt'){
            Resolve-HrsContainedFile $publicInputs $relative
        }else{Resolve-HrsContainedFile $paths.LaneRoot $relative}
        $to=Resolve-HrsContainedFile $customer $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
        if ($relative -ceq 'dev/ui/p0158.ps1') {
            $manager=[IO.File]::ReadAllText($from)
            if (@([regex]::Matches($manager,'(?m)^\$useDevCandidate = \$true\r?$')).Count -ne 1) { throw 'HRS_CUSTOMER_MODE_UNSUPPORTED' }
            $devLabel='Release | '+[string]$release.version+' DEV'
            if (@([regex]::Matches($manager,[regex]::Escape($devLabel))).Count -ne 1) { throw 'HRS_CUSTOMER_VERSION_LABEL_UNSUPPORTED' }
            $manager=$manager.Replace('$useDevCandidate = $true','$useDevCandidate = $false').Replace($devLabel,('Release | '+[string]$release.version+' QA'))
            [IO.File]::WriteAllText($to,("# Candidate "+$CandidateId+[Environment]::NewLine+$manager),(New-Object Text.UTF8Encoding($false)))
        } else { [IO.File]::Copy($from,$to,$false) }
    }
    $files=@($customerFiles | ForEach-Object {
        $p=Resolve-HrsContainedFile $customer $_
        [pscustomobject]@{path=$_;bytes=(Get-Item -LiteralPath $p).Length;sha256=(Get-HrsQaSha256 $p)}
    })
    Write-HrsQaJson (Join-Path $customer 'package-manifest.json') ([pscustomobject]@{schema='hrs-candidate-package-manifest/v1';candidateId=$CandidateId;files=$files})
    $manifestHash=Get-HrsQaSha256 (Join-Path $customer 'package-manifest.json')
    if(!$unifiedPublic){
        Compress-Archive -LiteralPath $customer -DestinationPath ($destination+'.partial.zip')
        [void](Read-HrsVerifiedZip ($destination+'.partial.zip') ($customerFolder+'/package-manifest.json') $customerFiles ($customerFolder+'/') $manifestHash)
    }
    # Legacy exports retain their companion; full public exports embed this context.
    $companion=if($unifiedPublic){Join-Path $public 'context'}else{Join-Path $stage 'companion'}
    [void][IO.Directory]::CreateDirectory($companion)
    $companions=@('dev/qa/rel.json','dev/qa/cases.json',[string]$release.build.recordPath)
    $companions+=@($release.sourceSnapshot.sourceHashes | ForEach-Object { 'dev/src/runtime/main/'+$_.path })
    foreach ($relative in $companions) {
        $to=Resolve-HrsContainedFile $companion $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
        [IO.File]::Copy((Resolve-HrsContainedFile $paths.LaneRoot $relative),$to,$false)
    }
    Write-HrsQaJson (Join-Path $companion 'qa-workspace.json') ([pscustomobject]@{schema='hrs-qa-workspace/v1';candidateId=$CandidateId})
    $contextFiles=@(Get-ChildItem -LiteralPath $companion -Recurse -File | ForEach-Object {
        [pscustomobject]@{path=$_.FullName.Substring($companion.Length+1).Replace('\','/');bytes=$_.Length;sha256=(Get-HrsQaSha256 $_.FullName)}
    })
    Write-HrsQaJson (Join-Path $companion 'context-manifest.json') ([pscustomobject]@{schema='hrs-qa-context/v1';candidateId=$CandidateId;files=$contextFiles})
    if($unifiedPublic){
        $toolRoot=Join-Path $public 'tools'
        [void][IO.Directory]::CreateDirectory($toolRoot)
        foreach($name in @('HrsQaTools.psm1','HrsIdentity.ps1','New-HrsQaWorkspace.ps1','Start-HrsQaRun.ps1','Record-HrsQaObservation.ps1','Export-HrsQaRun.ps1','Complete-HrsQaCycle.ps1','Test-HrsRelease.ps1')){
            [IO.File]::Copy((Join-Path $PSScriptRoot $name),(Join-Path $toolRoot $name),$false)
        }
        Write-HrsQaJson (Join-Path $public 'public-package-receipt.json') ([pscustomobject][ordered]@{
            schema='hrs-public-package-receipt/v1';candidateId=$CandidateId;releaseVersion=$release.version
            releaseRecordSha256=(Get-HrsQaSha256 $paths.ReleasePath);contractSha256=(Get-HrsQaSha256 $paths.ContractPath)
            buildRecordSha256=(Get-HrsQaSha256 $buildPath);buildAttempt=$build.attempt
            runtimeSha256=$release.artifacts[0].sha256;modInfoSha256=$release.artifacts[1].sha256
            packageManifestSha256=$manifestHash;contextManifestSha256=(Get-HrsQaSha256 (Join-Path $companion 'context-manifest.json'))
            exportedUtc=[datetime]::UtcNow.ToString('o')
        })
        $publicFiles=@(Get-ChildItem -LiteralPath $public -Recurse -File -Force|Sort-Object FullName|ForEach-Object{
            $relative=$_.FullName.Substring($public.Length+1).Replace('\','/')
            [void](Resolve-HrsContainedFile $public $relative)
            [pscustomobject]@{path=$relative;bytes=$_.Length;sha256=(Get-HrsQaSha256 $_.FullName)}
        })
        Write-HrsQaJson (Join-Path $public 'distribution-manifest.json') ([pscustomobject]@{
            schema='hrs-public-distribution-manifest/v1';candidateId=$CandidateId;files=$publicFiles
        })
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::CreateFromDirectory($public,($destination+'.partial.zip'),[IO.Compression.CompressionLevel]::Optimal,$false)
        [void](Read-HrsVerifiedZip ($destination+'.partial.zip') 'distribution-manifest.json' @($publicFiles.path))
        $receipt=New-HrsPublicArchiveReceipt -ArchivePath ($destination+'.partial.zip') -ExpectedCandidateId $CandidateId
        [IO.File]::Move(($destination+'.partial.zip'),$destination)
    }else{
    Compress-Archive -Path (Join-Path $companion '*') -DestinationPath ($destination+'.companion.zip')
    [void](Read-HrsVerifiedZip ($destination+'.companion.zip') 'context-manifest.json')
    [IO.File]::Move(($destination+'.partial.zip'),$destination)
    $receipt=[pscustomobject][ordered]@{
        schema='hrs-candidate-export/v1';candidateId=$CandidateId;releaseVersion=$release.version
        releaseRecordSha256=(Get-HrsQaSha256 $paths.ReleasePath);contractSha256=(Get-HrsQaSha256 $paths.ContractPath)
        buildRecordSha256=(Get-HrsQaSha256 $buildPath);buildAttempt=$build.attempt
        runtimeSha256=$release.artifacts[0].sha256;modInfoSha256=$release.artifacts[1].sha256
        packageManifestSha256=$manifestHash;archiveSha256=(Get-HrsQaSha256 $destination)
        companionSha256=(Get-HrsQaSha256 ($destination+'.companion.zip'));contextManifestSha256=(Get-HrsQaSha256 (Join-Path $companion 'context-manifest.json'))
        exportedUtc=[datetime]::UtcNow.ToString('o')
    }
    }
    Write-HrsQaJson ($destination+'.receipt.json') $receipt
    $record=[pscustomobject][ordered]@{
        candidateId=$CandidateId;status='exported-awaiting-live-qa';archiveSha256=$receipt.archiveSha256
        receiptSha256=(Get-HrsQaSha256 ($destination+'.receipt.json'))
        releaseRecordSha256=$receipt.releaseRecordSha256;contractSha256=$receipt.contractSha256
    }
    $registry.records=@($registry.records | Where-Object { $_.candidateId -cne $CandidateId })+@($record)
    Write-HrsQaJson $registryPath $registry
    Write-Output "Candidate exported: $destination"
    Write-Output "SHA-256: $($receipt.archiveSha256)"
    if($unifiedPublic){Write-Output 'One full public archive for QA, customers and Nexus; source/history/lore/evidence included.'}
    else{Write-Output "Companion: $destination.companion.zip"}
} finally { $lock.Dispose() }
