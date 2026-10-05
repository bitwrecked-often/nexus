param(
    [ValidateSet('All','standard','selection','failure','dev','steam-refresh','launch','result','startup','uninstall','ux-state','ux-state-dev','round2','round2-dev','editor','uncertain-recovery','apply-reject','storage','migration')][string]$Group='All',
    [string]$EvidenceRoot=(Join-Path $PSScriptRoot '../qa/native-ux-round2/callbacks'),
    [string]$ExpectedSourceSha256=''
)
$ErrorActionPreference='Stop'
$laneRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$source=Join-Path $laneRoot 'dev/ui/p0158.ps1'
$harness=Join-Path $laneRoot 'dev/tests/Test-ManagerCallbackWiring.ps1'
if (!$ExpectedSourceSha256) { $ExpectedSourceSha256=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash }
$groups=@(
    @{name='standard';branch='Verified';probes=@();expectedCount=2;record='callback-verified.json'},
    @{name='selection';branch='Verified';probes=@('-SelectionProbe');expectedCount=8;record='callback-verified-selection.json'},
    @{name='failure';branch='Verified';probes=@('-FailureProbe','-FailurePoint','DuringPolicyReadback');expectedCount=1;record='callback-verified-failure-duringpolicyreadback.json'},
    @{name='dev';branch='DevDispatch';probes=@();expectedCount=2;record='callback-devdispatch.json'},
    @{name='steam-refresh';branch='Verified';probes=@('-SteamRefreshProbe');expectedCount=1;record='callback-verified-steam-refresh.json'},
    @{name='launch';branch='Verified';probes=@('-LaunchProbe');expectedCount=16;record='callback-verified-launch.json'},
    @{name='result';branch='Verified';probes=@('-ResultProbe');expectedCount=1;record='callback-verified-result.json'},
    @{name='startup';branch='Verified';probes=@('-StartupProbe');expectedCount=4;record='callback-verified-startup.json'},
    @{name='uninstall';branch='Verified';probes=@('-UninstallProbe');expectedCount=6;record='callback-verified-uninstall.json'},
    @{name='ux-state';branch='Verified';probes=@('-UxStateProbe');expectedCount=9;record='callback-verified-ux-state.json'},
    @{name='ux-state-dev';branch='DevDispatch';probes=@('-UxStateProbe');expectedCount=9;record='callback-devdispatch-ux-state.json'},
    @{name='round2';branch='Verified';probes=@('-Round2Probe');expectedCount=6;record='callback-verified-round2.json'},
    @{name='round2-dev';branch='DevDispatch';probes=@('-Round2Probe');expectedCount=6;record='callback-devdispatch-round2.json'},
    @{name='editor';branch='Verified';probes=@('-EditorProbe');expectedCount=2;record='callback-verified-editor.json'},
    @{name='uncertain-recovery';branch='Verified';probes=@('-FailureProbe','-FailurePoint','AfterDllCopy','-RecoveryFail');expectedCount=1;record='callback-verified-failure-afterdllcopy-recoveryfailed.json'},
    @{name='apply-reject';branch='Verified';probes=@('-ApplyRejectProbe');expectedCount=17;record='callback-verified-apply-reject.json'},
    @{name='storage';branch='Verified';probes=@('-StorageProbe');expectedCount=3;record='callback-verified-storage.json'},
    @{name='migration';branch='Verified';probes=@('-MigrationMatrix');expectedCount=3;record='callback-verified-migration-matrix.json'}
)
foreach($item in @($groups|Where-Object{$Group -ceq 'All' -or $_.name -ceq $Group})) {
    $groupRoot=Join-Path ([IO.Path]::GetFullPath($EvidenceRoot)) ('callback-'+$item.name)
    if ([IO.File]::Exists((Join-Path $groupRoot 'replay-result.json'))) {
        $history=Join-Path ([IO.Path]::GetFullPath($EvidenceRoot)) ('attempt-history/'+$item.name+'-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'-'+[guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $history))
        Copy-Item -LiteralPath $groupRoot -Destination $history -Recurse
    }
    [void][IO.Directory]::CreateDirectory($groupRoot)
    $before=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    if($before -cne $ExpectedSourceSha256){throw 'CALLBACK_SOURCE_CHANGED_BEFORE_GROUP: '+$item.name}
    $arguments=@('-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',$harness,'-EvidenceRoot',$groupRoot,'-Branch',$item.branch)+$item.probes
    $record=[ordered]@{
        group=$item.name;branch=$item.branch;status='Pending';expectedCount=$item.expectedCount
        sourceBeforeSha256=$before;sourceAfterSha256='';harnessSha256=(Get-FileHash -LiteralPath $harness -Algorithm SHA256).Hash
        executable='powershell.exe';arguments=$arguments;startedUtc=[DateTime]::UtcNow.ToString('o')
        exitCode=$null;scenarioPassCount=0;evidence=$item.record
    }
    try {
        $oldPreference=$ErrorActionPreference
        try {
            $ErrorActionPreference='Continue'
            $output=& powershell.exe @arguments 2>&1
            $record.exitCode=$LASTEXITCODE
        } finally {$ErrorActionPreference=$oldPreference}
        $output|Set-Content -LiteralPath (Join-Path $groupRoot 'suite-output.txt') -Encoding UTF8
        $record.sourceAfterSha256=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        if($record.sourceAfterSha256 -cne $before){throw 'CALLBACK_SOURCE_CHANGED_DURING_GROUP: '+$item.name}
        if($record.exitCode -ne 0){throw "CALLBACK_GROUP_FAILED: $($item.name); exit=$($record.exitCode); $($output|Out-String)"}
        $rows=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $groupRoot $item.record)))
        if($rows -isnot [array]){$rows=@($rows)}
        $passes=@($rows|Where-Object{$_.exitCode -eq 0 -and $_.sourceSha256 -ceq $before})
        $record.scenarioPassCount=$passes.Count
        if($rows.Count -ne $item.expectedCount -or $passes.Count -ne $item.expectedCount){throw 'CALLBACK_CASE_COUNT_OR_SOURCE_MISMATCH: '+$item.name}
        $record.status='Pass'
    } catch {
        $record.status='Fail'
        $record.error=$_.Exception.Message
        throw
    } finally {
        $record.completedUtc=[DateTime]::UtcNow.ToString('o')
        $record|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $groupRoot 'replay-result.json') -Encoding UTF8
    }
    "PASS: callback-$($item.name), $($record.scenarioPassCount) scenarios, source $before"
}

