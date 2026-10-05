param([Parameter(Mandatory=$true)][string]$EvidenceRoot)

$ErrorActionPreference='Stop'
$devRoot=Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $devRoot 'src/launcher/m0161.psm1') -Force
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('hrs125-invalid-writer-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixture)
$policyPath=Join-Path $fixture 'policy.v2.json'
$records=New-Object System.Collections.Generic.List[object]
$cases=@(
    @{name='WeightOver100';change={param($p) $p.forest=101}},
    @{name='WeightNegative';change={param($p) $p.forest=-1}},
    @{name='WeightString';change={param($p) $p.forest='ten'}},
    @{name='UnknownBiome';change={param($p) $p.selection='Chosen';$p.chosenBiome=99;$p.forest=0;$p.burntForest=0;$p.desert=0;$p.snow=0;$p.wasteland=0}},
    @{name='UnknownMethod';change={param($p) $p.selection='Lottery'}},
    @{name='UnknownMode';change={param($p) $p.mode='Teleport'}},
    @{name='MalformedTimestamp';change={param($p) $p.writtenUtc='yesterday'}},
    @{name='InvalidExactName';change={param($p) $p.gameName='Bad/Name'}},
    @{name='AllZeroWeighted';change={param($p) $p.forest=0;$p.burntForest=0;$p.desert=0;$p.snow=0;$p.wasteland=0}},
    @{name='InactiveWeights';change={param($p) $p.selection='Any'}},
    @{name='InactiveBiome';change={param($p) $p.chosenBiome=8}}
)
foreach($case in $cases) {
    $baseline=New-HrsPolicy -Revision ([UInt64]1) -GameName 'Valid Writer Fixture' -Mode Random -Selection Weighted -Weights @(10,20,20,25,25)
    [void](Write-HrsPolicyFile -Path $policyPath -AllowedRoot $fixture -Policy $baseline)
    $before=(Get-FileHash -LiteralPath $policyPath -Algorithm SHA256).Hash
    $invalid=New-HrsPolicy -Revision ([UInt64]2) -GameName 'Valid Writer Fixture' -Mode Random -Selection Weighted -Weights @(10,20,20,25,25)
    & $case.change $invalid
    $reason=''
    try { [void](Write-HrsPolicyFile -Path $policyPath -AllowedRoot $fixture -Policy $invalid) }
    catch { $reason=$_.Exception.Message }
    $after=(Get-FileHash -LiteralPath $policyPath -Algorithm SHA256).Hash
    $readback=Read-HrsPolicyFile -Path $policyPath
    if(-not $reason -or $before -cne $after -or $readback.revision -ne 1 -or $readback.policyDigest -cne $baseline.policyDigest) {
        throw "$($case.name) invalid writer changed prior policy or was accepted: $reason"
    }
    [void]$records.Add([pscustomobject]@{scenario=$case.name;rejected=$true;reason=$reason;beforeSha256=$before;afterSha256=$after;priorRevision=$readback.revision})
}
$evidence=[IO.Path]::GetFullPath($EvidenceRoot)
[void][IO.Directory]::CreateDirectory($evidence)
$resultPath=Join-Path $evidence 'writer-invalid-fixtures.json'
$records.ToArray()|ConvertTo-Json -Depth 4|Set-Content -LiteralPath $resultPath -Encoding UTF8
"PASS: $($records.Count) invalid policy writer fixtures rejected without changing prior policy; evidence $resultPath"
