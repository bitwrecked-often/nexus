param([switch] $SmokeTest, [string] $ScreenshotPath)

# Standalone UX prototype. It does not read or write game or mod files.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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
$version.Text = 'Release | 1.2.4 QA - biome UX prototype'
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

$details = New-Object System.Windows.Forms.Label
$details.Text = "Game folder:`r`nPrototype preview - no game or mod files will be changed"
$details.AutoSize = $false
$details.Size = New-Object System.Drawing.Size(550,42)
$details.Location = New-Object System.Drawing.Point(27,522)
$form.Controls.Add($details)

function Get-PrototypeOdds {
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

function Update-PrototypePreview {
    $isRandom = $randomRadio.Checked
    $biomeGroup.Enabled = $isRandom
    $biomeProtectCheck.Enabled = $isRandom
    $chosenCombo.Visible = $isRandom -and $selectionCombo.SelectedIndex -eq 1
    $editWeights.Visible = $isRandom -and $selectionCombo.SelectedIndex -eq 2
    $total = 0
    foreach ($biome in $biomes) { $total += [int]$weights[$biome] }
    $applyButton.Enabled = (-not $isRandom) -or $selectionCombo.SelectedIndex -ne 2 -or $total -gt 0

    if (-not $isRandom) {
        $selectionNote.Text = 'Use the usual start for this exact new game.'
        $status.Text = 'Prototype preview - Standard start'
    }
    elseif ($selectionCombo.SelectedIndex -eq 0) {
        $selectionNote.Text = 'Each available biome has the same chance. The game still checks for a safe placed POI.'
        $status.Text = 'Prototype preview - Random, any available biome'
    }
    elseif ($selectionCombo.SelectedIndex -eq 1) {
        $selectionNote.Text = 'A missing or unsafe destination keeps the ordinary start.'
        $status.Text = "Prototype preview - Random, $($chosenCombo.SelectedItem)"
    }
    else {
        $odds = Get-PrototypeOdds
        $parts = foreach ($biome in $biomes) {
            '{0} {1:N0}%' -f $biome, [double]$odds[$biome]
        }
        $selectionNote.Text = $parts -join '  |  '
        $status.Text = if ($total -gt 0) {
            'Prototype preview - Random, custom biome weights'
        } else {
            'Set at least one biome weight above zero'
        }
    }
}

function Show-WeightEditor {
    param([string] $CapturePath = '')

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'Historical Random Start - biome weights'
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dialog.MinimizeBox = $false
    $dialog.MaximizeBox = $false
    $dialog.Size = New-Object System.Drawing.Size(430,355)

    $heading = New-Object System.Windows.Forms.Label
    $heading.Text = 'Set starting biome weights'
    $heading.Font = New-Object System.Drawing.Font('Segoe UI',13,[System.Drawing.FontStyle]::Bold)
    $heading.AutoSize = $true
    $heading.Location = New-Object System.Drawing.Point(20,18)
    $dialog.Controls.Add($heading)

    $help = New-Object System.Windows.Forms.Label
    $help.Text = 'Higher weight means a higher chance. Zero excludes a biome.'
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
            $chanceLabels[$biome].Text = ('{0:N1}% chance' -f $chance)
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
    Update-PrototypePreview
}

$standardRadio.Add_CheckedChanged({ Update-PrototypePreview })
$randomRadio.Add_CheckedChanged({ Update-PrototypePreview })
$selectionCombo.Add_SelectedIndexChanged({ Update-PrototypePreview })
$chosenCombo.Add_SelectedIndexChanged({ Update-PrototypePreview })
$editWeights.Add_Click({ Show-WeightEditor })

$applyButton.Add_Click({
    $name = $gameNameBox.Text
    if ([string]::IsNullOrWhiteSpace($name) -or $name -ne $name.Trim()) {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            'Enter the exact new Game Name without spaces at either end.',
            'Historical Random Start',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        $gameNameBox.Focus()
        return
    }

    $modeLabel = if (-not $randomRadio.Checked) { 'Standard start' }
        elseif ($selectionCombo.SelectedIndex -eq 0) { 'Random start - any available biome (equal chance)' }
        elseif ($selectionCombo.SelectedIndex -eq 1) { "Random start - $($chosenCombo.SelectedItem)" }
        else {
            $odds = Get-PrototypeOdds
            'Random start - custom weights: ' + (($biomes | ForEach-Object {
                '{0} {1:N1}%' -f $_, [double]$odds[$_]
            }) -join ', ')
        }
    $protection = if ($randomRadio.Checked -and $biomeProtectCheck.Checked) { 'On' } else { 'Off' }
    $message = "$modeLabel`r`nStarting-biome protection: $protection`r`n`r`nNew game name: $name`r`n`r`nPrototype only. No game files or settings will change."
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        $form,
        $message,
        'Confirm Historical Random Start',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    $status.Text = if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
        'Prototype confirmed - no changes made'
    } else {
        'Prototype canceled - no changes made'
    }
})

Update-PrototypePreview

if ($SmokeTest) {
    $form.Show()
    [System.Windows.Forms.Application]::DoEvents()
    if ($biomeGroup.Enabled) { throw 'Standard must disable biome controls.' }
    $randomRadio.Checked = $true
    if (-not $biomeGroup.Enabled -or -not $biomeProtectCheck.Enabled) {
        throw 'Random must enable biome controls and hazard protection.'
    }
    $selectionCombo.SelectedIndex = 1
    $chosenCombo.SelectedItem = 'Snow'
    if (-not $chosenCombo.Visible -or $editWeights.Visible) { throw 'Chosen biome controls are wrong.' }
    $odds = Get-PrototypeOdds
    if ($odds['Snow'] -ne 100.0 -or $odds['Forest'] -ne 0.0) { throw 'Chosen biome odds are wrong.' }
    $selectionCombo.SelectedIndex = 2
    if (-not $editWeights.Visible -or $chosenCombo.Visible) { throw 'Custom weight controls are wrong.' }
    foreach ($biome in $biomes) { $weights[$biome] = 0 }
    Update-PrototypePreview
    if ($applyButton.Enabled) { throw 'All-zero weights must be blocked.' }
    $weights['Wasteland'] = 100
    Update-PrototypePreview
    if (-not $applyButton.Enabled) { throw 'A positive weight must enable preview.' }
    $odds = Get-PrototypeOdds
    if ($odds['Wasteland'] -ne 100.0 -or $odds['Snow'] -ne 0.0) { throw 'Weighted odds are wrong.' }

    if (-not [string]::IsNullOrWhiteSpace($ScreenshotPath)) {
        $bitmap = New-Object System.Drawing.Bitmap($form.Width,$form.Height)
        try {
            $form.DrawToBitmap($bitmap,(New-Object System.Drawing.Rectangle(0,0,$form.Width,$form.Height)))
            $bitmap.Save($ScreenshotPath,[System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally { $bitmap.Dispose() }
        $editorPath = [System.IO.Path]::Combine(
            [System.IO.Path]::GetDirectoryName($ScreenshotPath),
            [System.IO.Path]::GetFileNameWithoutExtension($ScreenshotPath) + '-weights.png'
        )
        Show-WeightEditor -CapturePath $editorPath
    }
    $form.Dispose()
    Write-Output 'Biome selection UX smoke test passed.'
    exit 0
}

$form.Add_Shown({
    $availableHeight = [System.Windows.Forms.Screen]::FromControl($form).WorkingArea.Height - 20
    if ($form.Height -gt $availableHeight) { $form.Height = [Math]::Max(430,$availableHeight) }
    $gameNameBox.Focus()
})
[void]$form.ShowDialog()
$form.Dispose()
