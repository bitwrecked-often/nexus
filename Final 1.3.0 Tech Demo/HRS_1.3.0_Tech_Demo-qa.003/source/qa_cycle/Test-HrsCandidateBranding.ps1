[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('hrs branding '+[guid]::NewGuid().ToString('N'))
$tools=Join-Path $fixture 'tools'
[void][IO.Directory]::CreateDirectory($tools)
Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object {
    $_.Extension -in @('.ps1','.psm1') -or $_.Name -eq 'candidate-registry.json'
} | Copy-Item -Destination $tools
Import-Module (Join-Path $tools 'HrsQaTools.psm1') -Force
$passed=0
function Check([bool]$Ok,[string]$Name) {
    if (-not $Ok) { throw "FAIL: $Name" }
    $script:passed++; Write-Output "PASS: $Name"
}
$realRegistry=Join-Path $PSScriptRoot 'candidate-registry.json'
$registryBefore=Get-HrsQaSha256 $realRegistry
$legacyZip=Join-Path $PSScriptRoot 'candidates/1.2.5-qa.001.zip'
$legacyBefore=Get-HrsQaSha256 $legacyZip
$legacy=Get-HrsRegistryRecord '1.2.5-qa.001'
Check (Test-HrsCandidateArchive $legacyZip $legacy.candidateId $legacy.releaseRecordSha256 $legacy.contractSha256).valid 'frozen 1.2.5-qa.001 still verifies'
Check (@(Get-HrsCustomerFiles).Count -eq 11) 'legacy caller file set unchanged'
Check (@(Get-HrsCustomerFiles -CandidateId '1.2.5-qa.001').Count -eq 11) '001 keeps legacy package layout'
Check (@(Get-HrsCustomerFiles -CandidateId '1.2.5-qa.002') -ccontains 'dev/ui/logo.ico') 'next candidate requires branding icon'
Check (@(Get-HrsCustomerFiles -CandidateId '1.2.6-qa.001') -ccontains 'dev/ui/logo.ico') 'later versions retain the icon requirement'

# The frozen 001 extraction supplies a self-consistent synthetic source lane.
# All test exports and registry changes stay beneath this disposable directory.
$baseline=Join-Path $fixture 'baseline'
& (Join-Path $tools 'New-HrsQaWorkspace.ps1') -CandidateId $legacy.candidateId -ArchivePath $legacyZip -Destination $baseline | Out-Null
$lane=Join-Path $fixture 'synthetic lane'
$baselineCustomer=Join-Path $baseline 'customer/HistoricalRandomStart_1.2.5'
Copy-Item -LiteralPath $baselineCustomer -Destination $lane -Recurse
$context=Join-Path $baseline 'context'
$release=Read-HrsQaJson (Join-Path $context 'dev/qa/rel.json')
$contract=Read-HrsQaJson (Join-Path $context 'dev/qa/cases.json')
$id='1.2.5-qa.992'
$build=Read-HrsQaJson (Join-Path $context $release.build.recordPath)
$buildRelative="dev/builds/$id/build-record.json"
Write-HrsQaJson (Join-Path $lane $buildRelative) $build
foreach ($source in $release.sourceSnapshot.sourceHashes) {
    $relative='dev/src/runtime/main/'+$source.path
    $to=Resolve-HrsContainedFile $lane $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
    [IO.File]::Copy((Join-Path $context $relative),$to,$false)
}
$release.candidateId=$id
$release.build.candidateId=$id
$release.build.recordPath=$buildRelative
$release.build.recordSha256=Get-HrsQaSha256 (Join-Path $lane $buildRelative)
$contract.candidateId=$id
Write-HrsQaJson (Join-Path $lane 'dev/qa/rel.json') $release
Write-HrsQaJson (Join-Path $lane 'dev/qa/cases.json') $contract
$manager=Join-Path $lane 'dev/ui/p0158.ps1'
$text=[IO.File]::ReadAllText($manager).Replace('$useDevCandidate = $false','$useDevCandidate = $true').Replace('Release | 1.2.5 QA','Release | 1.2.5 DEV')
[IO.File]::WriteAllText($manager,$text,(New-Object Text.UTF8Encoding($false)))
$icon=Join-Path $repo 'hrs_1.2.5/dev/ui/logo.ico'
[IO.File]::Copy($icon,(Join-Path $lane 'dev/ui/logo.ico'),$false)
$zip=Join-Path $fixture 'synthetic-branded.zip'
& (Join-Path $tools 'Export-HrsCandidate.ps1') -LaneRoot $lane -CandidateId $id -OutputPath $zip | Out-Null
$record=Get-HrsRegistryRecord $id
$valid=Test-HrsCandidateArchive $zip $id $record.releaseRecordSha256 $record.contractSha256
Check $valid.valid 'synthetic new candidate exports and verifies'
$iconRecord=@($valid.manifest.files | Where-Object { $_.path -ceq 'dev/ui/logo.ico' })
Check ($iconRecord.Count -eq 1 -and $iconRecord[0].sha256 -ceq (Get-HrsQaSha256 $icon)) 'export manifest pins the existing branded icon bytes'
$workspace=Join-Path $fixture 'branded extraction'
& (Join-Path $tools 'New-HrsQaWorkspace.ps1') -CandidateId $id -ArchivePath $zip -Destination $workspace | Out-Null
Check ((Get-HrsQaSha256 (Join-Path $workspace 'customer/HistoricalRandomStart_1.2.5/dev/ui/logo.ico')) -ceq (Get-HrsQaSha256 $icon)) 'isolated workspace retains exact icon'

foreach ($scenario in @('MissingIcon','TamperedIcon','ExtraAsset')) {
    $bad=Join-Path $fixture ($scenario+'.zip')
    [IO.File]::Copy($zip,$bad,$false)
    $archive=[IO.Compression.ZipFile]::Open($bad,[IO.Compression.ZipArchiveMode]::Update)
    try {
        $prefix='HistoricalRandomStart_1.2.5/'
        $entry=@($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq ($prefix+'dev/ui/logo.ico') })[0]
        if ($scenario -eq 'MissingIcon') {
            $entry.Delete()
            $manifestEntry=@($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq ($prefix+'package-manifest.json') })[0]
            $reader=New-Object IO.StreamReader($manifestEntry.Open())
            try { $manifest=$reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
            $manifest.files=@($manifest.files | Where-Object { $_.path -cne 'dev/ui/logo.ico' })
            $manifestEntry.Delete()
            $manifestEntry=$archive.CreateEntry($prefix+'package-manifest.json')
            $writer=New-Object IO.StreamWriter($manifestEntry.Open())
            try { $writer.Write(($manifest | ConvertTo-Json -Depth 8)) } finally { $writer.Dispose() }
        } elseif ($scenario -eq 'TamperedIcon') {
            $stream=$entry.Open()
            try { $stream.SetLength(1) } finally { $stream.Dispose() }
        } else {
            [void]$archive.CreateEntry($prefix+'dev/ui/unexpected.ico')
        }
    } finally { $archive.Dispose() }
    # Authenticate each deliberately bad fixture's outer bytes, so rejection
    # must come from the inner allowlist/file checks rather than archive drift.
    $archive=[IO.Compression.ZipFile]::OpenRead($bad)
    $sha=[Security.Cryptography.SHA256]::Create()
    try {
        $entry=@($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq ($prefix+'package-manifest.json') })[0]
        $stream=$entry.Open()
        try { $manifestHash=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','') } finally { $stream.Dispose() }
    } finally { $sha.Dispose(); $archive.Dispose() }
    $receipt=Read-HrsQaJson ($zip+'.receipt.json')
    $receipt.archiveSha256=Get-HrsQaSha256 $bad
    $receipt.packageManifestSha256=$manifestHash
    Write-HrsQaJson ($bad+'.receipt.json') $receipt
    $registry=Read-HrsQaJson (Join-Path $tools 'candidate-registry.json')
    $badRecord=@($registry.records | Where-Object { $_.candidateId -ceq $id })[0]
    $badRecord.archiveSha256=$receipt.archiveSha256
    $badRecord.receiptSha256=Get-HrsQaSha256 ($bad+'.receipt.json')
    Write-HrsQaJson (Join-Path $tools 'candidate-registry.json') $registry
    $rejected=Test-HrsCandidateArchive $bad $id $record.releaseRecordSha256 $record.contractSha256
    $reason=if($scenario -eq 'MissingIcon'){'HRS_PACKAGE_ALLOWLIST'}elseif($scenario -eq 'TamperedIcon'){'HRS_ZIP_FILE_IDENTITY'}else{'HRS_ZIP_EXTRA_OR_EMPTY'}
    Check (-not $rejected.valid -and ($rejected.errors -join ',').Contains($reason)) "$scenario rejected by exact package checks"
}
Check ((Get-HrsQaSha256 $realRegistry) -ceq $registryBefore -and (Get-HrsQaSha256 $legacyZip) -ceq $legacyBefore) 'real registry and frozen archive unchanged'
Write-Output "Branding package tests passed: $passed/$passed"
Write-Output "Disposable synthetic evidence: $fixture"
