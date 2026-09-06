# Bit Wrecked Historical Random Start - Alpha 6 Method player preview.
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This uses the proven Bit Wrecked blank framework layout. It has no runtime
# helper, gameplay payload, policy writer, or install/remove capability.

param(
    [switch]$SmokeTest,
    [switch]$PreviewWorkflowTestHost
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $packageRoot
$script:PackageVersion = '0.0.7-preview'
$script:Alpha6EvidenceUrl = 'https://7daystodie.com/?p=1150'
$script:HowItWorksCopy = "This mod has two start types:`r`n`r`n  - Standard - use the game's normal start`r`n  - Random - begin at a different authored start location`r`n`r`nRandom keeps dangerous-biome hazards on unless you choose one safeguard:`r`n  - Starting biome only - turn off the hazard where you arrive`r`n  - All dangerous biomes - turn off all four hazard families`r`n`r`nIf your starting biome has no dangerous hazard, nothing is turned off. Zombies, falls, and POI danger stay on.`r`n`r`nAfter a Random start, your opening trader quest points to the nearest trader."
$script:PersistentLogEnabled = $false
$script:PersistentLogPath = ''
$script:IsUpdatingPersistentLog = $false
$script:IsUpdatingRandomSafeguardScope = $false
$script:AppliedPreviewSettings = $null
$script:FolderValidationState = 'Required'
$script:ValidatedGameRootKey = ''
$script:CurrentPreviewState = 'FolderCheckRequired'
$script:GameRootValidator = $null
$script:PreviewDialogHandler = $null
$script:LogoImageToDispose = $null
$script:RoundedControls = New-Object System.Collections.ArrayList

function New-Color {
    param([int]$R, [int]$G, [int]$B)

    return [System.Drawing.Color]::FromArgb($R, $G, $B)
}

function New-RoundedPath {
    param(
        [System.Drawing.Rectangle]$Bounds,
        [int]$Radius
    )

    $width = [Math]::Max(1, $Bounds.Width)
    $height = [Math]::Max(1, $Bounds.Height)
    $safeBounds = New-Object System.Drawing.Rectangle($Bounds.X, $Bounds.Y, $width, $height)
    $safeRadius = [Math]::Max(0, [Math]::Min($Radius, [Math]::Floor([Math]::Min($width, $height) / 2)))
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath

    if ($safeRadius -lt 1) {
        $path.AddRectangle($safeBounds)
        return $path
    }

    $diameter = [Math]::Max(1, $safeRadius * 2)
    $path.AddArc($safeBounds.X, $safeBounds.Y, $diameter, $diameter, 180, 90)
    $path.AddArc(($safeBounds.Right - $diameter), $safeBounds.Y, $diameter, $diameter, 270, 90)
    $path.AddArc(($safeBounds.Right - $diameter), ($safeBounds.Bottom - $diameter), $diameter, $diameter, 0, 90)
    $path.AddArc($safeBounds.X, ($safeBounds.Bottom - $diameter), $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Set-RoundedRegion {
    param(
        [System.Windows.Forms.Control]$Control,
        [int]$Radius
    )

    if ($Control.Width -lt 1 -or $Control.Height -lt 1) {
        return
    }

    $bounds = New-Object System.Drawing.Rectangle(0, 0, $Control.Width, $Control.Height)
    $path = New-RoundedPath -Bounds $bounds -Radius $Radius
    try {
        $Control.Region = New-Object System.Drawing.Region($path)
    }
    finally {
        $path.Dispose()
    }
}

function Enable-RoundedBorder {
    param(
        [System.Windows.Forms.Control]$Control,
        [int]$Radius,
        [System.Drawing.Color]$BorderColor
    )

    $Control.Tag = @{ Radius = $Radius; BorderColor = $BorderColor }
    Set-RoundedRegion -Control $Control -Radius $Radius
    [void]$script:RoundedControls.Add($Control)
    $Control.Add_Resize({
        param($sender, $eventArgs)
        Set-RoundedRegion -Control $sender -Radius ([int]$sender.Tag.Radius)
    })
    $Control.Add_Paint({
        param($sender, $event)
        if ($sender.Width -lt 2 -or $sender.Height -lt 2) {
            return
        }

        $event.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $bounds = New-Object System.Drawing.Rectangle(0, 0, ($sender.Width - 1), ($sender.Height - 1))
        $path = New-RoundedPath -Bounds $bounds -Radius ([int]$sender.Tag.Radius)
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]$sender.Tag.BorderColor, 1.0)
        try {
            $event.Graphics.DrawPath($pen, $path)
        }
        finally {
            $pen.Dispose()
            $path.Dispose()
        }
    })
}

function Get-DefaultGameRoot {
    $default = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\7 Days To Die'
    if (Test-Path -LiteralPath (Join-Path $default '7DaysToDie.exe') -PathType Leaf) {
        return $default
    }
    return ''
}

function Get-PreviewGameRootKey {
    param([string]$GameRoot)

    if ([string]::IsNullOrWhiteSpace($GameRoot)) {
        return ''
    }

    $candidate = $GameRoot.Trim()
    try {
        $fullPath = [System.IO.Path]::GetFullPath($candidate)
        $pathRoot = [System.IO.Path]::GetPathRoot($fullPath)
        if ($fullPath.Length -gt $pathRoot.Length) {
            return $fullPath.TrimEnd([char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar))
        }
        return $fullPath
    }
    catch {
        return $candidate
    }
}

function Test-GameRoot {
    param([string]$GameRoot)

    if ([string]::IsNullOrWhiteSpace($GameRoot)) {
        return $false
    }

    if ($PreviewWorkflowTestHost -and $null -ne $script:GameRootValidator) {
        return [bool](& $script:GameRootValidator (Get-PreviewGameRootKey -GameRoot $GameRoot))
    }

    try {
        return (Test-Path -LiteralPath (Join-Path $GameRoot.Trim() '7DaysToDie.exe') -PathType Leaf)
    }
    catch {
        return $false
    }
}

function Save-ActivityLogSnapshot {
    if (-not $script:PersistentLogEnabled -or
        [string]::IsNullOrWhiteSpace($script:PersistentLogPath) -or
        $null -eq $script:ActivityLogBox -or
        $script:ActivityLogBox.IsDisposed) {
        return
    }

    try {
        $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($script:PersistentLogPath, $script:ActivityLogBox.Text, $utf8WithBom)
    }
    catch {
        $script:PersistentLogEnabled = $false
        $script:IsUpdatingPersistentLog = $true
        $script:PersistentLogCheck.Checked = $false
        $script:IsUpdatingPersistentLog = $false
        $script:PersistentLogPathLabel.Text = 'Could not save activity; it is still visible here.'
        $script:PersistentLogPathLabel.ForeColor = [System.Drawing.Color]::Firebrick
    }
}

function Add-Activity {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = $null
    )

    if ($null -eq $script:ActivityLogBox -or $script:ActivityLogBox.IsDisposed) {
        return
    }

    if ($null -ne $Color) {
        $script:ActivityLogBox.SelectionColor = $Color
    }
    $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
    $script:ActivityLogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] $Message$([Environment]::NewLine)")
    $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
    $script:ActivityLogBox.ScrollToCaret()
    Save-ActivityLogSnapshot
}

function Set-Status {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color
    )

    $status.Text = $Message
    $status.ForeColor = $Color
    Add-Activity -Message $Message -Color $Color
}

function Get-SelectedPreviewSettings {
    $startType = if ($randomRadio.Checked) { 'Random' } else { 'Standard' }
    $effectiveSafeguard = if ($startType -eq 'Standard') {
        'Ignored while Standard is selected'
    }
    elseif ($startingBiomeOnlyCheck.Checked) {
        'Starting biome only'
    }
    elseif ($allDangerousBiomesCheck.Checked) {
        'All dangerous biomes'
    }
    else {
        'None'
    }

    return [pscustomobject]@{
        GameRoot = $pathBox.Text.Trim()
        StartType = $startType
        StartingBiomeOnly = [bool]$startingBiomeOnlyCheck.Checked
        AllDangerousBiomes = [bool]$allDangerousBiomesCheck.Checked
        EffectiveSafeguard = $effectiveSafeguard
    }
}

