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
$verifiedRuntimeSha256 = 'DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507'

# DEV working-tree test lane: build and deploy exact deterministic candidate.
# Set to $false for verified QA/release payload behavior.
$useDevCandidate = $true

$verifiedAssemblyCSharpMvid = [guid]'229796d0-95ca-4662-b426-1a6f1f1596ed'

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

$gameRoot = Select-HrsGameRoot -StartPath $managerRoot

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Bit Wrecked - Historical Random Start'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(620,500)
$form.MinimumSize = $form.Size

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Historical Random Start'
$title.Font = New-Object System.Drawing.Font('Segoe UI',18,[System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24,20)
$form.Controls.Add($title)

$version = New-Object System.Windows.Forms.Label
$version.Text = 'Release | 1.2.3 DEV'
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

$biomeProtectCheck = New-Object System.Windows.Forms.CheckBox
$biomeProtectCheck.Text = 'Protect from hazards in starting biome'
$biomeProtectCheck.AutoSize = $true
$biomeProtectCheck.Checked = $false
$biomeProtectCheck.Enabled = $false
$biomeProtectCheck.Location = New-Object System.Drawing.Point(30,247)
$form.Controls.Add($biomeProtectCheck)

$biomeNote = New-Object System.Windows.Forms.Label
$biomeNote.Text = "Optional. Protects this character from environmental hazards in the starting biome.`r`nHazards in other biomes remain active."
$biomeNote.AutoSize = $false
$biomeNote.Size = New-Object System.Drawing.Size(550,38)
$biomeNote.Location = New-Object System.Drawing.Point(27,273)
$biomeNote.ForeColor = [System.Drawing.Color]::FromArgb(70,70,70)
$form.Controls.Add($biomeNote)

$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Text = 'Apply Settings'
$applyButton.Size = New-Object System.Drawing.Size(120,38)
$applyButton.Location = New-Object System.Drawing.Point(27,319)
$form.Controls.Add($applyButton)

$launchButton = New-Object System.Windows.Forms.Button
$launchButton.Text = 'Launch Game'
$launchButton.Size = New-Object System.Drawing.Size(140,38)
$launchButton.Location = New-Object System.Drawing.Point(160,319)
$form.Controls.Add($launchButton)

$uninstallButton = New-Object System.Windows.Forms.Button
$uninstallButton.Text = 'Uninstall Mod'
$uninstallButton.Size = New-Object System.Drawing.Size(120,30)
$uninstallButton.Location = New-Object System.Drawing.Point(447,319)
$form.Controls.Add($uninstallButton)

$details = New-Object System.Windows.Forms.Label
$details.Text = "Game folder:`r`n$gameRoot"
$details.AutoSize = $false
$details.Size = New-Object System.Drawing.Size(550,55)
$details.Location = New-Object System.Drawing.Point(27,377)
$form.Controls.Add($details)

function Update-HrsStatus {
    $process = Get-HrsProcessState

    if ($process.Game -ne 'Closed') {
        $status.Text = 'Game is running - changes unavailable'
        $applyButton.Enabled = $false
        $launchButton.Enabled = $false
        $uninstallButton.Enabled = $false
        return
    }

    $applyButton.Enabled = $true
    $launchButton.Enabled = ($process.Steam -eq 'Running')
    $uninstallButton.Enabled = $true

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

$applyButton.Add_Click({
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

        if (-not (Test-Path -LiteralPath $paths.BridgeRoot -PathType Container)) {
            if (-not $useDevCandidate -and (Test-Path -LiteralPath $verifiedArtifactsRoot -PathType Container)) {
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

                $assemblyCSharp = [System.Reflection.Assembly]::ReflectionOnlyLoadFrom($assemblyCSharpPath)
                $installedMvid = $assemblyCSharp.ManifestModule.ModuleVersionId
                if ($installedMvid -ne $verifiedAssemblyCSharpMvid) {
                    throw "Game build mismatch. Required Assembly-CSharp MVID: $verifiedAssemblyCSharpMvid; installed: $installedMvid. Do not install this QA package."
                }

                $dllHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $verifiedDll).Hash

                if (-not [string]::Equals(
                    $dllHash,
                    $verifiedRuntimeSha256,
                    [System.StringComparison]::Ordinal
                )) {
                    throw 'Verified QA runtime hash mismatch. Do not install; redownload the QA package.'
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
                        '1.2.3',
                        [System.StringComparison]::Ordinal
                    )) {
                        throw 'mod version mismatch'
                    }
                }
                catch {
                    throw 'Verified QA ModInfo identity validation failed. Do not install; redownload the QA package.'
                }

                $status.Text = 'Installing verified Historical Random Start QA payload...'
                $form.Refresh()
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

            $manifest = New-HrsDeploymentManifest `
                -PayloadRoot $payloadRoot `
                -ReleaseVersion '1.2.3'

            $before = Test-HrsDeploymentInventory `
                -GameRoot $gameRoot `
                -Manifest $manifest

            if (-not $before.Valid -or $before.State -ne 'NotInstalled') {
                throw "Release destination is not safe to install: $($before.Reason)"
            }

            $paths = Get-HrsBridgePaths -GameRoot $gameRoot

            [void][System.IO.Directory]::CreateDirectory($paths.ReleaseRoot)
            [void][System.IO.Directory]::CreateDirectory($paths.BridgeRoot)

            [System.IO.File]::Copy(
                (Join-Path $payloadRoot 'd0163.dll'),
                (Join-Path $paths.ReleaseRoot 'd0163.dll'),
                $false
            )

            [System.IO.File]::Copy(
                (Join-Path $payloadRoot 'ModInfo.xml'),
                (Join-Path $paths.ReleaseRoot 'ModInfo.xml'),
                $false
            )

            $after = Test-HrsDeploymentInventory `
                -GameRoot $gameRoot `
                -Manifest $manifest

            if (-not $after.Valid -or $after.State -ne 'InstalledValid') {
                throw "Release installation verification failed: $($after.Reason)"
            }

            $status.Text = 'Historical Random Start installed and verified'
            $form.Refresh()
        }

        $mode = if (-not $randomRadio.Checked) { 'Standard' }
            elseif ($biomeProtectCheck.Checked) { 'RandomSafe' }
            else { 'Random' }

        $revision = [UInt64]1
        if (Test-Path -LiteralPath $paths.PolicyPath -PathType Leaf) {
            $current = Read-HrsPolicyFile -Path $paths.PolicyPath
            if ([UInt64]$current.revision -eq [UInt64]::MaxValue) {
                throw 'Policy revision is exhausted.'
            }
            $revision = [UInt64]$current.revision + 1
        }

        $policy = New-HrsPolicy `
            -Revision $revision `
            -GameName $gameName `
            -Mode $mode

        $modeLabel = if ($mode -eq 'RandomSafe') { 'Random start with starting-biome protection' }
            elseif ($mode -eq 'Random') { 'Random start' }
            else { 'Standard start' }

        $confirm = [System.Windows.Forms.MessageBox]::Show(
            $form,
            "$modeLabel`r`n`r`nNew game name: $gameName`r`n`r`nThe name must exactly match the game you create in 7 Days to Die.`r`nThe game will not launch automatically.",
            'Confirm Historical Random Start',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
            $status.Text = 'Settings canceled - no change made'
            return
        }

        $written = Write-HrsPolicyFile `
            -Path $paths.PolicyPath `
            -AllowedRoot $paths.BridgeRoot `
            -Policy $policy

        if ($mode -ne 'Standard') {
            $suffix = if ($mode -eq 'RandomSafe') { ' - Random start, starting-biome protection ON' } else { ' - Random start' }
            $status.Text = "Ready for $gameName$suffix"
        }
        else {
            $status.Text = "Ready for $gameName - Standard start"
        }
    }
    catch {
        $status.Text = "Settings blocked: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            $_.Exception.Message,
            'Historical Random Start',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
})

$randomRadio.Add_CheckedChanged({
    $biomeProtectCheck.Enabled = $randomRadio.Checked
})

$launchButton.Add_Click({
    try {
        $process = Get-HrsProcessState

        if ($process.Game -ne 'Closed') {
            throw '7 Days to Die is already running.'
        }

        if ($process.Steam -ne 'Running') {
            throw 'Steam must already be running.'
        }

        $exe = Join-Path $gameRoot '7DaysToDie.exe'
        if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
            throw '7DaysToDie.exe was not found.'
        }

        Start-Process -FilePath $exe -WorkingDirectory $gameRoot
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            $_.Exception.Message,
            'Historical Random Start',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
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
            -ReleaseVersion '1.2.3'

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
    $gameNameBox.Focus()
})

[void]$form.ShowDialog()
