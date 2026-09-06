# Bit Wrecked Offense Weapons Design Tool - empty framework shell.
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This deliberately mirrors the proven Wasteland Animal Tuning tool's visual
# layout. It has no weapon rows, no payload, and no install/remove capability.

param(
    [switch]$SmokeTest
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $packageRoot
$script:PackageVersion = '0.0.1-design'
$script:PersistentLogEnabled = $false
$script:PersistentLogPath = ''
$script:IsUpdatingPersistentLog = $false
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

function Test-GameRoot {
    param([string]$GameRoot)

    if ([string]::IsNullOrWhiteSpace($GameRoot)) {
        return $false
    }
    return (Test-Path -LiteralPath (Join-Path $GameRoot '7DaysToDie.exe') -PathType Leaf)
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
        $script:PersistentLogPathLabel.Text = 'Save failed; runtime log remains available.'
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

function Set-Tip {
    param(
        [System.Windows.Forms.Control]$Control,
        [string]$Text
    )

    $toolTip.SetToolTip($Control, $Text)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Bit Wrecked - 7DTD Offense Weapons'
$form.ClientSize = New-Object System.Drawing.Size(620, 660)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = New-Color 250 249 247

$logoPath = Join-Path $workspaceRoot 'framework_reference_4.1.1\Support_Files_Do_Not_Edit\Assets\bit-wrecked-channel-avatar.png'
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
$title.Text = '7DTD Offense Weapons'
$title.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = New-Color 32 32 32
$title.AutoSize = $false
$title.Location = New-Object System.Drawing.Point(90, 40)
$title.Size = New-Object System.Drawing.Size(504, 30)
$form.Controls.Add($title)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = 'Design workspace | Version 0.0.1'
$versionLabel.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$versionLabel.ForeColor = New-Color 92 92 88
$versionLabel.AutoSize = $true
$versionLabel.Location = New-Object System.Drawing.Point(92, 70)
$form.Controls.Add($versionLabel)

$designLabel = New-Object System.Windows.Forms.Label
$designLabel.Text = 'No payload yet'
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
$stateValue.Text = 'Design workspace - choose a game folder when ready.'
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
    @{ Text = 'Weapon Effect'; Left = 22; Width = 118 },
    @{ Text = 'Control'; Left = 166; Width = 108 },
    @{ Text = 'Action'; Left = 261; Width = 82 },
    @{ Text = 'Current'; Left = 343; Width = 100 },
    @{ Text = 'Result'; Left = 447; Width = 90 }
)
foreach ($header in $headers) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $header.Text
    $label.Font = New-Object System.Drawing.Font('Segoe UI', 8)
    $label.ForeColor = New-Color 110 110 105
    $label.Location = New-Object System.Drawing.Point($header.Left, 25)
    $label.Size = New-Object System.Drawing.Size($header.Width, 18)
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $designPanel.Controls.Add($label)
}

$headerRule = New-Object System.Windows.Forms.Panel
$headerRule.Location = New-Object System.Drawing.Point(18, 45)
$headerRule.Size = New-Object System.Drawing.Size(528, 1)
$headerRule.BackColor = New-Color 236 234 229
$designPanel.Controls.Add($headerRule)

$emptyState = New-Object System.Windows.Forms.Label
$emptyState.Text = "No weapon features defined yet.`r`n`r`nApproved effect groups and weapon rows will appear here."
$emptyState.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$emptyState.ForeColor = New-Color 110 110 105
$emptyState.Location = New-Object System.Drawing.Point(38, 88)
$emptyState.Size = New-Object System.Drawing.Size(490, 62)
$emptyState.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$designPanel.Controls.Add($emptyState)

$emptySubstate = New-Object System.Windows.Forms.Label
$emptySubstate.Text = 'Design only. No payload or game-file action is enabled.'
$emptySubstate.Font = New-Object System.Drawing.Font('Segoe UI', 7.5)
$emptySubstate.ForeColor = New-Color 130 45 35
$emptySubstate.Location = New-Object System.Drawing.Point(28, 168)
$emptySubstate.Size = New-Object System.Drawing.Size(510, 18)
$emptySubstate.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$designPanel.Controls.Add($emptySubstate)

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = 'Validate Current Game Settings'
$scanButton.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$scanButton.FlatStyle = 'Flat'
$scanButton.FlatAppearance.BorderSize = 0
$scanButton.BackColor = [System.Drawing.Color]::White
$scanButton.ForeColor = New-Color 38 38 36
$scanButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$scanButton.Location = New-Object System.Drawing.Point(179, 216)
$scanButton.Size = New-Object System.Drawing.Size(210, 30)
$designPanel.Controls.Add($scanButton)
Enable-RoundedBorder -Control $scanButton -Radius 15 -BorderColor (New-Color 208 208 202)

$reservedPanel = New-Object System.Windows.Forms.Panel
$reservedPanel.Location = New-Object System.Drawing.Point(27, 498)
$reservedPanel.Size = New-Object System.Drawing.Size(567, 44)
$reservedPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($reservedPanel)
Enable-RoundedBorder -Control $reservedPanel -Radius 16 -BorderColor (New-Color 226 224 218)

$reservedCheck = New-Object System.Windows.Forms.CheckBox
$reservedCheck.Text = 'Reserved capability - not defined'
$reservedCheck.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 8.5, [System.Drawing.FontStyle]::Bold)
$reservedCheck.ForeColor = New-Color 130 45 35
$reservedCheck.AutoSize = $false
$reservedCheck.Location = New-Object System.Drawing.Point(16, 10)
$reservedCheck.Size = New-Object System.Drawing.Size(520, 24)
$reservedCheck.Enabled = $false
$reservedPanel.Controls.Add($reservedCheck)

