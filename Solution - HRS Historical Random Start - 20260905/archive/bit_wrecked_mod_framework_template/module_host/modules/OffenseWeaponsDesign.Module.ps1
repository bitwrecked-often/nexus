# Bit Wrecked Module Host - Offense Weapons design-only module.
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later

function New-OffenseWeaponsDesignModule {
    $renderWorkspace = {
        param($Context)

        $panel = $Context.WorkspacePanel
        $columns = @(
            @{ Text = 'Weapon Effect'; Left = 16; Width = 126 },
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

        $empty = New-BitWreckedWorkspaceLabel -Text 'No weapon features are defined yet.' -Left 48 -Top 88 -Width 544 -Height 28 -AccessibleName 'Offense Weapons empty workspace' -FontSize 10
        $panel.Controls.Add($empty)
        $explanation = New-BitWreckedWorkspaceLabel -Text 'Approved effect groups and weapon rows will appear here after design review.' -Left 48 -Top 122 -Width 544 -Height 28 -AccessibleName 'Offense Weapons future row location'
        $panel.Controls.Add($explanation)

        $last = $Context.ModuleSessionState.LastValidation
        $lastMatchesRoot = $null -ne $last -and (Test-BitWreckedSamePath -First ([string]$last.GameRoot) -Second ([string]$Context.SelectedGameRoot))
        $statusText = if ($null -eq $last -or -not $lastMatchesRoot) {
            'Design workspace loaded. No payload or game-folder validation has run.'
        }
        else {
            [string]$last.Summary
        }
        $validation = New-BitWreckedWorkspaceLabel -Text $statusText -Left 38 -Top 174 -Width 564 -Height 48 -AccessibleName 'Offense Weapons validation result'
        $validation.ForeColor = if ([System.Windows.Forms.SystemInformation]::HighContrast) { [System.Drawing.SystemColors]::ControlText } elseif ($lastMatchesRoot -and $last.Status -eq 'success') { [System.Drawing.Color]::FromArgb(42, 112, 72) } else { [System.Drawing.Color]::FromArgb(118, 76, 51) }
        $panel.Controls.Add($validation)

        $boundary = New-BitWreckedWorkspaceLabel -Text 'Design Rows First | No payload | No game-file action is enabled' -Left 38 -Top 238 -Width 564 -Height 24 -AccessibleName 'Offense Weapons design boundary' -Bold $true
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
            return New-BitWreckedValidationResult -ModuleId $Request.ModuleId -RequestId $Request.RequestId -ContextGeneration $Request.ContextGeneration -GameRoot $Request.GameRoot -Status 'invalid' -Summary 'Folder not recognized as a local game root. Offense Weapons remains design-only; no changes made.' -Details @($localRoot.Reason, 'Expected 7DaysToDie.exe in the selected folder.', 'No weapons payload was inspected or created.')
        }

        return New-BitWreckedValidationResult -ModuleId $Request.ModuleId -RequestId $Request.RequestId -ContextGeneration $Request.ContextGeneration -GameRoot $Request.GameRoot -Status 'success' -Summary 'Game folder recognized. Offense Weapons has no payload yet; no changes made.' -Details @('7DaysToDie.exe was found.', 'No weapon rows, payload, installer, or removal action exists in this module.') -Observations ([pscustomobject]@{ GameRootRecognized = $true; PayloadState = 'design_only' })
    }

    return [pscustomobject]@{
        ContractVersion = '0.0.1'
        Id = 'offense_weapons_design'
        DisplayName = 'Offense Weapons'
        Version = '0.0.1'
        State = 'design'
        Description = 'Intentional empty offense-weapons workspace; no payload or weapon rows.'
        SupportedGameBuild = 'Design-only; no gameplay compatibility claim.'
        Columns = @('Weapon Effect', 'Control', 'Action', 'Current', 'Result')
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
        LineItemReference = '../bit_wrecked_offense_weapons_solution/versions/0.0.1/OFFENSE_WEAPONS_LINE_ITEM_MAP_0.0.1.md'
        WriteBoundary = 'none in this build'
        RecoveryReference = '../bit_wrecked_offense_weapons_design/WEAPONS_DESIGN_SHELL_MANIFEST.md'
    }
}