function Test-PreviewSettingsMatch {
    param(
        [pscustomobject]$Left,
        [pscustomobject]$Right
    )

    if ($null -eq $Left -or $null -eq $Right) {
        return $false
    }

    $leftRoot = Get-PreviewGameRootKey -GameRoot $Left.GameRoot
    $rightRoot = Get-PreviewGameRootKey -GameRoot $Right.GameRoot
    return (
        [string]::Equals($leftRoot, $rightRoot, [System.StringComparison]::OrdinalIgnoreCase) -and
        $Left.StartType -eq $Right.StartType -and
        [bool]$Left.StartingBiomeOnly -eq [bool]$Right.StartingBiomeOnly -and
        [bool]$Left.AllDangerousBiomes -eq [bool]$Right.AllDangerousBiomes
    )
}

function Get-PreviewSessionState {
    param(
        [pscustomobject]$Current,
        [pscustomobject]$Applied,
        [string]$ValidationState,
        [string]$ValidatedGameRootKey
    )

    if ($ValidationState -eq 'Invalid') {
        return 'InvalidFolder'
    }
    if ($ValidationState -ne 'Valid') {
        return 'FolderCheckRequired'
    }

    $currentRootKey = Get-PreviewGameRootKey -GameRoot $Current.GameRoot
    if (-not [string]::Equals($currentRootKey, $ValidatedGameRootKey, [System.StringComparison]::OrdinalIgnoreCase)) {
        return 'FolderCheckRequired'
    }
    if ($null -eq $Applied) {
        return 'NotApplied'
    }
    if (Test-PreviewSettingsMatch -Left $Current -Right $Applied) {
        return 'Applied'
    }
    return 'Pending'
}

function Get-PreviewSettingLines {
    param([pscustomobject]$Settings)

    return @(
        'Game folder: checked current folder'
        "Start type: $($Settings.StartType)"
        "Starting biome only: $(if ($Settings.StartingBiomeOnly) { 'On' } else { 'Off' })"
        "All dangerous biomes: $(if ($Settings.AllDangerousBiomes) { 'On' } else { 'Off' })"
        "Computed safeguard: $($Settings.EffectiveSafeguard)"
    )
}

