param([string]$ExportDirectory='',[switch]$SmokeTest,[string]$RecipeId='bitwrecked-quiet',[string]$RecipePath='')
$ErrorActionPreference='Stop'
if([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA'){throw 'Run this workbench with Windows PowerShell -STA.'}
Import-Module (Join-Path $PSScriptRoot 'NativeGraphics.psm1') -Force
Import-NativeGraphics
Import-Module (Join-Path $PSScriptRoot 'Presentation.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Recipes.psm1') -Force
$recipe=Get-DesignRecipe -Id $RecipeId -Path $RecipePath -Target Manager
$recipeSource=if($RecipePath){[IO.Path]::GetFullPath($RecipePath)}else{Join-Path $PSScriptRoot ("recipes/$($recipe.id).json")}
$theme=[pscustomobject]@{schema='bitwrecked-native-graphics/v1';fontFamily=$recipe.typography.fontFamily;fontSize=$recipe.typography.bodySize;background=$recipe.palette.background;surface=$recipe.palette.surface;text=$recipe.palette.text;muted=$recipe.palette.muted;border=$recipe.palette.border;accent=$recipe.palette.accent;cornerRadius=$recipe.geometry.cornerRadius;spacing=$recipe.geometry.spacing;buttonFill=$recipe.palette.buttonFill}
$capability=Get-NativeGraphicsCapability
[Windows.Forms.Application]::EnableVisualStyles()
$form=New-Object Windows.Forms.Form
$form.Text='Bit Wrecked - Graphics workbench'
$form.ClientSize=New-Object Drawing.Size(960,790)
$form.MinimumSize=New-Object Drawing.Size(760,620)
$form.StartPosition='CenterScreen'
$form.AutoScaleMode='Font'
$form.Font=New-Object Drawing.Font($theme.fontFamily,$theme.fontSize)
$form.BackColor=ConvertTo-WorkbenchColor $theme.background
$form.ForeColor=ConvertTo-WorkbenchColor $theme.text
$logoPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../ui/Assets/i0141.png'))
$logo=[Drawing.Image]::FromFile($logoPath)
$owned=New-Object Collections.Generic.List[IDisposable]
$owned.Add($logo)
$owned.Add($form.Font)

function New-Label([string]$Text,[float]$Size=10,[bool]$Muted=$false,[bool]$FixedSize=$false){
    $label=New-Object Windows.Forms.Label
    $label.Text=$Text; $label.AutoSize=$true; $label.UseMnemonic=$false
    $initialSize=if($FixedSize){$Size}else{$Size+$theme.fontSize-10}
    $label.Font=New-Object Drawing.Font($theme.fontFamily,[float]$initialSize)
    $owned.Add($label.Font); $label.Tag=@{BaseFontSize=$initialSize}
    $label.ForeColor=if($Muted){ConvertTo-WorkbenchColor $theme.muted}else{ConvertTo-WorkbenchColor $theme.text}
    $label.Margin=New-Object Windows.Forms.Padding(0,0,0,[int]$theme.spacing)
    return $label
}
function New-Column([int]$Width){
    $column=New-Object Windows.Forms.TableLayoutPanel
    $column.ColumnCount=1; $column.AutoSize=$true; $column.AutoSizeMode='GrowAndShrink'
    $column.Width=$Width; $column.Padding=New-Object Windows.Forms.Padding(0)
    [void]$column.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100)))
    return $column
}
function Add-Row($Column,$Control){
    $Control.Dock='Top'
    $Column.Controls.Add($Control,0,$Column.RowCount)
    $Column.RowCount++
}
function New-StudySurface([int]$Width,[int]$Height){
    $surface=New-Object BitWrecked.NativeGraphics.V1.SurfacePanel
    $surface.Size=New-Object Drawing.Size($Width,$Height)
    $surface.FillColor=ConvertTo-WorkbenchColor $theme.surface
    $surface.BorderColor=ConvertTo-WorkbenchColor $theme.border
    $surface.CornerRadius=$theme.cornerRadius
    $surface.Padding=New-Object Windows.Forms.Padding([int]($theme.spacing+8))
    $surface.Margin=New-Object Windows.Forms.Padding(0,0,20,16)
    return $surface
}
function New-Outline([string]$Text){
    $button=New-Object BitWrecked.NativeGraphics.V1.OutlineButton
    $button.Text=$Text; $button.Size=New-Object Drawing.Size(154,42)
    $button.FillColor=ConvertTo-WorkbenchColor $theme.buttonFill
    $button.ForeColor=ConvertTo-WorkbenchColor $theme.text
    $button.BorderColor=ConvertTo-WorkbenchColor $recipe.palette.buttonBorder
    $button.DisabledFillColor=ConvertTo-WorkbenchColor $recipe.palette.disabledFill
    $button.DisabledBorderColor=ConvertTo-WorkbenchColor $recipe.palette.disabledBorder
    $button.DisabledTextColor=ConvertTo-WorkbenchColor $recipe.palette.disabledText
    $button.AccentColor=ConvertTo-WorkbenchColor $theme.accent
    $button.CornerRadius=$theme.cornerRadius
    $button.AccessibleName=$Text
    $button.Margin=New-Object Windows.Forms.Padding(0,0,[int]$theme.spacing,8)
    return $button
}

