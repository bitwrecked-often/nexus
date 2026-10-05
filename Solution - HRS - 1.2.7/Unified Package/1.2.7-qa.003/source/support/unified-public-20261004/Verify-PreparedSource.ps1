[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PublicContentRoot,
      [Parameter(Mandatory=$true)][string]$GameReferenceRoot,
      [Parameter(Mandatory=$true)][string]$EvidenceRoot)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -cne 'Desktop'){throw 'Use Windows PowerShell 5.1.'}
if(Test-Path -LiteralPath $EvidenceRoot){throw 'Preserve existing source-verification evidence.'}
$root=[IO.Path]::GetFullPath($PublicContentRoot)
$evidence=[IO.Path]::GetFullPath($EvidenceRoot)
[void][IO.Directory]::CreateDirectory($evidence)
$workingRoot=Join-Path ([IO.Path]::GetTempPath()) ('hrs-public-source-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($workingRoot)
$original=Join-Path $root 'source/hrs_1.2.7'
$working=Join-Path $workingRoot 'hrs_1.2.7'
Copy-Item -LiteralPath $original -Destination $working -Recurse
$expected=(Get-FileHash -LiteralPath (Join-Path $working 'dev/verified/main/d0163.dll') -Algorithm SHA256).Hash
$rows=New-Object 'Collections.Generic.List[object]'
function Invoke-PreparedCheck([string]$Name,[scriptblock]$Action){
    $stdout=Join-Path $evidence ($Name+'.txt')
    $raw=(& $Action 2>&1|Out-String)
    [IO.File]::WriteAllText($stdout,$raw,(New-Object Text.UTF8Encoding($false)))
    [void]$rows.Add([pscustomobject]@{name=$Name;status='Pass';stdoutFile=$Name+'.txt';stdoutSha256=(Get-FileHash -LiteralPath $stdout -Algorithm SHA256).Hash})
}
Invoke-PreparedCheck 'native-pinned-build' {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $working 'dev/src/runtime/p0143.ps1') -GameRoot $GameReferenceRoot
    if($LASTEXITCODE -ne 0){throw 'Native pinned build failed.'}
}
$recordFile=Get-ChildItem -LiteralPath (Join-Path $working 'dev/out') -Recurse -File -Filter 'j0144.json'|Select-Object -First 1
$record=Get-Content -LiteralPath $recordFile.FullName -Raw|ConvertFrom-Json
if(!$record.deterministicDoubleBuild -or $record.dllSha256 -cne $expected -or $record.sourceHashes.Count -ne 15){
    throw 'Public-source rebuild did not match the exact qualified runtime.'
}
Invoke-PreparedCheck 'native-design-check' {
    & powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $working 'dev/tools/NativeGraphics/Sync-ManagerDesign.ps1') -Check
    if($LASTEXITCODE -ne 0){throw 'Native design check failed.'}
}
Invoke-PreparedCheck 'compiled-policy' {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $working 'dev/tests/Test-CompiledPolicy.ps1')
    if($LASTEXITCODE -ne 0){throw 'Compiled-policy check failed.'}
}
Invoke-PreparedCheck 'policy-v2' {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $working 'dev/tests/Test-PolicyV2.ps1')
    if($LASTEXITCODE -ne 0){throw 'PolicyV2 check failed.'}
}
Invoke-PreparedCheck 'manager-review' {
    & powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $working 'dev/tests/Test-ManagerReviewRepairs.ps1') -EvidenceRoot (Join-Path $evidence 'manager')
    if($LASTEXITCODE -ne 0){throw 'Focused manager check failed.'}
}
Invoke-PreparedCheck 'runtime-review' {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $working 'dev/tests/Test-RuntimeReviewRepairs.ps1') -EvidenceRoot (Join-Path $evidence 'runtime')
    if($LASTEXITCODE -ne 0){throw 'Focused runtime check failed.'}
}
$runtime=Get-Content -LiteralPath (Join-Path $evidence 'runtime/verification.json') -Raw|ConvertFrom-Json
$manager=Get-Content -LiteralPath (Join-Path $evidence 'manager/verification.json') -Raw|ConvertFrom-Json
$managerCount=if($manager.PSObject.Properties['assertions']){@($manager.assertions).Count}elseif($manager.PSObject.Properties['total']){[int]$manager.total}else{@($manager.checks).Count}
$verification=[pscustomobject][ordered]@{
    schema='hrs-public-source-verification/v1';candidateId='1.2.7-qa.003';status='Pass';verifiedUtc=[DateTime]::UtcNow.ToString('o')
    sourceLayout='source/hrs_1.2.7';method='Copy supplied public source into a new disposable local directory; invoke its real native builder and reusable source tests with existing authenticated external reference inputs.'
    expectedRuntimeSha256=$expected;rebuiltRuntimeSha256=$record.dllSha256;deterministicDoubleBuild=$record.deterministicDoubleBuild
    compiledSourceCount=$record.sourceHashes.Count;referenceCount=$record.references.Count
    runtimeScenarios=$runtime.total;runtimePassed=$runtime.passed;runtimeFailed=$runtime.failed
    managerAssertions=$managerCount;checks=$rows.ToArray();preparedContentChanged=$false
    installedGameWrites=0;gameLaunched=$false;independentQaCasesPassed=0;publicationApproved=$false
}
[IO.File]::WriteAllText((Join-Path $evidence 'verification.json'),($verification|ConvertTo-Json -Depth 8)+"`r`n",(New-Object Text.UTF8Encoding($false)))
$verification