function Get-PreviewSettingChanges {
    param(
        [pscustomobject]$Previous,
        [pscustomobject]$Current
    )

    if ($null -eq $Previous) {
        return @(
            'Game folder: not applied -> checked current folder'
            "Start type: not applied -> $($Current.StartType)"
            "Starting biome only: not applied -> $(if ($Current.StartingBiomeOnly) { 'On' } else { 'Off' })"
            "All dangerous biomes: not applied -> $(if ($Current.AllDangerousBiomes) { 'On' } else { 'Off' })"
            "Effective Random safeguard: not applied -> $($Current.EffectiveSafeguard)"
        )
    }

    $changes = New-Object System.Collections.Generic.List[string]
    $previousRoot = Get-PreviewGameRootKey -GameRoot $Previous.GameRoot
    $currentRoot = Get-PreviewGameRootKey -GameRoot $Current.GameRoot
    if (-not [string]::Equals($previousRoot, $currentRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        [void]$changes.Add('Game folder: changed since last Apply (paths omitted)')
    }
    if ($Previous.StartType -ne $Current.StartType) {
        [void]$changes.Add("Start type: $($Previous.StartType) -> $($Current.StartType)")
    }
    if ([bool]$Previous.StartingBiomeOnly -ne [bool]$Current.StartingBiomeOnly) {
        [void]$changes.Add("Starting biome only: $(if ($Previous.StartingBiomeOnly) { 'On' } else { 'Off' }) -> $(if ($Current.StartingBiomeOnly) { 'On' } else { 'Off' })")
    }
    if ([bool]$Previous.AllDangerousBiomes -ne [bool]$Current.AllDangerousBiomes) {
        [void]$changes.Add("All dangerous biomes: $(if ($Previous.AllDangerousBiomes) { 'On' } else { 'Off' }) -> $(if ($Current.AllDangerousBiomes) { 'On' } else { 'Off' })")
    }
    if ($Previous.EffectiveSafeguard -ne $Current.EffectiveSafeguard) {
        [void]$changes.Add("Effective Random safeguard: $($Previous.EffectiveSafeguard) -> $($Current.EffectiveSafeguard)")
    }

    if ($changes.Count -eq 0) {
        return @('No setting values changed; the session preview record will be refreshed.')
    }
    return @($changes)
}

function Invoke-PreviewDialog {
    param(
        [string]$Text,
        [string]$Caption,
        [System.Windows.Forms.MessageBoxButtons]$Buttons,
        [System.Windows.Forms.MessageBoxIcon]$Icon
    )

    if ($PreviewWorkflowTestHost -and $null -ne $script:PreviewDialogHandler) {
        return & $script:PreviewDialogHandler $Text $Caption $Buttons $Icon
    }

    return [System.Windows.Forms.MessageBox]::Show($form, $Text, $Caption, $Buttons, $Icon)
}

function Get-PreviewConfirmationText {
    param(
        [pscustomobject]$Current,
        [pscustomobject]$Applied,
        [string]$SessionState,
        [string[]]$Changes
    )

    $safeguardText = if ($Current.StartType -eq 'Standard') {
        'Random safeguards: inactive'
    }
    else {
        "Random safeguard: $($Current.EffectiveSafeguard)"
    }
    $summaryText = @(
        "Start: $($Current.StartType)"
        'Game folder: checked'
        $safeguardText
    ) -join [Environment]::NewLine
    $safetyText = 'Preview only - game files, saves, and runtime settings will not change.'

    if ($null -eq $Applied) {
        return "Create preview-session snapshot?`r`n`r`nNot yet applied`r`n$summaryText`r`n`r`n$safetyText"
    }

    if ($SessionState -eq 'Applied') {
        return "Refresh applied preview snapshot?`r`n`r`nNo changes detected`r`n$summaryText`r`n`r`n$safetyText"
    }

    $changeText = ($Changes -join [Environment]::NewLine)
    return "Apply pending preview changes?`r`n`r`nPending changes:`r`n$changeText`r`n`r`nGame folder: checked`r`n`r`n$safetyText"
}

function Apply-PreviewSelection {
    $current = Get-SelectedPreviewSettings
    $currentState = Get-PreviewSessionState `
        -Current $current `
        -Applied $script:AppliedPreviewSettings `
        -ValidationState $script:FolderValidationState `
        -ValidatedGameRootKey $script:ValidatedGameRootKey

    if ($currentState -eq 'FolderCheckRequired') {
        [void](Update-DesignState)
        Set-Status -Message 'Apply stopped. Click Check Game Folder for the current folder first.' -Color (New-Color 130 45 35)
        [void](Invoke-PreviewDialog `
            -Text 'The game-folder entry changed. Click Check Game Folder before applying preview settings.' `
            -Caption 'Historical Random Start Preview' `
            -Buttons ([System.Windows.Forms.MessageBoxButtons]::OK) `
            -Icon ([System.Windows.Forms.MessageBoxIcon]::Warning))
        return 'BlockedFolderCheckRequired'
    }

    if ($currentState -eq 'InvalidFolder') {
        [void](Update-DesignState)
        Set-Status -Message 'Apply stopped. Choose and check a valid 7 Days to Die game folder.' -Color (New-Color 130 45 35)
        [void](Invoke-PreviewDialog `
            -Text 'Choose a valid 7 Days to Die game folder, then click Check Game Folder before applying preview settings.' `
            -Caption 'Historical Random Start Preview' `
            -Buttons ([System.Windows.Forms.MessageBoxButtons]::OK) `
            -Icon ([System.Windows.Forms.MessageBoxIcon]::Warning))
        return 'BlockedInvalidFolder'
    }

    if (-not (Test-GameRoot -GameRoot $current.GameRoot)) {
        $script:FolderValidationState = 'Invalid'
        $script:ValidatedGameRootKey = ''
        [void](Update-DesignState)
        Set-Status -Message 'Apply stopped. The checked game folder is no longer valid; check it again.' -Color (New-Color 130 45 35)
        [void](Invoke-PreviewDialog `
            -Text 'The checked game folder is no longer valid. Correct it and click Check Game Folder before applying preview settings.' `
            -Caption 'Historical Random Start Preview' `
            -Buttons ([System.Windows.Forms.MessageBoxButtons]::OK) `
            -Icon ([System.Windows.Forms.MessageBoxIcon]::Warning))
        return 'BlockedInvalidFolder'
    }

    $changes = @(Get-PreviewSettingChanges -Previous $script:AppliedPreviewSettings -Current $current)
    $settingsText = (Get-PreviewSettingLines -Settings $current) -join [Environment]::NewLine
    $confirmationText = Get-PreviewConfirmationText `
        -Current $current `
        -Applied $script:AppliedPreviewSettings `
        -SessionState $currentState `
        -Changes $changes
    $confirmation = Invoke-PreviewDialog `
        -Text $confirmationText `
        -Caption 'Confirm Preview Settings' `
        -Buttons ([System.Windows.Forms.MessageBoxButtons]::YesNo) `
        -Icon ([System.Windows.Forms.MessageBoxIcon]::Question)

    if ($confirmation -ne [System.Windows.Forms.DialogResult]::Yes) {
        [void](Update-DesignState -Outcome 'Canceled')
        if ($null -eq $script:AppliedPreviewSettings) {
            Add-Activity -Message 'Preview settings apply canceled. Current selections remain not applied.' -Color (New-Color 130 45 35)
        }
        elseif ($currentState -eq 'Pending') {
            Add-Activity -Message 'Preview settings apply canceled. Current selections remain pending; the last applied session snapshot is unchanged.' -Color (New-Color 130 45 35)
        }
        else {
            Add-Activity -Message 'Preview settings apply canceled. The applied session snapshot is unchanged.' -Color (New-Color 130 45 35)
        }
        return 'Canceled'
    }

    $script:AppliedPreviewSettings = $current
    [void](Update-DesignState)
    Add-Activity -Message 'Preview settings applied to this open session. Game unchanged.' -Color (New-Color 42 91 55)
    if ($changes.Count -eq 1 -and $changes[0] -match '^No setting values changed') {
        Add-Activity -Message 'Applied session snapshot refreshed; no setting values changed.' -Color (New-Color 42 91 55)
    }
    else {
        foreach ($change in $changes) {
            Add-Activity -Message "Confirmed change: $change" -Color (New-Color 42 91 55)
        }
    }
    Add-Activity -Message 'Applied session value: Game folder = checked current folder (path omitted).' -Color (New-Color 42 91 55)
    Add-Activity -Message "Applied session value: Start type = $($current.StartType)." -Color (New-Color 42 91 55)
    Add-Activity -Message "Applied session value: Starting biome only = $(if ($current.StartingBiomeOnly) { 'On' } else { 'Off' })." -Color (New-Color 42 91 55)
    Add-Activity -Message "Applied session value: All dangerous biomes = $(if ($current.AllDangerousBiomes) { 'On' } else { 'Off' })." -Color (New-Color 42 91 55)
    Add-Activity -Message "Applied session value: Effective Random safeguard = $($current.EffectiveSafeguard)." -Color (New-Color 42 91 55)

    [void](Invoke-PreviewDialog `
        -Text "Preview settings applied for this open session.`r`n`r`n$settingsText`r`n`r`nNo game files, saves, or runtime settings were changed." `
        -Caption 'Preview Settings Applied' `
        -Buttons ([System.Windows.Forms.MessageBoxButtons]::OK) `
        -Icon ([System.Windows.Forms.MessageBoxIcon]::Information))
    Set-ActivityLogExpanded -Expanded $true
    return 'Applied'
}

function Set-Tip {
    param(
        [System.Windows.Forms.Control]$Control,
        [string]$Text
    )

    $toolTip.SetToolTip($Control, $Text)
}

function Show-HowItWorksDialog {
    param([System.Windows.Forms.Form]$Owner)

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'How Your Starting Location Is Chosen'
    $dialog.ClientSize = New-Object System.Drawing.Size(620, 470)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = New-Color 250 249 247

    $quotePanel = New-Object System.Windows.Forms.Panel
    $quotePanel.Location = New-Object System.Drawing.Point(24, 20)
    $quotePanel.Size = New-Object System.Drawing.Size(572, 72)
    $quotePanel.BackColor = [System.Drawing.Color]::White
    $dialog.Controls.Add($quotePanel)
    Enable-RoundedBorder -Control $quotePanel -Radius 16 -BorderColor (New-Color 226 224 218)

    $quoteLogo = New-Object System.Windows.Forms.PictureBox
    $quoteLogo.Location = New-Object System.Drawing.Point(14, 16)
    $quoteLogo.Size = New-Object System.Drawing.Size(40, 40)
    $quoteLogo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $quoteLogo.BackColor = [System.Drawing.Color]::Transparent
    if ($null -ne $script:LogoImageToDispose) {
        $quoteLogo.Image = New-Object System.Drawing.Bitmap $script:LogoImageToDispose
    }
    $quotePanel.Controls.Add($quoteLogo)
    Set-RoundedRegion -Control $quoteLogo -Radius 20

    $quoteText = New-Object System.Windows.Forms.Label
    $quoteText.Text = '"Random starts were part of the Alpha 6-17.4 era."'
    $quoteText.Font = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Italic)
    $quoteText.ForeColor = New-Color 48 48 48
    $quoteText.AutoSize = $false
    $quoteText.Location = New-Object System.Drawing.Point(68, 14)
    $quoteText.Size = New-Object System.Drawing.Size(444, 25)
    $quotePanel.Controls.Add($quoteText)

    $quoteByline = New-Object System.Windows.Forms.Label
    $quoteByline.Text = '- Bit Wrecked historical note'
    $quoteByline.Font = New-Object System.Drawing.Font('Segoe UI', 8)
    $quoteByline.ForeColor = New-Color 130 45 35
    $quoteByline.AutoSize = $true
    $quoteByline.Location = New-Object System.Drawing.Point(70, 40)
    $quotePanel.Controls.Add($quoteByline)

    $choices = New-Object System.Windows.Forms.Label
    $choices.Text = $script:HowItWorksCopy
    $choices.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $choices.ForeColor = New-Color 64 64 60
    $choices.AutoSize = $false
    $choices.Location = New-Object System.Drawing.Point(42, 112)
    $choices.Size = New-Object System.Drawing.Size(536, 205)
    $dialog.Controls.Add($choices)

    $history = New-Object System.Windows.Forms.Label
    $history.Text = 'By Alpha 18, the same world name or seed could produce the same opening location.'
    $history.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
    $history.ForeColor = New-Color 92 92 88
    $history.AutoSize = $false
    $history.Location = New-Object System.Drawing.Point(42, 326)
    $history.Size = New-Object System.Drawing.Size(536, 36)
    $dialog.Controls.Add($history)

    $evidenceLink = New-Object System.Windows.Forms.LinkLabel
    $evidenceLink.Text = 'Read the official Alpha 6 release notes'
    $evidenceLink.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
    $evidenceLink.LinkColor = New-Color 38 86 150
    $evidenceLink.ActiveLinkColor = New-Color 130 45 35
    $evidenceLink.AutoSize = $true
    $evidenceLink.Location = New-Object System.Drawing.Point(42, 362)
    $evidenceLink.Cursor = [System.Windows.Forms.Cursors]::Hand
    $dialog.Controls.Add($evidenceLink)
    $evidenceLink.Add_LinkClicked({
        Start-Process $script:Alpha6EvidenceUrl
    })

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = 'OK'
    $okButton.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $okButton.FlatStyle = 'Flat'
    $okButton.FlatAppearance.BorderSize = 0
    $okButton.BackColor = [System.Drawing.Color]::White
    $okButton.ForeColor = New-Color 38 38 36
    $okButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $okButton.Location = New-Object System.Drawing.Point(466, 390)
    $okButton.Size = New-Object System.Drawing.Size(130, 38)
    $dialog.Controls.Add($okButton)
    Enable-RoundedBorder -Control $okButton -Radius 19 -BorderColor (New-Color 208 208 202)
    $okButton.Add_Click({ $dialog.Close() })
    $dialog.AcceptButton = $okButton
    $dialog.CancelButton = $okButton

    $dialog.Add_FormClosed({
        if ($null -ne $quoteLogo.Image) {
            $quoteLogo.Image.Dispose()
        }
    })

    [void]$dialog.ShowDialog($Owner)
    $dialog.Dispose()
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Bit Wrecked - Historical Random Start - Alpha 6 Method'
$form.ClientSize = New-Object System.Drawing.Size(620, 660)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = New-Color 250 249 247

$logoPath = Join-Path $packageRoot 'Assets\i0141.png'
if (Test-Path -LiteralPath $logoPath -PathType Leaf) {
    $logoStream = [System.IO.File]::OpenRead($logoPath)
    try {
        $loadedLogo = [System.Drawing.Image]::FromStream($logoStream)
        try {
            $script:LogoImageToDispose = New-Object System.Drawing.Bitmap $loadedLogo
        }
        finally {
            $loadedLogo.Dispose()
        }
    }
    finally {
        $logoStream.Dispose()
    }

    $logoBox = New-Object System.Windows.Forms.PictureBox
    $logoBox.Image = $script:LogoImageToDispose
    $logoBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $logoBox.BackColor = [System.Drawing.Color]::Transparent
    $logoBox.Location = New-Object System.Drawing.Point(27, 18)
    $logoBox.Size = New-Object System.Drawing.Size(52, 52)
    $form.Controls.Add($logoBox)
    Set-RoundedRegion -Control $logoBox -Radius 26
}

$form.Add_FormClosed({
    if ($null -ne $script:LogoImageToDispose) {
        $script:LogoImageToDispose.Dispose()
    }
})

$brand = New-Object System.Windows.Forms.Label
$brand.Text = 'Bit Wrecked'
$brand.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 9, [System.Drawing.FontStyle]::Bold)
$brand.ForeColor = New-Color 130 45 35
$brand.AutoSize = $true
$brand.Location = New-Object System.Drawing.Point(92, 20)
$form.Controls.Add($brand)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Historical Random Start - Alpha 6 Method'
$title.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = New-Color 32 32 32
$title.AutoSize = $false
$title.Location = New-Object System.Drawing.Point(90, 40)
$title.Size = New-Object System.Drawing.Size(504, 30)
$form.Controls.Add($title)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = 'Player preview | Version 0.0.7'
$versionLabel.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$versionLabel.ForeColor = New-Color 92 92 88
$versionLabel.AutoSize = $true
$versionLabel.Location = New-Object System.Drawing.Point(92, 70)
$form.Controls.Add($versionLabel)

