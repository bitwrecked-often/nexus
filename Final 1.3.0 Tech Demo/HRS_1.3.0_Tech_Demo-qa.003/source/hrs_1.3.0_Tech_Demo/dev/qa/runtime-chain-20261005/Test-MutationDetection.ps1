[CmdletBinding()]
param([string]$EvidenceRoot='')
$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -ne 'Desktop'){throw 'Run under Windows PowerShell 5.1.'}
$devRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$sourceRoot=Join-Path $devRoot 'src/runtime/main'
$testPath=Join-Path $devRoot 'tests/Test-RuntimeReviewRepairs.ps1'
if(-not $EvidenceRoot){$EvidenceRoot=Join-Path $PSScriptRoot 'mutations-003'}
$mutationRoot=[IO.Path]::GetFullPath($EvidenceRoot)
$qaPrefix=[IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')+'\'
if(-not $mutationRoot.StartsWith($qaPrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Mutation outputs must remain under this bounded QA directory.'}
if(Test-Path -LiteralPath $mutationRoot){throw 'Preserve previous mutation evidence; choose an unused root.'}
$files=@(Get-ChildItem -LiteralPath $sourceRoot -File | Where-Object {$_.Extension -ceq '.cs'})
if($files.Count -ne 15){throw 'Unexpected production runtime source set.'}
$before=@($files | ForEach-Object {[pscustomobject]@{path=$_.Name;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}})
$mutations=@(
    [pscustomobject]@{name='completed-return-branch-disabled';
        needle="if (state == MarkerState.Completed)`n            {`n                // The loaded character";
        replacement="if (state == MarkerState.Completed && false)`n            {`n                // The loaded character";
        expectedScenario='CompletedProtectedReturnDoesNotRelocate'},
    [pscustomobject]@{name='protection-opt-out-guard-removed';
        needle="if (sessionPolicy.ProtectArrivalBiome &&`n                    MarkerStore.ReadProtectionFamily(player) > 0)";
        replacement='if (MarkerStore.ReadProtectionFamily(player) > 0)';
        secondNeedle='if (!sessionPolicy.ProtectArrivalBiome || protectedEntityId < 0 ||';
        secondReplacement='if (protectedEntityId < 0 ||';
        expectedScenario='ExplicitProtectionOptOutReturn'},
    [pscustomobject]@{name='failed-trader-filter-restoration-removed';
        needle='objective.biomeFilter = originalFilter;';replacement='// Deliberate DEV mutation: omit original-filter restoration.';
        expectedScenario='FailedTraderDestinationRestoresAndRetries'}
)
[void][IO.Directory]::CreateDirectory($mutationRoot)
$records=@()
foreach($mutation in $mutations){
    $caseRoot=Join-Path $mutationRoot $mutation.name
    $copiedSource=Join-Path $caseRoot 'runtime-source'
    [void][IO.Directory]::CreateDirectory($copiedSource)
    foreach($file in $files){[IO.File]::Copy($file.FullName,(Join-Path $copiedSource $file.Name),$false)}
    $consumerPath=Join-Path $copiedSource 'c0167.cs'
    $text=[IO.File]::ReadAllText($consumerPath).Replace("`r`n","`n")
    if([regex]::Matches($text,[regex]::Escape($mutation.needle)).Count -ne 1){throw "Mutation seam ambiguous: $($mutation.name)"}
    $text=$text.Replace($mutation.needle,$mutation.replacement)
    if($mutation.secondNeedle){
        if([regex]::Matches($text,[regex]::Escape($mutation.secondNeedle)).Count -ne 1){throw "Second mutation seam ambiguous: $($mutation.name)"}
        $text=$text.Replace($mutation.secondNeedle,$mutation.secondReplacement)
    }
    [IO.File]::WriteAllText($consumerPath,$text,[Text.UTF8Encoding]::new($false))
    $resultRoot=Join-Path $caseRoot 'results'
    & $testPath -EvidenceRoot $resultRoot -RuntimeSourceRoot $copiedSource -AllowFixtureFailures | Out-Null
    $result=Get-Content -LiteralPath (Join-Path $resultRoot 'verification.json') -Raw | ConvertFrom-Json
    $expected=@($result.cases | Where-Object {$_.scenario -ceq $mutation.expectedScenario})
    if($expected.Count -ne 1 -or $expected[0].pass -ne $false -or $result.failed -lt 1 -or $result.fixtureExitCode -eq 0){
        throw "Broken callback escaped its expected detection: $($mutation.name)"
    }
    $records+=[pscustomobject][ordered]@{mutation=$mutation.name;changedFile='c0167.cs';
        originalSha256=($before | Where-Object {$_.path -ceq 'c0167.cs'}).sha256;
        mutatedSha256=(Get-FileHash -LiteralPath $consumerPath -Algorithm SHA256).Hash;
        expectedScenario=$mutation.expectedScenario;detected=$true;assertion=$expected[0].error;
        fixtureTotal=$result.total;fixtureFailed=$result.failed;fixtureExitCode=$result.fixtureExitCode;
        evidencePath=($mutation.name+'/results/verification.json')}
}
foreach($record in $before){
    if((Get-FileHash -LiteralPath (Join-Path $sourceRoot $record.path) -Algorithm SHA256).Hash -cne $record.sha256){
        throw "Production source changed during isolated mutation verification: $($record.path)"
    }
}
$receipt=[ordered]@{schema='hrs-runtime-chain-mutation-detection/v1';status='Pass';
    generatedUtc=[DateTime]::UtcNow.ToString('o');scope='Deliberately broken copies under isolated QA evidence only. Expected fixture failures demonstrate detection; these are not production failures or human QA passes.';
    total=$records.Count;detected=$records.Count;records=$records;productionSourceHashes=$before;
    productionSourceChanged=$false;realGameWrites=0;independentQaCasesChanged=0}
[IO.File]::WriteAllText((Join-Path $mutationRoot 'verification.json'),($receipt | ConvertTo-Json -Depth 9)+"`n",[Text.UTF8Encoding]::new($false))
Write-Output ('PASS: '+$records.Count+' deliberate callback mutations detected; production sources unchanged.')
