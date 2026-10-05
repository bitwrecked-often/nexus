$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
$dev=Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $dev 'src/launcher/m0161.psm1') -Force
$sources=@('PolicyV1.cs','PolicyV2.cs','BiomePreference.cs') | ForEach-Object { Join-Path $dev "src/runtime/main/$_" }
Add-Type -Path @($sources + (Join-Path $PSScriptRoot 'PolicyProbe.cs'))
$out=Join-Path ([IO.Path]::GetTempPath()) ('hrs-policy-v2-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($out)
$path=Join-Path $out 'policy.v2.json'
$utf8=New-Object Text.UTF8Encoding($false)
$script:count=0
function Assert($ok,$label) { if (!$ok) { throw "FAIL: $label" }; $script:count++ }
function RejectBoth($json,$label) {
    [IO.File]::WriteAllText($path,$json,$utf8)
    $rejected=$false
    try { $null=ConvertFrom-HrsPolicyJson $json } catch { $rejected=$true }
    Assert $rejected "PS $label"
    Assert ([PolicyProbe]::ReadV2($path) -eq 'POLICY_REJECTED') "C# $label"
}
$date=[datetime]'2026-09-27T18:00:00.000Z'
$vectors=New-Object Collections.Generic.List[object]
foreach($mode in @('Standard','Random','RandomSafe')) {
    foreach($selection in @('Any','Chosen','Weighted')) {
        if($mode -eq 'Standard' -and $selection -ne 'Any') {continue}
        $chosen=if($selection -eq 'Chosen'){8}else{0}
        $weights=if($selection -eq 'Weighted'){@(10,20,20,25,25)}else{@(0,0,0,0,0)}
        $p=New-HrsPolicy -Revision 2 -GameName 'QA Biomes' -Mode $mode -Selection $selection -ChosenBiome $chosen -Weights $weights -WrittenUtc $date
        $json=ConvertTo-HrsPolicyJson $p
        $read=Write-HrsPolicyFile -Path $path -AllowedRoot $out -Policy $p
        Assert ($read.policyDigest -ceq $p.policyDigest) 'atomic PS readback'
        Assert ([PolicyProbe]::ReadV2($path) -ceq $json) 'cross-language bytes'
        Assert (![PolicyProbe]::AcceptsV1($path)) 'v1 runtime rejects v2'
        [void]$vectors.Add([ordered]@{mode=$mode;selection=$selection;canonical=$json;digest=$p.policyDigest})
    }
}
$vectors | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $out 'vectors.json') -Encoding UTF8
$fixed=Get-Content (Join-Path $dev 'qa/POLICY_V2_VECTORS.json') -Raw | ConvertFrom-Json
for($i=0;$i -lt $fixed.Count;$i++){Assert ($fixed[$i].canonical -ceq $vectors[$i].canonical) 'fixed canonical vector'}
RejectBoth ($json.Replace('"forest":10','"forest":101')) 'weight range'
RejectBoth ($json.Replace('"selection":"Weighted"','"selection":"Unknown"')) 'selection enum'
RejectBoth ($json.Replace('"chosenBiome":0','"chosenBiome":99')) 'inactive biome'
RejectBoth ($json.Replace('"revision":2','"revision":02')) 'leading zero'
RejectBoth ($json+"`n") 'trailing newline'
RejectBoth ($json.Replace('"forest":10,"burntForest":20','"burntForest":20,"forest":10')) 'reordered fields'
RejectBoth ($json.Replace('"forest":10','"forest":11')) 'digest tampering'
RejectBoth ($json.Replace('"forest":10','"forest":1.0')) 'noninteger'
RejectBoth ($json.Replace('"revision":2','"revision":18446744073709551616')) 'overflow'
foreach($selection in @('Weighted','Chosen')) {
    $rejected=$false
    try { $null=New-HrsPolicy -Revision 1 -GameName 'QA' -Mode Random -Selection $selection } catch {$rejected=$true}
    Assert $rejected "invalid $selection cannot be created"
}
# Enumerate every integer ticket: exact probabilities, independent of POI counts.
$ids=@(3,9,5,1,8)
for($i=0;$i -lt 5;$i++) { Assert ([PolicyProbe]::Draw('Any',0,@(0,0,0,0,0),$ids,$i) -eq $ids[$i]) 'uniform categories' }
$counts=@{}
for($i=0;$i -lt 45;$i++) { $id=[PolicyProbe]::Draw('Weighted',0,@(10,20,20,25,25),@(5,8),$i); if(!$counts.ContainsKey($id)){$counts[$id]=0}; $counts[$id]++ }
Assert ($counts[5] -eq 20 -and $counts[8] -eq 25) 'absent biomes renormalized'
Assert ([PolicyProbe]::Draw('Weighted',0,@(0,0,0,0,100),$ids,99) -eq 8) 'single positive excludes zero weights'
Assert ([PolicyProbe]::Draw('Chosen',1,@(0,0,0,0,0),$ids,0) -eq 1) 'chosen biome'
try { [void][PolicyProbe]::Draw('Chosen',1,@(0,0,0,0,0),@(3,8),0);throw 'UNEXPECTED' } catch { Assert ($_.Exception.ToString().Contains('REQUESTED_BIOME_ABSENT')) 'chosen absent' }
try { [void][PolicyProbe]::Draw('Weighted',0,@(0,0,0,0,100),@(3),0);throw 'UNEXPECTED' } catch { Assert ($_.Exception.ToString().Contains('WEIGHTED_POOL_EMPTY')) 'weighted empty' }
Import-Module (Join-Path $dev 'src/launcher/m0162.psm1') -Force
Import-Module (Join-Path $dev 'src/launcher/m0164.psm1') -Force
Import-Module (Join-Path $dev 'src/launcher/m0161.psm1') -Force
$game=Join-Path $out 'Game'
$bridge=Get-HrsBridgePaths -GameRoot $game
[void][IO.Directory]::CreateDirectory($bridge.BridgeRoot)
[IO.File]::WriteAllText((Join-Path $game '7DaysToDie.exe'),'fixture')
foreach($mode in @('Standard','Random','RandomSafe')) {
    if([IO.File]::Exists($bridge.PolicyPath)){[IO.File]::Delete($bridge.PolicyPath)}
    $legacy= & (Get-Module m0161) {param($mode) New-HrsLegacyPolicy -Revision 7 -GameName 'Existing exact game' -Mode $mode} $mode
    $legacyJson=ConvertTo-HrsPolicyJson $legacy
    [IO.File]::WriteAllText($bridge.LegacyPolicyPath,$legacyJson,$utf8)
    $old=Read-HrsConfiguredPolicy $game
    $args=Get-HrsSelectionArguments $old
    $next=New-HrsPolicy -Revision ($old.revision+1) -GameName $old.gameName -Mode $old.mode @args
    $written=Write-HrsAppliedPolicy -GameRoot $game -Policy $next
    Assert ($written.revision -eq 8 -and $written.mode -ceq $mode -and $written.selection -ceq 'Any' -and $written.gameName -ceq $old.gameName) 'explicit v1 migration'
    Assert (![IO.File]::Exists($bridge.LegacyPolicyPath)) 'only v2 authoritative'
    [IO.File]::WriteAllText($bridge.LegacyPolicyPath,$legacyJson,$utf8)
    Assert (!(Test-HrsBridgePaths $game).Valid) 'ambiguous bridge rejected'
    [IO.File]::Delete($bridge.LegacyPolicyPath)
}
# A failed legacy deletion must leave the exact old policy authoritative.
[IO.File]::Delete($bridge.PolicyPath)
[IO.File]::WriteAllText($bridge.LegacyPolicyPath,$legacyJson,$utf8)
[IO.File]::SetAttributes($bridge.LegacyPolicyPath,[IO.FileAttributes]::ReadOnly)
try {
    $rejected=$false
    try {$null=Write-HrsAppliedPolicy -GameRoot $game -Policy $next} catch {$rejected=$true}
    Assert ($rejected -and ![IO.File]::Exists($bridge.PolicyPath) -and [IO.File]::ReadAllText($bridge.LegacyPolicyPath) -ceq $legacyJson) 'migration failure restores old authoritative bridge'
} finally {[IO.File]::SetAttributes($bridge.LegacyPolicyPath,[IO.FileAttributes]::Normal)}
$null=Write-HrsAppliedPolicy -GameRoot $game -Policy $next
$beforeBytes=[IO.File]::ReadAllText($bridge.PolicyPath)
try { Write-HrsAtomicUtf8File -Path $bridge.PolicyPath -AllowedRoot $bridge.BridgeRoot -Text 'invalid' -ReadbackValidator {throw 'INJECTED_READBACK_FAILURE'} } catch {}
Assert ([IO.File]::ReadAllText($bridge.PolicyPath) -ceq $beforeBytes) 'atomic failed readback restores exact prior bytes'
# Recovery uses the full policy object, including the selected method and weights.
$manager=Join-Path $out 'Manager'
[void][IO.Directory]::CreateDirectory((Join-Path $manager 'ui'))
$weighted=New-HrsPolicy -Revision 9 -GameName 'Saved biome' -Mode RandomSafe -Selection Weighted -Weights @(0,0,20,30,50)
$correlation=New-HrsCorrelationId
$null=Add-HrsRecoveryAttempt -ManagerRoot $manager -Outcome Succeeded -Reason POLICY_APPLIED -CorrelationId $correlation -KnownGood -Policy $weighted
$plan=Get-HrsRestorePlan -ManagerRoot $manager -AttemptId $correlation -CurrentPolicy $written
Assert ($plan.Valid -and $plan.Policy.selection -ceq 'Weighted' -and $plan.Policy.wasteland -eq 50 -and $plan.Policy.mode -ceq 'RandomSafe' -and $plan.Policy.revision -eq 10) 'recovery preserves settings and advances revision'
$overflow=$false
try { & (Get-Module m0164) {Get-HrsNextRecoveryRevision -HighestRevision ([UInt64]::MaxValue)} } catch {$overflow=$true}
Assert $overflow 'revision exhaustion fails closed'
"PASS: $script:count policy, migration, recovery and deterministic draw assertions"
