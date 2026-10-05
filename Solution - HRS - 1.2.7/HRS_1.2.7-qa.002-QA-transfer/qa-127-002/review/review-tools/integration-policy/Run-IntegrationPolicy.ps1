[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$LaneRoot)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
if($PSVersionTable.PSEdition -cne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5){throw 'Native Windows PowerShell5.1 required.'}
$lane=[IO.Path]::GetFullPath($LaneRoot)
$evidence=$PSScriptRoot
$verificationPath=Join-Path $evidence 'verification.json'
if([IO.File]::Exists($verificationPath)){throw 'Preserve existing policy integration result.'}
$utf8=New-Object Text.UTF8Encoding($false)
$native=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
$env:PSModulePath='C:\Windows\system32\WindowsPowerShell\v1.0\Modules;C:\Program Files\WindowsPowerShell\Modules;C:\Users\mobil\Documents\WindowsPowerShell\Modules'
$expectedDll='134F56AE20BAA6E6A53E9802436465DA282D8231A042DC6826D5A07848B057BB'
$dllPath=Join-Path $lane 'dev/verified/main/d0163.dll'
if((Get-FileHash -LiteralPath $dllPath -Algorithm SHA256).Hash -cne $expectedDll -or ([IO.FileInfo]$dllPath).Length -ne 77312){throw 'Qualified DLL identity differs.'}
$copiedInputs=@('dev/tests/Test-PolicyV2.ps1','dev/tests/Test-PolicyInvalidFixtures.ps1','dev/tests/PolicyProbe.cs',
    'dev/src/launcher/m0161.psm1','dev/src/launcher/m0162.psm1','dev/src/launcher/m0164.psm1',
    'dev/src/runtime/main/PolicyV1.cs','dev/src/runtime/main/PolicyV2.cs','dev/src/runtime/main/BiomePreference.cs','dev/qa/POLICY_V2_VECTORS.json')
$protectedInputs=@($copiedInputs)+@('dev/tests/Test-CompiledPolicy.ps1','dev/verified/main/d0163.dll','dev/verified/main/ModInfo.xml',
    'dev/ui/p0158.ps1','dev/tools/NativeGraphics/Sync-ManagerDesign.ps1','dev/tools/NativeGraphics/Recipes.psm1',
    'dev/tools/NativeGraphics/NativeControls.cs','dev/tools/NativeGraphics/recipes/bitwrecked-quiet.json',
    'dev/qa/cases.json','dev/qa/rel.json','dev/builds/1.2.7-qa.002/build-record.json')