$header=New-Object Windows.Forms.Panel
$header.Dock='Top'; $header.Height=104; $header.Padding=New-Object Windows.Forms.Padding(24,18,24,0)
$picture=New-Object Windows.Forms.PictureBox
$picture.Image=$logo; $picture.SizeMode='Zoom'; $picture.Size=New-Object Drawing.Size(40,40)
$picture.Location=New-Object Drawing.Point(24,22); $picture.AccessibleName='Bit Wrecked picture-only logo'; $picture.TabStop=$false
$heading=New-Label 'Graphics workbench' 21
$heading.Location=New-Object Drawing.Point(80,19)
$subheading=New-Label $recipe.name 10 $true
$subheading.Location=New-Object Drawing.Point(82,60)
$header.Controls.AddRange([Windows.Forms.Control[]]@($picture,$heading,$subheading))

$toolbar=New-Object Windows.Forms.FlowLayoutPanel
$toolbar.Dock='Top'; $toolbar.AutoSize=$true; $toolbar.WrapContents=$true
$toolbar.Padding=New-Object Windows.Forms.Padding(24,0,24,12)
$radiusLabel=New-Label 'Corners'
$radiusLabel.Margin=New-Object Windows.Forms.Padding(0,9,8,0)
$radius=New-Object Windows.Forms.ComboBox
$radius.DropDownStyle='DropDownList'; $radius.Width=125; $radius.AccessibleName='Corner radius'; $radius.TabIndex=0
[void]$radius.Items.AddRange([object[]]@("$($theme.cornerRadius) px (theme)",'Square','Subtle','Soft')); $radius.SelectedIndex=0
$radius.Margin=New-Object Windows.Forms.Padding(0,5,20,0)
$fontLabel=New-Label 'Text size'; $fontLabel.Margin=New-Object Windows.Forms.Padding(0,9,8,0)
$fontChoice=New-Object Windows.Forms.ComboBox
$fontChoice.DropDownStyle='DropDownList'; $fontChoice.Width=128; $fontChoice.AccessibleName='Preview text size'; $fontChoice.TabIndex=1
[void]$fontChoice.Items.AddRange([object[]]@("$($theme.fontSize) pt (theme)",'10 pt','11 pt','12 pt')); $fontChoice.SelectedIndex=0
$fontChoice.Margin=New-Object Windows.Forms.Padding(0,5,20,0)
$contrast=New-Object Windows.Forms.CheckBox
$contrast.Text='Contrast preview'; $contrast.AutoSize=$true; $contrast.AccessibleName='Simulate high-contrast rendering'
$contrast.Margin=New-Object Windows.Forms.Padding(0,9,20,0); $contrast.TabIndex=2
$export=New-Outline 'Export previews'; $export.TabIndex=3
$toolbar.Controls.AddRange([Windows.Forms.Control[]]@($radiusLabel,$radius,$fontLabel,$fontChoice,$contrast,$export))

