# Candidate 1.2.5-qa.002
param([switch] $SmokeTest, [string] $GameRootOverride, [string] $ScreenshotPath, [float] $UiScale=1)

# Bit Wrecked Historical Random Start - Alpha Core Manager
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$packageRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$managerRoot   = Split-Path -Parent $packageRoot
$launcherRoot  = Join-Path $managerRoot 'src\launcher'
$verifiedArtifactsRoot = Join-Path $managerRoot 'verified'
$verifiedPayloadRoot = Join-Path $verifiedArtifactsRoot 'main'
$verifiedRuntimeSha256 = 'D8C73D5A4126D1BC7826C0E507A946B53FA3F79E6DD3053E90F3BB593CF33EF8'
$verifiedModInfoSha256 = 'A17E85688E8341369892801DB2BBEE06842D7358EEE25B47A2D07E31557F9DAE'

# DEV working-tree test lane: build and deploy exact deterministic candidate.
# Set to $false for verified QA/release payload behavior.
$useDevCandidate = $false

$verifiedAssemblyCSharpMvid = [guid]'7c57b7de-39a1-497d-bf48-8d5d1d4a1ff1'
$verifiedAssemblyCSharpSha256 = 'AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146'
$unverifiedGameBuildMessage = 'This game build has not been verified with HRS. HRS will try to run. If the required game hooks are unavailable, it will leave the normal start in place.'
$script:appliedManifest = $null
$script:appliedPayloadRoot = $null

Import-Module (Join-Path $launcherRoot 'm0160.psm1') -Force
Import-Module (Join-Path $launcherRoot 'm0162.psm1') -Force
Import-Module (Join-Path $launcherRoot 'm0164.psm1') -Force
Import-Module (Join-Path $launcherRoot 'm0166.psm1') -Force

# Import Core last because dependent modules also load Core internally.
# The manager requires Core's public commands in the caller session.
Import-Module (Join-Path $launcherRoot 'm0161.psm1') -Force

function Test-HrsGameRootCandidate {
    param([Parameter(Mandatory = $true)] [string] $Path)

    try { $root = [System.IO.Path]::GetFullPath($Path) } catch { return $false }
    return (
        [System.IO.File]::Exists([System.IO.Path]::Combine($root, '7DaysToDie.exe')) -and
        [System.IO.File]::Exists([System.IO.Path]::Combine(
            $root,
            '7DaysToDie_Data\Managed\Assembly-CSharp.dll'
        ))
    )
}

