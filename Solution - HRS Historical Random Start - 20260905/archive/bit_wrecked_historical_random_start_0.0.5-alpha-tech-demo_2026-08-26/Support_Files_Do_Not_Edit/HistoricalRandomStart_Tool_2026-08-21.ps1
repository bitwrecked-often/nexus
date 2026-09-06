# Bit Wrecked Historical Random Start - Alpha Core Manager
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$packageRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$managerRoot   = Split-Path -Parent $packageRoot
$launcherRoot  = Join-Path $managerRoot 'src\launcher'
$verifiedArtifactsRoot = Join-Path $managerRoot 'VERIFIED_ARTIFACTS_2026-08-27'
$verifiedPayloadRoot = Join-Path $verifiedArtifactsRoot 'main_runtime'
$verifiedRuntimeSha256 = '96AFCBD7D967B45C58F8B4A8728439909A30A66CBBC9F56269896E2444DF3FFD'
$verifiedModInfoSha256 = 'B6812606D072B0392DE7643C11EFF8B10C0B3253C24DF16ECDC0D3DD3A1BD355'
$verifiedAssemblyCSharpMvid = [guid]'326ffd03-1d6d-4efb-a7dc-79201537b1c3'

Import-Module (Join-Path $launcherRoot 'HistoricalRandomStart.Copy.psm1') -Force
Import-Module (Join-Path $launcherRoot 'HistoricalRandomStart.Deployment.psm1') -Force
Import-Module (Join-Path $launcherRoot 'HistoricalRandomStart.Management.psm1') -Force
Import-Module (Join-Path $launcherRoot 'HistoricalRandomStart.State.psm1') -Force

# Import Core last because dependent modules also load Core internally.
# The manager requires Core's public commands in the caller session.
Import-Module (Join-Path $launcherRoot 'HistoricalRandomStart.Core.psm1') -Force

# Solution lives:
# <GameRoot>\_game_dev_ai_tracking\solutions\bit_wrecked_historical_random_start_0.0.5-alpha-tech-demo_2026-08-26
$gameRoot = Split-Path -Parent (
    Split-Path -Parent (
        Split-Path -Parent $managerRoot
    )
)

function Resolve-HrsApprovedQaPayload {
    if (-not (Test-Path -LiteralPath $verifiedArtifactsRoot -PathType Container)) {
        return $null
    }

    $verifiedDll = Join-Path $verifiedPayloadRoot 'HistoricalRandomStart.dll'
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
    $modInfoHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $verifiedModInfo).Hash
    if (-not [string]::Equals($dllHash, $verifiedRuntimeSha256, [System.StringComparison]::Ordinal) -or
        -not [string]::Equals($modInfoHash, $verifiedModInfoSha256, [System.StringComparison]::Ordinal)) {
        throw 'Verified QA payload hash mismatch. Do not install; redownload the QA package.'
    }

    $manifest = New-HrsDeploymentManifest `
        -PayloadRoot $verifiedPayloadRoot `
        -ReleaseVersion '0.0.5-alpha-tech-demo'
    return [pscustomobject]@{
        PayloadRoot = $verifiedPayloadRoot
        Manifest = $manifest
        Source = 'VerifiedQaPackage'
    }
}