$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = 'Design Rows First'
$installButton.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$installButton.FlatStyle = 'Flat'
$installButton.FlatAppearance.BorderSize = 0
$installButton.BackColor = New-Color 238 240 237
$installButton.ForeColor = New-Color 110 110 105
$installButton.Location = New-Object System.Drawing.Point(27, 561)
$installButton.Size = New-Object System.Drawing.Size(206, 42)
$installButton.Enabled = $false
$form.Controls.Add($installButton)
Enable-RoundedBorder -Control $installButton -Radius 21 -BorderColor (New-Color 208 208 202)

$actionDot = New-Object System.Windows.Forms.Label
$actionDot.Text = [char]0x2191
$actionDot.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$actionDot.ForeColor = New-Color 156 156 150
$actionDot.BackColor = [System.Drawing.Color]::White
$actionDot.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$actionDot.Location = New-Object System.Drawing.Point(184, 562)
$actionDot.Size = New-Object System.Drawing.Size(40, 40)
$actionDot.Visible = $false
$form.Controls.Add($actionDot)
Set-RoundedRegion -Control $actionDot -Radius 20
$actionDot.BringToFront()

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = 'Remove Mod'
$removeButton.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$removeButton.FlatStyle = 'Flat'
$removeButton.FlatAppearance.BorderSize = 0
$removeButton.BackColor = [System.Drawing.Color]::White
$removeButton.ForeColor = New-Color 110 110 105
$removeButton.Location = New-Object System.Drawing.Point(249, 561)
$removeButton.Size = New-Object System.Drawing.Size(112, 42)
$removeButton.Enabled = $false
$form.Controls.Add($removeButton)
Enable-RoundedBorder -Control $removeButton -Radius 21 -BorderColor (New-Color 208 208 202)