function Get-HrsSteamRoots {
    $roots = New-Object System.Collections.Generic.List[string]
    $registryPaths = @(
        'HKCU:\Software\Valve\Steam',
        'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam',
        'HKLM:\SOFTWARE\Valve\Steam'
    )
    foreach ($registryPath in $registryPaths) {
        try {
            $record = Get-ItemProperty -LiteralPath $registryPath -ErrorAction Stop
            foreach ($property in @('SteamPath', 'InstallPath')) {
                $value = [string]$record.$property
                if (-not [string]::IsNullOrWhiteSpace($value)) { [void]$roots.Add($value) }
            }
        }
        catch { }
    }
    foreach ($programRoot in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
        if (-not [string]::IsNullOrWhiteSpace($programRoot)) {
            [void]$roots.Add([System.IO.Path]::Combine($programRoot, 'Steam'))
        }
    }

    $expanded = New-Object System.Collections.Generic.List[string]
    foreach ($steamRoot in @($roots)) {
        try { $canonical = [System.IO.Path]::GetFullPath($steamRoot) } catch { continue }
        if (-not $expanded.Contains($canonical)) { [void]$expanded.Add($canonical) }
        $vdf = [System.IO.Path]::Combine($canonical, 'steamapps\libraryfolders.vdf')
        if (-not [System.IO.File]::Exists($vdf)) { continue }
        try { $vdfText = [System.IO.File]::ReadAllText($vdf) } catch { continue }
        foreach ($match in [regex]::Matches($vdfText, '(?m)^\s*"path"\s*"(?<path>(?:\\.|[^"\\])*)"')) {
            $library = $match.Groups['path'].Value.Replace('\\', '\')
            try { $library = [System.IO.Path]::GetFullPath($library) } catch { continue }
            if (-not $expanded.Contains($library)) { [void]$expanded.Add($library) }
        }
    }
    return $expanded.ToArray()
}

function Find-HrsGameRoots {
    param([Parameter(Mandatory = $true)] [string] $StartPath)

    $candidates = New-Object System.Collections.Generic.List[string]
    try { $cursor = New-Object System.IO.DirectoryInfo([System.IO.Path]::GetFullPath($StartPath)) }
    catch { $cursor = $null }
    while ($null -ne $cursor) {
        [void]$candidates.Add($cursor.FullName)
        $cursor = $cursor.Parent
    }
    foreach ($steamRoot in @(Get-HrsSteamRoots)) {
        [void]$candidates.Add([System.IO.Path]::Combine(
            $steamRoot,
            'steamapps\common\7 Days To Die'
        ))
    }

    $valid = New-Object System.Collections.Generic.List[string]
    foreach ($candidate in @($candidates)) {
        if (-not (Test-HrsGameRootCandidate -Path $candidate)) { continue }
        $canonical = [System.IO.Path]::GetFullPath($candidate).TrimEnd('\')
        if (-not ($valid | Where-Object {
            [string]::Equals($_, $canonical, [System.StringComparison]::OrdinalIgnoreCase)
        })) { [void]$valid.Add($canonical) }
    }
    return $valid.ToArray()
}

function Select-HrsGameRoot {
    param([Parameter(Mandatory = $true)] [string] $StartPath)

    $discovered = @(Find-HrsGameRoots -StartPath $StartPath)
    if ($discovered.Count -eq 1) { return $discovered[0] }

    $picker = New-Object System.Windows.Forms.FolderBrowserDialog
    $picker.Description = if ($discovered.Count -gt 1) {
        'Multiple 7 Days to Die installations were found. Select the game folder to use.'
    }
    else {
        'Select the 7 Days to Die game folder containing 7DaysToDie.exe.'
    }
    $picker.ShowNewFolderButton = $false
    if ($discovered.Count -gt 0) { $picker.SelectedPath = $discovered[0] }
    try { $choice = $picker.ShowDialog() } finally { $selectedPath = $picker.SelectedPath; $picker.Dispose() }
    if ($choice -ne [System.Windows.Forms.DialogResult]::OK) { throw 'Game folder selection was canceled.' }
    if (-not (Test-HrsGameRootCandidate -Path $selectedPath)) {
        throw 'The selected folder is not a valid 7 Days to Die game folder.'
    }
    return [System.IO.Path]::GetFullPath($selectedPath).TrimEnd('\')
}

$gameRoot = if ($SmokeTest -and $GameRootOverride) { $GameRootOverride } else { Select-HrsGameRoot -StartPath $managerRoot }

$biomes = @('Forest', 'Burnt Forest', 'Desert', 'Snow', 'Wasteland')
$weights = [ordered]@{
    'Forest' = 10
    'Burnt Forest' = 20
    'Desert' = 20
    'Snow' = 25
    'Wasteland' = 25
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Bit Wrecked - Historical Random Start'
$iconPath = Join-Path $packageRoot 'logo.ico'
if (Test-Path -LiteralPath $iconPath -PathType Leaf) {
    $form.Icon = New-Object System.Drawing.Icon($iconPath)
}
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(620,610)
$form.MinimumSize = New-Object System.Drawing.Size(620,430)
$form.AutoScroll = $true

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Historical Random Start'
$title.Font = New-Object System.Drawing.Font('Segoe UI',18,[System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24,20)
$form.Controls.Add($title)

$version = New-Object System.Windows.Forms.Label
$version.Text = 'Release | 1.2.5 QA'
$version.AutoSize = $true
$version.Location = New-Object System.Drawing.Point(27,58)
$form.Controls.Add($version)

$status = New-Object System.Windows.Forms.Label
$status.AutoSize = $false
$status.Size = New-Object System.Drawing.Size(550,42)
$status.Location = New-Object System.Drawing.Point(27,90)
$status.Font = New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold)
$form.Controls.Add($status)

$gameLabel = New-Object System.Windows.Forms.Label
$gameLabel.Text = 'New game name'
$gameLabel.AutoSize = $true
$gameLabel.Location = New-Object System.Drawing.Point(27,150)
$form.Controls.Add($gameLabel)

$gameNameBox = New-Object System.Windows.Forms.TextBox
$gameNameBox.Size = New-Object System.Drawing.Size(540,25)
$gameNameBox.Location = New-Object System.Drawing.Point(27,174)
$gameNameBox.MaxLength = 64
$form.Controls.Add($gameNameBox)

$gameNameHelp = New-Object System.Windows.Forms.Label
$gameNameHelp.Text = 'Must exactly match the new game name in 7 Days to Die.'
$gameNameHelp.AutoSize = $true
$gameNameHelp.Location = New-Object System.Drawing.Point(27,201)
$gameNameHelp.ForeColor = [System.Drawing.Color]::FromArgb(90,90,90)
$form.Controls.Add($gameNameHelp)

$standardRadio = New-Object System.Windows.Forms.RadioButton
$standardRadio.Text = 'Standard'
$standardRadio.Checked = $true
$standardRadio.AutoSize = $true
$standardRadio.Location = New-Object System.Drawing.Point(30,220)
$form.Controls.Add($standardRadio)

$randomRadio = New-Object System.Windows.Forms.RadioButton
$randomRadio.Text = 'Random'
$randomRadio.AutoSize = $true
$randomRadio.Location = New-Object System.Drawing.Point(150,220)
$form.Controls.Add($randomRadio)

$biomeGroup = New-Object System.Windows.Forms.GroupBox
$biomeGroup.Text = 'Random starting biome'
$biomeGroup.Size = New-Object System.Drawing.Size(540,122)
$biomeGroup.Location = New-Object System.Drawing.Point(27,250)
$form.Controls.Add($biomeGroup)

$selectionLabel = New-Object System.Windows.Forms.Label
$selectionLabel.Text = 'Selection method'
$selectionLabel.AutoSize = $true
$selectionLabel.Location = New-Object System.Drawing.Point(12,23)
$biomeGroup.Controls.Add($selectionLabel)

$selectionCombo = New-Object System.Windows.Forms.ComboBox
$selectionCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$selectionCombo.Size = New-Object System.Drawing.Size(295,26)
$selectionCombo.Location = New-Object System.Drawing.Point(12,44)
[void]$selectionCombo.Items.AddRange([object[]]@(
    'Any biome (equal chance)',
    'Choose a biome',
    'Set custom weights'
))
$selectionCombo.SelectedIndex = 0
$biomeGroup.Controls.Add($selectionCombo)

$chosenCombo = New-Object System.Windows.Forms.ComboBox
$chosenCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$chosenCombo.Size = New-Object System.Drawing.Size(195,26)
$chosenCombo.Location = New-Object System.Drawing.Point(328,44)
[void]$chosenCombo.Items.AddRange([object[]]$biomes)
$chosenCombo.SelectedItem = 'Wasteland'
$biomeGroup.Controls.Add($chosenCombo)

$editWeights = New-Object System.Windows.Forms.Button
$editWeights.Text = 'Edit weights...'
$editWeights.Size = New-Object System.Drawing.Size(125,27)
$editWeights.Location = New-Object System.Drawing.Point(328,43)
$biomeGroup.Controls.Add($editWeights)

$selectionNote = New-Object System.Windows.Forms.Label
$selectionNote.AutoSize = $false
$selectionNote.Size = New-Object System.Drawing.Size(510,34)
$selectionNote.Location = New-Object System.Drawing.Point(12,79)
$selectionNote.ForeColor = [System.Drawing.Color]::FromArgb(70,70,70)
$biomeGroup.Controls.Add($selectionNote)

$biomeProtectCheck = New-Object System.Windows.Forms.CheckBox
$biomeProtectCheck.Text = 'Protect from hazards in starting biome'
$biomeProtectCheck.AutoSize = $true
$biomeProtectCheck.Location = New-Object System.Drawing.Point(30,384)
$form.Controls.Add($biomeProtectCheck)

$biomeNote = New-Object System.Windows.Forms.Label
$biomeNote.Text = "Optional. Protects this character from environmental hazards in the starting biome.`r`nHazards in other biomes remain active."
$biomeNote.AutoSize = $false
$biomeNote.Size = New-Object System.Drawing.Size(550,38)
$biomeNote.Location = New-Object System.Drawing.Point(27,410)
$biomeNote.ForeColor = [System.Drawing.Color]::FromArgb(70,70,70)
$form.Controls.Add($biomeNote)

$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Text = 'Apply Settings'
$applyButton.Size = New-Object System.Drawing.Size(120,38)
$applyButton.Location = New-Object System.Drawing.Point(27,462)
$form.Controls.Add($applyButton)

$launchButton = New-Object System.Windows.Forms.Button
$launchButton.Text = 'Launch Game'
$launchButton.Size = New-Object System.Drawing.Size(140,38)
$launchButton.Location = New-Object System.Drawing.Point(160,462)
$launchButton.Enabled = $false
$form.Controls.Add($launchButton)

$uninstallButton = New-Object System.Windows.Forms.Button
$uninstallButton.Text = 'Uninstall Mod'
$uninstallButton.Size = New-Object System.Drawing.Size(120,30)
$uninstallButton.Location = New-Object System.Drawing.Point(447,462)
$uninstallButton.Enabled = $false
$form.Controls.Add($uninstallButton)

$restoreButton = New-Object System.Windows.Forms.Button
$restoreButton.Text = 'Restore Previous'
$restoreButton.Size = New-Object System.Drawing.Size(115,30)
$restoreButton.Location = New-Object System.Drawing.Point(305,462)
$form.Controls.Add($restoreButton)

$details = New-Object System.Windows.Forms.Label
$details.Text = "Game folder:`r`n$gameRoot"
$details.AutoSize = $false
$details.Size = New-Object System.Drawing.Size(550,42)
$details.Location = New-Object System.Drawing.Point(27,522)
$form.Controls.Add($details)

$resultStatus = New-Object System.Windows.Forms.Label
$resultStatus.Text = 'Last start: no current result'
$resultStatus.AutoSize = $false
$resultStatus.Size = New-Object System.Drawing.Size(550,32)
$resultStatus.Location = New-Object System.Drawing.Point(27,562)
$form.Controls.Add($resultStatus)

function Get-HrsConfiguredOdds {
    $odds = [ordered]@{}
    foreach ($biome in $biomes) { $odds[$biome] = 0.0 }
    if (-not $randomRadio.Checked) { return $odds }
    if ($selectionCombo.SelectedIndex -eq 0) {
        foreach ($biome in $biomes) { $odds[$biome] = 100.0 / $biomes.Count }
    }
    elseif ($selectionCombo.SelectedIndex -eq 1) {
        $odds[[string]$chosenCombo.SelectedItem] = 100.0
    }
    else {
        $total = 0.0
        foreach ($biome in $biomes) { $total += [double]$weights[$biome] }
        if ($total -gt 0) {
            foreach ($biome in $biomes) { $odds[$biome] = 100.0 * [double]$weights[$biome] / $total }
        }
    }
    return $odds
}

function Update-HrsBiomePreview {
    $isRandom = $randomRadio.Checked
    $biomeGroup.Enabled = $isRandom
    $biomeProtectCheck.Enabled = $isRandom
    $chosenCombo.Visible = $isRandom -and $selectionCombo.SelectedIndex -eq 1
    $editWeights.Visible = $isRandom -and $selectionCombo.SelectedIndex -eq 2
    $total = 0
    foreach ($biome in $biomes) { $total += [int]$weights[$biome] }
    if (-not $isRandom) { $selectionNote.Text = 'Use the usual start for this exact new game.' }
    elseif ($selectionCombo.SelectedIndex -eq 0) { $selectionNote.Text = 'Each eligible biome has equal odds. If no safe start is available, use the normal start.' }
    elseif ($selectionCombo.SelectedIndex -eq 1) { $selectionNote.Text = "Try to start in $($chosenCombo.SelectedItem). If no safe start is available there, use the normal start." }
    else { $selectionNote.Text = 'Configured weights; absent biomes are excluded in game. A safe landing is not guaranteed.' }
    Update-HrsStatus

}

function Show-WeightEditor {
    param([string] $CapturePath = '', [ValidateSet('None','Cancel','Save')] [string] $TestAction='None')

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'Historical Random Start - biome weights'
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dialog.MinimizeBox = $false
    $dialog.MaximizeBox = $false
    $dialog.Size = New-Object System.Drawing.Size(460,390)
    $dialog.AutoScroll = $true
    $dialog.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Font

    $heading = New-Object System.Windows.Forms.Label
    $heading.Text = 'Set starting biome weights'
    $heading.Font = New-Object System.Drawing.Font('Segoe UI',13,[System.Drawing.FontStyle]::Bold)
    $heading.AutoSize = $true
    $heading.Location = New-Object System.Drawing.Point(20,18)
    $dialog.Controls.Add($heading)

    $help = New-Object System.Windows.Forms.Label
    $help.Text = 'Configured proportions. Absent biomes are excluded in game. Zero excludes a biome.'
    $help.AutoSize = $false
    $help.Size = New-Object System.Drawing.Size(380,34)
    $help.Location = New-Object System.Drawing.Point(21,49)
    $dialog.Controls.Add($help)

    $editControls = [ordered]@{}
    $chanceLabels = [ordered]@{}
    for ($i = 0; $i -lt $biomes.Count; $i++) {
        $biome = $biomes[$i]
        $y = 91 + ($i * 34)

        $label = New-Object System.Windows.Forms.Label
        $label.Text = $biome
        $label.AutoSize = $false
        $label.Size = New-Object System.Drawing.Size(112,24)
        $label.Location = New-Object System.Drawing.Point(22,$y)
        $dialog.Controls.Add($label)

        $numeric = New-Object System.Windows.Forms.NumericUpDown
        $numeric.Minimum = 0
        $numeric.Maximum = 100
        $numeric.Value = [int]$weights[$biome]
        $numeric.Size = New-Object System.Drawing.Size(75,25)
        $numeric.Location = New-Object System.Drawing.Point(139,$y)
        $numeric.AccessibleName = "$biome weight"
        $dialog.Controls.Add($numeric)
        $editControls[$biome] = $numeric

        $chance = New-Object System.Windows.Forms.Label
        $chance.AutoSize = $false
        $chance.Size = New-Object System.Drawing.Size(135,24)
        $chance.Location = New-Object System.Drawing.Point(236,$y)
        $dialog.Controls.Add($chance)
        $chanceLabels[$biome] = $chance
    }

    $save = New-Object System.Windows.Forms.Button
    $save.Text = 'Use Weights'
    $save.Size = New-Object System.Drawing.Size(110,32)
    $save.Location = New-Object System.Drawing.Point(180,276)
    $dialog.Controls.Add($save)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = 'Cancel'
    $cancel.Size = New-Object System.Drawing.Size(92,32)
    $cancel.Location = New-Object System.Drawing.Point(302,276)
    $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dialog.Controls.Add($cancel)
    $dialog.CancelButton = $cancel

    $updateEditor = {
        $total = 0.0
        foreach ($biome in $biomes) { $total += [double]$editControls[$biome].Value }
        foreach ($biome in $biomes) {
            $chance = if ($total -gt 0) { 100.0 * [double]$editControls[$biome].Value / $total } else { 0.0 }
            $chanceLabels[$biome].Text = ('{0:N1}% configured' -f $chance)
        }
        $save.Enabled = $total -gt 0
    }
    foreach ($biome in $biomes) { $editControls[$biome].Add_ValueChanged($updateEditor) }
    & $updateEditor

    $save.Add_Click({
        foreach ($biome in $biomes) { $weights[$biome] = [int]$editControls[$biome].Value }
        $dialog.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $dialog.Close()
    })

    if ($SmokeTest -and $TestAction -ne 'None') {
        $dialog.Show($form)
        [Windows.Forms.Application]::DoEvents()
        foreach($biome in $biomes){$editControls[$biome].Value=0}
        if($save.Enabled){throw 'EDITOR_ALL_ZERO_NOT_BLOCKED'}
        $editControls['Wasteland'].Value=100
        if(!$save.Enabled){throw 'EDITOR_POSITIVE_BLOCKED'}
        if($TestAction -eq 'Save'){$save.PerformClick()}else{$cancel.PerformClick()}
        $dialog.Dispose()
        Update-HrsBiomePreview
        return
    }
    if ($SmokeTest -and $UiScale -ne 1) { $dialog.Scale((New-Object Drawing.SizeF($UiScale,$UiScale))) }
    $dialog.Height=[Math]::Min($dialog.Height,([Windows.Forms.Screen]::FromControl($form).WorkingArea.Height-20))

    if (-not [string]::IsNullOrWhiteSpace($CapturePath)) {
        $dialog.Show($form)
        [System.Windows.Forms.Application]::DoEvents()
        $bitmap = New-Object System.Drawing.Bitmap($dialog.Width,$dialog.Height)
        try {
            $dialog.DrawToBitmap($bitmap,(New-Object System.Drawing.Rectangle(0,0,$dialog.Width,$dialog.Height)))
            $bitmap.Save($CapturePath,[System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally { $bitmap.Dispose() }
        $dialog.Close()
        $dialog.Dispose()
        return
    }

    [void]$dialog.ShowDialog($form)
    $dialog.Dispose()
    Update-HrsBiomePreview
}

$standardRadio.Add_CheckedChanged({ Update-HrsBiomePreview })
$randomRadio.Add_CheckedChanged({ Update-HrsBiomePreview })
$selectionCombo.Add_SelectedIndexChanged({ Update-HrsBiomePreview })
$chosenCombo.Add_SelectedIndexChanged({ Update-HrsBiomePreview })
$editWeights.Add_Click({ Show-WeightEditor })


$biomeIds=@(3,9,5,1,8)
function Get-HrsFormSelection {
    if (!$randomRadio.Checked -or $selectionCombo.SelectedIndex -eq 0) {return @{Selection='Any';ChosenBiome=0;Weights=@(0,0,0,0,0)}}
    if ($selectionCombo.SelectedIndex -eq 1) {return @{Selection='Chosen';ChosenBiome=$biomeIds[$chosenCombo.SelectedIndex];Weights=@(0,0,0,0,0)}}
    return @{Selection='Weighted';ChosenBiome=0;Weights=@($biomes | ForEach-Object { [int]$weights[$_] })}
}
function Get-HrsFormDescription {
    if (!$randomRadio.Checked) {return 'Standard start'}
    if ($selectionCombo.SelectedIndex -eq 0) {return 'Any biome (equal chance among eligible biomes)'}
    if ($selectionCombo.SelectedIndex -eq 1) {return "Try to start in $($chosenCombo.SelectedItem). If no safe start is available there, use the normal start."}
    return 'Configured weights: '+(($biomes | ForEach-Object {"$_ $($weights[$_])"}) -join ', ')
}
function Set-HrsFormFromPolicy {
    param([Parameter(Mandatory=$true)][psobject]$Policy)
    $gameNameBox.Text = $Policy.gameName
    $randomRadio.Checked = $Policy.mode -ne 'Standard'
    $standardRadio.Checked = !$randomRadio.Checked
    $biomeProtectCheck.Checked = $Policy.mode -eq 'RandomSafe'
    $savedArgs = Get-HrsSelectionArguments $Policy
    $selectionCombo.SelectedIndex = @('Any','Chosen','Weighted').IndexOf($savedArgs.Selection)
    if ($savedArgs.Selection -eq 'Chosen') {
        $chosenCombo.SelectedIndex = @($biomeIds).IndexOf([int]$savedArgs.ChosenBiome)
    }
    if ($savedArgs.Selection -eq 'Weighted') {
        for($i=0;$i -lt 5;$i++){ $weights[$biomes[$i]]=$savedArgs.Weights[$i] }
    }
    Update-HrsBiomePreview
}
function Initialize-HrsBiomeLayout {
    $form.SuspendLayout()
    $form.AutoScaleMode=[Windows.Forms.AutoScaleMode]::Font
    $form.AutoScroll=$true
    $form.Size=New-Object Drawing.Size(660,740)
    $form.MinimumSize=New-Object Drawing.Size(500,360)
    $form.Controls.Clear()
    $layout=New-Object Windows.Forms.TableLayoutPanel
    $layout.ColumnCount=1
    $layout.AutoSize=$true
    $layout.Dock='Top'
    $layout.Padding=New-Object Windows.Forms.Padding(20)
    $form.Controls.Add($layout)
    $modes=New-Object Windows.Forms.FlowLayoutPanel
    $modes.AutoSize=$true
    $modes.Controls.AddRange([Windows.Forms.Control[]]@($standardRadio,$randomRadio))
    $actions=New-Object Windows.Forms.FlowLayoutPanel
    $actions.AutoSize=$true
    $actions.Controls.AddRange([Windows.Forms.Control[]]@($applyButton,$launchButton,$restoreButton,$uninstallButton))
    $biomeGroup.Controls.Clear()
    $biomeGroup.AutoSize=$true
    $choices=New-Object Windows.Forms.TableLayoutPanel
    $choices.AutoSize=$true
    $choices.Dock='Top'
    $choices.ColumnCount=1
    $choices.Padding=New-Object Windows.Forms.Padding(8)
    $biomeGroup.Controls.Add($choices)
    foreach($c in @($selectionLabel,$selectionCombo,$chosenCombo,$editWeights,$selectionNote)) {
        $c.Dock='Top';$c.Margin=New-Object Windows.Forms.Padding(3,3,3,6)
        $choices.Controls.Add($c,0,$choices.RowCount);$choices.RowCount++
    }
    $gameNameBox.MaxLength=64
    $gameNameHelp.Text='Must exactly match the game name in 7 Days to Die. Changing settings will not trigger a second start for an already started character.'
    $row=0
    foreach($c in @($title,$version,$status,$gameLabel,$gameNameBox,$gameNameHelp,$modes,$biomeGroup,$biomeProtectCheck,$biomeNote,$actions,$resultStatus,$details)) {
        $c.Dock='Top';$c.Margin=New-Object Windows.Forms.Padding(3,3,3,8)
        if($c -is [Windows.Forms.Label]) { $c.AutoSize=$true; $c.MaximumSize=New-Object Drawing.Size(570,0) }
        $c.TabIndex=$row
        if(!$c.AccessibleName){$c.AccessibleName=$c.Text}
        $layout.Controls.Add($c,0,$row);$row++
    }
    $selectionNote.AutoSize=$true
    $selectionNote.MaximumSize=New-Object Drawing.Size(530,0)
    $gameNameBox.AccessibleName='Exact game name'
    $selectionCombo.AccessibleName='Biome selection method'
    $chosenCombo.AccessibleName='Chosen starting biome'
    $form.ResumeLayout($true)
}

function Update-HrsStatus {
    $process = Get-HrsProcessState

    if ($process.Game -ne 'Closed') {
        $status.Text = 'Game is running - changes unavailable'
        $applyButton.Enabled = $false
        $launchButton.Enabled = $false
        $uninstallButton.Enabled = $false
        $restoreButton.Enabled = $false
        return
    }

    $total=0; foreach($biome in $biomes){$total += $weights[$biome]}
    $applyButton.Enabled = (!$randomRadio.Checked -or $selectionCombo.SelectedIndex -ne 2 -or $total -gt 0)
    $launchButton.Enabled = ($process.Steam -eq 'Running')
    $uninstallButton.Enabled = $true
    $restoreButton.Enabled = $true

    try {
        $paths = Get-HrsBridgePaths -GameRoot $gameRoot

        if (Test-Path -LiteralPath $paths.BridgeRoot -PathType Container) {
            $status.Text = 'Ready - choose Standard or Random'
        }
        elseif ($useDevCandidate) {
            $status.Text = 'DEV candidate build ready - choose Standard or Random'
        }
        elseif (Test-Path -LiteralPath $verifiedArtifactsRoot -PathType Container) {
            $status.Text = 'Verified QA payload ready - choose Standard or Random'
        }
        else {
            $status.Text = 'Setup requires validation - release bridge is not installed'
        }
    }
    catch {
        $status.Text = 'Setup requires validation'
        $applyButton.Enabled = $false
    }
}

function Update-HrsResultStatus {
    try {
        $currentResult = Get-HrsCurrentResultState -GameRoot $gameRoot
        if ($currentResult.State -eq 'Current') {
            $resultStatus.Text = "Last start for current settings: $($currentResult.Result.outcome) / $($currentResult.Result.reason)"
        }
        elseif ($currentResult.State -eq 'Stale') {
            $resultStatus.Text = 'Last start belongs to earlier settings; no result for the current revision'
        }
        else { $resultStatus.Text = 'Last start: no result for the current settings' }
    }
    catch { $resultStatus.Text = 'Last start result unavailable or invalid' }
}

function Get-HrsGameBuildNotice {
    $assemblyPath = Join-Path $gameRoot '7DaysToDie_Data\Managed\Assembly-CSharp.dll'
    if (-not [IO.File]::Exists($assemblyPath)) {
        throw 'Game compatibility check failed: Assembly-CSharp.dll was not found.'
    }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $assemblyPath).Hash -cne $verifiedAssemblyCSharpSha256) {
        return $unverifiedGameBuildMessage
    }
    # The full-file fingerprint identifies the tested assembly, including its MVID,
    # without loading/caching or locking game DLLs in the manager process.
    return ''
}

function Initialize-HrsManagerStorage {
    $probe = $null
    try {
        $statePaths = Initialize-HrsManagerState -ManagerRoot $managerRoot
        $probe = Join-Path $statePaths.StateRoot ('.write-check-' + [guid]::NewGuid().ToString('N'))
        $stream = [IO.File]::Open($probe, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $stream.Dispose()
        [IO.File]::Delete($probe)
        $probe = $null
    }
    catch {
        throw 'HRS cannot save recovery settings in this folder. Move the entire extracted HRS folder to a writable local folder outside OneDrive or other synced or linked folders, reopen START.bat, and apply again. No game files were changed.'
    }
    finally {
        if ($null -ne $probe -and [IO.File]::Exists($probe)) {
            try { [IO.File]::Delete($probe) } catch { }
        }
    }
}

$applyButton.Add_Click({
    $applyConfirmed = $false
    $applySucceeded = $false
    $successText = ''
    try {
        $process = Get-HrsProcessState
        if ($process.Game -ne 'Closed') {
            throw 'Game is running. Close it before applying settings.'
        }

        $gameName = $gameNameBox.Text

        $nameCheck = Test-HrsExactGameName -GameName $gameName
        if (-not $nameCheck.Valid) {
            throw "New game name is invalid: $($nameCheck.Reason)"
        }

        $paths = Get-HrsBridgePaths -GameRoot $gameRoot
        $current = Read-HrsConfiguredPolicy -GameRoot $gameRoot
        $revision = [UInt64]1
        if ($null -ne $current) {
            if ($current.revision -eq [UInt64]::MaxValue) { throw 'Policy revision is exhausted.' }
            $revision = [UInt64]$current.revision + 1
        }
        $mode = if (!$randomRadio.Checked) { 'Standard' } elseif ($biomeProtectCheck.Checked) { 'RandomSafe' } else { 'Random' }
        $selectionArgs = Get-HrsFormSelection
        $policy = New-HrsPolicy -Revision $revision -GameName $gameName -Mode $mode @selectionArgs
        $description = Get-HrsFormDescription
        $protection = if ($mode -eq 'RandomSafe') { 'On' } else { 'Off' }
        $gameBuildNotice = Get-HrsGameBuildNotice
        $confirmationText = "New game name: $gameName`r`n$description`r`nStarting-biome protection: $protection`r`n`r`n" +
            "If no safe start is available, use the normal start.`r`nChanging settings does not give an already started character another HRS start.`r`nThe game will not launch automatically.`r`n$gameBuildNotice"
        $confirm = [Windows.Forms.MessageBox]::Show($form,
            $confirmationText,
            'Confirm Historical Random Start',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)
        if ($confirm -ne [Windows.Forms.DialogResult]::Yes) {
            $status.Text='Settings canceled - no change made'
            return
        }
        $applyConfirmed = $true
        $launchButton.Enabled = $false
        Initialize-HrsManagerStorage

        if (-not $useDevCandidate) {
            $verifiedDll = Join-Path $verifiedPayloadRoot 'd0163.dll'
            $verifiedModInfo = Join-Path $verifiedPayloadRoot 'ModInfo.xml'
            $assemblyCSharpPath = Join-Path $gameRoot '7DaysToDie_Data\Managed\Assembly-CSharp.dll'

            if (-not (Test-Path -LiteralPath $verifiedDll -PathType Leaf) -or
                -not (Test-Path -LiteralPath $verifiedModInfo -PathType Leaf)) {
                throw 'Verified QA payload is incomplete. Redownload the QA package.'
            }

            if (-not (Test-Path -LiteralPath $assemblyCSharpPath -PathType Leaf)) {
                throw 'Game compatibility check failed: Assembly-CSharp.dll was not found.'
            }

            $dllHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $verifiedDll).Hash

            if (-not [string]::Equals(
                $dllHash,
                $verifiedRuntimeSha256,
                [System.StringComparison]::Ordinal
            )) {
                throw 'Verified QA runtime hash mismatch. Do not install; redownload the QA package.'
            }

            $modInfoHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $verifiedModInfo).Hash
            if (-not [string]::Equals(
                $modInfoHash,
                $verifiedModInfoSha256,
                [System.StringComparison]::Ordinal
            )) {
                throw 'Verified QA ModInfo hash mismatch. Do not install; redownload the QA package.'
            }

            try {
                [xml]$modInfo = [System.IO.File]::ReadAllText($verifiedModInfo)

                $nameNode = @($modInfo.DocumentElement.ChildNodes | Where-Object {
                    [string]::Equals($_.Name, 'Name', [System.StringComparison]::Ordinal)
                }) | Select-Object -First 1

                $versionNode = @($modInfo.DocumentElement.ChildNodes | Where-Object {
                    [string]::Equals($_.Name, 'Version', [System.StringComparison]::Ordinal)
                }) | Select-Object -First 1

                if ($null -eq $nameNode -or $null -eq $versionNode) {
                    throw 'required identity node missing'
                }

                $modName = [string]$nameNode.GetAttribute('value')
                $modVersion = [string]$versionNode.GetAttribute('value')

                if (-not [string]::Equals(
                    $modName,
                    'BitWrecked_HistoricalRandomStart',
                    [System.StringComparison]::Ordinal
                )) {
                    throw 'mod identity mismatch'
                }

                if (-not [string]::Equals(
                    $modVersion,
                    '1.2.5',
                    [System.StringComparison]::Ordinal
                )) {
                    throw 'mod version mismatch'
                }
            }
            catch {
                throw 'Verified QA ModInfo identity validation failed. Do not install; redownload the QA package.'
            }

            $payloadRoot = $verifiedPayloadRoot
        }
        else {
            $buildScript = Join-Path $managerRoot 'src\runtime\p0143.ps1'

            if (-not (Test-Path -LiteralPath $buildScript -PathType Leaf)) {
                throw 'Alpha Core build script was not found.'
            }

            $status.Text = 'Building Historical Random Start release...'
            $form.Refresh()

            $buildRecord = & $buildScript -GameRoot $gameRoot

            if ($null -eq $buildRecord -or [string]::IsNullOrWhiteSpace([string]$buildRecord.candidateRoot)) {
                throw 'Build did not return a candidate release.'
            }

            $payloadRoot = Join-Path $buildRecord.candidateRoot 'mod'
        }

        $status.Text = 'Applying Historical Random Start settings...'
        $form.Refresh()
        $applied = Invoke-HrsInstallAndApply `
            -GameRoot $gameRoot `
            -PayloadRoot $payloadRoot `
            -Policy $policy `
            -ReleaseVersion '1.2.5'
        $script:appliedManifest = $applied.Manifest
        $script:appliedPayloadRoot = $payloadRoot
        $historyError = ''
        if ($null -ne $current -and $current.schema -ceq 'hrs-policy/v1') {
            try {
                [void](Add-HrsRecoveryAttempt -ManagerRoot $managerRoot -Outcome Succeeded `
                    -Reason LEGACY_BASELINE_CAPTURED -Policy $current -KnownGood)
            } catch { $historyError = $_.Exception.Message }
        }
        try {
            [void](Add-HrsRecoveryAttempt -ManagerRoot $managerRoot -Outcome Succeeded -Reason APPLY_SUCCEEDED -Policy $applied.Policy -KnownGood)
        } catch { $historyError = $_.Exception.Message }

        if ($mode -ne 'Standard') {
            $suffix = if ($mode -eq 'RandomSafe') { ' - Random start, starting-biome protection ON' } else { ' - Random start' }
            $status.Text = "Ready for $gameName$suffix"
        }
        else {
            $status.Text = "Ready for $gameName - Standard start"
        }
        if ($gameBuildNotice) { $status.Text += ' - untested game build' }
        if ($historyError) {
            $status.Text = "Settings applied for $gameName; recovery history unavailable: $historyError"
        }
        Update-HrsResultStatus
        $traderSessionNotice = if ($mode -eq 'Standard') { '' } else {
            "Do not log out until your first trader is assigned. Wait for the Journey to Settlement trader marker. Leaving earlier may send the quest to Pine Forest when you return.`r`n`r`n"
        }
        $historyNotice = if ($historyError) { "Recovery history unavailable: $historyError`r`n`r`n" } else { '' }
        $successText = "Settings applied and verified for: $gameName`r`n$description`r`nStarting-biome protection: $protection`r`n`r`n" +
            "$traderSessionNotice$historyNotice" +
            'Click OK, then use Launch Game when Steam is running.'
        $applySucceeded = $true
    }
    catch {
        $applyError = $_.Exception.Message
        if ($applyConfirmed) {
            try {
                [void](Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action Apply -Outcome Failed `
                    -Reason APPLY_FAILED -GameName $gameName -Revision $revision -Mode $mode)
            } catch { }
        }
        $status.Text = "Settings blocked: $applyError"
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            $applyError,
            'Historical Random Start',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
    if ($applySucceeded) {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            $successText,
            'Historical Random Start - Settings Applied',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        $processAfterApply = Get-HrsProcessState
        $launchButton.Enabled = ($processAfterApply.Game -eq 'Closed' -and $processAfterApply.Steam -eq 'Running')
    }
})

$randomRadio.Add_CheckedChanged({
    $biomeProtectCheck.Enabled = $randomRadio.Checked
})

$launchButton.Add_Click({
    try {
        $configuredPolicy = Read-HrsConfiguredPolicy -GameRoot $gameRoot
        if ($null -eq $configuredPolicy -or $configuredPolicy.schema -cne 'hrs-policy/v2') {
            throw 'Apply Settings before launching. Enter the exact game name, choose your settings, then click Apply Settings.'
        }
        if ($useDevCandidate) {
            if ($null -eq $script:appliedManifest) {
                throw 'Apply Settings in this DEV manager session before launching.'
            }
            $launchManifest = $script:appliedManifest
        }
        else {
            $verifiedDll = Join-Path $verifiedPayloadRoot 'd0163.dll'
            $verifiedModInfo = Join-Path $verifiedPayloadRoot 'ModInfo.xml'
            if (-not (Test-Path -LiteralPath $verifiedDll -PathType Leaf) -or
                -not (Test-Path -LiteralPath $verifiedModInfo -PathType Leaf) -or
                (Get-FileHash -Algorithm SHA256 -LiteralPath $verifiedDll).Hash -cne $verifiedRuntimeSha256 -or
                (Get-FileHash -Algorithm SHA256 -LiteralPath $verifiedModInfo).Hash -cne $verifiedModInfoSha256) {
                throw 'Verified QA payload changed. Reinstall from the QA package.'
            }
            $launchManifest = New-HrsDeploymentManifest -PayloadRoot $verifiedPayloadRoot -ReleaseVersion '1.2.5'
        }
        $launch = Test-HrsLaunchInstallation `
            -GameRoot $gameRoot `
            -Manifest $launchManifest `
            -ProcessState (Get-HrsProcessState)
        $gameBuildNotice = Get-HrsGameBuildNotice
        $status.Text = if ($gameBuildNotice) { 'Launching game - untested build; HRS will attempt compatible hooks.' } else { 'Launching game...' }
        Start-Process -FilePath $launch.Executable -WorkingDirectory $launch.WorkingDirectory -WindowStyle Normal
    }
    catch {
        $status.Text = "Launch blocked: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            $_.Exception.Message,
            'Historical Random Start',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
})

$restoreButton.Add_Click({
    try {
        $process = Get-HrsProcessState
        if ($process.Game -ne 'Closed') { throw 'Close 7 Days to Die before restoring settings.' }
        $current = Read-HrsConfiguredPolicy -GameRoot $gameRoot
        if ($null -eq $current -or $current.schema -cne 'hrs-policy/v2') {
            throw 'Apply Settings with this manager before restoring saved settings.'
        }
        $view = Get-HrsRecoveryView -ManagerRoot $managerRoot
        $plan = $null
        foreach ($item in @($view.Items | Where-Object {
            $_.Kind -ceq 'Attempt' -and $_.Available -and $_.Outcome -ceq 'Succeeded'
        })) {
            $candidate = Get-HrsRestorePlan -ManagerRoot $managerRoot -AttemptId $item.Id -CurrentPolicy $current
            if ($candidate.Valid -and -not $candidate.NoWrite -and $candidate.Diff.Changed) {
                $plan = $candidate
                break
            }
        }
        if ($null -eq $plan) { throw 'No earlier different settings are available to restore.' }
        $selection = Get-HrsSelectionArguments -Policy $plan.Policy
        $restoreConfirm = [Windows.Forms.MessageBox]::Show($form,
            "Restore the previous saved settings?`r`n`r`nGame: $($plan.Policy.gameName)`r`nMode: $($plan.Policy.mode)`r`nBiome method: $($selection.Selection)`r`nNew revision: $($plan.Policy.revision)`r`n`r`nThis does not restart an existing character or launch the game.",
            'Confirm Settings Restore',[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question)
        if ($restoreConfirm -ne [Windows.Forms.DialogResult]::Yes) {
            $status.Text = 'Restore canceled - no change made'
            return
        }
        Initialize-HrsManagerStorage
        if ($useDevCandidate) {
            if ([string]::IsNullOrWhiteSpace([string]$script:appliedPayloadRoot)) {
                throw 'Apply Settings in this DEV manager session before restoring.'
            }
            $restorePayload = $script:appliedPayloadRoot
        }
        else {
            $dll = Join-Path $verifiedPayloadRoot 'd0163.dll'
            $modInfo = Join-Path $verifiedPayloadRoot 'ModInfo.xml'
            if (-not (Test-Path -LiteralPath $dll -PathType Leaf) -or
                -not (Test-Path -LiteralPath $modInfo -PathType Leaf) -or
                (Get-FileHash -Algorithm SHA256 -LiteralPath $dll).Hash -cne $verifiedRuntimeSha256 -or
                (Get-FileHash -Algorithm SHA256 -LiteralPath $modInfo).Hash -cne $verifiedModInfoSha256) {
                throw 'Verified QA payload changed. Restore blocked.'
            }
            $restorePayload = $verifiedPayloadRoot
        }
        $restored = Invoke-HrsInstallAndApply -GameRoot $gameRoot -PayloadRoot $restorePayload -Policy $plan.Policy -ReleaseVersion '1.2.5'
        $script:appliedManifest = $restored.Manifest
        $script:appliedPayloadRoot = $restorePayload
        Set-HrsFormFromPolicy -Policy $restored.Policy
        try {
            [void](Add-HrsRecoveryAttempt -ManagerRoot $managerRoot -Outcome Succeeded -Reason RESTORE_SUCCEEDED -Policy $restored.Policy -KnownGood)
            $status.Text = "Restored settings for $($restored.Policy.gameName)"
        }
        catch { $status.Text = "Settings restored; recovery history unavailable: $($_.Exception.Message)" }
        Update-HrsResultStatus
    }
    catch {
        $status.Text = "Restore blocked: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show($form,$_.Exception.Message,
            'Historical Random Start',[Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    }
})

$uninstallButton.Add_Click({
    try {
        $process = Get-HrsProcessState

        if ($process.Game -ne 'Closed') {
            throw 'Close 7 Days to Die before uninstalling the mod.'
        }

        $ownership = Test-HrsRemovalOwnership -GameRoot $gameRoot

        if (-not $ownership.Valid) {
            throw "Uninstall blocked: $($ownership.Reason)"
        }

        if ($ownership.State -eq 'NotInstalled') {
            $status.Text = 'Historical Random Start is not installed'
            return
        }

        if ($ownership.State -ne 'Owned') {
            throw 'Uninstall blocked because the installed files could not be confirmed as Historical Random Start.'
        }

        $confirm = [System.Windows.Forms.MessageBox]::Show(
            $form,
            "Uninstall Historical Random Start from this game?`r`n`r`nYour saved games and game progress will not be deleted.",
            'Confirm Uninstall',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
            $status.Text = 'Uninstall canceled - no change made'
            return
        }

        $manifest = New-HrsDeploymentManifest `
            -PayloadRoot $verifiedPayloadRoot `
            -ReleaseVersion '1.2.5'

        $result = Invoke-HrsRemoveFromGame `
            -GameRoot $gameRoot `
            -Manifest $manifest `
            -ProcessState $process `
            -Confirmed

        if (-not $result.Removed) {
            throw 'Uninstall did not complete.'
        }

        Update-HrsStatus
        $status.Text = 'Historical Random Start uninstalled'
        Update-HrsResultStatus
    }
    catch {
        $status.Text = "Uninstall blocked: $($_.Exception.Message)"

        [System.Windows.Forms.MessageBox]::Show(
            $form,
            $_.Exception.Message,
            'Historical Random Start',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
})
$form.Add_Shown({
    Update-HrsStatus
    try {
        $saved = Read-HrsConfiguredPolicy -GameRoot $gameRoot
        if ($null -ne $saved) {
            Set-HrsFormFromPolicy -Policy $saved
        }
        Update-HrsBiomePreview
        Update-HrsResultStatus
    } catch { $status.Text="Settings blocked: $($_.Exception.Message)"; $applyButton.Enabled=$false }
    $available=[Windows.Forms.Screen]::FromControl($form).WorkingArea
    $form.Height=[Math]::Min($form.Height,$available.Height-20)
    $gameNameBox.Focus()
})

Initialize-HrsBiomeLayout
if ($SmokeTest) {
    $form.Show()
    [Windows.Forms.Application]::DoEvents()
    if ($UiScale -ne 1) { $form.Scale((New-Object Drawing.SizeF($UiScale,$UiScale))) }
    $saved=Read-HrsConfiguredPolicy -GameRoot $gameRoot
    if($null -ne $saved) {
        if($gameNameBox.Text -cne $saved.gameName){throw 'FORM_SAVED_NAME_FAILED'}
        $expected=Get-HrsSelectionArguments $saved
        if((Get-HrsFormSelection).Selection -cne $expected.Selection){throw 'FORM_SAVED_METHOD_FAILED'}
    }
    $before=@($biomes | ForEach-Object {$weights[$_]})
    Show-WeightEditor -TestAction Cancel
    if((@($biomes | ForEach-Object {$weights[$_]}) -join ',') -cne ($before -join ',')){throw 'EDITOR_CANCEL_CHANGED_WEIGHTS'}
    Show-WeightEditor -TestAction Save
    if($weights['Wasteland'] -ne 100 -or $weights['Forest'] -ne 0){throw 'EDITOR_SAVE_FAILED'}
    for($i=0;$i -lt 5;$i++){$weights[$biomes[$i]]=$before[$i]}
    $form.Height=[Math]::Min($form.Height,([Windows.Forms.Screen]::FromControl($form).WorkingArea.Height-20))
    $randomRadio.Checked=$true
    $selectionCombo.SelectedIndex=1
    $chosenCombo.SelectedItem='Snow'
    if ((Get-HrsFormSelection).ChosenBiome -ne 1) { throw 'FORM_CHOSEN_FAILED' }
    $selectionCombo.SelectedIndex=2
    $args=Get-HrsFormSelection
    if ($args.Weights.Count -ne 5 -or $args.Selection -cne 'Weighted') { throw 'FORM_WEIGHTS_FAILED' }
    $selectionCombo.SelectedIndex=0
    $selectionCombo.SelectedIndex=2
    if ((Get-HrsFormSelection).Weights[4] -ne $weights['Wasteland']) {throw 'FORM_RETAIN_WEIGHTS_FAILED'}
    if ($ScreenshotPath) {
        $bmp=New-Object Drawing.Bitmap($form.Width,$form.Height)
        try { $form.DrawToBitmap($bmp,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bmp.Save($ScreenshotPath) } finally {$bmp.Dispose()}
        Show-WeightEditor -CapturePath ($ScreenshotPath -replace '\.png$','-weights.png')
    }
    $form.Dispose()
    'PASS: real manager controls and selection binding (no install/launch)'
    exit 0
}
[void]$form.ShowDialog()