$tabs=New-Object Windows.Forms.TabControl
$tabs.Dock='Fill'; $tabs.TabIndex=4
$managerTab=New-Object Windows.Forms.TabPage; $managerTab.Text='Manager study'
$componentTab=New-Object Windows.Forms.TabPage; $componentTab.Text='Components'
$releaseTab=New-Object Windows.Forms.TabPage; $releaseTab.Text='Release cards'
foreach($tab in @($managerTab,$componentTab,$releaseTab)){
    $tab.BackColor=$form.BackColor; $tab.Padding=New-Object Windows.Forms.Padding(20); $tab.AutoScroll=$true
    [void]$tabs.TabPages.Add($tab)
}
$body=New-Object Windows.Forms.FlowLayoutPanel
$body.AutoSize=$true; $body.WrapContents=$true; $body.Dock='Top'
$managerTab.Controls.Add($body)
$study=New-StudySurface ([int]($recipe.geometry.contentWidth+2*$recipe.geometry.contentPadding)) 600
$study.Padding=New-Object Windows.Forms.Padding([int]$recipe.geometry.contentPadding)
$studyColumn=New-Column ([int]$recipe.geometry.contentWidth); $studyColumn.Dock='Top'
$study.Controls.Add($studyColumn)
$studyHeader=New-Object Windows.Forms.TableLayoutPanel
$studyHeader.ColumnCount=3; $studyHeader.AutoSize=$true
[void]$studyHeader.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::AutoSize)))
[void]$studyHeader.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100)))
[void]$studyHeader.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::AutoSize)))
$studyLogo=New-Object Windows.Forms.PictureBox; $studyLogo.Image=$logo; $studyLogo.SizeMode='Zoom'
$studyLogo.Size=New-Object Drawing.Size([int]$recipe.manager.logoSize,[int]$recipe.manager.logoSize)
$studyLogo.AccessibleName='Bit Wrecked picture-only logo'; $studyLogo.TabStop=$false; $studyLogo.Anchor='Left'
$studyLogo.Margin=New-Object Windows.Forms.Padding(0,0,[int]$theme.spacing,0)
$studyVersion=New-Label '1.3.0 DEV' 10; $studyVersion.ForeColor=ConvertTo-WorkbenchColor $theme.accent
$studyVersion.Anchor='Right'; $studyVersion.Margin=New-Object Windows.Forms.Padding([int]$theme.spacing,0,0,0)
$titleLabel=New-Label $recipe.copy.manager.title ([float]$recipe.typography.titleSize) $false $true
$titleLabel.Anchor='Left'; $titleLabel.Margin=New-Object Windows.Forms.Padding(0)
$studyHeader.Controls.Add($studyLogo,0,0); $studyHeader.Controls.Add($titleLabel,1,0); $studyHeader.Controls.Add($studyVersion,2,0); Add-Row $studyColumn $studyHeader
$introLabel=New-Label $recipe.copy.manager.intro 10 $true; Add-Row $studyColumn $introLabel
Add-Row $studyColumn (New-Label 'Game Name')
$gameName=New-Object Windows.Forms.TextBox; $gameName.Text='A Different Beginning'
$gameName.AccessibleName='Game Name preview'; $gameName.Margin=New-Object Windows.Forms.Padding(0,0,0,8); $gameName.TabIndex=0
Add-Row $studyColumn $gameName
$modes=New-Object Windows.Forms.FlowLayoutPanel; $modes.AutoSize=$true; $modes.Margin=New-Object Windows.Forms.Padding(0,4,0,12)
$standard=New-Object Windows.Forms.RadioButton; $standard.Text='Standard'; $standard.AutoSize=$true; $standard.Margin=New-Object Windows.Forms.Padding(0,0,24,0)
$random=New-Object Windows.Forms.RadioButton; $random.Text='Random'; $random.AutoSize=$true; $standard.Checked=$true
$modes.Controls.AddRange([Windows.Forms.Control[]]@($standard,$random)); Add-Row $studyColumn $modes
$biome=New-StudySurface ([int]$recipe.geometry.contentWidth) 124; $biome.Padding=New-Object Windows.Forms.Padding([int]$recipe.manager.biomePadding)
$biomeColumn=New-Column ([int]($recipe.geometry.contentWidth-$biome.Padding.Horizontal)); $biomeColumn.Dock='Top'; $biome.Controls.Add($biomeColumn)
$biomeColumn.AccessibleName='Biome selection method preview'; $biomeColumn.AccessibleRole='Grouping'
$script:studyMethod='Any'; $script:studyLoading=$false
$methodRadios=[ordered]@{}
foreach($item in @(@('Any','Any biome (equal chance)'),@('Chosen','Choose a biome'),@('Weighted','Custom weights'))){
    $radio=New-Object Windows.Forms.RadioButton; $radio.Text=$item[1]; $radio.Tag=$item[0]; $radio.AutoSize=$true; $radio.AccessibleName=$item[1]
    $radio.Add_CheckedChanged({param($sender,$eventArgs); if($sender.Checked -and !$script:studyLoading){Set-StudyMethod -Method ([string]$sender.Tag); Set-StudyDirty}})
    $methodRadios[$item[0]]=$radio
}
Add-Row $biomeColumn $methodRadios.Any; Add-Row $biomeColumn $methodRadios.Chosen
$chosen=New-Object Windows.Forms.ComboBox; $chosen.DropDownStyle='DropDownList'; $chosen.AccessibleName='Chosen starting biome'
[void]$chosen.Items.AddRange([object[]]@('Pine Forest','Burnt Forest','Desert','Snow','Wasteland')); $chosen.SelectedIndex=4
Add-Row $biomeColumn $chosen
$chosen.Margin=New-Object Windows.Forms.Padding(18,0,0,8)
Add-Row $biomeColumn $methodRadios.Weighted
$weightNames=@('Pine Forest','Burnt Forest','Desert','Snow','Wasteland')
$script:previewWeights=@(10,20,20,25,25)
$editWeights=New-Outline 'Edit weights...'; $editWeights.Size=New-Object Drawing.Size(154,34)
Add-Row $biomeColumn $editWeights; $editWeights.Dock='None'; $editWeights.Anchor='Left'
$editWeights.Margin=New-Object Windows.Forms.Padding(18,0,0,[int]$recipe.manager.choiceMargin)
$weightSummary=New-Label '' 10 $true; $weightSummary.MinimumSize=New-Object Drawing.Size(0,$form.Font.Height); Add-Row $biomeColumn $weightSummary
$weightSummary.Margin=New-Object Windows.Forms.Padding(18,0,0,0)
Add-Row $studyColumn $biome
$protect=New-Object Windows.Forms.CheckBox; $protect.Text='Starting-biome protection'; $protect.AutoSize=$true; $protect.Margin=New-Object Windows.Forms.Padding(0,0,0,8)
Add-Row $studyColumn $protect
$state=New-Label 'Choose your start.' 10; $state.AccessibleName=$state.Text; Add-Row $studyColumn $state
$next=New-Label 'Apply settings to use this start.' 10 $true; Add-Row $studyColumn $next
$actions=New-Object Windows.Forms.FlowLayoutPanel; $actions.AutoSize=$true; $actions.WrapContents=$true
$apply=New-Outline 'Apply Settings'; $launch=New-Outline 'Launch Game'; $launch.Enabled=$false
$apply.Height=[int]$recipe.geometry.buttonHeight; $launch.Height=[int]$recipe.geometry.buttonHeight
$applyBadge=New-Object BitWrecked.NativeGraphics.V1.StatusBadge; $applyBadge.AutoSize=$true; $applyBadge.Font=$form.Font
$applyBadge.ShowAccent=$true; $applyBadge.CornerRadius=[float]$recipe.geometry.cornerRadius; $applyBadge.AccessibleName='Configuration status preview'
$applyBadge.Margin=New-Object Windows.Forms.Padding(0,7,[int]$theme.spacing,8)
$script:studyConfigurationState='Pending'
$actions.Controls.AddRange([Windows.Forms.Control[]]@($apply,$applyBadge,$launch)); Add-Row $studyColumn $actions
$lastStart=New-Label 'Last start: no applied settings.' 10 $true; Add-Row $studyColumn $lastStart
$maintenance=New-Object Windows.Forms.FlowLayoutPanel; $maintenance.AutoSize=$true
$uninstall=New-Outline 'Uninstall Mod'; $uninstall.Size=New-Object Drawing.Size(140,32); $uninstall.Enabled=$false
$maintenance.Controls.Add($uninstall); Add-Row $studyColumn $maintenance
$detailsToggle=New-Object Windows.Forms.LinkLabel; $detailsToggle.Text='Game details'; $detailsToggle.AutoSize=$true
$detailsToggle.LinkColor=ConvertTo-WorkbenchColor $theme.muted; $detailsToggle.ActiveLinkColor=ConvertTo-WorkbenchColor $theme.accent
$detailsToggle.LinkBehavior='HoverUnderline'
$helpLink=New-Object Windows.Forms.LinkLabel; $helpLink.Text='Help'; $helpLink.AutoSize=$true; $helpLink.AccessibleName='Help with manager study'
$helpLink.LinkBehavior='HoverUnderline'; $helpLink.LinkColor=ConvertTo-WorkbenchColor $theme.muted
$helpLink.Add_LinkClicked({[void][Windows.Forms.MessageBox]::Show($form,"Design study only. No game action is connected.`r`n`r`nEnter the save's exact Game Name, distinct from the world name. Random placement happens on a fresh character's first spawn.`r`n`r`nAny gives equal chances among eligible biomes. Weights are relative values from 0 to 100; zero excludes a biome. At least one weight must be positive.`r`n`r`nProtection covers recognized environmental hazards in the starting biome. Enemies and other-biome hazards remain active.`r`n`r`nThe customer manager applies and verifies settings, then acknowledges completion. Launch is separate. For Random, finish the opening tasks in the first session until the Journey to Settlement trader marker is assigned.",'Manager study help',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)})
$links=New-Object Windows.Forms.FlowLayoutPanel; $links.AutoSize=$true; $links.WrapContents=$true
$helpLink.Margin=New-Object Windows.Forms.Padding(0,0,20,0); $links.Controls.AddRange([Windows.Forms.Control[]]@($helpLink,$detailsToggle)); Add-Row $studyColumn $links
$studyDetails=New-Label 'Design study only. No game folder or live result is connected.' 9 $true
Add-Row $studyColumn $studyDetails; $studyDetails.Visible=$false
$detailsToggle.Add_LinkClicked({$studyDetails.Visible=!$studyDetails.Visible; $detailsToggle.Text=if($studyDetails.Visible){'Hide game details'}else{'Game details'}; Update-StudyLayout})
$body.Controls.Add($study)
$reset=New-Outline 'Reset study'; $reset.Height=32
$toolbar.Controls.Add($reset)