$before=New-Object Collections.Generic.List[object]
foreach($relative in $protectedInputs){[void]$before.Add([pscustomobject]@{path=$relative;sha256=(Get-FileHash -LiteralPath (Join-Path $lane $relative) -Algorithm SHA256).Hash})}
$clone=Join-Path ([IO.Path]::GetTempPath()) ('hrs127-policy-inputs-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($clone)
$copies=New-Object Collections.Generic.List[object]
foreach($relative in $copiedInputs){
    $from=Join-Path $lane $relative;$to=Join-Path $clone $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
    [IO.File]::Copy($from,$to,$false)
    $hash=(Get-FileHash -LiteralPath $from -Algorithm SHA256).Hash
    if((Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash -cne $hash){throw 'Cloned test input differs.'}
    [void]$copies.Add([pscustomobject]@{path=$relative;sha256=$hash;copiedExactly=$true})
}
$checks=New-Object Collections.Generic.List[object]
function Invoke-NativeCheck {
    param([string]$Name,[string]$Script,[string[]]$Extra=@())
    $outputPath=Join-Path $evidence ($Name+'-stdout.txt')
    if([IO.File]::Exists($outputPath)){throw 'Preserve existing stdout.'}
    $started=[datetime]::UtcNow.ToString('o')
    $arguments=@('-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',$Script)+@($Extra)
    $lines=@(& $native @arguments 2>&1)
    $code=$LASTEXITCODE
    $output=($lines|Out-String)
    [IO.File]::WriteAllText($outputPath,$output,$utf8)
    [void]$checks.Add([pscustomobject][ordered]@{name=$Name;status=$(if($code -eq 0){'Pass'}else{'Fail'});executable=$native;arguments=$arguments;startedUtc=$started;completedUtc=[datetime]::UtcNow.ToString('o');exitCode=$code;stdout=[IO.Path]::GetFileName($outputPath);stdoutSha256=(Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash})
    Write-Output ($Name+': exit '+$code)
}
Invoke-NativeCheck -Name compiled-policy -Script (Join-Path $lane 'dev/tests/Test-CompiledPolicy.ps1')
Invoke-NativeCheck -Name policy-v2 -Script (Join-Path $clone 'dev/tests/Test-PolicyV2.ps1')
Invoke-NativeCheck -Name invalid-writer -Script (Join-Path $clone 'dev/tests/Test-PolicyInvalidFixtures.ps1') -Extra @('-EvidenceRoot',$evidence)
$helper=Join-Path $evidence 'Check-NativeInputs.ps1'
Invoke-NativeCheck -Name embedding -Script $helper -Extra @('-LaneRoot',$lane,'-Check','Embedding','-ReportPath',(Join-Path $evidence 'embedding.json'))
Invoke-NativeCheck -Name parser -Script $helper -Extra @('-LaneRoot',$lane,'-Check','Parser','-ReportPath',(Join-Path $evidence 'parser.json'))
$after=New-Object Collections.Generic.List[object]
foreach($entry in $before){$actual=(Get-FileHash -LiteralPath (Join-Path $lane $entry.path) -Algorithm SHA256).Hash;[void]$after.Add([pscustomobject]@{path=$entry.path;beforeSha256=$entry.sha256;afterSha256=$actual;unchanged=($entry.sha256 -ceq $actual)})}
$clonedVectorPath=Join-Path $clone 'dev/qa/POLICY_V2_VECTORS.json'
$vectorHash=(Get-FileHash -LiteralPath (Join-Path $lane 'dev/qa/POLICY_V2_VECTORS.json') -Algorithm SHA256).Hash
$clonedVectorHash=(Get-FileHash -LiteralPath $clonedVectorPath -Algorithm SHA256).Hash
$compiledText=[IO.File]::ReadAllText((Join-Path $evidence 'compiled-policy-stdout.txt'))
$policyText=[IO.File]::ReadAllText((Join-Path $evidence 'policy-v2-stdout.txt'))
$invalidText=[IO.File]::ReadAllText((Join-Path $evidence 'invalid-writer-stdout.txt'))
$assertions=[regex]::Match($policyText,'PASS: (?<count>\d+) policy, migration, recovery and deterministic draw assertions')
$summary=[pscustomobject][ordered]@{
    schema='hrs-repair-integration-policy-check/v1';status='Pass';checkedUtc=[datetime]::UtcNow.ToString('o');candidateId='1.2.7-qa.002'
    scope='Native DEV policy/codec/integration/syntax checks only; no real game, Apply, customer export or independent QA.'
    powerShellEdition=$PSVersionTable.PSEdition;powerShellVersion=$PSVersionTable.PSVersion.ToString()
    runtimeSha256=$expectedDll;runtimeBytes=77312
    compiledPolicy=[pscustomobject]@{canonicalVectors=7;tamperRejected=$compiledText.Contains('7 canonical vectors and tamper rejection');actualQualifiedDll=$true}
    policyV2=[pscustomobject]@{assertionCount=$(if($assertions.Success){[int]$assertions.Groups['count'].Value}else{0});isolatedInputs=$clone}
    invalidWriter=[pscustomobject]@{fixtureCount=11;priorBytesPreserved=$invalidText.Contains('11 invalid policy writer fixtures rejected without changing prior policy');evidence='writer-invalid-fixtures.json'}
    fixedVectors=[pscustomobject]@{sha256=$vectorHash;cloneSha256=$clonedVectorHash;unchanged=($vectorHash -ceq $clonedVectorHash)}
    checks=$checks.ToArray();clonedInputs=$copies.ToArray();inputReadback=$after.ToArray()
    independentQaPending=46;limitations='Cross-language helper fixtures compile current policy sources; only compiled-policy exercises the actual qualified DLL. Fixtures use inert temp game roots and bounded local writes. No actual display/accessibility or gameplay certification.'
}
if(@($checks.ToArray()|Where-Object{$_.status -cne 'Pass'}).Count -or @($after.ToArray()|Where-Object{!$_.unchanged}).Count -or !$assertions.Success -or !$summary.compiledPolicy.tamperRejected -or !$summary.invalidWriter.priorBytesPreserved -or !$summary.fixedVectors.unchanged){$summary.status='Fail'}
[IO.File]::WriteAllText($verificationPath,($summary|ConvertTo-Json -Depth 10),$utf8)
Write-Output ('Integration policy status: '+$summary.status)
if($summary.status -cne 'Pass'){exit 1}
