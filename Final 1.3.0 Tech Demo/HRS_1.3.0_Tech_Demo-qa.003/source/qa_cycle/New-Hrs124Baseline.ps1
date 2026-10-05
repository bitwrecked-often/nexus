[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$origin = Join-Path $repo 'hrs_1.2.3'
$destination = Join-Path $repo 'hrs_1.2.4'
if (Test-Path -LiteralPath $destination) { throw 'Baseline destination already exists; never overwrite it.' }
$head = (& git -C $repo rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Cannot identify baseline commit.' }
$allowlist = @(
    'LICENSE.md', 'START.bat',
    'dev/ui/p0158.ps1', 'dev/ui/logo.ico', 'dev/ui/Assets/i0141.png',
    'dev/src/launcher/m0160.psm1', 'dev/src/launcher/m0161.psm1',
    'dev/src/launcher/m0162.psm1', 'dev/src/launcher/m0164.psm1',
    'dev/src/launcher/m0166.psm1', 'dev/src/runtime/p0143.ps1',
    'dev/src/runtime/main/c0140.cs', 'dev/src/runtime/main/c0147.cs',
    'dev/src/runtime/main/c0167.cs', 'dev/src/runtime/main/c0181.cs',
    'dev/src/runtime/main/c0184.cs', 'dev/src/runtime/main/c0185.cs',
    'dev/src/runtime/main/c0213.cs', 'dev/src/runtime/main/c0217.cs',
    'dev/src/runtime/main/c0218.cs', 'dev/src/runtime/main/PolicyV1.cs',
    'dev/src/runtime/main/ResultV1.cs', 'dev/src/runtime/main/j0148.json',
    'dev/src/runtime/main/ModInfo.xml'
)
foreach ($relative in $allowlist) {
    if (-not (Test-Path -LiteralPath (Join-Path $origin $relative) -PathType Leaf)) {
        throw "Missing required input: $relative"
    }
}
function Fingerprint($file) {
    [pscustomobject]@{
        path = $file.FullName.Substring($repo.Length + 1).Replace('\','/')
        bytes = $file.Length
        sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
}
$protected = @(Get-ChildItem -LiteralPath $origin -Recurse -File | ForEach-Object { Fingerprint $_ })
foreach ($relative in @('qa_cycle/candidates', 'qa_runs/QA 1.2.3-qa.003', 'hrs_1.2.1/dev/verified')) {
    $path = Join-Path $repo $relative
    if (Test-Path -LiteralPath $path) {
        $protected += @(Get-ChildItem -LiteralPath $path -Recurse -File | ForEach-Object { Fingerprint $_ })
    }
}
foreach ($relative in @('qa_cycle/candidate-registry.json', 'qa_cycle/HRS_1.2.3_CUSTOMER_QA.zip')) {
    $path = Join-Path $repo $relative
    if (Test-Path -LiteralPath $path) { $protected += Fingerprint (Get-Item -LiteralPath $path) }
}
$utf8 = New-Object Text.UTF8Encoding($false)
$entries = @()
foreach ($relative in $allowlist) {
    $source = Join-Path $origin $relative
    $target = Join-Path $destination $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    [IO.File]::Copy($source, $target, $false)
    $action = 'copied-unchanged'
    if ($relative -in @('START.bat','dev/ui/p0158.ps1','dev/src/runtime/main/c0217.cs','dev/src/runtime/main/ModInfo.xml')) {
        $content = [IO.File]::ReadAllText($target).Replace('1.2.3','1.2.4')
        if ($relative -eq 'dev/src/runtime/main/c0217.cs') { $content = $content.Replace('build=r123','build=r124-baseline') }
        if ($relative -eq 'dev/ui/p0158.ps1') {
            $content = $content.Replace('A762CA1A337647A729EDEEDB4C32F8689F70022276310F471C9763CE564B2F75','UNBUILT')
            $content = $content.Replace('B6A9668AAA4AE10984153324F2572352CACB3A851E34B38AD886858AC1477293','UNBUILT')
        }
        [IO.File]::WriteAllText($target, $content, $utf8)
        $action = 'adapted-identity-only'
    }
    $entries += [pscustomobject]@{
        origin = 'hrs_1.2.3/' + $relative
        destination = 'hrs_1.2.4/' + $relative
        originSha256 = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        destinationSha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        originBytes = (Get-Item -LiteralPath $source).Length
        destinationBytes = (Get-Item -LiteralPath $target).Length
        action = $action
    }
}
$excluded = @(Get-ChildItem -LiteralPath $origin -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring($origin.Length + 1).Replace('\','/')
    if ($allowlist -notcontains $relative) {
        [pscustomobject]@{ path='hrs_1.2.3/'+$relative; action='preserved-reference-only'; sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    }
})
$record = [ordered]@{
    schema='hrs-baseline-migration/v1'; sourceCommit=$head
    createdUtc=[datetime]::UtcNow.ToString('o'); status='source-baseline-unbuilt'
    semanticVersion='1.2.4'; buildId='r124-baseline'; candidateId=$null
    files=$entries; excluded=$excluded; protectedBefore=$protected
}
[IO.File]::WriteAllText((Join-Path $destination 'BASELINE_PROVENANCE.json'), ($record | ConvertTo-Json -Depth 8), $utf8)
foreach ($entry in $protected) {
    if ((Get-FileHash -LiteralPath (Join-Path $repo $entry.path) -Algorithm SHA256).Hash -cne $entry.sha256) {
        throw "Protected file changed: $($entry.path)"
    }
}
Write-Output "Created hrs_1.2.4: $($entries.Count) inputs; $($protected.Count) protected files unchanged."