$components=New-Column 800; $components.Dock='Top'; $componentTab.Controls.Add($components)
Add-Row $components (New-Label 'Reusable native graphics' 20)
Add-Row $components (New-Label 'Code-drawn shapes and icons. Ordinary Windows inputs.' 11 $true)
$glyphRow=New-Object Windows.Forms.FlowLayoutPanel; $glyphRow.AutoSize=$true
$glyphs=New-Object Collections.Generic.List[Windows.Forms.Control]
foreach($name in @('Check','Info','ArrowRight','ChevronDown','Shield','Settings')){
    $tile=New-StudySurface 118 104; $tile.Padding=New-Object Windows.Forms.Padding(8)
    $glyph=New-NativeGlyph -Glyph $name
    $glyph.Location=New-Object Drawing.Point(40,12); $glyph.Size=New-Object Drawing.Size(32,32)
    $glyph.ForeColor=ConvertTo-WorkbenchColor $theme.accent
    $glyphs.Add($glyph); $tile.Controls.Add($glyph)
    $label=New-Label $name 9 $true; $label.Location=New-Object Drawing.Point(8,62); $tile.Controls.Add($label)
    $glyphRow.Controls.Add($tile)
}
Add-Row $components $glyphRow
$buttonRow=New-Object Windows.Forms.FlowLayoutPanel; $buttonRow.AutoSize=$true
$sampleButton=New-Outline 'Try Space or Enter'; $sampleButton.Width=190
$disabledButton=New-Outline 'Disabled'; $disabledButton.Enabled=$false
$buttonRow.Controls.AddRange([Windows.Forms.Control[]]@($sampleButton,$disabledButton)); Add-Row $components $buttonRow
$componentStatus=New-Label 'Tab to the button. Focus stays visible.' 10 $true; Add-Row $components $componentStatus
$sampleButton.Add_Click({$componentStatus.Text='Button activated. Native Click behavior is intact.'})

