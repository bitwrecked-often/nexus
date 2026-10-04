# Shared exact-byte boundaries. Dot-sourced by HrsQaTools.psm1.
function Resolve-HrsContainedFile {
    param([string]$Root, [string]$Relative)
    if ($Relative -cnotmatch '^[A-Za-z0-9_ ./-]+$' -or
        $Relative -match '(^|/)\.\.?(/|$)|//|[ .](/|$)' -or
        [IO.Path]::IsPathRooted($Relative)) { throw 'HRS_UNSAFE_PATH' }
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\','/')
    $full = [IO.Path]::GetFullPath((Join-Path $base $Relative))
    if (-not $full.StartsWith($base + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'HRS_UNSAFE_PATH' }
    $cursor = $full
    while ($cursor.Length -ge $base.Length) {
        if ((Test-Path -LiteralPath $cursor) -and
            ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'HRS_REPARSE_POINT' }
        if ($cursor -eq $base) { break }
        $cursor = Split-Path -Parent $cursor
    }
    return $full
}

function Get-HrsStreamHash {
    param($Stream)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Stream))).Replace('-','') }
    finally { $sha.Dispose(); $Stream.Dispose() }
}

function Get-HrsRegistryRecord {
    param([string]$CandidateId)
    $registry = Read-HrsQaJson (Join-Path $PSScriptRoot 'candidate-registry.json')
    if ($registry.schema -cne 'hrs-candidate-registry/v1') { throw 'HRS_REGISTRY_SCHEMA' }
    $records = @($registry.records | Where-Object { $_.candidateId -ceq $CandidateId })
    if ($records.Count -ne 1 -or $records[0].archiveSha256 -cnotmatch '^[A-F0-9]{64}$') { throw 'HRS_CANDIDATE_NOT_UNIQUE_OR_REGISTERED' }
    return $records[0]
}

function Get-HrsCustomerFiles {
    param([string]$CandidateId = '')
    $files = @('LICENSE.md','README.md','START.bat',
        'dev/src/launcher/m0160.psm1','dev/src/launcher/m0161.psm1',
        'dev/src/launcher/m0162.psm1','dev/src/launcher/m0164.psm1','dev/src/launcher/m0166.psm1',
        'dev/ui/p0158.ps1','dev/verified/main/d0163.dll','dev/verified/main/ModInfo.xml')
    # Preserve the exact layout of frozen candidates and existing callers.
    # Branding is required beginning with 1.2.5-qa.002. The archive verifier
    # supplies the candidate ID authenticated by its receipt and registry.
    if ($CandidateId) {
        if ($CandidateId -cnotmatch '^(\d+\.\d+\.\d+)-qa\.(\d{3})$') {
            throw 'HRS_CANDIDATE_ID_INVALID'
        }
        $version = [version]$Matches[1]
        $number = [int]$Matches[2]
        if ($version -gt [version]'1.2.5' -or
            ($version -eq [version]'1.2.5' -and $number -ge 2)) {
            $files += 'dev/ui/logo.ico'
        }
    }
    return $files
}

function Get-HrsCustomerFolder {
    param([Parameter(Mandatory=$true)][string]$Version)
    if ($Version -cnotmatch '^\d+\.\d+\.\d+$') { throw 'HRS_CUSTOMER_VERSION_INVALID' }
    return 'HistoricalRandomStart_' + $Version
}

function Read-HrsVerifiedZip {
    param([string]$ArchivePath, [string]$ManifestPath, [string[]]$ExpectedFiles = @(),
          [string]$Prefix = '', [string]$ExpectedManifestHash = '')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($ArchivePath))
    try {
        $entries = @{}
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName.Replace('\','/')
            # Even directory entries must be contained and unambiguous.
            [void](Resolve-HrsContainedFile $env:TEMP ($name.TrimEnd('/')))
            if ($name.EndsWith('/')) { continue }
            if ($entries.ContainsKey($name)) { throw 'HRS_ZIP_DUPLICATE' }
            $entries[$name] = $entry
        }
        if (-not $entries.ContainsKey($ManifestPath)) { throw 'HRS_ZIP_MANIFEST_MISSING' }
        $manifestHash = Get-HrsStreamHash $entries[$ManifestPath].Open()
        if ($ExpectedManifestHash -and $manifestHash -cne $ExpectedManifestHash) { throw 'HRS_ZIP_MANIFEST_HASH' }
        $reader = New-Object IO.StreamReader($entries[$ManifestPath].Open())
        try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        $listed = @{}
        foreach ($file in @($manifest.files)) {
            [void](Resolve-HrsContainedFile $env:TEMP ([string]$file.path))
            $key = $Prefix + [string]$file.path
            if ($listed.ContainsKey($key) -or $key -eq $ManifestPath) { throw 'HRS_MANIFEST_DUPLICATE' }
            $listed[$key] = $true
            if (-not $entries.ContainsKey($key) -or $file.sha256 -cnotmatch '^[A-F0-9]{64}$' -or
                [int64]$file.bytes -ne $entries[$key].Length -or
                (Get-HrsStreamHash $entries[$key].Open()) -cne $file.sha256) { throw "HRS_ZIP_FILE_IDENTITY: $key" }
        }
        if ($listed.Count -eq 0 -or $entries.Count -ne $listed.Count + 1) { throw 'HRS_ZIP_EXTRA_OR_EMPTY' }
        if ($ExpectedFiles.Count -gt 0) {
            if ($listed.Count -ne $ExpectedFiles.Count) { throw 'HRS_PACKAGE_ALLOWLIST' }
            foreach ($name in $ExpectedFiles) { if (-not $listed.ContainsKey($Prefix + $name)) { throw 'HRS_PACKAGE_ALLOWLIST' } }
        }
        return $manifest
    }
    finally { $zip.Dispose() }
}

