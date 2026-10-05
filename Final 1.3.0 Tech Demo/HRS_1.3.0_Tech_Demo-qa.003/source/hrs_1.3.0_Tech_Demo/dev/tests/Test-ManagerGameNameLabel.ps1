# Scoped owner-requested label change: prove the exact delta against sealed qa.002.
# Prior behavioral receipts stay tied to their original manager; this does not rerun them.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$BaselineArchivePath,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [Parameter(Mandatory=$true)][string]$NativeEventLoopEvidenceRoot
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
if($PSVersionTable.PSVersion.Major -ne 5){throw 'Use Windows PowerShell 5.1.'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$devRoot=Split-Path -Parent $PSScriptRoot
$repoRoot=[IO.Path]::GetFullPath((Join-Path $devRoot '../..'))
$graphics=Join-Path $devRoot 'tools/NativeGraphics'
$source=Join-Path $devRoot 'ui/p0158.ps1'
$recipePath=Join-Path $graphics 'recipes/bitwrecked-quiet.json'
$recipesModule=Join-Path $graphics 'Recipes.psm1'
$archive=[IO.Path]::GetFullPath($BaselineArchivePath)
$evidence=[IO.Path]::GetFullPath($EvidenceRoot)
if([IO.Directory]::Exists($evidence)){throw 'Use a new evidence directory.'}
[void][IO.Directory]::CreateDirectory($evidence)
$root=Join-Path ([IO.Path]::GetTempPath()) ('hrs130-game-name-label-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($root)
$encoding=New-Object Text.UTF8Encoding($false)
$archivePin='48AD02DF397917C95E7BD27422C030910860824F9B11CE152258DA47FB68DE45'
$managerPin='5C522439354FEF0E6C370D5C92C99DE74D5453BD2B8F34B432A5394EDD18073D'
$recipePin='4564D45D2D2DB003F2BA668AB0EE72B61E75D7BF9B22A0B27C44FFE8F728C4C2'
$checks=New-Object Collections.Generic.List[string]
function Assert-Label([bool]$Condition,[string]$Name){if(!$Condition){throw "Label-only proof failed: $Name"};$checks.Add($Name)}
function Replace-Once([string]$Text,[string]$Before,[string]$After){
    if($Text.Split(@($Before),[StringSplitOptions]::None).Length -ne 2){throw 'Transformation anchor is not unique.'}
    return $Text.Replace($Before,$After)
}
Assert-Label ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ceq $archivePin) 'sealed-baseline-archive-pin'
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
try {
    foreach($member in @(
        @('source/hrs_1.3.0_Tech_Demo/dev/ui/p0158.ps1','baseline-manager.ps1'),
        @('source/hrs_1.3.0_Tech_Demo/dev/tools/NativeGraphics/recipes/bitwrecked-quiet.json','baseline-recipe.json'),
        @('source/hrs_1.3.0_Tech_Demo/dev/tools/NativeGraphics/Recipes.psm1','baseline-Recipes.psm1'),
        @('source/hrs_1.3.0_Tech_Demo/dev/tools/NativeGraphics/NativeControls.cs','baseline-NativeControls.cs')
    )) {
        $matches=@($zip.Entries | Where-Object {$_.FullName.Replace('\','/') -ceq $member[0]})
        if($matches.Count -ne 1){throw ('Baseline member is not unique: '+$member[0])}
        $stream=$matches[0].Open();$target=[IO.File]::Create((Join-Path $root $member[1]))
        try{$stream.CopyTo($target)}finally{$target.Dispose();$stream.Dispose()}
    }
} finally {$zip.Dispose()}
$baselineManager=Join-Path $root 'baseline-manager.ps1'
$baselineRecipe=Join-Path $root 'baseline-recipe.json'
$baselineRecipes=Join-Path $root 'baseline-Recipes.psm1'
Assert-Label ((Get-FileHash $baselineManager -Algorithm SHA256).Hash -ceq $managerPin) 'sealed-baseline-manager-pin'
Assert-Label ((Get-FileHash $baselineRecipe -Algorithm SHA256).Hash -ceq $recipePin) 'sealed-baseline-recipe-pin'
Assert-Label ((Get-FileHash (Join-Path $root 'baseline-NativeControls.cs') -Algorithm SHA256).Hash -ceq (Get-FileHash (Join-Path $graphics 'NativeControls.cs') -Algorithm SHA256).Hash) 'native-controls-unchanged'
$baselineRecipeText=[IO.File]::ReadAllText($baselineRecipe)
$newline=[regex]::Match($baselineRecipeText,'\r\n|\n|\r').Value
$recipeBefore='      "gameNameHelp": "Use the save''s exact Game Name, not the world name.",'
$recipeAfter='      "gameNameLabel": "Game Name",'+$newline+$recipeBefore
$expectedRecipe=Replace-Once $baselineRecipeText $recipeBefore $recipeAfter
Assert-Label ($expectedRecipe -ceq [IO.File]::ReadAllText($recipePath)) 'recipe-exact-one-field-addition'
$recipe=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($recipePath))
$withoutLabel=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($recipePath))
$withoutLabel.copy.manager.PSObject.Properties.Remove('gameNameLabel')
$oldRecipe=ConvertFrom-Json -InputObject $baselineRecipeText
Assert-Label (($withoutLabel | ConvertTo-Json -Depth 16) -ceq ($oldRecipe | ConvertTo-Json -Depth 16)) 'recipe-structural-diff-only-gameNameLabel'
Assert-Label ($recipe.copy.manager.gameNameLabel -ceq 'Game Name') 'recipe-exact-owner-label'
$moduleBefore=[IO.File]::ReadAllText($baselineRecipes)
$moduleNewline=[regex]::Match($moduleBefore,'\r\n|\n|\r').Value
$moduleExpected=Replace-Once $moduleBefore '        Assert-RecipeObject $Recipe.copy.manager ''copy.manager'' $managerCopy' '        Assert-RecipeObject $Recipe.copy.manager ''copy.manager'' $managerCopy @(''gameNameLabel'')'
$validationAnchor='        foreach ($field in $managerCopy) { Assert-RecipeText $Recipe.copy.manager.$field "copy.manager.$field" 240 }'
$validationAfter=$validationAnchor+$moduleNewline+'        if (@($Recipe.copy.manager.PSObject.Properties.Name) -ccontains ''gameNameLabel'') {'+$moduleNewline+'            Assert-RecipeText $Recipe.copy.manager.gameNameLabel ''copy.manager.gameNameLabel'' 80'+$moduleNewline+'        }'
$moduleExpected=Replace-Once $moduleExpected $validationAnchor $validationAfter
Assert-Label ($moduleExpected -ceq [IO.File]::ReadAllText($recipesModule)) 'recipe-tooling-exact-optional-text-validation'
Import-Module $recipesModule -Force
$null=Get-DesignRecipe -Path $recipePath -Target Manager
$null=Get-DesignRecipe -Path $baselineRecipe -Target Manager
Assert-Label $true 'new-and-prior-no-label-recipes-accepted'
foreach($bad in @(37,'',"Bad`nlabel",('x'*81))) {
    $invalid=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($recipePath))
    $invalid.copy.manager.gameNameLabel=$bad
    $rejected=$false
    $invalidPath=Join-Path $root 'invalid-label.json'
    [IO.File]::WriteAllText($invalidPath,($invalid | ConvertTo-Json -Depth 16),$encoding)
    try{$null=Get-DesignRecipe -Path $invalidPath -Target Manager}catch{$rejected=$_.Exception.Message -match 'copy.manager.gameNameLabel must be short plain text'}
    Assert-Label $rejected ('invalid-optional-label-rejected-'+$checks.Count)
}
$labelBefore='    $gameLabel.Text = ''Game Name for your save'''
$labelAfter='    $gameLabel.Text = if (@($recipe.copy.manager.PSObject.Properties.Name) -ccontains ''gameNameLabel'') { $recipe.copy.manager.gameNameLabel } else { ''Game Name'' }'
$baselineText=[IO.File]::ReadAllText($baselineManager)
$expectedManager=Join-Path $root 'expected-manager.ps1'
[IO.File]::WriteAllText($expectedManager,(Replace-Once $baselineText $labelBefore $labelAfter),$encoding)
$sync=& (Join-Path $graphics 'Sync-ManagerDesign.ps1') -ManagerPath $expectedManager -RecipePath $recipePath
$sourceHash=(Get-FileHash $source -Algorithm SHA256).Hash
$expectedHash=(Get-FileHash $expectedManager -Algorithm SHA256).Hash
Assert-Label ($expectedHash -ceq $sourceHash) 'manager-byte-equality-after-declared-label-and-derived-embedding'
$embedding=& (Join-Path $graphics 'Sync-ManagerDesign.ps1') -Check
Assert-Label ($embedding.Status -ceq 'Current' -and $embedding.Embedded -and !$embedding.Changed) 'canonical-embedding-current'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors)
Assert-Label (!$errors) 'manager-parses-on-Windows-PowerShell-5.1'
$layout=$ast.Find({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Initialize-HrsBiomeLayout'},$true)
$labelAssignment=$layout.Find({param($node)$node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$gameLabel.Text'},$true)
$recipe=$oldRecipe;$gameLabel=[pscustomobject]@{Text='before'}
& ([scriptblock]::Create($labelAssignment.Extent.Text))
Assert-Label ($gameLabel.Text -ceq 'Game Name') 'old-no-label-recipe-falls-back-to-Game-Name'
$recipe=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($recipePath));$gameLabel.Text='before'
& ([scriptblock]::Create($labelAssignment.Extent.Text))
Assert-Label ($gameLabel.Text -ceq 'Game Name') 'current-recipe-binds-exact-visible-label'
foreach($diff in @(@($baselineManager,$source,'manager.diff'),@($baselineRecipe,$recipePath,'recipe.diff'),@($baselineRecipes,$recipesModule,'recipe-tooling.diff'))) {
    $savedPreference=$ErrorActionPreference
    try{$ErrorActionPreference='Continue';$diffText=& git -c core.autocrlf=false diff --no-index --no-ext-diff -- $diff[0] $diff[1] 2>&1;$diffCode=$LASTEXITCODE}
    finally{$ErrorActionPreference=$savedPreference}
    if($diffCode -ne 1){throw 'Expected a bounded nonempty diff.'}
    $diffText | Set-Content -LiteralPath (Join-Path $evidence $diff[2]) -Encoding UTF8
}
# Use the independently completed current native event-loop receipt; no extra host run.
$nativePath=Join-Path ([IO.Path]::GetFullPath($NativeEventLoopEvidenceRoot)) 'verification.json'
$native=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($nativePath))
Assert-Label ($native.status -ceq 'Pass' -and $native.sourceSha256 -ceq $sourceHash) 'current-native-loop-receipt-binds-new-manager'
$nativeEvents=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $NativeEventLoopEvidenceRoot 'native-events.json')))
$nativeErrors=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $NativeEventLoopEvidenceRoot 'native-errors.json')))
Assert-Label (@($nativeErrors | Where-Object {$null -ne $_}).Count -eq 0 -and $nativeEvents -ccontains 'normal close' -and $nativeEvents -ccontains 'multicolor logo rendered') 'current-native-loop-clean-close-and-logo'
Assert-Label ([IO.File]::Exists((Join-Path $NativeEventLoopEvidenceRoot 'normal-event-loop.png'))) 'current-native-manager-capture-present'
Copy-Item -LiteralPath $nativePath -Destination (Join-Path $evidence 'native-loop-receipt.json')
Assert-Label ((Get-FileHash $source -Algorithm SHA256).Hash -ceq $sourceHash) 'source-stable-during-checks'
Assert-Label ((Get-FileHash $archive -Algorithm SHA256).Hash -ceq $archivePin) 'sealed-archive-still-unchanged'
$checks.ToArray() | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $evidence 'assertions.json') -Encoding UTF8
$receipt=[ordered]@{
    schema='hrs-manager-label-only-carry/v1';status='Pass';completedUtc=[DateTime]::UtcNow.ToString('o');baselineCandidateId='1.3.0-qa.002';baselineArchiveSha256=$archivePin;
    baselineManagerSha256=$managerPin;sourceSha256=$sourceHash;expectedTransformedManagerSha256=$expectedHash;
    baselineRecipeSha256=$recipePin;recipeSha256=(Get-FileHash $recipePath -Algorithm SHA256).Hash;
    baselineRecipesModuleSha256=(Get-FileHash $baselineRecipes -Algorithm SHA256).Hash;recipesModuleSha256=(Get-FileHash $recipesModule -Algorithm SHA256).Hash;
    controlsSha256=(Get-FileHash (Join-Path $graphics 'NativeControls.cs') -Algorithm SHA256).Hash;
    managerLabelOnlyEquality=$true;recipeLabelOnlyEquality=$true;recipeToolingLabelOnlyEquality=$true;embeddingCurrent=$true;nativeLabelPass=$true;
    recipeStructuralDiff=@([ordered]@{operation='add';path='copy.manager.gameNameLabel';value='Game Name'});
    managerTransformations=@([ordered]@{before=$labelBefore;after=$labelAfter},[ordered]@{operation='Sync-ManagerDesign.ps1';scope='Derived recipe JSON and recipe SHA in existing generated region; NativeControls.cs unchanged'});
    supportingToolingTransformations=@('Allow optional gameNameLabel; preserve required manager copy fields','Validate supplied label as short plain text, maximum 80; reject non-string, empty, control-bearing and oversized labels');
    preservedSemantics='All manager bytes outside declared label assignment and derived recipe embedding equal sealed baseline. Help, confirmation, field control identity and behavior are preserved.';
    carriedBaselineEvidence=@('dev/qa/ux-return-20261005/focused-r008/verification.json','dev/qa/ux-return-20261005/manager-review-r004/verification.json','dev/qa/ux-return-20261005/callbacks-final-20261005/callbacks-verification.json');
    carriedEvidenceScope='Prior 86 focused, 26 review and 97 callback DEV results retain original 5C522 manager hash; carried through exact label-only transformation, not freshly rerun or relabeled.';
    nativeReceipt='native-loop-receipt.json';nativeReceiptSha256=(Get-FileHash $nativePath -Algorithm SHA256).Hash;nativeEvidenceRoot='dev/qa/native-event-loop-20261005/run-006';assertionCount=$checks.Count;harnessSha256=(Get-FileHash $PSCommandPath -Algorithm SHA256).Hash;
    independentQa='Pending';scope='Requested visible label only; current native display, recipe compatibility/validation, embedding and exact delta. No runtime, gameplay, OS-scale matrix or release approval.'
}
$receipt | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $evidence 'verification.json') -Encoding UTF8
'PASS: exact label-only sealed-baseline proof; '+$checks.Count+' scoped checks.'
