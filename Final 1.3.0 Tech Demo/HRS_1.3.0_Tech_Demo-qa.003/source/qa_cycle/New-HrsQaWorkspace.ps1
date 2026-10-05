[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$CandidateId,
      [Parameter(Mandatory=$true)][string]$ArchivePath,
      [Parameter(Mandatory=$true)][string]$Destination,
      [string]$ExpectedArchiveSha256 = '')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $root) { throw 'HRS_WORKSPACE_EXISTS' }
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
$registryPath=Join-Path $PSScriptRoot 'candidate-registry.json'
$record=$null
if ([IO.File]::Exists($registryPath)) {
    $registry=Read-HrsQaJson $registryPath
    if ($registry.schema -cne 'hrs-candidate-registry/v1') { throw 'HRS_REGISTRY_SCHEMA' }
    $matches=@($registry.records | Where-Object { $_.candidateId -ceq $CandidateId })
    if ($matches.Count -gt 0) { $record=Get-HrsRegistryRecord $CandidateId }
}
if ($ExpectedArchiveSha256 -and ($ExpectedArchiveSha256 -cnotmatch '^[A-F0-9]{64}$' -or
    (Get-HrsQaSha256 $ArchivePath) -cne $ExpectedArchiveSha256)) { throw 'HRS_PUBLIC_ARCHIVE_IDENTITY' }
if ($null -eq $record -and -not $ExpectedArchiveSha256) {
    throw 'HRS_PUBLIC_EXPECTED_SHA_REQUIRED: pass the published SHA-256 with -ExpectedArchiveSha256 when this candidate is not in a trusted local registry.'
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($ArchivePath))
try { $unified=$null -ne $zip.GetEntry('distribution-manifest.json') }
finally { $zip.Dispose() }
if ($unified) {
    $trustedDigest=$ExpectedArchiveSha256
    if ($null -ne $record) { $trustedDigest=[string]$record.archiveSha256 }
    $identity=Get-HrsPublicPackageIdentity $ArchivePath $CandidateId $trustedDigest
    $receipt=New-HrsPublicArchiveReceipt $ArchivePath $CandidateId
    if ($null -ne $record -and ($receipt.releaseRecordSha256 -cne $record.releaseRecordSha256 -or
        $receipt.contractSha256 -cne $record.contractSha256)) { throw 'HRS_CANDIDATE_IDENTITY' }
    [void][IO.Directory]::CreateDirectory($root)
    $localArchive=Join-Path $root ($CandidateId+'.zip')
    [IO.File]::Copy([IO.Path]::GetFullPath($ArchivePath),$localArchive,$false)
    # Every ZIP entry was contained, listed and hash-verified before extraction.
    Expand-Archive -LiteralPath $localArchive -DestinationPath $root
    Write-HrsQaJson ($localArchive+'.receipt.json') $receipt
    $receiptDigest=Get-HrsQaSha256 ($localArchive+'.receipt.json')
    if ($null -ne $record -and $receiptDigest -cne $record.receiptSha256) { throw 'HRS_RECEIPT_REGISTRY_MISMATCH' }
    $localRecord=[pscustomobject][ordered]@{
        candidateId=$CandidateId;status='exported-awaiting-live-qa';archiveSha256=$identity.archiveSha256
        receiptSha256=$receiptDigest;releaseRecordSha256=$receipt.releaseRecordSha256;contractSha256=$receipt.contractSha256
    }
    Write-HrsQaJson (Join-Path $root 'tools/candidate-registry.json') ([pscustomobject][ordered]@{
        schema='hrs-candidate-registry/v1';records=@($localRecord)
    })
    Import-Module (Join-Path $root 'tools/HrsQaTools.psm1') -Force
    [void](Assert-HrsWorkspace $root $localArchive)
    Write-Output "QA workspace verified: $root"
    Write-Output "LaneRoot: $(Join-Path $root 'context')"
    Write-Output "CandidateArchivePath: $localArchive"
    Write-Output "Archive SHA-256: $($identity.archiveSha256)"
    return
}
if ($null -eq $record) { throw 'HRS_CANDIDATE_NOT_UNIQUE_OR_REGISTERED' }
$check=Test-HrsCandidateArchive $ArchivePath $CandidateId $record.releaseRecordSha256 $record.contractSha256
if (-not $check.valid) { throw ('HRS_CANDIDATE_ARCHIVE_INVALID: '+($check.errors -join ',')) }
if ((Get-HrsQaSha256 ($ArchivePath+'.companion.zip')) -cne $check.receipt.companionSha256) { throw 'HRS_COMPANION_DRIFT' }
[void](Read-HrsVerifiedZip ($ArchivePath+'.companion.zip') 'context-manifest.json')
[void][IO.Directory]::CreateDirectory($root)
$localArchive=Join-Path $root ($CandidateId+'.zip')
foreach ($suffix in @('','.receipt.json','.companion.zip')) { [IO.File]::Copy([IO.Path]::GetFullPath($ArchivePath+$suffix),$localArchive+$suffix,$false) }
# All entries were validated before extraction; this destination is newly created.
Expand-Archive -LiteralPath $localArchive -DestinationPath (Join-Path $root 'customer')
Expand-Archive -LiteralPath ($localArchive+'.companion.zip') -DestinationPath (Join-Path $root 'context')
[void](Assert-HrsWorkspace $root $localArchive)
$toolRoot=Join-Path $root 'tools'
[void][IO.Directory]::CreateDirectory($toolRoot)
foreach ($file in @('HrsQaTools.psm1','HrsIdentity.ps1','Start-HrsQaRun.ps1','Record-HrsQaObservation.ps1','Export-HrsQaRun.ps1','Complete-HrsQaCycle.ps1','Test-HrsRelease.ps1','candidate-registry.json')) {
    [IO.File]::Copy((Join-Path $PSScriptRoot $file),(Join-Path $toolRoot $file),$false)
}
Write-Output "QA workspace verified: $root"
Write-Output "LaneRoot: $(Join-Path $root 'context')"
Write-Output "CandidateArchivePath: $localArchive"