$designLabel = New-Object System.Windows.Forms.Label
$designLabel.Text = 'Preview'
$designLabel.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$designLabel.ForeColor = New-Color 130 45 35
$designLabel.AutoSize = $true
$designLabel.Location = New-Object System.Drawing.Point(318, 70)
$form.Controls.Add($designLabel)

$statePanel = New-Object System.Windows.Forms.Panel
$statePanel.Location = New-Object System.Drawing.Point(26, 102)
$statePanel.Size = New-Object System.Drawing.Size(568, 58)
$statePanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($statePanel)
Enable-RoundedBorder -Control $statePanel -Radius 16 -BorderColor (New-Color 226 224 218)

$stateAccent = New-Object System.Windows.Forms.Panel
$stateAccent.Location = New-Object System.Drawing.Point(18, 20)
$stateAccent.Size = New-Object System.Drawing.Size(18, 18)
$stateAccent.BackColor = New-Color 156 156 150
$statePanel.Controls.Add($stateAccent)
Set-RoundedRegion -Control $stateAccent -Radius 9

$stateValue = New-Object System.Windows.Forms.Label
$stateValue.Text = 'Choose your game folder to get started.'
$stateValue.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 10, [System.Drawing.FontStyle]::Bold)
$stateValue.ForeColor = New-Color 48 48 48
$stateValue.AutoSize = $false
$stateValue.Location = New-Object System.Drawing.Point(47, 18)
$stateValue.Size = New-Object System.Drawing.Size(492, 22)
$statePanel.Controls.Add($stateValue)

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 5000
$toolTip.InitialDelay = 250
$toolTip.ReshowDelay = 75

$pathShell = New-Object System.Windows.Forms.Panel
$pathShell.Location = New-Object System.Drawing.Point(27, 180)
$pathShell.Size = New-Object System.Drawing.Size(414, 34)
$pathShell.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($pathShell)
Enable-RoundedBorder -Control $pathShell -Radius 16 -BorderColor (New-Color 208 208 202)

$pathBox = New-Object System.Windows.Forms.TextBox
$pathBox.BorderStyle = 'None'
$pathBox.BackColor = [System.Drawing.Color]::White
$pathBox.Location = New-Object System.Drawing.Point(13, 9)
$pathBox.Size = New-Object System.Drawing.Size(386, 20)
$pathBox.Text = Get-DefaultGameRoot
$pathShell.Controls.Add($pathBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = 'Choose Game Folder'
$browseButton.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$browseButton.FlatStyle = 'Flat'
$browseButton.FlatAppearance.BorderSize = 0
$browseButton.BackColor = [System.Drawing.Color]::White
$browseButton.ForeColor = New-Color 38 38 36
$browseButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$browseButton.Location = New-Object System.Drawing.Point(454, 178)
$browseButton.Size = New-Object System.Drawing.Size(140, 36)
$form.Controls.Add($browseButton)
Enable-RoundedBorder -Control $browseButton -Radius 18 -BorderColor (New-Color 208 208 202)

$designPanel = New-Object System.Windows.Forms.Panel
$designPanel.Location = New-Object System.Drawing.Point(27, 230)
$designPanel.Size = New-Object System.Drawing.Size(567, 252)
$designPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($designPanel)
Enable-RoundedBorder -Control $designPanel -Radius 16 -BorderColor (New-Color 226 224 218)

$headers = @(
    @{ Text = 'How your initial start location will be chosen'; Left = 22; Width = 524 }
)
foreach ($header in $headers) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $header.Text
    $label.Font = New-Object System.Drawing.Font('Segoe UI', 8)
    $label.ForeColor = New-Color 110 110 105
    $label.Location = New-Object System.Drawing.Point($header.Left, 25)
    $label.Size = New-Object System.Drawing.Size($header.Width, 18)
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $designPanel.Controls.Add($label)
}

$headerRule = New-Object System.Windows.Forms.Panel
$headerRule.Location = New-Object System.Drawing.Point(18, 45)
$headerRule.Size = New-Object System.Drawing.Size(528, 1)
$headerRule.BackColor = New-Color 236 234 229
$designPanel.Controls.Add($headerRule)

$standardRadio = New-Object System.Windows.Forms.RadioButton
$standardRadio.Text = 'Standard'
$standardRadio.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 8.5, [System.Drawing.FontStyle]::Bold)
$standardRadio.ForeColor = New-Color 48 48 48
$standardRadio.Location = New-Object System.Drawing.Point(130, 54)
$standardRadio.Size = New-Object System.Drawing.Size(130, 24)
$standardRadio.Checked = $true
$designPanel.Controls.Add($standardRadio)

$randomRadio = New-Object System.Windows.Forms.RadioButton
$randomRadio.Text = 'Random'
$randomRadio.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 8.5, [System.Drawing.FontStyle]::Bold)
$randomRadio.ForeColor = New-Color 48 48 48
$randomRadio.Location = New-Object System.Drawing.Point(325, 54)
$randomRadio.Size = New-Object System.Drawing.Size(130, 24)
$designPanel.Controls.Add($randomRadio)

$randomSafeguardPanel = New-Object System.Windows.Forms.Panel
$randomSafeguardPanel.Location = New-Object System.Drawing.Point(28, 82)
$randomSafeguardPanel.Size = New-Object System.Drawing.Size(510, 104)
$randomSafeguardPanel.BackColor = New-Color 247 248 246
$designPanel.Controls.Add($randomSafeguardPanel)
Enable-RoundedBorder -Control $randomSafeguardPanel -Radius 13 -BorderColor (New-Color 226 224 218)

$randomSafeguardTitle = New-Object System.Windows.Forms.Label
$randomSafeguardTitle.Text = 'Random-start safeguards (optional)'
$randomSafeguardTitle.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 8, [System.Drawing.FontStyle]::Bold)
$randomSafeguardTitle.ForeColor = New-Color 48 48 48
$randomSafeguardTitle.Location = New-Object System.Drawing.Point(14, 7)
$randomSafeguardTitle.Size = New-Object System.Drawing.Size(470, 19)
$randomSafeguardPanel.Controls.Add($randomSafeguardTitle)

$startingBiomeOnlyCheck = New-Object System.Windows.Forms.CheckBox
$startingBiomeOnlyCheck.Text = 'Starting biome only'
$startingBiomeOnlyCheck.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$startingBiomeOnlyCheck.ForeColor = New-Color 55 55 52
$startingBiomeOnlyCheck.Location = New-Object System.Drawing.Point(14, 29)
$startingBiomeOnlyCheck.Size = New-Object System.Drawing.Size(205, 22)
$startingBiomeOnlyCheck.TabIndex = 0
$startingBiomeOnlyCheck.Checked = $false
$randomSafeguardPanel.Controls.Add($startingBiomeOnlyCheck)

