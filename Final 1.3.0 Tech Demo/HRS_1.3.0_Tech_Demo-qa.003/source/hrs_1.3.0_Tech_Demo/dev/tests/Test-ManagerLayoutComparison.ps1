# Same-host, fixed-viewport DEV comparison; not actual OS-scale/accessibility QA.
param([Parameter(Mandatory=$true)][string]$EvidenceRoot)
$ErrorActionPreference='Stop'
$newLane=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$repoRoot=Split-Path -Parent $newLane
$evidence=[IO.Path]::GetFullPath($EvidenceRoot);[void][IO.Directory]::CreateDirectory($evidence)
$records=New-Object Collections.Generic.List[object]
foreach($lane in @(@{name='before-1.2.7';root=(Join-Path $repoRoot 'hrs_1.2.7')},@{name='after-1.3.0';root=$newLane})) {
    $dev=Join-Path $lane.root 'dev';$source=Join-Path $dev 'ui/p0158.ps1';$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    $root=Join-Path ([IO.Path]::GetTempPath()) ('hrs-manager-layout-'+[guid]::NewGuid().ToString('N'))
    $fixture=Join-Path $root 'game';$stage=Join-Path $root 'stage'
    foreach($path in @((Join-Path $stage 'dev/ui'),(Join-Path $stage 'dev/src/launcher'),(Join-Path $stage 'dev/verified/main'),(Join-Path $fixture '7DaysToDie_Data/Managed'))) {[void][IO.Directory]::CreateDirectory($path)}
    Copy-Item (Join-Path $dev 'src/launcher/*.psm1') (Join-Path $stage 'dev/src/launcher');Copy-Item (Join-Path $dev 'verified/main/*') (Join-Path $stage 'dev/verified/main');Copy-Item -LiteralPath (Join-Path $dev 'ui/logo.ico') -Destination (Join-Path $stage 'dev/ui/logo.ico')
    [IO.File]::WriteAllText((Join-Path $fixture '7DaysToDie.exe'),'inert fixture, never executed');[IO.File]::WriteAllText((Join-Path $fixture '7DaysToDie_Data/Managed/Assembly-CSharp.dll'),'existence fixture only')
    $text=[IO.File]::ReadAllText($source).Replace('$useDevCandidate = $true','$useDevCandidate = $false')
    $tail='(?s)if \(\$SmokeTest\) \{\r?\n    \$form\.Show\(\).*?\r?\n\}\r?\n\[void\]\$form\.ShowDialog\(\)\s*$'
    if([regex]::Matches($text,$tail).Count -ne 1){throw 'Layout driver anchor changed'}
    $driver=@'
function Get-HrsProcessState { [pscustomobject]@{Game='Closed';Steam='Closed';Reason='ISOLATED_FIXTURE'} }
try {
    $form.Show();[Windows.Forms.Application]::DoEvents()
    if($gameRoot -cne $expectedRoot){throw 'Fixture root mismatch'}
    $gameNameBox.Text='Layout comparison';$randomRadio.Checked=$true;$biomeProtectCheck.Checked=$true
    $script:managerUserResized=$true;$form.Size=New-Object Drawing.Size(712,720)
    $measurements=New-Object Collections.Generic.List[object]
    foreach($method in @('Any','Chosen','Weighted')) {
        Set-HrsSelectionMethod $method; $chosenCombo.SelectedItem='Wasteland';Update-HrsBiomePreview;[Windows.Forms.Application]::DoEvents()
        $form.ActiveControl=$null;$form.AutoScrollPosition=[Drawing.Point]::Empty;[Windows.Forms.Application]::DoEvents()
        [void]$measurements.Add([pscustomobject]@{method=$method;outerWidth=$form.Width;outerHeight=$form.Height;contentHeight=$script:managerFrame.Height;biomeHeight=$biomeGroup.Height;chosenVisible=$chosenCombo.Visible;editorVisible=$editWeights.Visible;workingAreaWidth=([Windows.Forms.Screen]::FromControl($form).WorkingArea.Width);workingAreaHeight=([Windows.Forms.Screen]::FromControl($form).WorkingArea.Height)})
        $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height);try{$form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bitmap.Save((Join-Path $evidenceRoot ($label+'-'+$method+'.png')),[Drawing.Imaging.ImageFormat]::Png)}finally{$bitmap.Dispose()}
    }
    $measurements.ToArray() | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidenceRoot ($label+'.json')) -Encoding UTF8
}finally{$form.Dispose()}
'@
    $driver='$evidenceRoot='+"'"+$evidence.Replace("'","''")+"'`r`n"+'$expectedRoot='+"'"+$fixture.Replace("'","''")+"'`r`n"+'$label='+"'"+$lane.name+"'`r`n"+$driver
    $text=[regex]::Replace($text,$tail,[Text.RegularExpressions.MatchEvaluator]{param($m)$driver});$staged=Join-Path $stage 'dev/ui/p0158.ps1';[IO.File]::WriteAllText($staged,$text,(New-Object Text.UTF8Encoding($false)))
    $previousPreference=$ErrorActionPreference;try{$ErrorActionPreference='Continue';$output=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $staged -SmokeTest -GameRootOverride $fixture 2>&1;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$previousPreference}
    $output | Set-Content -LiteralPath (Join-Path $evidence ($lane.name+'-output.txt')) -Encoding UTF8
    if($code -ne 0){throw "Layout comparison failed: $($output|Out-String)"}
    if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $sourceHash){throw 'Source changed during layout comparison'}
    $parsedRows=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $evidence ($lane.name+'.json'))))
    # Copy scalar fields: Windows PowerShell can decorate a parsed array with
    # ETS properties that otherwise serialize as a value/Count wrapper.
    $rows=@($parsedRows | ForEach-Object { [pscustomobject]@{method=[string]$_.method;outerWidth=[int]$_.outerWidth;outerHeight=[int]$_.outerHeight;contentHeight=[int]$_.contentHeight;biomeHeight=[int]$_.biomeHeight;chosenVisible=[bool]$_.chosenVisible;editorVisible=[bool]$_.editorVisible;workingAreaWidth=[int]$_.workingAreaWidth;workingAreaHeight=[int]$_.workingAreaHeight} })
    foreach($row in $rows){if($row.outerWidth -ne 712 -or $row.outerHeight -ne 720){throw 'Comparison outer viewport changed'}}
    [void]$records.Add([pscustomobject]@{lane=$lane.name;sourceSha256=$sourceHash;measurements=[object[]]$rows})
}
foreach($method in @('Any','Chosen','Weighted')) {
    $beforeMatches=@($records[0].measurements|Where-Object{$_.method -ceq $method});$afterMatches=@($records[1].measurements|Where-Object{$_.method -ceq $method})
    if($beforeMatches.Count -ne 1 -or $afterMatches.Count -ne 1){throw 'Comparison method not unique'}
    $before=$beforeMatches[0];$after=$afterMatches[0]
    if($after.contentHeight -ge $before.contentHeight){throw "No measured reduction for $method"}
}
[ordered]@{schema='hrs-manager-layout-comparison/v1';status='Pass';completedUtc=[DateTime]::UtcNow.ToString('o');scope='Same host and fixed 712x720 outer viewport, disposable no-policy fixture, native DrawToBitmap. Does not qualify other actual OS scales/accessibility/newcomer/gameplay.';harnessSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash;records=$records.ToArray()} | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $evidence 'verification.json') -Encoding UTF8
'PASS same-host fixed-viewport layout comparison'
