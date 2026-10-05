[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PublicContentRoot)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..')).TrimEnd('\','/')
$lane=Join-Path $repo 'hrs_1.2.7'
$output=[IO.Path]::GetFullPath($PublicContentRoot).TrimEnd('\','/')
$allowed=[IO.Path]::GetFullPath((Join-Path $lane 'dev/tmp')).TrimEnd('\','/')+'\'
if(!$output.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)){
    throw 'Prepared content must remain beneath the DEV tmp directory.'
}
$manifestPath=Join-Path $output 'evidence/PUBLIC-CONTENT-MANIFEST.json'
$projectionPath=Join-Path $output 'evidence/PUBLIC-PROJECTION.json'
$manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
$projection=Get-Content -LiteralPath $projectionPath -Raw|ConvertFrom-Json
if($manifest.candidateId -cne '1.2.7-qa.003' -or $projection.candidateId -cne '1.2.7-qa.003'){
    throw 'Only the unexported prepared candidate-003 content may be extended.'
}
# Load the exact copy/projection helpers without invoking the fresh-output entry.
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Prepare-PublicContent.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Preparation helper does not parse.'}
foreach($name in @('Get-ContentHash','Resolve-ContentPath','Get-PathPattern','Copy-PublicFile')){
    $fn=@($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    if($fn.Count -ne 1){throw 'Required projection helper is not unique.'}
    . ([scriptblock]::Create($fn[0].Extent.Text))
}
foreach($entry in $manifest.files){
    $path=[IO.Path]::GetFullPath((Join-Path $output $entry.path))
    if(!$path.StartsWith($output+'\',[StringComparison]::OrdinalIgnoreCase) -or
        (Get-ContentHash $path) -cne $entry.sha256){throw 'Original prepared subset changed: '+$entry.path}
}
$beforeProjection=Join-Path $PSScriptRoot 'public-projection.before-extension.json'
$beforeManifest=Join-Path $PSScriptRoot 'public-content-manifest.before-extension.json'
foreach($path in @($beforeProjection,$beforeManifest)){if(Test-Path -LiteralPath $path){throw 'Preserve previous extension record.'}}
[IO.File]::Copy($projectionPath,$beforeProjection,$false)
[IO.File]::Copy($manifestPath,$beforeManifest,$false)
$utf8=New-Object Text.UTF8Encoding($false)
$copies=New-Object 'Collections.Generic.List[object]'
foreach($entry in $projection.copies){[void]$copies.Add($entry)}
$pathRules=@(
    [pscustomobject]@{pattern=(Get-PathPattern $repo);token='<DEV_REPO>'},
    [pscustomobject]@{pattern=(Get-PathPattern ([IO.Path]::GetTempPath()));token='<DEV_TEMP>'},
    [pscustomobject]@{pattern=(Get-PathPattern ([Environment]::GetFolderPath('UserProfile')));token='<DEV_HOME>'},
    [pscustomobject]@{pattern='(?i)[A-Z]:[\\/]+Users[\\/]+[^\\/\s"''<>]+';token='<DEV_HOME>'}
)
foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $repo 'qa_cycle') -File -Force)){
    if($file.Extension -notin @('.ps1','.psm1','.md')){continue}
    Copy-PublicFile $file.FullName ('source/qa_cycle/'+$file.Name) ('qa_cycle/'+$file.Name) 'Current generic packaging/QA tool source'
}
foreach($name in @('Prepare-PublicContent.ps1','Verify-PreparedSource.ps1','Extend-PublicContent.ps1','Verify-PublicCandidate.ps1')){
    Copy-PublicFile (Join-Path $PSScriptRoot $name) ('source/support/unified-public-20261004/'+$name) ('hrs_1.2.7/dev/qa/unified-public-20261004/'+$name) 'Current public-content preparation/verification source; original DEV inputs remain external'
}
$newEvidence=@(
    @('hrs_1.2.7/dev/qa/unified-public-package-20261004/tool-verification.json','evidence/qa003/tools/tool-verification.json'),
    @('hrs_1.2.7/dev/qa/unified-public-package-20261004/legacy-tool-verification.json','evidence/qa003/tools/legacy-tool-verification.json'),
    @('hrs_1.2.7/dev/qa/unified-public-package-20261004/TOOLS.md','evidence/qa003/tools/TOOLS.md')
)
foreach($pair in $newEvidence){
    Copy-PublicFile (Join-Path $repo $pair[0]) $pair[1] $pair[0] 'Current candidate-003 generic-tool verification; bounded DEV fixture evidence' -ProjectText -StripRepositoryLinks:([IO.Path]::GetExtension($pair[0]) -ieq '.md')
}
$sourceEvidenceRoot=Join-Path $PSScriptRoot 'prepared-source-r002'
foreach($file in @(Get-ChildItem -LiteralPath $sourceEvidenceRoot -Recurse -File -Force)){
    $relative=$file.FullName.Substring($sourceEvidenceRoot.Length+1).Replace('\','/')
    if($relative -match '(^|/)(fixture-bin|fixture-obj|bin|obj)(/|$)' -or $file.Extension -notin @('.json','.txt')){continue}
    Copy-PublicFile $file.FullName ('evidence/qa003/prepared-source/'+$relative) ('hrs_1.2.7/dev/qa/unified-public-20261004/prepared-source-r002/'+$relative) 'Current supplied-source-layout verification; bounded DEV fixture evidence' -ProjectText
}
$privacyFiles=@()
foreach($file in @(Get-ChildItem -LiteralPath $output -Recurse -File -Force)){
    if($file.Extension -notin @('.json','.md','.txt','.ps1','.psm1','.cs','.csproj','.xml','.bat','.cmd')){continue}
    if([IO.File]::ReadAllText($file.FullName) -match '(?i)[A-Z]:[\\/]+Users[\\/]+'){
        $privacyFiles+=$file.FullName.Substring($output.Length+1).Replace('\','/')
    }
}
if($privacyFiles.Count){throw 'Private workstation path survived extension: '+($privacyFiles -join ', ')}
$projection.copies=$copies.ToArray()
$projection.privatePathRedactions=(@($copies|Measure-Object privatePathRedactions -Sum))[0].Sum
$projection|Add-Member -NotePropertyName extendedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString('o'))
$projection|Add-Member -NotePropertyName extensionScope -NotePropertyValue 'Complete generic qa_cycle source, preparation/verifier source and fresh tool/source-layout DEV evidence.'
[IO.File]::WriteAllText($projectionPath,($projection|ConvertTo-Json -Depth 8)+"`r`n",$utf8)
# Root entry files were added by the release packager. Record them unchanged as
# part of the complete current content subset; never replace their bytes here.
$files=@(Get-ChildItem -LiteralPath $output -Recurse -File -Force|Where-Object{$_.FullName -cne $manifestPath}|Sort-Object FullName|ForEach-Object{
    [pscustomobject]@{path=$_.FullName.Substring($output.Length+1).Replace('\','/');bytes=$_.Length;sha256=(Get-ContentHash $_.FullName)}
})
$manifest.files=$files
$manifest|Add-Member -NotePropertyName extendedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString('o'))
[IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 6)+"`r`n",$utf8)
[pscustomobject]@{status='Pass';candidateId='1.2.7-qa.003';files=$files.Count+1;copiedInputs=$copies.Count;privatePathRedactions=$projection.privatePathRedactions;privateWorkstationPaths=0;projectionSha256=(Get-ContentHash $projectionPath);manifestSha256=(Get-ContentHash $manifestPath)}