$allDangerousBiomesCheck = New-Object System.Windows.Forms.CheckBox
$allDangerousBiomesCheck.Text = 'All dangerous biomes'
$allDangerousBiomesCheck.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$allDangerousBiomesCheck.ForeColor = New-Color 55 55 52
$allDangerousBiomesCheck.Location = New-Object System.Drawing.Point(252, 29)
$allDangerousBiomesCheck.Size = New-Object System.Drawing.Size(225, 22)
$allDangerousBiomesCheck.TabIndex = 1
$allDangerousBiomesCheck.Checked = $false
$randomSafeguardPanel.Controls.Add($allDangerousBiomesCheck)

$randomSafeguardNote = New-Object System.Windows.Forms.Label
$randomSafeguardNote.Font = New-Object System.Drawing.Font('Segoe UI', 7.2)
$randomSafeguardNote.ForeColor = New-Color 92 92 88
$randomSafeguardNote.Location = New-Object System.Drawing.Point(14, 58)
$randomSafeguardNote.Size = New-Object System.Drawing.Size(480, 38)
$randomSafeguardNote.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
$randomSafeguardPanel.Controls.Add($randomSafeguardNote)

$previewOnlyLabel = New-Object System.Windows.Forms.Label
$previewOnlyLabel.Text = 'Preview only - Apply records choices for this session; your game stays unchanged.'
$previewOnlyLabel.Font = New-Object System.Drawing.Font('Segoe UI', 7.3)
$previewOnlyLabel.ForeColor = New-Color 130 45 35
$previewOnlyLabel.Location = New-Object System.Drawing.Point(28, 190)
$previewOnlyLabel.Size = New-Object System.Drawing.Size(510, 18)
$previewOnlyLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$designPanel.Controls.Add($previewOnlyLabel)

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = 'Check Game Folder'
$scanButton.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$scanButton.FlatStyle = 'Flat'
$scanButton.FlatAppearance.BorderSize = 0
$scanButton.BackColor = [System.Drawing.Color]::White
$scanButton.ForeColor = New-Color 38 38 36
$scanButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$scanButton.Location = New-Object System.Drawing.Point(45, 216)
$scanButton.Size = New-Object System.Drawing.Size(220, 30)
$designPanel.Controls.Add($scanButton)
Enable-RoundedBorder -Control $scanButton -Radius 15 -BorderColor (New-Color 208 208 202)

$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Text = 'Apply Preview Settings'
$applyButton.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$applyButton.FlatStyle = 'Flat'
$applyButton.FlatAppearance.BorderSize = 0
$applyButton.BackColor = New-Color 238 246 239
$applyButton.ForeColor = New-Color 42 91 55
$applyButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$applyButton.Location = New-Object System.Drawing.Point(300, 216)
$applyButton.Size = New-Object System.Drawing.Size(220, 30)
$applyButton.Enabled = $false
$designPanel.Controls.Add($applyButton)
Enable-RoundedBorder -Control $applyButton -Radius 15 -BorderColor (New-Color 83 158 98)

function Update-RandomSafeguardPreview {
    $isRandom = $randomRadio.Checked
    if (-not $startingBiomeOnlyCheck.Checked -and -not $allDangerousBiomesCheck.Checked) {
        $randomSafeguardNote.Text = 'All biome hazards stay on. Choose one safeguard only if you want it for Random.'
    }
    elseif (-not $isRandom) {
        $randomSafeguardNote.Text = 'Your safeguard is ready for Random. Standard remains unchanged.'
    }
    elseif ($startingBiomeOnlyCheck.Checked) {
        $randomSafeguardNote.Text = 'Only your starting biome hazard turns off. Other dangerous biomes stay fully active.'
    }
    else {
        $randomSafeguardNote.Text = 'All four dangerous-biome hazards turn off. Zombies, falls, and POI danger stay on.'
    }
}

function Add-PreviewSelectionChangedActivity {
    param(
        [string]$Change,
        [string]$State
    )

    switch ($State) {
        'Pending' {
            Add-Activity -Message "$Change Current selections are pending; the last applied session snapshot is unchanged." -Color (New-Color 176 112 35)
        }
        'Applied' {
            Add-Activity -Message "$Change Current selections again match the applied session snapshot." -Color (New-Color 42 91 55)
        }
        default {
            Add-Activity -Message "$Change Current selections are not applied." -Color (New-Color 82 82 78)
        }
    }
}

$modeChanged = {
    param($sender, $eventArgs)
    if (-not $sender.Checked) {
        return
    }
    Update-RandomSafeguardPreview
    $state = Update-DesignState
    Add-PreviewSelectionChangedActivity -Change "Start choice changed to $($sender.Text)." -State $state
}
$standardRadio.Add_CheckedChanged($modeChanged)
$randomRadio.Add_CheckedChanged($modeChanged)

$startingBiomeOnlyCheck.Add_CheckedChanged({
    if ($script:IsUpdatingRandomSafeguardScope) {
        return
    }
    if ($startingBiomeOnlyCheck.Checked -and $allDangerousBiomesCheck.Checked) {
        $script:IsUpdatingRandomSafeguardScope = $true
        $allDangerousBiomesCheck.Checked = $false
        $script:IsUpdatingRandomSafeguardScope = $false
    }
    Update-RandomSafeguardPreview
    $state = Update-DesignState
    Add-PreviewSelectionChangedActivity -Change 'Random-start safeguard scope changed.' -State $state
})
$allDangerousBiomesCheck.Add_CheckedChanged({
    if ($script:IsUpdatingRandomSafeguardScope) {
        return
    }
    if ($allDangerousBiomesCheck.Checked -and $startingBiomeOnlyCheck.Checked) {
        $script:IsUpdatingRandomSafeguardScope = $true
        $startingBiomeOnlyCheck.Checked = $false
        $script:IsUpdatingRandomSafeguardScope = $false
    }
    Update-RandomSafeguardPreview
    $state = Update-DesignState
    Add-PreviewSelectionChangedActivity -Change 'Random-start safeguard scope changed.' -State $state
})
Update-RandomSafeguardPreview

$reservedPanel = New-Object System.Windows.Forms.Panel
$reservedPanel.Location = New-Object System.Drawing.Point(27, 498)
$reservedPanel.Size = New-Object System.Drawing.Size(567, 44)
$reservedPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($reservedPanel)
Enable-RoundedBorder -Control $reservedPanel -Radius 16 -BorderColor (New-Color 226 224 218)

$previewNote = New-Object System.Windows.Forms.Label
$previewNote.Text = 'Preview mode - your game stays unchanged.'
$previewNote.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 8.5, [System.Drawing.FontStyle]::Bold)
$previewNote.ForeColor = New-Color 130 45 35
$previewNote.AutoSize = $false
$previewNote.Location = New-Object System.Drawing.Point(16, 10)
$previewNote.Size = New-Object System.Drawing.Size(520, 24)
$previewNote.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$reservedPanel.Controls.Add($previewNote)

$howItWorksButton = New-Object System.Windows.Forms.Button
$howItWorksButton.Text = 'How It Works'
$howItWorksButton.Font = New-Object System.Drawing.Font('Segoe UI', 8.5, [System.Drawing.FontStyle]::Bold)
$howItWorksButton.FlatStyle = 'Flat'
$howItWorksButton.FlatAppearance.BorderSize = 0
$howItWorksButton.BackColor = [System.Drawing.Color]::White
$howItWorksButton.ForeColor = New-Color 38 38 36
$howItWorksButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$howItWorksButton.Location = New-Object System.Drawing.Point(432, 66)
$howItWorksButton.Size = New-Object System.Drawing.Size(162, 28)
$form.Controls.Add($howItWorksButton)
Enable-RoundedBorder -Control $howItWorksButton -Radius 21 -BorderColor (New-Color 208 208 202)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = 'Close'
$closeButton.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$closeButton.FlatStyle = 'Flat'
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.BackColor = [System.Drawing.Color]::White
$closeButton.ForeColor = New-Color 38 38 36
$closeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$closeButton.Location = New-Object System.Drawing.Point(510, 561)
$closeButton.Size = New-Object System.Drawing.Size(84, 42)
$form.Controls.Add($closeButton)
Enable-RoundedBorder -Control $closeButton -Radius 21 -BorderColor (New-Color 208 208 202)

$activityPanel = New-Object System.Windows.Forms.Panel
$activityPanel.BackColor = [System.Drawing.Color]::White
$activityPanel.Dock = 'Fill'
$activityPanel.BorderStyle = 'FixedSingle'