$releaseColumn=New-Column 850; $releaseColumn.Dock='Top'; $releaseTab.Controls.Add($releaseColumn)
Add-Row $releaseColumn (New-Label 'Native release-card composition' 20)
Add-Row $releaseColumn (New-Label 'Light and contrast studies. Existing logo, drawn geometry and type.' 11 $true)
$releaseStyle=New-Object Windows.Forms.ComboBox; $releaseStyle.DropDownStyle='DropDownList'; $releaseStyle.Width=240; $releaseStyle.Dock='Left'
$releaseRecipes=@(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'recipes') -Filter '*.json' -File | Sort-Object Name | ForEach-Object {
    $item=Get-DesignRecipe -Path $_.FullName
    if($item.targets -ccontains 'ReleaseCard'){[pscustomobject]@{name=$item.name;id=$item.id;path=$_.FullName}}
})
if($recipe.targets -ccontains 'ReleaseCard' -and @($releaseRecipes.path) -notcontains $recipeSource){$releaseRecipes+=,[pscustomobject]@{name=$recipe.name;id=$recipe.id;path=$recipeSource}}
foreach($item in $releaseRecipes){[void]$releaseStyle.Items.Add($item.name)}
$releaseStyle.SelectedIndex=[Math]::Max(0,@($releaseRecipes.path).IndexOf($recipeSource)); $releaseStyle.AccessibleName='Release card recipe'
Add-Row $releaseColumn $releaseStyle
$card=New-Object Windows.Forms.PictureBox; $card.SizeMode='Zoom'; $card.Size=New-Object Drawing.Size(830,467); $card.AccessibleName='Release card design study'
Add-Row $releaseColumn $card
$temporaryCard=Join-Path ([IO.Path]::GetTempPath()) ('bitwrecked-card-'+[guid]::NewGuid().ToString('N')+'.png')
function Update-ReleaseCard {
    $null=Export-WorkbenchReleaseCard -Path $temporaryCard -RecipePath $releaseRecipes[$releaseStyle.SelectedIndex].path -LogoPath $logoPath
    $loaded=[Drawing.Image]::FromFile($temporaryCard)
    try {$copy=New-Object Drawing.Bitmap($loaded)} finally {$loaded.Dispose()}
    if($card.Image){$card.Image.Dispose()}; $card.Image=$copy
    Remove-Item -LiteralPath $temporaryCard -Force
    Remove-Item -LiteralPath ($temporaryCard+'.recipe.json') -Force
}

