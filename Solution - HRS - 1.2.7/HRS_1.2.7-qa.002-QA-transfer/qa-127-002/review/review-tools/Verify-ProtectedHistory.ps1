$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$before=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'protected-before.json') -Raw | ConvertFrom-Json
$rows=@(foreach($entry in $before){
    if($entry.path -ceq 'qa_cycle/candidate-registry.json'){continue}
    $file=Join-Path $repo $entry.path
    $actual=if(Test-Path -LiteralPath $file){(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash}else{'MISSING'}
    [pscustomobject]@{path=$entry.path;expectedSha256=$entry.sha256;actualSha256=$actual;match=($actual -ceq $entry.sha256)}
})
$old=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'before/candidate-registry.json') -Raw | ConvertFrom-Json
$current=Get-Content -LiteralPath (Join-Path $repo 'qa_cycle/candidate-registry.json') -Raw | ConvertFrom-Json
$prior=@(for($index=0;$index -lt $old.records.Count;$index++){
    $entry=$old.records[$index]
    # Preserved history includes two entries for the first 1.2.3 candidate.
    # Authenticate each original record in order rather than assuming unique IDs.
    $same=$current.records.Count -gt $index -and (($current.records[$index]|ConvertTo-Json -Depth 20 -Compress) -ceq ($entry|ConvertTo-Json -Depth 20 -Compress))
    [pscustomobject]@{index=$index;candidateId=$entry.candidateId;match=$same}
})
$new=@($current.records|Where-Object{$_.candidateId -ceq '1.2.7-qa.002'})
$valid=(@($rows|Where-Object{!$_.match}).Count -eq 0 -and @($prior|Where-Object{!$_.match}).Count -eq 0 -and $new.Count -eq 1 -and $new[0].status -ceq 'exported-awaiting-live-qa' -and $current.records.Count -eq ($old.records.Count+1))
$result=[ordered]@{
    schema='hrs-history-preservation/v1';status=$(if($valid){'Pass'}else{'Fail'});checkedUtc=[DateTime]::UtcNow.ToString('o')
    verifierSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
    protectedFileCount=$rows.Count;changedProtectedFiles=@($rows|Where-Object{!$_.match});previousRegistryRecords=$prior
    expectedRegistryAppend=$new;protectedFiles=$rows
}
$result|ConvertTo-Json -Depth 20|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'history-preservation.json') -Encoding UTF8
if(!$valid){throw 'Protected historical files or registry records changed unexpectedly'}
'PASS: '+$rows.Count+' historical paths and '+$prior.Count+' previous registry records preserved; only candidate 002 appended.'