$activityTitle = New-Object System.Windows.Forms.Label
$activityTitle.Text = 'Recent activity'
$activityTitle.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 9, [System.Drawing.FontStyle]::Bold)
$activityTitle.ForeColor = New-Color 38 38 36
$activityTitle.Location = New-Object System.Drawing.Point(14, 12)
$activityTitle.Size = New-Object System.Drawing.Size(410, 20)
$activityPanel.Controls.Add($activityTitle)

$status = New-Object System.Windows.Forms.Label
$status.Text = 'Ready - choose your game folder.'
$status.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$status.Location = New-Object System.Drawing.Point(14, 36)
$status.Size = New-Object System.Drawing.Size(415, 20)
$status.ForeColor = New-Color 82 82 78
$status.AutoEllipsis = $true
$activityPanel.Controls.Add($status)

$persistentLogCheck = New-Object System.Windows.Forms.CheckBox
$persistentLogCheck.Text = 'Save recent activity'
$persistentLogCheck.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$persistentLogCheck.ForeColor = New-Color 55 55 52
$persistentLogCheck.Location = New-Object System.Drawing.Point(14, 58)
$persistentLogCheck.Size = New-Object System.Drawing.Size(122, 24)
$activityPanel.Controls.Add($persistentLogCheck)
$script:PersistentLogCheck = $persistentLogCheck

$chooseLogFileButton = New-Object System.Windows.Forms.Button
$chooseLogFileButton.Text = 'Choose Save Location'
$chooseLogFileButton.Font = New-Object System.Drawing.Font('Segoe UI', 7.5)
$chooseLogFileButton.FlatStyle = 'Flat'
$chooseLogFileButton.FlatAppearance.BorderSize = 0
$chooseLogFileButton.BackColor = New-Color 247 248 246
$chooseLogFileButton.ForeColor = New-Color 38 38 36
$chooseLogFileButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$chooseLogFileButton.Location = New-Object System.Drawing.Point(142, 57)
$chooseLogFileButton.Size = New-Object System.Drawing.Size(120, 26)
$activityPanel.Controls.Add($chooseLogFileButton)
Enable-RoundedBorder -Control $chooseLogFileButton -Radius 13 -BorderColor (New-Color 208 208 202)

$persistentLogPathLabel = New-Object System.Windows.Forms.Label
$persistentLogPathLabel.Text = 'Activity is not saved automatically.'
$persistentLogPathLabel.Font = New-Object System.Drawing.Font('Segoe UI', 7)
$persistentLogPathLabel.ForeColor = New-Color 110 110 105
$persistentLogPathLabel.Location = New-Object System.Drawing.Point(14, 86)
$persistentLogPathLabel.Size = New-Object System.Drawing.Size(248, 28)
$persistentLogPathLabel.AutoEllipsis = $true
$activityPanel.Controls.Add($persistentLogPathLabel)
$script:PersistentLogPathLabel = $persistentLogPathLabel

$activityLog = New-Object System.Windows.Forms.RichTextBox
$activityLog.ReadOnly = $true
$activityLog.BorderStyle = 'None'
$activityLog.BackColor = New-Color 247 248 246
$activityLog.ForeColor = New-Color 55 55 52
$activityLog.Font = New-Object System.Drawing.Font('Consolas', 7.5)
$activityLog.Location = New-Object System.Drawing.Point(14, 118)
$activityLog.Size = New-Object System.Drawing.Size(415, 515)
$activityLog.ScrollBars = 'Vertical'
$activityLog.WordWrap = $true
$activityLog.DetectUrls = $false
$activityLog.Text = "[$(Get-Date -Format 'HH:mm:ss')] Ready. Choose your 7 Days to Die folder to begin.$([Environment]::NewLine)[$(Get-Date -Format 'HH:mm:ss')] This is a player preview. Your game will not be changed.$([Environment]::NewLine)"
$activityPanel.Controls.Add($activityLog)
$script:ActivityLogBox = $activityLog

$activityPanel.Add_Resize({
    $contentWidth = [Math]::Max(120, $activityPanel.ClientSize.Width - 28)
    $activityTitle.Width = $contentWidth
    $status.Width = $contentWidth
    $persistentLogPathLabel.Width = $contentWidth
    $chooseLogFileButton.Left = [Math]::Max(142, $activityPanel.ClientSize.Width - 134)
    $activityLog.Width = $contentWidth
    $activityLog.Height = [Math]::Max(100, $activityPanel.ClientSize.Height - 135)
})

$activityToggleButton = New-Object System.Windows.Forms.Button
$activityToggleButton.Text = [char]0x25B6
$activityToggleButton.Font = New-Object System.Drawing.Font('Segoe UI Symbol', 9, [System.Drawing.FontStyle]::Bold)
$activityToggleButton.FlatStyle = 'Flat'
$activityToggleButton.FlatAppearance.BorderSize = 0
$activityToggleButton.BackColor = New-Color 238 240 237
$activityToggleButton.ForeColor = New-Color 42 91 55
$activityToggleButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$activityToggleButton.Location = New-Object System.Drawing.Point(596, 306)
$activityToggleButton.Size = New-Object System.Drawing.Size(18, 74)
$form.Controls.Add($activityToggleButton)
Enable-RoundedBorder -Control $activityToggleButton -Radius 9 -BorderColor (New-Color 83 158 98)
$activityToggleButton.BringToFront()

$workspaceSplit = New-Object System.Windows.Forms.SplitContainer
$workspaceSplit.Size = New-Object System.Drawing.Size(1250, 660)
$workspaceSplit.Dock = 'Fill'
$workspaceSplit.Orientation = 'Vertical'
$workspaceSplit.FixedPanel = 'Panel1'
$workspaceSplit.SplitterWidth = 7
$workspaceSplit.Panel1MinSize = 600
$workspaceSplit.Panel2MinSize = 300
$workspaceSplit.SplitterDistance = 620
$workspaceSplit.IsSplitterFixed = $false
$workspaceSplit.BackColor = New-Color 214 218 212
$workspaceSplit.Panel1.BackColor = $form.BackColor
$workspaceSplit.Panel2.BackColor = $form.BackColor
$workspaceSplit.Panel2.Padding = New-Object System.Windows.Forms.Padding(10, 18, 17, 22)

$mainControls = @($form.Controls | Where-Object { $_ -ne $activityPanel })
foreach ($control in $mainControls) {
    $form.Controls.Remove($control)
    $workspaceSplit.Panel1.Controls.Add($control)
}
$workspaceSplit.Panel2.Controls.Add($activityPanel)
$form.Controls.Add($workspaceSplit)
$activityToggleButton.BringToFront()

$script:IsActivityLogExpanded = $false
function Set-ActivityLogExpanded {
    param([bool]$Expanded)

    $form.SuspendLayout()
    try {
        $script:IsActivityLogExpanded = $Expanded
        if ($Expanded) {
            $form.FormBorderStyle = 'Sizable'
            $form.MaximizeBox = $true
            $form.MinimumSize = New-Object System.Drawing.Size(900, 500)
            $form.ClientSize = New-Object System.Drawing.Size(930, 660)
            $workspaceSplit.Panel2Collapsed = $false
            $workspaceSplit.SplitterDistance = 620
            $activityToggleButton.Text = [char]0x25C0
        }
        else {
            if ($form.WindowState -eq 'Maximized') {
                $form.WindowState = 'Normal'
            }
            $workspaceSplit.Panel2Collapsed = $true
            $form.MinimumSize = New-Object System.Drawing.Size(0, 0)
            $form.FormBorderStyle = 'FixedDialog'
            $form.MaximizeBox = $false
            $form.ClientSize = New-Object System.Drawing.Size(620, 660)
            $activityToggleButton.Text = [char]0x25B6
        }
        $activityToggleButton.BringToFront()
    }
    finally {
        $form.ResumeLayout($true)
    }
}