function Test-HrsCandidateArchive {
    param([string]$ArchivePath, [string]$ExpectedCandidateId,
          [string]$ExpectedReleaseDigest, [string]$ExpectedContractDigest)
    try {
        if ($ExpectedCandidateId -cnotmatch '^(\d+\.\d+\.\d+)-qa\.\d{3}$') { throw 'HRS_CANDIDATE_ID_INVALID' }
        $version = $Matches[1]
        $folder = Get-HrsCustomerFolder $version
        $record = Get-HrsRegistryRecord $ExpectedCandidateId
        $receiptPath = [IO.Path]::GetFullPath($ArchivePath) + '.receipt.json'
        if ((Get-HrsQaSha256 $receiptPath) -cne $record.receiptSha256) { throw 'HRS_RECEIPT_REGISTRY_MISMATCH' }
        $receipt = Read-HrsQaJson $receiptPath
        $digest = Get-HrsQaSha256 $ArchivePath
        if ($digest -cne $record.archiveSha256 -or $digest -cne $receipt.archiveSha256 -or
            $receipt.candidateId -cne $ExpectedCandidateId -or
            $receipt.releaseVersion -cne $version -or
            $receipt.releaseRecordSha256 -cne $ExpectedReleaseDigest -or
            $receipt.contractSha256 -cne $ExpectedContractDigest -or
            $record.releaseRecordSha256 -cne $ExpectedReleaseDigest -or
            $record.contractSha256 -cne $ExpectedContractDigest) { throw 'HRS_CANDIDATE_IDENTITY' }
        $manifest = Read-HrsVerifiedZip $ArchivePath ($folder+'/package-manifest.json') (Get-HrsCustomerFiles -CandidateId $ExpectedCandidateId) ($folder+'/') $receipt.packageManifestSha256
        if ($manifest.candidateId -cne $ExpectedCandidateId) { throw 'HRS_PACKAGE_CANDIDATE' }
        return [pscustomobject]@{ valid=$true; errors=@(); archiveSha256=$digest; receipt=$receipt; manifest=$manifest }
    }
    catch { return [pscustomobject]@{ valid=$false; errors=@($_.Exception.Message) } }
}