$openFolderButton = New-Object System.Windows.Forms.Button
$openFolderButton.Text = 'Open Mods Folder'
$openFolderButton.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$openFolderButton.FlatStyle = 'Flat'
$openFolderButton.FlatAppearance.BorderSize = 0
$openFolderButton.BackColor = [System.Drawing.Color]::White
$openFolderButton.ForeColor = New-Color 38 38 36
$openFolderButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$openFolderButton.Location = New-Object System.Drawing.Point(371, 561)
$openFolderButton.Size = New-Object System.Drawing.Size(130, 42)
$form.Controls.Add($openFolderButton)
Enable-RoundedBorder -Control $openFolderButton -Radius 21 -BorderColor (New-Color 208 208 202)

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
$activityTitle.Text = 'Layered Reasoning Log / Recent Actions'
$activityTitle.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 9, [System.Drawing.FontStyle]::Bold)
$activityTitle.ForeColor = New-Color 38 38 36
$activityTitle.Location = New-Object System.Drawing.Point(14, 12)
$activityTitle.Size = New-Object System.Drawing.Size(410, 20)
$activityPanel.Controls.Add($activityTitle)

$status = New-Object System.Windows.Forms.Label
$status.Text = 'Ready - design shell has no payload.'
$status.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$status.Location = New-Object System.Drawing.Point(14, 36)
$status.Size = New-Object System.Drawing.Size(415, 20)
$status.ForeColor = New-Color 82 82 78
$status.AutoEllipsis = $true
$activityPanel.Controls.Add($status)

$persistentLogCheck = New-Object System.Windows.Forms.CheckBox
$persistentLogCheck.Text = 'Persistent log'
$persistentLogCheck.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$persistentLogCheck.ForeColor = New-Color 55 55 52
$persistentLogCheck.Location = New-Object System.Drawing.Point(14, 58)
$persistentLogCheck.Size = New-Object System.Drawing.Size(122, 24)
$activityPanel.Controls.Add($persistentLogCheck)
$script:PersistentLogCheck = $persistentLogCheck

$chooseLogFileButton = New-Object System.Windows.Forms.Button
$chooseLogFileButton.Text = 'Choose Log File'
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
$persistentLogPathLabel.Text = 'Runtime only - clears when this application restarts.'
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
$activityLog.Text = "[$(Get-Date -Format 'HH:mm:ss')] Ready.$([Environment]::NewLine)[$(Get-Date -Format 'HH:mm:ss')] DESIGN | Empty shell; no weapon rows or payload are configured.$([Environment]::NewLine)"
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
    if (Test-GameRoot -GameRoot $pathBox.Text) {
        $stateAccent.BackColor = New-Color 83 158 98
        $stateValue.Text = 'Game folder recognized - no weapons payload is configured.'
        Set-Status -Message 'Validated game folder. Design workspace remains read-only and payload-free.' -Color (New-Color 82 82 78)
    }
    else {
        $stateAccent.BackColor = New-Color 156 156 150
        $stateValue.Text = 'Design shell - choose a valid 7 Days to Die game folder.'
        Set-Status -Message 'No valid game folder selected. No file action is available.' -Color (New-Color 130 45 35)
    }
}

Set-Tip -Control $statePanel -Text 'Shows this workspace is a design-only shell. It cannot install or remove a mod.'
Set-Tip -Control $pathBox -Text 'Choose the main 7 Days to Die folder containing 7DaysToDie.exe, not its Mods folder.'
Set-Tip -Control $browseButton -Text 'Select a game folder only. This does not install or change anything.'
Set-Tip -Control $designPanel -Text 'This deliberately empty table is where approved offense-weapon effect rows will appear later.'
Set-Tip -Control $scanButton -Text 'Read-only folder validation. No game, mod, or server configuration is changed.'
Set-Tip -Control $reservedPanel -Text 'Reserved for an explicit future capability. It is disabled because no safe, approved behavior is defined.'
Set-Tip -Control $installButton -Text 'Disabled until a line-item map, payload, tests, and release approval exist.'
Set-Tip -Control $removeButton -Text 'Disabled because this design shell never installs a mod.'
Set-Tip -Control $openFolderButton -Text 'Open an existing Mods folder only. This design shell will never create it.'
Set-Tip -Control $activityToggleButton -Text 'Show or hide the runtime activity log.'

$browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Select your 7 Days to Die game folder'
    $dialog.ShowNewFolderButton = $false
    if (Test-Path -LiteralPath $pathBox.Text -PathType Container) {
        $dialog.SelectedPath = $pathBox.Text
    }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathBox.Text = $dialog.SelectedPath
        Add-Activity -Message "Selected game folder: $($dialog.SelectedPath)" -Color (New-Color 82 82 78)
        Update-DesignState
    }
})