function Update-DesignState {
    param([ValidateSet('', 'Canceled')][string]$Outcome = '')

    $current = Get-SelectedPreviewSettings
    $state = Get-PreviewSessionState `
        -Current $current `
        -Applied $script:AppliedPreviewSettings `
        -ValidationState $script:FolderValidationState `
        -ValidatedGameRootKey $script:ValidatedGameRootKey
    $script:CurrentPreviewState = $state
    $applyButton.Enabled = $state -in @('NotApplied', 'Pending', 'Applied')

    switch ($state) {
        'FolderCheckRequired' {
            $stateAccent.BackColor = New-Color 176 112 35
            if ($null -ne $script:AppliedPreviewSettings) {
                $stateValue.Text = 'Game folder changed - applied session snapshot is stale.'
                $previewOnlyLabel.Text = 'Folder check required - last applied snapshot is stale; your game is unchanged.'
                $previewNote.Text = 'Check the current game folder before Apply - your game stays unchanged.'
                $status.Text = 'Game folder changed. Check the current folder before applying.'
            }
            else {
                $stateValue.Text = 'Check your current 7 Days to Die game folder to continue.'
                $previewOnlyLabel.Text = 'Not applied - check the current game folder before Apply; your game is unchanged.'
                $previewNote.Text = 'Preview not applied - check the game folder first.'
                $status.Text = 'Click Check Game Folder before applying preview settings.'
            }
            $previewOnlyLabel.ForeColor = New-Color 130 86 25
            $previewNote.ForeColor = New-Color 130 86 25
            $status.ForeColor = New-Color 130 86 25
        }
        'InvalidFolder' {
            $stateAccent.BackColor = New-Color 156 80 68
            $stateValue.Text = 'Game folder not recognized - preview settings cannot be applied.'
            if ($null -ne $script:AppliedPreviewSettings) {
                $previewOnlyLabel.Text = 'Invalid folder - last applied snapshot is stale; your game is unchanged.'
            }
            else {
                $previewOnlyLabel.Text = 'Invalid folder - nothing is applied; your game is unchanged.'
            }
            $previewOnlyLabel.ForeColor = New-Color 130 45 35
            $previewNote.Text = 'Choose a valid game folder, then check it before Apply.'
            $previewNote.ForeColor = New-Color 130 45 35
            $status.Text = 'The current folder is not a recognized 7 Days to Die installation.'
            $status.ForeColor = New-Color 130 45 35
        }
        'NotApplied' {
            $stateAccent.BackColor = New-Color 156 156 150
            $stateValue.Text = 'Game folder checked - preview choices are not applied.'
            $previewOnlyLabel.Text = 'Not applied - Apply records choices only for this open session; game unchanged.'
            $previewOnlyLabel.ForeColor = New-Color 92 92 88
            $previewNote.Text = 'Preview choices are ready but not applied - your game stays unchanged.'
            $previewNote.ForeColor = New-Color 92 92 88
            $status.Text = 'Game folder checked. Preview choices have not been applied.'
            $status.ForeColor = New-Color 82 82 78
        }
        'Pending' {
            $stateAccent.BackColor = New-Color 211 151 62
            $stateValue.Text = 'Pending changes - current choices are not yet applied.'
            $previewOnlyLabel.Text = 'Pending - current choices differ from the applied session snapshot; game unchanged.'
            $previewOnlyLabel.ForeColor = New-Color 130 86 25
            $previewNote.Text = 'Pending preview changes - Apply again to update this open session.'
            $previewNote.ForeColor = New-Color 130 86 25
            $status.Text = 'Current selections are pending; the last applied session snapshot is unchanged.'
            $status.ForeColor = New-Color 130 86 25
        }
        'Applied' {
            $stateAccent.BackColor = New-Color 83 158 98
            $stateValue.Text = 'Applied snapshot matches current choices - game unchanged.'
            $previewOnlyLabel.Text = 'Applied to this open session only - current choices match; game unchanged.'
            $previewOnlyLabel.ForeColor = New-Color 42 91 55
            $previewNote.Text = 'Preview settings applied to this open session - your game stays unchanged.'
            $previewNote.ForeColor = New-Color 42 91 55
            $status.Text = 'Current selections match the applied session snapshot.'
            $status.ForeColor = New-Color 42 91 55
        }
    }

    if ($Outcome -eq 'Canceled') {
        $stateAccent.BackColor = New-Color 156 80 68
        switch ($state) {
            'NotApplied' {
                $stateValue.Text = 'Apply canceled - choices are still not applied.'
                $previewOnlyLabel.Text = 'Canceled - current choices remain not applied; your game is unchanged.'
            }
            'Pending' {
                $stateValue.Text = 'Apply canceled - pending choices were not applied.'
                $previewOnlyLabel.Text = 'Canceled - pending choices remain; applied snapshot and game are unchanged.'
            }
            'Applied' {
                $stateValue.Text = 'Apply canceled - applied session snapshot is unchanged.'
                $previewOnlyLabel.Text = 'Canceled - current choices still match the applied snapshot; game unchanged.'
            }
        }
        $previewOnlyLabel.ForeColor = New-Color 130 45 35
        $previewNote.Text = 'Apply canceled - no session snapshot or game data changed.'
        $previewNote.ForeColor = New-Color 130 45 35
        $status.Text = $stateValue.Text
        $status.ForeColor = New-Color 130 45 35
    }

    return $state
}

function Set-GameRootValidationRequired {
    $shouldLog = $script:FolderValidationState -ne 'Required'
    $script:FolderValidationState = 'Required'
    $script:ValidatedGameRootKey = ''
    [void](Update-DesignState)

    if ($shouldLog) {
        if ($null -ne $script:AppliedPreviewSettings) {
            Add-Activity -Message 'Game folder changed. The last applied session snapshot is stale; click Check Game Folder before Apply.' -Color (New-Color 176 112 35)
        }
        else {
            Add-Activity -Message 'Game folder changed. Click Check Game Folder before Apply.' -Color (New-Color 176 112 35)
        }
    }
}

function Set-CurrentGameRootValidation {
    param([bool]$ShowDialog = $true)

    $currentRoot = $pathBox.Text.Trim()
    if (Test-GameRoot -GameRoot $currentRoot) {
        $script:FolderValidationState = 'Valid'
        $script:ValidatedGameRootKey = Get-PreviewGameRootKey -GameRoot $currentRoot
        $state = Update-DesignState
        Add-Activity -Message "Game folder check passed. Current preview state: $state." -Color (New-Color 42 91 55)
        if ($ShowDialog) {
            [void](Invoke-PreviewDialog `
                -Text "Your 7 Days to Die game folder was found.`r`n`r`nThis preview is safe: it has not installed anything or changed your game.`r`n`r`nThe planned mod has two start types: Standard or Random." `
                -Caption 'Historical Random Start Preview' `
                -Buttons ([System.Windows.Forms.MessageBoxButtons]::OK) `
                -Icon ([System.Windows.Forms.MessageBoxIcon]::Information))
        }
        return $true
    }

    $script:FolderValidationState = 'Invalid'
    $script:ValidatedGameRootKey = ''
    [void](Update-DesignState)
    Add-Activity -Message 'Game folder check failed. Choose the folder containing 7DaysToDie.exe and check again.' -Color (New-Color 130 45 35)
    if ($ShowDialog) {
        [void](Invoke-PreviewDialog `
            -Text 'That folder was not recognized. Choose the 7 Days to Die folder containing 7DaysToDie.exe, then check again.' `
            -Caption 'Historical Random Start Preview' `
            -Buttons ([System.Windows.Forms.MessageBoxButtons]::OK) `
            -Icon ([System.Windows.Forms.MessageBoxIcon]::Warning))
    }
    return $false
}

Set-Tip -Control $statePanel -Text 'This preview helps you check the game folder before the start-choice feature is ready.'
Set-Tip -Control $pathBox -Text 'Choose the main 7 Days to Die folder containing 7DaysToDie.exe.'
Set-Tip -Control $browseButton -Text 'Select your 7 Days to Die game folder. This does not install or change anything.'
Set-Tip -Control $designPanel -Text 'See the planned choices for how a new character''s initial start location will be chosen.'
Set-Tip -Control $standardRadio -Text 'Use the normal game start. This remains an exact gameplay no-op.'
Set-Tip -Control $randomRadio -Text 'Use a broader location from the current world''s authored spawnpoint list.'
Set-Tip -Control $randomSafeguardPanel -Text 'Optional safeguards for Random starts. They start unchecked and do not save or change the game in this preview.'
Set-Tip -Control $startingBiomeOnlyCheck -Text 'Turn off only the hazard family for the biome where the Random-start character arrives. Other dangerous biomes stay active.'
Set-Tip -Control $allDangerousBiomesCheck -Text 'Turn off the Burnt Forest, Desert, Snow, and Wasteland hazard families for the Random-start character.'
Set-Tip -Control $scanButton -Text 'Check that the selected folder is your 7 Days to Die installation.'
Set-Tip -Control $applyButton -Text 'Confirm and record the selected settings for this open preview session. No game files are changed.'
Set-Tip -Control $reservedPanel -Text 'This preview can record choices for the open session. It does not install anything or change your game.'
Set-Tip -Control $howItWorksButton -Text 'Learn what the finished tool will do and what is available in this preview.'
Set-Tip -Control $activityToggleButton -Text 'Show or hide the runtime activity log.'

