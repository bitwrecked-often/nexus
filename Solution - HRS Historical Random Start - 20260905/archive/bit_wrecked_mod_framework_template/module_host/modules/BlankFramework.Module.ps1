# Bit Wrecked Module Host - Blank Framework read-only module.
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later

function New-BlankFrameworkModule {
    $renderWorkspace = {
        param($Context)

        $panel = $Context.WorkspacePanel
        $columns = @(
            @{ Text = 'Feature Group'; Left = 16; Width = 126 },
            @{ Text = 'Control'; Left = 148; Width = 118 },
            @{ Text = 'Action'; Left = 272; Width = 104 },
            @{ Text = 'Current'; Left = 382; Width = 118 },
            @{ Text = 'Result'; Left = 506; Width = 118 }
        )
        foreach ($column in $columns) {
            $header = New-BitWreckedWorkspaceLabel -Text $column.Text -Left $column.Left -Top 14 -Width $column.Width -Height 22 -AccessibleName "Column: $($column.Text)" -Bold $true
            $panel.Controls.Add($header)
        }

        $rule = New-Object System.Windows.Forms.Panel
        $rule.Location = New-Object System.Drawing.Point(16, 42)
        $rule.Size = New-Object System.Drawing.Size(608, 1)
        $rule.BackColor = if ([System.Windows.Forms.SystemInformation]::HighContrast) { [System.Drawing.SystemColors]::ControlDark } else { [System.Drawing.Color]::FromArgb(232, 230, 225) }
        $panel.Controls.Add($rule)

        $empty = New-BitWreckedWorkspaceLabel -Text 'No mod features are defined in the Blank Framework.' -Left 48 -Top 92 -Width 544 -Height 28 -AccessibleName 'Blank Framework empty workspace' -FontSize 10
        $panel.Controls.Add($empty)
        $explanation = New-BitWreckedWorkspaceLabel -Text 'This module proves the host contract without representing a payload.' -Left 48 -Top 124 -Width 544 -Height 26 -AccessibleName 'Blank Framework boundary'
        $panel.Controls.Add($explanation)

        $last = $Context.ModuleSessionState.LastValidation
        $lastMatchesRoot = $null -ne $last -and (Test-BitWreckedSamePath -First ([string]$last.GameRoot) -Second ([string]$Context.SelectedGameRoot))
        $statusText = if ($null -eq $last -or -not $lastMatchesRoot) {
            'Not validated. Module switching has performed no game-folder read.'
        }
        else {
            [string]$last.Summary
        }
        $validation = New-BitWreckedWorkspaceLabel -Text $statusText -Left 38 -Top 174 -Width 564 -Height 48 -AccessibleName 'Blank Framework validation result' -FontSize 8
        $validation.ForeColor = if ([System.Windows.Forms.SystemInformation]::HighContrast) { [System.Drawing.SystemColors]::ControlText } elseif ($lastMatchesRoot -and $last.Status -eq 'success') { [System.Drawing.Color]::FromArgb(42, 112, 72) } else { [System.Drawing.Color]::FromArgb(118, 76, 51) }
        $panel.Controls.Add($validation)

        $boundary = New-BitWreckedWorkspaceLabel -Text 'Read-only | No payload | No install, remove, restore, or package action' -Left 38 -Top 238 -Width 564 -Height 24 -AccessibleName 'Blank Framework action boundary' -Bold $true
        $boundary.ForeColor = if ([System.Windows.Forms.SystemInformation]::HighContrast) { [System.Drawing.SystemColors]::ControlText } else { [System.Drawing.Color]::FromArgb(130, 45, 35) }
        $panel.Controls.Add($boundary)

        $Context.ModuleSessionState.RenderCount = [int]$Context.ModuleSessionState.RenderCount + 1
        return [pscustomobject]@{ DefaultFocusControl = $null; RenderedRowCount = 0 }
    }

    $validateReadOnly = {
        param($Request)

        $localRoot = Resolve-BitWreckedLocalPath -Path ([string]$Request.GameRoot)
        $exePath = if (-not $localRoot.IsAllowed) { '' } else { Join-Path $localRoot.Path '7DaysToDie.exe' }
        if ([string]::IsNullOrWhiteSpace($exePath) -or -not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
            return New-BitWreckedValidationResult -ModuleId $Request.ModuleId -RequestId $Request.RequestId -ContextGeneration $Request.ContextGeneration -GameRoot $Request.GameRoot -Status 'invalid' -Summary 'Folder not recognized as a local 7 Days to Die game root. No changes made.' -Details @($localRoot.Reason, 'Expected 7DaysToDie.exe in the selected folder.', 'Blank Framework has no payload.')
        }

        return New-BitWreckedValidationResult -ModuleId $Request.ModuleId -RequestId $Request.RequestId -ContextGeneration $Request.ContextGeneration -GameRoot $Request.GameRoot -Status 'success' -Summary 'Game folder recognized. Blank Framework has no payload; no changes made.' -Details @('7DaysToDie.exe was found.', 'No Mods folder or game configuration was inspected.') -Observations ([pscustomobject]@{ GameRootRecognized = $true; PayloadState = 'none' })
    }

    return [pscustomobject]@{
        ContractVersion = '0.0.1'
        Id = 'blank_framework'
        DisplayName = 'Blank Framework'
        Version = '0.0.1'
        State = 'read_only'
        Description = 'Neutral framework module with no payload or feature rows.'
        SupportedGameBuild = 'Windows/Steam candidate root recognition only; no gameplay compatibility claim.'
        Columns = @('Feature Group', 'Control', 'Action', 'Current', 'Result')
        Capabilities = @('render', 'validate_read_only')
        NewSessionState = {
            return [ordered]@{
                LastValidation = $null
                LastGameRoot = ''
                RenderCount = 0
            }
        }
        RenderWorkspace = $renderWorkspace
        GetActionState = {
            param($Context)
            return @([pscustomobject]@{
                Id = 'validate'
                Label = 'Validate Current Game Settings'
                Kind = 'read_only'
                Visible = $true
                Enabled = [bool](Resolve-BitWreckedLocalPath -Path ([string]$Context.SelectedGameRoot)).IsAllowed
                UnavailableReason = 'Choose a game folder first.'
            })
        }
        ValidateReadOnly = $validateReadOnly
        ApplyValidationResult = {
            param($Context, $Result)
            $Context.ModuleSessionState.LastValidation = $Result
            $Context.ModuleSessionState.LastGameRoot = [string]$Result.GameRoot
        }
        Deactivate = { param($Context) }
        DisposeWorkspace = { param($Context) }
        LineItemReference = 'none'
        WriteBoundary = 'none in this build'
        RecoveryReference = 'MODULE_HOST_MANIFEST_0.0.1.md'
    }
}