function Assert-HrsTree {
    param([string]$Root, $Files, [string[]]$ExtraAllowed = @())
    $names = @{}
    foreach ($file in @($Files)) {
        $full = Resolve-HrsContainedFile $Root $file.path
        if ($names.ContainsKey($file.path)) { throw 'HRS_TREE_DUPLICATE' }
        $names[$file.path] = $true
        if ((Get-HrsQaSha256 $full) -cne $file.sha256 -or (Get-Item -LiteralPath $full).Length -ne $file.bytes) { throw "HRS_TREE_DRIFT: $($file.path)" }
    }
    foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -File -Force) {
        $relative = $file.FullName.Substring($Root.TrimEnd('\','/').Length).TrimStart('\','/').Replace('\','/')
        if (-not $names.ContainsKey($relative) -and $ExtraAllowed -notcontains $relative) { throw "HRS_TREE_EXTRA: $relative" }
    }
}

function Assert-HrsFrozenRun {
    param([string]$RunPath)
    $run = Read-HrsQaJson (Join-Path $RunPath 'run.json')
    if ((Get-HrsQaSha256 (Join-Path $RunPath 'release.json')) -cne $run.releaseRecordSha256) { throw 'HRS_RUN_RELEASE_DRIFT' }
    if ($run.PSObject.Properties.Name -contains 'contractSha256') {
        if ((Get-HrsQaSha256 (Join-Path $RunPath 'qa-contract.json')) -cne $run.contractSha256) { throw 'HRS_RUN_CONTRACT_DRIFT' }
    }
    if ($run.PSObject.Properties.Name -contains 'candidateId' -and $run.candidateId) {
        $session = Read-HrsQaJson (Join-Path $RunPath 'session.local.json')
        $check = Test-HrsCandidateArchive $session.candidateArchivePath $run.candidateId $run.releaseRecordSha256 $run.contractSha256
        if (-not $check.valid -or $check.archiveSha256 -cne $run.candidateArchiveSha256) { throw 'HRS_RUN_CANDIDATE_DRIFT' }
        # A frozen miniature lane is sufficient for installed inventory. No live source is consulted.
        if ((Get-HrsQaSha256 (Join-Path $RunPath 'dev/qa/rel.json')) -cne $run.releaseRecordSha256) { throw 'HRS_RUN_INVENTORY_CONTRACT_DRIFT' }
        if ($session.PSObject.Properties.Name -contains 'workspaceRoot' -and $session.workspaceRoot) {
            [void](Assert-HrsWorkspace $session.workspaceRoot $session.candidateArchivePath)
        }
    }
    return $run
}

function Assert-HrsEvidence {
    param([string]$RunPath, $Case)
    $manifest = Read-HrsVerifiedZip ($RunPath + '.zip') 'evidence-manifest.json'
    if ($manifest.schema -cne 'hrs-evidence-manifest/v1') { throw 'HRS_EVIDENCE_SCHEMA' }
    foreach ($file in @($manifest.files)) {
        if ((Get-HrsQaSha256 (Resolve-HrsContainedFile $RunPath $file.path)) -cne $file.sha256) { throw 'HRS_EVIDENCE_SIDECAR_DRIFT' }
    }
    if ((Get-HrsQaSha256 (Join-Path $RunPath 'evidence-manifest.json')) -cne
        (Get-HrsZipEntryHash ($RunPath + '.zip') 'evidence-manifest.json')) { throw 'HRS_EVIDENCE_MANIFEST_DRIFT' }
    $names = @($manifest.files | ForEach-Object { $_.path })
    foreach ($required in @('run','qa-result','release','qa-contract','release-validation') + @($Case.requiredEvidence)) {
        if ($names -cnotcontains ($required + '.json')) { throw "HRS_REQUIRED_EVIDENCE: $required" }
    }
}

function Get-HrsZipEntryHash {
    param([string]$ArchivePath,[string]$Name)
    $zip = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try { return Get-HrsStreamHash $zip.GetEntry($Name).Open() } finally { $zip.Dispose() }
}

function Assert-HrsWorkspace {
    param([string]$Root,[string]$ArchivePath)
    $context=Join-Path ([IO.Path]::GetFullPath($Root)) 'context'
    $release=Read-HrsQaJson (Join-Path $context 'dev/qa/rel.json')
    $check=Test-HrsCandidateArchive $ArchivePath $release.candidateId (Get-HrsQaSha256 (Join-Path $context 'dev/qa/rel.json')) (Get-HrsQaSha256 (Join-Path $context 'dev/qa/cases.json'))
    if (-not $check.valid) { throw ('HRS_WORKSPACE_CANDIDATE: '+($check.errors -join ',')) }
    if ((Get-HrsQaSha256 ($ArchivePath+'.companion.zip')) -cne $check.receipt.companionSha256) { throw 'HRS_COMPANION_DRIFT' }
    $manifest=Read-HrsVerifiedZip ($ArchivePath+'.companion.zip') 'context-manifest.json' @() '' $check.receipt.contextManifestSha256
    Assert-HrsTree $context $manifest.files @('context-manifest.json')
    if ((Get-HrsQaSha256 (Join-Path $context 'context-manifest.json')) -cne $check.receipt.contextManifestSha256) { throw 'HRS_CONTEXT_DRIFT' }
    $customer=Join-Path ([IO.Path]::GetFullPath($Root)) ('customer/'+(Get-HrsCustomerFolder $release.version))
    # Manager-generated history is private QA state, not package payload.
    $state=@(Get-ChildItem -LiteralPath $customer -Recurse -File | Where-Object {
        $_.FullName.StartsWith((Join-Path $customer 'dev/ui/HistoricalRandomStart_State')+'\',[StringComparison]::OrdinalIgnoreCase)
    } | ForEach-Object { $_.FullName.Substring($customer.Length+1).Replace('\','/') })
    Assert-HrsTree $customer $check.manifest.files (@('package-manifest.json')+$state)
    if ((Get-HrsQaSha256 (Join-Path $customer 'package-manifest.json')) -cne $check.receipt.packageManifestSha256) { throw 'HRS_PACKAGE_MANIFEST_DRIFT' }
    return $check
}
