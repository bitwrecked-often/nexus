param([string]$EvidenceDirectory=(Join-Path $PSScriptRoot '../../qa/lane-bootstrap/workbench'))
$ErrorActionPreference='Stop'
$managerBefore=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot '../../ui/p0158.ps1') -Algorithm SHA256).Hash
$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$baseline=@((ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '../../../BASELINE_PROVENANCE.json')))).protectedBefore | ForEach-Object { [pscustomobject]@{path=$_.path;afterSha256=$_.sha256} })
$mutableReferences=@()
$protectedBefore=@($baseline | ForEach-Object {
    $hash=(Get-FileHash -LiteralPath (Join-Path $repoRoot $_.path) -Algorithm SHA256).Hash
    if($_.path -notin $mutableReferences -and $hash -cne $_.afterSha256){throw ('Frozen reference changed: '+$_.path)}
    [pscustomobject]@{path=$_.path;sha256=$hash}
})
$evidence=[IO.Path]::GetFullPath($EvidenceDirectory)
[void][IO.Directory]::CreateDirectory($evidence)
$checks=New-Object Collections.Generic.List[string]
foreach($path in @(Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object {$_.Extension -in @('.ps1','.psm1')})){
    $tokens=$null; $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($path.FullName,[ref]$tokens,[ref]$errors)
    if($errors){throw "Parser failed: $($path.Name)"}
}
$checks.Add('PowerShell 5.1 parsers')
$output=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Show-GraphicsWorkbench.ps1') -SmokeTest -ExportDirectory $evidence 2>&1
$output | Set-Content -LiteralPath (Join-Path $evidence 'workbench-output.txt') -Encoding UTF8
if($LASTEXITCODE -ne 0){throw ($output | Out-String)}
$checks.Add('Actual workbench entry: preview states, empty-name refusal, compact Standard, Chosen, weighted zero/normalization/cancel/save, remembered choices, text size, corners and contrast')
Import-Module (Join-Path $PSScriptRoot 'NativeGraphics.psm1') -Force; Import-NativeGraphics
Import-Module (Join-Path $PSScriptRoot 'Presentation.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Recipes.psm1') -Force
$receipt=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $evidence 'export.json')))
if($receipt.exports.Count -ne 41){throw 'Unexpected export inventory'}
foreach($item in $receipt.exports){
    $path=Join-Path $evidence $item.file
    if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $item.sha256){throw "Export hash mismatch: $($item.file)"}
    if([IO.Path]::GetExtension($path) -ieq '.png'){
        $image=[Drawing.Bitmap]::FromFile($path)
        try {
            if($image.Width -lt 1 -or $image.Height -lt 1){throw 'Empty image'}
            if($item.file -match '^release-(light|contrast)\.png$' -and ($image.Width -ne 1440 -or $image.Height -ne 810)){throw 'Release card dimensions changed'}
            if($item.file -match '^glyphs/(.+)-(\d+)\.png$'){
                $size=[int]$Matches[2]
                if($image.Width -ne $size -or $image.Height -ne $size -or $image.GetPixel(0,0).A -ne 0){throw 'Glyph size/transparency failed'}
                $hasInk=$false
                for($y=0;$y -lt $size -and !$hasInk;$y++){for($x=0;$x -lt $size;$x++){if($image.GetPixel($x,$y).A -gt 0){$hasInk=$true;break}}}
                if(!$hasInk){throw 'Glyph export contains no drawing'}
            }
        } finally {$image.Dispose()}
    }
}
foreach($entry in @(@('release-light.png','bitwrecked-quiet'),@('release-contrast.png','bitwrecked-contrast'))){
    $cardReceipt=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $evidence ($entry[0]+'.recipe.json'))))
    if($cardReceipt.recipeId -cne $entry[1] -or $cardReceipt.recipeSha256 -cne (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot ('recipes/'+$entry[1]+'.json')) -Algorithm SHA256).Hash -or $cardReceipt.outputSha256 -cne (Get-FileHash -LiteralPath (Join-Path $evidence $entry[0]) -Algorithm SHA256).Hash){throw 'Card recipe receipt mismatch'}
    if($cardReceipt.logoSha256 -cne (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot '../../ui/Assets/i0141.png') -Algorithm SHA256).Hash -or $cardReceipt.rendererSha256 -cne (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'Presentation.psm1') -Algorithm SHA256).Hash){throw 'Card input/renderer receipt mismatch'}
}
$checks.Add('41 exports match receipt; PNGs decode; two card recipe/input receipts match; 30 glyphs have transparent margins and drawn content')
$iconPath=Join-Path $evidence 'picture-only.ico'
$bytes=[IO.File]::ReadAllBytes($iconPath)
if([BitConverter]::ToUInt16($bytes,0) -ne 0 -or [BitConverter]::ToUInt16($bytes,2) -ne 1 -or [BitConverter]::ToUInt16($bytes,4) -ne 7){throw 'ICO header failed'}
$expected=@(16,24,32,48,64,128,256)
for($i=0;$i -lt 7;$i++){
    $entry=6+16*$i; $size=if($bytes[$entry] -eq 0){256}else{[int]$bytes[$entry]}
    if($size -ne $expected[$i]){throw 'ICO size table failed'}
    $length=[BitConverter]::ToUInt32($bytes,$entry+8); $offset=[BitConverter]::ToUInt32($bytes,$entry+12)
    if($offset+$length -gt $bytes.Length -or $bytes[$offset] -ne 137 -or $bytes[$offset+1] -ne 80){throw 'ICO frame bounds/PNG signature failed'}
}
$icon=New-Object Drawing.Icon($iconPath,32,32); $icon.Dispose()
$checks.Add('Seven-size PNG ICO validates and loads through Windows Icon API')
$cli=Join-Path $evidence 'cli'; [void][IO.Directory]::CreateDirectory($cli)
$cliOutput=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Export-Graphics.ps1') -CardStyle Light -OutputPath (Join-Path $cli 'card.png') 2>&1
if($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath (Join-Path $cli 'card.png'))){throw 'CLI release export failed'}
$cliOutput=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Export-Graphics.ps1') -IconSource (Join-Path $PSScriptRoot '../../ui/Assets/i0141.png') -OutputPath (Join-Path $cli 'picture.ico') 2>&1
if($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath (Join-Path $cli 'picture.ico'))){throw 'CLI icon export failed'}
$cliOutput=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Export-Graphics.ps1') -Glyphs -OutputPath (Join-Path $cli 'glyphs') 2>&1
if($LASTEXITCODE -ne 0 -or @(Get-ChildItem -LiteralPath (Join-Path $cli 'glyphs') -Filter '*.png').Count -ne 30){throw 'CLI glyph export failed'}
$checks.Add('CLI card, ICO and glyph entry points')
$fixture=Get-DesignRecipe -Id bitwrecked-quiet -Target Manager
$fixture.id='fixture-quiet'; $fixture.name='Recipe change fixture'
$fixture.palette.background='#EEF5F2'; $fixture.palette.accent='#007B74'
$fixture.typography.bodySize=11; $fixture.typography.titleSize=27
$fixture.geometry.contentWidth=520
$fixture.geometry.contentPadding=28
$fixture.copy.manager.title='Recipe $(literal) study'
$fixture.copy.release.highlight='TEST'
$fixture.releaseCard.canvasWidth=1280; $fixture.releaseCard.canvasHeight=720
$fixture.releaseCard.headingSize=50; $fixture.releaseCard.highlightSize=108; $fixture.releaseCard.captionSize=24
$fixturePath=Join-Path $cli 'modified-recipe.json'
[IO.File]::WriteAllText($fixturePath,($fixture | ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
$fixtureDirectory=Join-Path $evidence 'recipe-fixture'
$fixtureOutput=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Show-GraphicsWorkbench.ps1') -RecipePath $fixturePath -ExportDirectory $fixtureDirectory 2>&1
$fixtureOutput | Set-Content -LiteralPath (Join-Path $evidence 'recipe-fixture-output.txt') -Encoding UTF8
if($LASTEXITCODE -ne 0){throw ($fixtureOutput | Out-String)}
$fixtureReceipt=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $fixtureDirectory 'export.json')))
if($fixtureReceipt.recipe.id -cne 'fixture-quiet' -or $fixtureReceipt.recipe.sha256 -cne (Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash){throw 'Custom manager recipe not selected'}
$fixtureImage=[Drawing.Bitmap]::FromFile((Join-Path $fixtureDirectory 'manager-rework-standard.png'))
try{if($fixtureImage.Width -ne 576){throw 'Custom recipe manager width not rendered'}}finally{$fixtureImage.Dispose()}
$fixtureGlyph=[Drawing.Bitmap]::FromFile((Join-Path $fixtureDirectory 'glyphs/Check-32.png'))
try{
    $hasAccent=$false
    for($y=0;$y -lt 32 -and !$hasAccent;$y++){for($x=0;$x -lt 32;$x++){$pixel=$fixtureGlyph.GetPixel($x,$y); if($pixel.A -eq 255 -and $pixel.R -eq 0 -and $pixel.G -eq 123 -and $pixel.B -eq 116){$hasAccent=$true;break}}}
    if(!$hasAccent){throw 'Custom manager recipe accent not rendered'}
}finally{$fixtureGlyph.Dispose()}
$fixtureCard=Join-Path $cli 'modified-recipe-card.png'
$fixtureOutput=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Export-Graphics.ps1') -RecipePath $fixturePath -ArtworkPath (Join-Path $PSScriptRoot '../../ui/Assets/i0141.png') -OutputPath $fixtureCard 2>&1
if($LASTEXITCODE -ne 0){throw ($fixtureOutput | Out-String)}
$fixtureImage=[Drawing.Bitmap]::FromFile($fixtureCard)
try{if($fixtureImage.Width -ne 1280 -or $fixtureImage.Height -ne 720 -or $fixtureImage.GetPixel(0,0).ToArgb() -ne (ConvertTo-WorkbenchColor '#EEF5F2').ToArgb()){throw 'Custom card recipe dimensions/background not rendered'}}finally{$fixtureImage.Dispose()}
$fixtureCardReceipt=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText(($fixtureCard+'.recipe.json')))
if($fixtureCardReceipt.recipeId -cne 'fixture-quiet' -or $fixtureCardReceipt.recipeSha256 -cne (Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash -or $fixtureCardReceipt.artworkSha256 -cne $fixtureCardReceipt.logoSha256){throw 'Custom recipe/artwork receipt mismatch'}
$checks.Add('Changed recipe renders a narrower manager and teal glyphs, plus a 1280x720 custom card/background and supplied artwork through actual entry points')
$badPath=Join-Path $cli 'wrong-extension.txt'
$oldErrorPreference=$ErrorActionPreference; $ErrorActionPreference='Continue'
$badOutput=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Export-Graphics.ps1') -CardStyle Light -OutputPath $badPath 2>&1
$badExit=$LASTEXITCODE; $ErrorActionPreference=$oldErrorPreference
$badOutput | Set-Content -LiteralPath (Join-Path $evidence 'invalid-export-output.txt') -Encoding UTF8
if($badExit -eq 0 -or (Test-Path -LiteralPath $badPath) -or ($badOutput | Out-String) -notmatch 'PNG export requires'){throw 'Invalid export was not safely rejected'}
$badTheme=Join-Path $cli 'invalid-theme.json'
[IO.File]::WriteAllText($badTheme,'{"schema":"wrong"}',(New-Object Text.UTF8Encoding($false)))
$rejected=$false
try {$null=Get-WorkbenchTheme -Path $badTheme}catch{$rejected=$_.Exception.Message -match 'Unsupported graphics theme'}
if(!$rejected){throw 'Invalid theme not rejected'}
$badRecipe=Join-Path $cli 'invalid-recipe.json'
[IO.File]::WriteAllText($badRecipe,'{"schema":"wrong"}',(New-Object Text.UTF8Encoding($false)))
$badRecipeOutput=Join-Path $cli 'invalid-recipe.png'
$oldErrorPreference=$ErrorActionPreference; $ErrorActionPreference='Continue'
$badOutput=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Export-Graphics.ps1') -RecipePath $badRecipe -OutputPath $badRecipeOutput 2>&1
$badExit=$LASTEXITCODE
$unsupportedDirectory=Join-Path $evidence 'unsupported-manager'
$unsupportedOutput=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Show-GraphicsWorkbench.ps1') -RecipeId bitwrecked-contrast -ExportDirectory $unsupportedDirectory 2>&1
$unsupportedExit=$LASTEXITCODE; $ErrorActionPreference=$oldErrorPreference
if($badExit -eq 0 -or (Test-Path -LiteralPath $badRecipeOutput)){throw 'Invalid recipe accepted by CLI'}
if($unsupportedExit -eq 0 -or (Test-Path -LiteralPath $unsupportedDirectory) -or ($unsupportedOutput | Out-String) -notmatch 'does not support Manager'){throw 'Release-only recipe accepted by manager'}
$unsupportedOutput | Set-Content -LiteralPath (Join-Path $evidence 'unsupported-manager-output.txt') -Encoding UTF8
$checks.Add('Invalid CLI extension/theme/recipe and unsupported manager recipe rejected before output')
$button=New-NativeOutlineButton -Text 'Apply Settings'; $hostForm=New-Object Windows.Forms.Form
$hostForm.StartPosition='Manual'; $hostForm.Location=New-Object Drawing.Point(-32000,-32000); $hostForm.Controls.Add($button); $hostForm.AcceptButton=$button
$script:clickCount=0; $button.Add_Click({$script:clickCount++})
try {
    $hostForm.Show(); [Windows.Forms.Application]::DoEvents(); [void]$button.Focus()
    $flags=[Reflection.BindingFlags]'Instance,NonPublic'
    $spaceEvent=(New-Object Windows.Forms.KeyEventArgs([Windows.Forms.Keys]::Space)).PSObject.BaseObject
    [void]$button.GetType().GetMethod('OnKeyDown',$flags).Invoke($button,[object[]]@($spaceEvent))
    [void]$button.GetType().GetMethod('OnKeyUp',$flags).Invoke($button,[object[]]@($spaceEvent))
    if($script:clickCount -ne 1){throw 'Space activation failed'}
    [void]$button.GetType().GetMethod('ProcessDialogKey',$flags).Invoke($button,[object[]]@([Windows.Forms.Keys]::Enter))
    if($script:clickCount -ne 2){throw 'Enter activation failed'}
    $button.Enabled=$false; $button.PerformClick(); if($script:clickCount -ne 2){throw 'Disabled button activated'}
    if($button.AccessibilityObject.Role -ne [Windows.Forms.AccessibleRole]::PushButton -or $button.AccessibilityObject.Name -cne 'Apply Settings'){throw 'Button accessibility identity failed'}
} finally {$hostForm.Dispose()}
$badge=New-NativeBadge -Text 'Initial state'
try {$badge.Text='Updated state'; if($badge.AccessibilityObject.Name -cne 'Updated state'){throw 'Badge accessible state is stale'}}finally{$badge.Dispose()}
$checks.Add('Native Space/Enter activation, disabled refusal, PushButton accessibility and dynamic badge state')
$protected=@($protectedBefore | ForEach-Object {
    $hash=(Get-FileHash -LiteralPath (Join-Path $repoRoot $_.path) -Algorithm SHA256).Hash
    [pscustomobject]@{path=$_.path;beforeSha256=$_.sha256;afterSha256=$hash;unchanged=($_.sha256 -ceq $hash)}
})
if(@($protected | Where-Object {!$_.unchanged}).Count){throw 'Protected release bytes changed'}
$manager=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot '../../ui/p0158.ps1') -Algorithm SHA256).Hash
if($manager -cne $managerBefore){throw 'Production manager changed during workbench verification'}
$protected | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidence 'immutable-after.json') -Encoding UTF8
$checks.Add('Production manager and all protected baseline inputs unchanged during verification')
[ordered]@{date=[TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow,[TimeZoneInfo]::FindSystemTimeZoneById('Pacific Standard Time')).ToString('yyyy-MM-dd');recordedUtc=[DateTime]::UtcNow.ToString('o');status='Pass';powerShellVersion=$PSVersionTable.PSVersion.ToString();checks=$checks.ToArray();count=$checks.Count;toolSources=$receipt.sources;exportReceipt='export.json';recipeFixture='recipe-fixture/export.json';productionManagerSha256=$manager;protectedFiles='immutable-after.json';externalDependencies=@();method='Actual PS5.1 recipe-driven workbench and CLI consumers, native key handler probes and decoded output validation; isolated offscreen forms, no game actions.';limitations=@('Keyboard event handlers are probed; physical operator/Narrator checks remain pending.','Contrast custom rendering path is simulated; actual OS theme and monitor DPI require operator review.','This workbench probe does not certify candidate packaging, gameplay or release readiness.','Changed geometry/fonts/copy require regenerated preview text-fit review; default release cards are 1440x810.')} | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $evidence 'verification.json') -Encoding UTF8
"PASS: $($checks.Count) native graphics workflow groups; 41 exports, custom recipe rendering, keyboard/accessibility probes, invalid-input refusal and protected bytes."