function Update-StudyLayout {
    $width=[Math]::Max(220,$study.ClientSize.Width-$study.Padding.Horizontal)
    foreach($label in @($introLabel,$studyDetails,$state,$next)){$label.MaximumSize=New-Object Drawing.Size($width,0)}
    $titleWidth=[Math]::Max(100,$width-$studyLogo.Width-$studyLogo.Margin.Horizontal-$studyVersion.PreferredSize.Width-$studyVersion.Margin.Horizontal)
    $titleLabel.MaximumSize=New-Object Drawing.Size($titleWidth,0)
    $weightSummary.MaximumSize=New-Object Drawing.Size(($width-$biome.Padding.Horizontal-$weightSummary.Margin.Horizontal),0)
    $biomeColumn.PerformLayout(); $biome.Height=$biomeColumn.PreferredSize.Height+$biome.Padding.Vertical+8
    $studyColumn.PerformLayout(); $study.Height=$studyColumn.PreferredSize.Height+$study.Padding.Vertical+8
    $body.PerformLayout()
}
function Update-StudyChoices {
    $biome.Visible=$random.Checked; $protect.Visible=$random.Checked
    $chosen.Enabled=$random.Checked -and $script:studyMethod -ceq 'Chosen'
    $editWeights.Enabled=$random.Checked -and $script:studyMethod -ceq 'Weighted'
    $weightSummary.Enabled=$editWeights.Enabled
    $sum=($script:previewWeights | Measure-Object -Sum).Sum
    $shares=for($i=0;$i -lt 5;$i++){"$($weightNames[$i]) $([Math]::Round(100*$script:previewWeights[$i]/[Math]::Max(1,$sum),1))%"}
    $weightSummary.Text=if($script:studyMethod -ceq 'Weighted'){$shares -join '  /  '}else{''}
    Update-StudyLayout
}
function Set-StudyMethod([ValidateSet('Any','Chosen','Weighted')][string]$Method){
    $script:studyLoading=$true
    try{
        $script:studyMethod=$Method
        foreach($key in $methodRadios.Keys){$methodRadios[$key].Checked=$key -ceq $Method}
    }finally{$script:studyLoading=$false}
    Update-StudyChoices
}
function Render-StudyConfiguration {
    $applied=$script:studyConfigurationState -ceq 'Applied'
    $prefix=if($applied){'applied'}else{'pending'}
    $applyBadge.Text=if($applied){'Changes applied.'}else{'Changes not applied.'}
    $applyBadge.FillColor=ConvertTo-WorkbenchColor $recipe.palette.($prefix+'Fill')
    $applyBadge.BorderColor=ConvertTo-WorkbenchColor $recipe.palette.($prefix+'Border')
    $applyBadge.ForeColor=ConvertTo-WorkbenchColor $recipe.palette.($prefix+'Text')
    $applyBadge.AccentColor=ConvertTo-WorkbenchColor $recipe.palette.($prefix+'Dot')
}
function Show-StudyWeights([ValidateSet('Interactive','SaveFixture','CancelFixture')][string]$Action='Interactive') {
    $dialog=New-Object Windows.Forms.Form; $dialog.Text='Bit Wrecked - Biome weights'
    $dialog.ClientSize=New-Object Drawing.Size(450,350); $dialog.Font=$form.Font; $dialog.BackColor=$form.BackColor; $dialog.ForeColor=$form.ForeColor
    $dialog.FormBorderStyle='FixedDialog'; $dialog.MaximizeBox=$false; $dialog.MinimizeBox=$false; $dialog.StartPosition='CenterParent'
    $inputs=@(); $shares=@()
    $label=New-Label 'Set your odds.' 16; $label.Location=New-Object Drawing.Point(22,18); $dialog.Controls.Add($label)
    for($i=0;$i -lt 5;$i++){
        $name=New-Label $weightNames[$i] 10; $name.Location=New-Object Drawing.Point(22,(64+$i*34)); $dialog.Controls.Add($name)
        $input=New-Object Windows.Forms.NumericUpDown; $input.Minimum=0; $input.Maximum=100; $input.Value=$script:previewWeights[$i]
        $input.Location=New-Object Drawing.Point(170,(61+$i*34)); $input.Size=New-Object Drawing.Size(76,28); $input.AccessibleName=$weightNames[$i]+' weight'
        $share=New-Label '' 10 $true; $share.Location=New-Object Drawing.Point(275,(64+$i*34)); $dialog.Controls.AddRange([Windows.Forms.Control[]]@($input,$share))
        $inputs+=,$input; $shares+=,$share
    }
    $note=New-Label "0 excludes a biome. At least one weight must be positive.`nOnly biomes in the world enter the draw." 9 $true
    $note.Location=New-Object Drawing.Point(22,239); $note.MaximumSize=New-Object Drawing.Size(410,0); $dialog.Controls.Add($note)
    $use=New-Outline 'Use weights'; $use.Location=New-Object Drawing.Point(22,297); $use.DialogResult='OK'
    $cancel=New-Outline 'Cancel'; $cancel.Location=New-Object Drawing.Point(200,297); $cancel.DialogResult='Cancel'
    $dialog.Controls.AddRange([Windows.Forms.Control[]]@($use,$cancel)); $dialog.AcceptButton=$use; $dialog.CancelButton=$cancel
    $update={
        $total=($inputs | ForEach-Object {[int]$_.Value} | Measure-Object -Sum).Sum
        $use.Enabled=$total -gt 0
        for($n=0;$n -lt 5;$n++){$shares[$n].Text=if($total -gt 0){"$([Math]::Round(100*[int]$inputs[$n].Value/$total,1))%"}else{'0%'}}
    }
    foreach($input in $inputs){$input.Add_ValueChanged($update)}; & $update
    try {
        if($Action -ne 'Interactive'){
            foreach($input in $inputs){$input.Value=0}; & $update
            if($use.Enabled){throw 'Zero weights must disable Use weights'}
            $inputs[4].Value=100; & $update
            if(!$use.Enabled -or $shares[4].Text -cne '100%'){throw 'Normalized weight preview failed'}
            $result=if($Action -eq 'SaveFixture'){'OK'}else{'Cancel'}
        } else {$result=$dialog.ShowDialog($form)}
        if($result -eq 'OK'){$script:previewWeights=@($inputs | ForEach-Object {[int]$_.Value}); Update-StudyChoices; Set-StudyDirty}
    } finally {$dialog.Dispose()}
}
function Set-StudyDirty {
    $script:studyConfigurationState='Pending'; Render-StudyConfiguration
    $state.Text='Design study only. No game action is connected.'; $launch.Enabled=$false
    $state.AccessibleName=$state.Text
    $apply.Enabled=![string]::IsNullOrWhiteSpace($gameName.Text)
    $next.Text=if($apply.Enabled){'Apply settings to use this start.'}else{'Enter a Game Name to try the preview.'}
}
$apply.Add_Click({$script:studyConfigurationState='Applied'; Render-StudyConfiguration; $state.Text='Preview ready'; $state.AccessibleName=$state.Text; $next.Text='Design study only. Nothing has been installed.'; $launch.Enabled=$true})
$launch.Add_Click({$next.Text='Launch preview selected. The game has not been started.'})
$gameName.Add_TextChanged({Set-StudyDirty})
$protect.Add_CheckedChanged({Set-StudyDirty})
$chosen.Add_SelectedIndexChanged({Update-StudyChoices; Set-StudyDirty})
$editWeights.Add_Click({Show-StudyWeights})
$random.Add_CheckedChanged({Update-StudyChoices; Set-StudyDirty})
$reset.Add_Click({$gameName.Text='A Different Beginning'; $standard.Checked=$true; Set-StudyMethod Any; $protect.Checked=$false; $script:previewWeights=@(10,20,20,25,25); Update-StudyChoices; Set-StudyDirty})
function Update-PreviewStyle {
    $corner=@($theme.cornerRadius,0,8,14)[$radius.SelectedIndex]
    $fontPoints=@($theme.fontSize,10,11,12)[$fontChoice.SelectedIndex]
    $form.Font=New-Object Drawing.Font($theme.fontFamily,$fontPoints)
    $owned.Add($form.Font)
    $queue=New-Object Collections.Generic.Queue[Windows.Forms.Control]; $queue.Enqueue($form)
    while($queue.Count){
        $control=$queue.Dequeue()
        if($control -is [Windows.Forms.Label] -and $control.Tag -is [Collections.IDictionary] -and $control.Tag.Contains('BaseFontSize')){
            $control.Font=New-Object Drawing.Font($theme.fontFamily,([float]$control.Tag.BaseFontSize+$fontPoints-$theme.fontSize))
            $owned.Add($control.Font)
        }
        if($control -is [BitWrecked.NativeGraphics.V1.StatusBadge]){
            $control.Font=New-Object Drawing.Font($theme.fontFamily,$fontPoints)
            $owned.Add($control.Font)
        }
        if($control -is [BitWrecked.NativeGraphics.V1.SurfacePanel] -or $control -is [BitWrecked.NativeGraphics.V1.OutlineButton] -or $control -is [BitWrecked.NativeGraphics.V1.StatusBadge]){$control.CornerRadius=$corner}
        if($control -is [BitWrecked.NativeGraphics.V1.SurfacePanel] -or $control -is [BitWrecked.NativeGraphics.V1.OutlineButton] -or $control -is [BitWrecked.NativeGraphics.V1.StatusBadge] -or $control -is [BitWrecked.NativeGraphics.V1.GlyphControl]){$control.PreviewHighContrast=$contrast.Checked; $control.Invalidate()}
        foreach($child in $control.Controls){$queue.Enqueue($child)}
    }
    $form.PerformLayout()
    Update-StudyLayout
}
$radius.Add_SelectedIndexChanged({Update-PreviewStyle})
$fontChoice.Add_SelectedIndexChanged({Update-PreviewStyle})
$contrast.Add_CheckedChanged({Update-PreviewStyle})
$releaseStyle.Add_SelectedIndexChanged({Update-ReleaseCard})