$approvedPayload = $null
$approvedPayloadError = $null
try { $approvedPayload = Resolve-HrsApprovedQaPayload }
catch { $approvedPayloadError = $_.Exception.Message }

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Bit Wrecked - Historical Random Start'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(620,430)
$form.MinimumSize = $form.Size

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Historical Random Start'
$title.Font = New-Object System.Drawing.Font('Segoe UI',18,[System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24,20)
$form.Controls.Add($title)

$version = New-Object System.Windows.Forms.Label
$version.Text = 'Alpha Tech Demo | 0.0.5-alpha-tech-demo'
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
$gameLabel.Text = 'New Game Name'
$gameLabel.AutoSize = $true
$gameLabel.Location = New-Object System.Drawing.Point(27,150)
$form.Controls.Add($gameLabel)

$gameNameBox = New-Object System.Windows.Forms.TextBox
$gameNameBox.Size = New-Object System.Drawing.Size(540,25)
$gameNameBox.Location = New-Object System.Drawing.Point(27,174)
$form.Controls.Add($gameNameBox)

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

$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Text = 'Apply'
$applyButton.Size = New-Object System.Drawing.Size(120,38)
$applyButton.Location = New-Object System.Drawing.Point(27,270)
$form.Controls.Add($applyButton)

$launchButton = New-Object System.Windows.Forms.Button
$launchButton.Text = 'Launch Game'
$launchButton.Size = New-Object System.Drawing.Size(140,38)
$launchButton.Location = New-Object System.Drawing.Point(160,270)
$form.Controls.Add($launchButton)

$details = New-Object System.Windows.Forms.Label
$details.Text = "Game folder:`r`n$gameRoot"
$details.AutoSize = $false
$details.Size = New-Object System.Drawing.Size(550,55)
$details.Location = New-Object System.Drawing.Point(27,330)
$form.Controls.Add($details)

function Update-HrsStatus {
    $process = Get-HrsProcessState

    if ($process.Game -ne 'Closed') {
        $status.Text = 'Game is running - changes unavailable'
        $applyButton.Enabled = $false
        $launchButton.Enabled = $false
        return
    }

    $applyButton.Enabled = $true
    $launchButton.Enabled = ($process.Steam -eq 'Running')

    try {
        $paths = Get-HrsBridgePaths -GameRoot $gameRoot
        if (-not [string]::IsNullOrWhiteSpace($approvedPayloadError)) {
            $status.Text = "Setup blocked - $approvedPayloadError"
            $applyButton.Enabled = $false
            return
        }
        if ($null -eq $approvedPayload) {
            if (Test-Path -LiteralPath $paths.ReleaseRoot) {
                $status.Text = 'Setup blocked - installed payload cannot be verified without an approved candidate'
                $applyButton.Enabled = $false
            }
            else {
                $status.Text = 'DEV build required - Apply will build and verify the candidate'
            }
            return
        }

        $inventory = Test-HrsDeploymentInventory -GameRoot $gameRoot -Manifest $approvedPayload.Manifest
        $decision = Get-HrsDeploymentUiDecision -Inventory $inventory -ApprovedPayloadAvailable $true
        $status.Text = $decision.Status
        $applyButton.Enabled = $decision.ApplyAllowed
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
            throw 'Game is running. Close it before Apply.'
        }

        $gameName = $gameNameBox.Text

        $nameCheck = Test-HrsExactGameName -GameName $gameName
        if (-not $nameCheck.Valid) {
            throw "New Game Name is invalid: $($nameCheck.Reason)"
        }

        $paths = Get-HrsBridgePaths -GameRoot $gameRoot
        if (-not [string]::IsNullOrWhiteSpace($approvedPayloadError)) {
            throw $approvedPayloadError
        }

        if ($null -eq $approvedPayload) {
            if (Test-Path -LiteralPath $paths.ReleaseRoot) {
                throw 'Installed payload cannot be verified without an approved candidate.'
            }
            else {
                $buildScript = Join-Path $managerRoot 'src\runtime\Build-AlphaCoreRelease.ps1'

                if (-not (Test-Path -LiteralPath $buildScript -PathType Leaf)) {
                    throw 'Alpha Core build script was not found.'
                }

                $status.Text = 'Building Historical Random Start release...'
                $form.Refresh()

                $buildRecord = & $buildScript -GameRoot $gameRoot

                if ($null -eq $buildRecord -or [string]::IsNullOrWhiteSpace([string]$buildRecord.candidateRoot)) {
                    throw 'Build did not return a candidate release.'
                }

                $payloadRoot = Join-Path $buildRecord.candidateRoot 'BitWrecked_HistoricalRandomStart'
                $approvedPayload = [pscustomobject]@{
                    PayloadRoot = $payloadRoot
                    Manifest = New-HrsDeploymentManifest -PayloadRoot $payloadRoot -ReleaseVersion '0.0.5-alpha-tech-demo'
                    Source = 'DevBuild'
                }
            }
        }

        $manifest = $approvedPayload.Manifest
        $payloadRoot = $approvedPayload.PayloadRoot
        $before = Test-HrsDeploymentInventory -GameRoot $gameRoot -Manifest $manifest
        $beforeDecision = Get-HrsDeploymentUiDecision -Inventory $before -ApprovedPayloadAvailable $true
        if (-not $beforeDecision.ApplyAllowed) {
            throw "Release destination is not safe to use: $($beforeDecision.Status) [$($before.Reason)]"
        }

        if ($before.State -ceq 'NotInstalled') {
            $status.Text = 'Installing verified Historical Random Start payload...'
            $form.Refresh()
            $paths = Get-HrsBridgePaths -GameRoot $gameRoot

            [void][System.IO.Directory]::CreateDirectory($paths.ReleaseRoot)
            [void][System.IO.Directory]::CreateDirectory($paths.BridgeRoot)

            [System.IO.File]::Copy(
                (Join-Path $payloadRoot 'HistoricalRandomStart.dll'),
                (Join-Path $paths.ReleaseRoot 'HistoricalRandomStart.dll'),
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

            $status.Text = 'Historical Random Start release installed - verified'
            $form.Refresh()
        }

        $mode = if ($randomRadio.Checked) { 'Random' } else { 'Standard' }

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

        $confirm = [System.Windows.Forms.MessageBox]::Show(
            $form,
            "Apply $mode start policy to exact new game name:`r`n`r`n$gameName`r`n`r`nThe game will not be launched automatically.",
            'Confirm Historical Random Start',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
            $status.Text = 'Apply canceled - no change made'
            return
        }

        $written = Write-HrsPolicyAfterDeploymentValidation `
            -GameRoot $gameRoot `
            -Manifest $manifest `
            -Path $paths.PolicyPath `
            -AllowedRoot $paths.BridgeRoot `
            -Policy $policy

        if ($mode -eq 'Random') {
            $status.Text = "Historical Random Start enabled for $gameName - confirmed"
        }
        else {
            $status.Text = "Standard start restored for $gameName - confirmed"
        }
    }
    catch {
        $status.Text = "Apply blocked: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            $_.Exception.Message,
            'Historical Random Start',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
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

$form.Add_Shown({
    Update-HrsStatus
    $gameNameBox.Focus()
})

[void]$form.ShowDialog()



