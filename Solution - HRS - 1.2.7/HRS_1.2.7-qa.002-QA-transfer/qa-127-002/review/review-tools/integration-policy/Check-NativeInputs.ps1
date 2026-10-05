[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$LaneRoot,
      [Parameter(Mandatory=$true)][ValidateSet('Embedding','Parser')][string]$Check,
      [Parameter(Mandatory=$true)][string]$ReportPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
if($PSVersionTable.PSEdition -cne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5){throw 'Native Windows PowerShell5.1 required.'}
$lane=[IO.Path]::GetFullPath($LaneRoot)
$utf8=New-Object Text.UTF8Encoding($false)
if($Check -ceq 'Embedding'){
    $result=& (Join-Path $lane 'dev/tools/NativeGraphics/Sync-ManagerDesign.ps1') -Check
    if($result.Status -cne 'Current' -or !$result.Embedded -or $result.Changed){throw 'Manager design is not current without mutation.'}
    $record=[pscustomobject][ordered]@{schema='hrs-native-embedding-check/v1';status='Pass';powerShellVersion=$PSVersionTable.PSVersion.ToString();result=$result}
}else{
    $relativeFiles=@('dev/ui/p0158.ps1','dev/tests/Test-RuntimeReviewRepairs.ps1','dev/tests/Test-ManagerReviewRepairs.ps1')
    $repair=Join-Path $lane 'dev/qa/review-repairs-20261004'
    $relativeFiles+=@(Get-ChildItem -LiteralPath $repair -File -Filter '*.ps1'|ForEach-Object{$_.FullName.Substring($lane.Length+1).Replace('\','/')})
    $relativeFiles+=@(Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter '*.ps1'|ForEach-Object{$_.FullName.Substring($lane.Length+1).Replace('\','/')})
    $records=New-Object Collections.Generic.List[object]
    foreach($relative in @($relativeFiles|Sort-Object -Unique)){
        $path=Join-Path $lane $relative
        $before=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        $tokens=$null;$errors=$null
        $null=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
        $after=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        [void]$records.Add([pscustomobject][ordered]@{path=$relative;sha256=$after;errorCount=@($errors).Count;unchanged=($before -ceq $after);errors=@($errors|ForEach-Object{$_.Message})})
    }
    $record=[pscustomobject][ordered]@{schema='hrs-native-repair-parser-check/v1';status='Pass';powerShellVersion=$PSVersionTable.PSVersion.ToString();fileCount=$records.Count;checks=$records.ToArray()}
    if(@($records.ToArray()|Where-Object{$_.errorCount -gt 0 -or !$_.unchanged}).Count){$record.status='Fail'}
}
[IO.File]::WriteAllText([IO.Path]::GetFullPath($ReportPath),($record|ConvertTo-Json -Depth 8),$utf8)
$record|ConvertTo-Json -Depth 8
if($record.status -cne 'Pass'){throw 'Native parser check failed.'}