$footer=New-Object Windows.Forms.Label
$footer.Dock='Bottom'; $footer.Height=30; $footer.Text='Design study only. Apply and Launch change this preview.'
$footer.Padding=New-Object Windows.Forms.Padding(24,6,0,0); $footer.ForeColor=ConvertTo-WorkbenchColor $theme.muted
$form.Controls.Add($tabs); $form.Controls.Add($toolbar); $form.Controls.Add($header); $form.Controls.Add($footer)

function Export-AllStudies([string]$Destination){
    $destinationFull=[IO.Path]::GetFullPath($Destination); [void][IO.Directory]::CreateDirectory($destinationFull)
    $files=New-Object Collections.Generic.List[string]
    $originalTab=$tabs.SelectedIndex; $originalContrast=$contrast.Checked
    $originalState=$state.Text; $originalNext=$next.Text; $originalLaunch=$launch.Enabled; $originalApply=$apply.Enabled; $originalConfiguration=$script:studyConfigurationState
    $contrast.Checked=$false
    for($i=0;$i -lt $tabs.TabPages.Count;$i++){
        $tabs.SelectedIndex=$i; $form.PerformLayout(); [Windows.Forms.Application]::DoEvents()
        $names=@('manager-study','components','release-workbench')
        $files.Add((Export-WorkbenchControl -Control $form -Path (Join-Path $destinationFull ($names[$i]+'.png'))))
    }
    $tabs.SelectedIndex=1; $contrast.Checked=$true; [Windows.Forms.Application]::DoEvents()
    $files.Add((Export-WorkbenchControl -Control $form -Path (Join-Path $destinationFull 'components-contrast.png')))
    $contrast.Checked=$originalContrast; $tabs.SelectedIndex=$originalTab
    $tabs.SelectedIndex=0
    $originalMode=$random.Checked; $originalSelection=$script:studyMethod
    $standard.Checked=$true; Update-StudyChoices; [Windows.Forms.Application]::DoEvents()
    $files.Add((Export-WorkbenchControl -Control $study -Path (Join-Path $destinationFull 'manager-rework-standard.png')))
    $random.Checked=$true
    foreach($variant in @('any','chosen','weighted')){
        Set-StudyMethod (@('Any','Chosen','Weighted')[@('any','chosen','weighted').IndexOf($variant)]); [Windows.Forms.Application]::DoEvents()
        $files.Add((Export-WorkbenchControl -Control $study -Path (Join-Path $destinationFull ("manager-rework-$variant.png"))))
    }
    Set-StudyMethod $originalSelection; $random.Checked=$originalMode; $standard.Checked=!$originalMode; Update-StudyChoices
    $tabs.SelectedIndex=$originalTab
    $state.Text=$originalState; $state.AccessibleName=$originalState; $next.Text=$originalNext; $launch.Enabled=$originalLaunch; $apply.Enabled=$originalApply; $script:studyConfigurationState=$originalConfiguration; Render-StudyConfiguration
    $files.Add((Export-WorkbenchReleaseCard -Path (Join-Path $destinationFull 'release-light.png') -RecipeId bitwrecked-quiet -LogoPath $logoPath))
    $files.Add((Export-WorkbenchReleaseCard -Path (Join-Path $destinationFull 'release-contrast.png') -RecipeId bitwrecked-contrast -LogoPath $logoPath))
    $files.Add((Export-WorkbenchIcon -SourcePath $logoPath -Path (Join-Path $destinationFull 'picture-only.ico')))
    foreach($glyphFile in @(Export-WorkbenchGlyphs -Directory (Join-Path $destinationFull 'glyphs') -Color $theme.accent)){$files.Add($glyphFile)}
    [ordered]@{schema='bitwrecked-graphics-export/v1';createdUtc=[DateTime]::UtcNow.ToString('o');windowsPowerShell=$PSVersionTable.PSVersion.ToString();capability=$capability;recipe=@{id=$recipe.id;path=$recipeSource;sha256=(Get-FileHash -LiteralPath $recipeSource -Algorithm SHA256).Hash};theme=$theme;cornerChoice=[string]$radius.SelectedItem;textChoice=[string]$fontChoice.SelectedItem;sources=@('NativeControls.cs','NativeGraphics.psm1','Recipes.psm1','Presentation.psm1','Show-GraphicsWorkbench.ps1','recipes/bitwrecked-quiet.json','recipes/bitwrecked-contrast.json' | ForEach-Object {[pscustomobject]@{file=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $_) -Algorithm SHA256).Hash}});exports=@($files | ForEach-Object {[pscustomobject]@{file=$_.Substring($destinationFull.TrimEnd('\').Length+1).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}});method='Recipe-driven native design study and code-drawn release cards. Contrast is simulated; no OS setting changed. No game or manager action invoked.'} | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $destinationFull 'export.json') -Encoding UTF8
    $footer.Text='Exported previews to '+$destinationFull
}
$export.Add_Click({
    $picker=New-Object Windows.Forms.FolderBrowserDialog
    $picker.Description='Choose a folder for graphics previews'; $picker.ShowNewFolderButton=$true
    try {if($picker.ShowDialog($form) -eq 'OK'){Export-AllStudies $picker.SelectedPath}}catch{[void][Windows.Forms.MessageBox]::Show($form,$_.Exception.Message,'Export failed')}finally{$picker.Dispose()}
})

try {
    Update-ReleaseCard; Set-StudyMethod Any; Render-StudyConfiguration; Update-PreviewStyle
    if($ExportDirectory -or $SmokeTest){
        $form.StartPosition='Manual'; $form.Location=New-Object Drawing.Point(-32000,-32000)
        $form.Show(); [Windows.Forms.Application]::DoEvents()
        if($SmokeTest){
            if($apply.FillColor -ne (ConvertTo-WorkbenchColor $theme.buttonFill)){throw 'Apply must use the recipe button fill.'}
            $apply.PerformClick(); if(!$launch.Enabled -or $state.Text -cne 'Preview ready'){throw 'Preview Apply transition failed.'}
            $gameName.Text=''; if($apply.Enabled -or $launch.Enabled){throw 'Empty preview name must block actions.'}
            $reset.PerformClick(); if(!$apply.Enabled -or $launch.Enabled){throw 'Preview reset failed.'}
            if($biome.Visible -or $protect.Visible){throw 'Standard must hide Random settings'}
            $random.Checked=$true; $methodRadios.Chosen.Checked=$true
            if(!$chosen.Visible -or !$chosen.Enabled -or !$editWeights.Visible -or $editWeights.Enabled -or $script:studyMethod -cne 'Chosen'){throw 'Chosen preview failed'}
            $methodRadios.Weighted.Checked=$true; if(!$editWeights.Visible -or !$editWeights.Enabled -or !$chosen.Visible -or $chosen.Enabled -or $script:studyMethod -cne 'Weighted'){throw 'Weighted preview failed'}
            $beforeWeights=$script:previewWeights -join ','
            Show-StudyWeights -Action CancelFixture; if(($script:previewWeights -join ',') -cne $beforeWeights){throw 'Cancel changed weights'}
            Show-StudyWeights -Action SaveFixture; if(($script:previewWeights -join ',') -cne '0,0,0,0,100'){throw 'Use weights preview failed'}
            $standard.Checked=$true; $random.Checked=$true
            if($script:studyMethod -cne 'Weighted' -or ($script:previewWeights -join ',') -cne '0,0,0,0,100'){throw 'Mode toggle lost remembered weights'}
            $reset.PerformClick()
            $tabs.SelectedIndex=1; [Windows.Forms.Application]::DoEvents()
            $sampleButton.PerformClick(); if($componentStatus.Text -notmatch 'activated'){throw 'Native button click failed.'}
            $tabs.SelectedIndex=0
            $fontChoice.SelectedIndex=3; if($gameName.Font.Size -ne 12 -or $state.Font.Size -ne 12 -or $applyBadge.Font.Size -ne 12){throw 'Text-size preview failed.'}; $fontChoice.SelectedIndex=0
            $radius.SelectedIndex=3; if($apply.CornerRadius -ne 14){throw 'Corner preview failed.'}; $radius.SelectedIndex=0
            $contrast.Checked=$true; if(!$apply.PreviewHighContrast){throw 'Contrast preview failed.'}; $contrast.Checked=$false
        }
        if($ExportDirectory){Export-AllStudies $ExportDirectory}
        Write-Output 'PASS: native graphics workbench (design preview only; no install or game launch).'
    } else {[void]$form.ShowDialog()}
} finally {
    if($card.Image){$card.Image.Dispose()}; $form.Dispose(); foreach($item in $owned){$item.Dispose()}
    if([IO.File]::Exists($temporaryCard)){Remove-Item -LiteralPath $temporaryCard -Force}
    if([IO.File]::Exists($temporaryCard+'.recipe.json')){Remove-Item -LiteralPath ($temporaryCard+'.recipe.json') -Force}
}