$scanButton.Add_Click({
    if (Test-GameRoot -GameRoot $pathBox.Text) {
        [System.Windows.Forms.MessageBox]::Show(
            "Game folder recognized.`n`nNo offense-weapon line items exist yet.`nNo payload, installer, or game-file write action is enabled.",
            'Offense Weapons Design Workspace',
            'OK',
            'Information'
        ) | Out-Null
    }
    Update-DesignState
})

$openFolderButton.Add_Click({
    if (-not (Test-GameRoot -GameRoot $pathBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show('Choose a valid 7 Days to Die game folder first.', 'Offense Weapons Design Workspace', 'OK', 'Warning') | Out-Null
        Add-Activity -Message 'Open Mods Folder blocked: valid game folder required.' -Color (New-Color 130 45 35)
        return
    }

    $modsPath = Join-Path $pathBox.Text 'Mods'
    if (-not (Test-Path -LiteralPath $modsPath -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show('No Mods folder exists. This design shell will not create one.', 'Offense Weapons Design Workspace', 'OK', 'Information') | Out-Null
        Add-Activity -Message 'Open Mods Folder skipped: folder does not exist and this shell performs no writes.' -Color (New-Color 130 45 35)
        return
    }

    Start-Process explorer.exe -ArgumentList @($modsPath)
    Add-Activity -Message "Opened existing Mods folder: $modsPath" -Color (New-Color 82 82 78)
})

$chooseLogFileButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Title = 'Choose Where to Save the Layered Reasoning Log'
    $dialog.Filter = 'Text log (*.txt)|*.txt|Log file (*.log)|*.log|All files (*.*)|*.*'
    $dialog.DefaultExt = 'txt'
    $dialog.AddExtension = $true
    $dialog.OverwritePrompt = $true
    $dialog.FileName = "BitWrecked-OffenseWeapons-Design-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:PersistentLogPath = $dialog.FileName
        $persistentLogPathLabel.Text = "Selected: $($dialog.FileName)"
        $persistentLogPathLabel.ForeColor = New-Color 82 82 78
        Add-Activity -Message "Persistent log destination selected: $($dialog.FileName)" -Color (New-Color 82 82 78)
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
            [System.Windows.Forms.MessageBox]::Show('Choose a log file first. Runtime logging remains active and is not saved automatically.', 'Offense Weapons Design Workspace', 'OK', 'Information') | Out-Null
            return
        }
        $script:PersistentLogEnabled = $true
        $persistentLogPathLabel.Text = "Saving: $script:PersistentLogPath"
        Add-Activity -Message 'Persistent activity logging enabled by user choice.' -Color (New-Color 82 82 78)
    }
    else {
        $script:PersistentLogEnabled = $false
        $persistentLogPathLabel.Text = if ([string]::IsNullOrWhiteSpace($script:PersistentLogPath)) { 'Runtime only - clears when this application restarts.' } else { "Persistence off; saved file remains: $script:PersistentLogPath" }
        Add-Activity -Message 'Persistent activity logging disabled; runtime log continues.' -Color (New-Color 82 82 78)
    }
})

$activityToggleButton.Add_Click({
    Set-ActivityLogExpanded -Expanded (-not $script:IsActivityLogExpanded)
})

$closeButton.Add_Click({ $form.Close() })
$form.Add_Shown({
    $form.ActiveControl = $browseButton
    Add-Activity -Message 'Design workspace started. No weapon rows, payload, installer, removal, or game-file write action is available.' -Color (New-Color 82 82 78)
    if ($SmokeTest) {
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
if (-not [string]::IsNullOrWhiteSpace($pathBox.Text)) {
    Update-DesignState
}

try {
    [void]$form.ShowDialog()
}
finally {
    if ($null -ne $script:SmokeTimer) {
        $script:SmokeTimer.Dispose()
    }
}