# Individual groups may run concurrently. The last completed group writes this
# summary only after all group receipts and original callback cases agree.
$groupReceipts=New-Object Collections.Generic.List[object]
$cases=New-Object Collections.Generic.List[object]
foreach($item in $groups) {
    $relative='callback-'+$item.name+'/replay-result.json'
    $receiptPath=Join-Path ([IO.Path]::GetFullPath($EvidenceRoot)) $relative
    if(![IO.File]::Exists($receiptPath)){return}
    $receipt=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($receiptPath))
    if($receipt.status -cne 'Pass'){return}
    if($receipt.sourceBeforeSha256 -cne $ExpectedSourceSha256 -or $receipt.sourceAfterSha256 -cne $ExpectedSourceSha256 -or $receipt.exitCode -ne 0 -or $receipt.scenarioPassCount -ne $item.expectedCount){throw 'CALLBACK_SUMMARY_RECEIPT_MISMATCH: '+$item.name}
    $rows=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path (Split-Path -Parent $receiptPath) $item.record)))
    if($rows -isnot [array]){$rows=@($rows)}
    if($rows.Count -ne $item.expectedCount){throw 'CALLBACK_SUMMARY_COUNT_MISMATCH: '+$item.name}
    foreach($row in $rows) {
        if($row.sourceSha256 -cne $ExpectedSourceSha256 -or $row.exitCode -ne 0){throw 'CALLBACK_SUMMARY_CASE_MISMATCH: '+$item.name}
        [void]$cases.Add([pscustomobject]@{branch=$row.branch;scenario=$row.scenario;status='Pass';sourceSha256=$row.sourceSha256;exitCode=$row.exitCode;evidence=('callback-'+$item.name+'/'+$item.record)})
    }
    [void]$groupReceipts.Add([pscustomobject]@{group=$item.name;status='Pass';scenarioPassCount=$receipt.scenarioPassCount;exitCode=$receipt.exitCode;sourceBeforeSha256=$receipt.sourceBeforeSha256;sourceAfterSha256=$receipt.sourceAfterSha256;receipt=$relative;executable=$receipt.executable;arguments=$receipt.arguments})
}
$current=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if($current -cne $ExpectedSourceSha256 -or $cases.Count -ne 97){throw 'CALLBACK_SUMMARY_FINAL_SOURCE_OR_COUNT_MISMATCH'}
[ordered]@{
    status='Pass';completedUtc=[DateTime]::UtcNow.ToString('o');powerShellVersion=$PSVersionTable.PSVersion.ToString()
    sourceBeforeSha256=$ExpectedSourceSha256;sourceAfterSha256=$current;independentCustomerCases='Pending'
    harnessSha256=(Get-FileHash -LiteralPath $harness -Algorithm SHA256).Hash
    replayScript='Replay-NativeUxRound2.ps1';replayScriptSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
    groupCount=$groupReceipts.Count;callbackCount=$cases.Count;groups=$groupReceipts.ToArray();callbackCases=$cases.ToArray()
    method='Existing real manager callbacks in disposable fixture installations; inert executable, controlled process states, captured launch requests and intercepted modal decisions. No live game action or candidate export.'
}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path ([IO.Path]::GetFullPath($EvidenceRoot)) 'callbacks-verification.json') -Encoding UTF8
"PASS: all $($groupReceipts.Count) callback groups and $($cases.Count) scenarios on guarded source $current"
