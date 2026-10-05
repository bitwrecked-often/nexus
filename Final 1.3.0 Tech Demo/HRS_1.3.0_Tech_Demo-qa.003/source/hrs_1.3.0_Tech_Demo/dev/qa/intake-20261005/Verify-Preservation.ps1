# Verify protected history plus Git filtering without staging or committing.
param([Parameter(Mandatory=$true)][string]$EvidenceRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
$lane=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$repo=Split-Path -Parent $lane
$provenance=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $lane 'BASELINE_PROVENANCE.json')))
$rows=New-Object 'Collections.Generic.List[object]'
foreach($item in $provenance.protectedBefore){
    $path=Join-Path $repo $item.path
    if(![IO.File]::Exists($path) -or (Get-Item -LiteralPath $path).Length -ne $item.bytes -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $item.sha256){throw ('Protected history changed: '+$item.path)}
    [void]$rows.Add([pscustomobject]@{path=$item.path;sha256=$item.sha256;bytes=$item.bytes;status='Pass'})
}
$samples=@(
    'QA Return Final 20261005/START-HERE.md',
    'QA Return Final 20261005/transfer-manifest.json',
    'QA Return Final 20261005/dev-handoff/hrs-1.2.7-qa.003-review/DEV-TODO.md',
    'QA Return Final 20261005/HRS_1.2.7-qa.003-QA-to-DEV-20261005.zip',
    'hrs_1.3.0_Tech_Demo/dev/ui/p0158.ps1',
    'hrs_1.3.0_Tech_Demo/dev/src/runtime/main/c0217.cs',
    'hrs_1.3.0_Tech_Demo/dev/verified/main/d0163.dll',
    'hrs_1.3.0_Tech_Demo/dev/ui/logo.ico')
$gitRows=New-Object 'Collections.Generic.List[object]'
foreach($relative in $samples){
    $path=Join-Path $repo $relative
    $raw=(& git -C $repo hash-object --no-filters -- $path).Trim()
    if($LASTEXITCODE -ne 0){throw ('Raw Git object failed: '+$relative)}
    $filtered=(& git -C $repo hash-object ('--path='+$relative) -- $path).Trim()
    if($LASTEXITCODE -ne 0 -or $filtered -cne $raw){throw ('Git changes source/return bytes: '+$relative)}
    [void]$gitRows.Add([pscustomobject]@{path=$relative;rawBlobSha1=$raw;filteredBlobSha1=$filtered;status='Pass'})
}
[void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($EvidenceRoot))
[ordered]@{schema='hrs-tech-demo-history-preservation/v1';status='Pass';protectedPaths=$rows.Count;protected=$rows.ToArray();gitFilterSamples=$gitRows.ToArray();scope='All baseline protected files retain exact bytes; supplied intake separately verifies all 566 returned paths. Git attributes tested on representative text/source/archive/image/runtime inputs without staging or commit.';completedUtc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'preservation-verification.json') -Encoding UTF8
'PASS: '+$rows.Count+' protected historical paths and '+$gitRows.Count+' exact-byte Git filter samples.'