$pathBox.Add_TextChanged({
    Set-GameRootValidationRequired
})

$browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Select your 7 Days to Die game folder'
    $dialog.ShowNewFolderButton = $false
    if (Test-Path -LiteralPath $pathBox.Text -PathType Container) {
        $dialog.SelectedPath = $pathBox.Text
    }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathBox.Text = $dialog.SelectedPath
    }
})

$scanButton.Add_Click({
    [void](Set-CurrentGameRootValidation -ShowDialog $true)
})

$applyButton.Add_Click({
    [void](Apply-PreviewSelection)
})

$howItWorksButton.Add_Click({
    Show-HowItWorksDialog -Owner $form
    Add-Activity -Message 'How It Works information opened.' -Color (New-Color 82 82 78)
})

$chooseLogFileButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Title = 'Choose Where to Save Recent Activity'
    $dialog.Filter = 'Text log (*.txt)|*.txt|Log file (*.log)|*.log|All files (*.*)|*.*'
    $dialog.DefaultExt = 'txt'
    $dialog.AddExtension = $true
    $dialog.OverwritePrompt = $true
    $dialog.FileName = "BitWrecked-HistoricalRandomStart-Activity-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:PersistentLogPath = $dialog.FileName
        $persistentLogPathLabel.Text = "Save location selected: $($dialog.FileName)"
        $persistentLogPathLabel.ForeColor = New-Color 82 82 78
        Add-Activity -Message 'A location was selected for saving recent activity.' -Color (New-Color 82 82 78)
    }
})

$persistentLogCheck.Add_CheckedChanged({
    if ($script:IsUpdatingPersistentLog) {
        return
    }

    if ($persistentLogCheck.Checked) {
        if ([string]::IsNullOrWhiteSpace($script:PersistentLogPath)) {
            $script:IsUpdatingPersistentLog = $true
            $persistentLogCheck.Checked = $false
            $script:IsUpdatingPersistentLog = $false
            [System.Windows.Forms.MessageBox]::Show('Choose a save location first. Recent activity is still visible here and will not be saved automatically.', 'Historical Random Start Preview', 'OK', 'Information') | Out-Null
            return
        }
        $script:PersistentLogEnabled = $true
        $persistentLogPathLabel.Text = "Saving activity: $script:PersistentLogPath"
        Add-Activity -Message 'Saving recent activity was turned on.' -Color (New-Color 82 82 78)
    }
    else {
        $script:PersistentLogEnabled = $false
        $persistentLogPathLabel.Text = if ([string]::IsNullOrWhiteSpace($script:PersistentLogPath)) { 'Activity is not saved automatically.' } else { "Saving is off; saved activity remains at: $script:PersistentLogPath" }
        Add-Activity -Message 'Saving recent activity was turned off. Existing saved activity was kept.' -Color (New-Color 82 82 78)
    }
})

$activityToggleButton.Add_Click({
    Set-ActivityLogExpanded -Expanded (-not $script:IsActivityLogExpanded)
})

$closeButton.Add_Click({ $form.Close() })
$form.Add_Shown({
    $form.ActiveControl = $browseButton
    Add-Activity -Message 'Preview opened. Your game will not be changed.' -Color (New-Color 82 82 78)
    if ($SmokeTest) {
        if ($script:HowItWorksCopy -notmatch 'opening trader quest points to the nearest trader') {
            throw 'Nearest-trader player guidance is missing.'
        }
        if ($script:Alpha6EvidenceUrl -ne 'https://7daystodie.com/?p=1150') {
            throw 'The official Alpha 6 evidence link changed unexpectedly.'
        }

        if ($script:HowItWorksCopy -notmatch 'keeps dangerous-biome hazards on unless you choose one safeguard' -or
            $script:HowItWorksCopy -notmatch 'Starting biome only' -or
            $script:HowItWorksCopy -notmatch 'All dangerous biomes') {
            throw 'Safeguard-scope guidance is missing.'
        }

        if ($script:HowItWorksCopy -notmatch 'two start types' -or
            $script:HowItWorksCopy -match 'Wilderness') {
            throw 'The player guidance is not limited to Standard and Random.'
        }

        if ($applyButton.Text -ne 'Apply Preview Settings' -or
            $previewOnlyLabel.Text -notmatch 'open session' -or
            $script:CurrentPreviewState -ne 'NotApplied') {
            throw 'The preview apply control did not initialize safely.'
        }

        $startTypeCount = @($designPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.RadioButton] }).Count
        $safeguardCount = @($randomSafeguardPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] }).Count

        if (-not $standardRadio.Checked -or
            $randomRadio.Checked -or
            $startTypeCount -ne 2 -or
            $safeguardCount -ne 2 -or
            $startingBiomeOnlyCheck.Checked -or
            $allDangerousBiomesCheck.Checked -or
            -not $startingBiomeOnlyCheck.Enabled -or
            -not $allDangerousBiomesCheck.Enabled -or
            $startingBiomeOnlyCheck.TabIndex -ne 0 -or
            $allDangerousBiomesCheck.TabIndex -ne 1 -or
            $randomSafeguardNote.Text -ne 'All biome hazards stay on. Choose one safeguard only if you want it for Random.') {
            throw 'The two start types and Random safeguards did not initialize safely.'
        }

        $startingBiomeOnlyCheck.Checked = $true
        if ($allDangerousBiomesCheck.Checked -or
            $randomSafeguardNote.Text -ne 'Your safeguard is ready for Random. Standard remains unchanged.') {
            throw 'Random safeguards did not remain available under Standard.'
        }

        $randomRadio.Checked = $true
        if (-not $startingBiomeOnlyCheck.Enabled -or
            -not $allDangerousBiomesCheck.Enabled -or
            $randomSafeguardNote.Text -ne 'Only your starting biome hazard turns off. Other dangerous biomes stay fully active.') {
            throw 'Starting-biome-only safeguard did not apply to Random.'
        }

        $allDangerousBiomesCheck.Checked = $true
        if ($startingBiomeOnlyCheck.Checked -or
            -not $allDangerousBiomesCheck.Checked -or
            $randomSafeguardNote.Text -ne 'All four dangerous-biome hazards turn off. Zombies, falls, and POI danger stay on.') {
            throw 'Safeguard choices were not mutually exclusive.'
        }

        $allDangerousBiomesCheck.Checked = $false
        if ($randomSafeguardNote.Text -ne 'All biome hazards stay on. Choose one safeguard only if you want it for Random.') {
            throw 'Random default-danger wording did not match the selected state.'
        }

        $startingBiomeOnlyCheck.Checked = $true
        $standardRadio.Checked = $true
        if (-not $startingBiomeOnlyCheck.Checked -or
            $allDangerousBiomesCheck.Checked -or
            -not $startingBiomeOnlyCheck.Enabled -or
            -not $allDangerousBiomesCheck.Enabled -or
            $randomSafeguardNote.Text -ne 'Your safeguard is ready for Random. Standard remains unchanged.') {
            throw 'Random safeguards were greyed out or changed Standard.'
        }

        $startingBiomeOnlyCheck.Checked = $false
        $allDangerousBiomesCheck.Checked = $false
        $script:SmokeTimer = New-Object System.Windows.Forms.Timer
        $script:SmokeTimer.Interval = 700
        $script:SmokeTimer.Add_Tick({
            $script:SmokeTimer.Stop()
            $form.Close()
        })
        $script:SmokeTimer.Start()
    }
})

Set-ActivityLogExpanded -Expanded $false
if ($PreviewWorkflowTestHost) {
    return
}

if (-not [string]::IsNullOrWhiteSpace($pathBox.Text) -and (Test-GameRoot -GameRoot $pathBox.Text)) {
    $script:FolderValidationState = 'Valid'
    $script:ValidatedGameRootKey = Get-PreviewGameRootKey -GameRoot $pathBox.Text
}
[void](Update-DesignState)

try {
    [void]$form.ShowDialog()
}
finally {
    if ($null -ne $script:SmokeTimer) {
        $script:SmokeTimer.Dispose()
    }
}
