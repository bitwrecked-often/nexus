# Bit Wrecked Module Host 0.0.1
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later

[CmdletBinding()]
param(
    [switch]$LibraryOnly,
    [switch]$HeadlessValidate,
    [switch]$SmokeTest,
    [string]$ModuleId = '',
    [string]$GameRoot = '',
    [string]$RequestId = '',
    [long]$ContextGeneration = 0,
    [int]$TestValidationDelayMs = 0,
    [string]$TestGameRoot = ''
)

$script:BitWreckedHostVersion = '0.0.1'
$script:BitWreckedHostRoot = $PSScriptRoot
$script:BitWreckedTemplateRoot = Split-Path -Parent $PSScriptRoot
$script:BitWreckedHostScriptPath = $MyInvocation.MyCommand.Path
$script:BWHRuntime = $null

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
. (Join-Path $PSScriptRoot 'modules\ModuleContract.ps1')

function Get-BitWreckedStateLabel {
    param([string]$State)
    switch ($State) {
        'read_only' { return 'Read-only' }
        'design' { return 'Design / No Payload' }
        default { return 'Unavailable' }
    }
}

function Get-BitWreckedEnvironmentOrValue {
    param([string]$Value, [string]$EnvironmentName)
    if (-not [string]::IsNullOrWhiteSpace($Value) -and $Value -ne '0') { return $Value }
    return [string][System.Environment]::GetEnvironmentVariable($EnvironmentName, [System.EnvironmentVariableTarget]::Process)
}

function Invoke-BitWreckedHeadlessValidation {
    $requestedModuleId = Get-BitWreckedEnvironmentOrValue -Value $ModuleId -EnvironmentName 'BITWRECKED_MODULE_ID'
    $requestedGameRoot = Get-BitWreckedEnvironmentOrValue -Value $GameRoot -EnvironmentName 'BITWRECKED_GAME_ROOT'
    $requestedId = Get-BitWreckedEnvironmentOrValue -Value $RequestId -EnvironmentName 'BITWRECKED_REQUEST_ID'
    $generationText = Get-BitWreckedEnvironmentOrValue -Value ([string]$ContextGeneration) -EnvironmentName 'BITWRECKED_CONTEXT_GENERATION'
    $delayText = Get-BitWreckedEnvironmentOrValue -Value ([string]$TestValidationDelayMs) -EnvironmentName 'BITWRECKED_TEST_DELAY_MS'
    $generation = [long]0
    $delay = 0
    [void][long]::TryParse($generationText, [ref]$generation)
    [void][int]::TryParse($delayText, [ref]$delay)
    if ([string]::IsNullOrWhiteSpace($requestedId)) { $requestedId = [guid]::NewGuid().ToString('N') }

    $loaded = Import-BitWreckedAllowlistedModules -ModuleHostRoot $script:BitWreckedHostRoot -TemplateRoot $script:BitWreckedTemplateRoot
    $definition = @($loaded.Definitions | Where-Object { $_.Id -ceq $requestedModuleId }) | Select-Object -First 1
    if ($null -eq $definition) {
        $result = New-BitWreckedValidationResult -ModuleId $requestedModuleId -RequestId $requestedId -ContextGeneration $generation -GameRoot $requestedGameRoot -Status 'error' -Summary 'The requested module is not in the reviewed registry.' -Details @($loaded.Errors, 'No changes were made.')
    }
    else {
        if ($delay -gt 0 -and $delay -le 10000) { [System.Threading.Thread]::Sleep($delay) }
        $request = New-BitWreckedValidationRequest -ModuleId $requestedModuleId -RequestId $requestedId -ContextGeneration $generation -GameRoot $requestedGameRoot
        $result = Invoke-BitWreckedModuleValidation -Definition $definition -Request $request
    }
    [Console]::Out.WriteLine(($result | ConvertTo-Json -Depth 20 -Compress))
    return $(if ($result.Status -eq 'error') { 2 } else { 0 })
}

if ($HeadlessValidate) {
    $headlessExitCode = Invoke-BitWreckedHeadlessValidation
    exit $headlessExitCode
}

function Get-BitWreckedPalette {
    param([switch]$ForceHighContrast)
    $highContrast = $ForceHighContrast -or [System.Windows.Forms.SystemInformation]::HighContrast
    if ($highContrast) {
        return [pscustomobject]@{
            HighContrast = $true; Window = [System.Drawing.SystemColors]::Window
            Panel = [System.Drawing.SystemColors]::Control; Text = [System.Drawing.SystemColors]::ControlText
            Muted = [System.Drawing.SystemColors]::GrayText; Accent = [System.Drawing.SystemColors]::Highlight
            AccentText = [System.Drawing.SystemColors]::HighlightText; Border = [System.Drawing.SystemColors]::ControlDark
            Good = [System.Drawing.SystemColors]::ControlText; Warning = [System.Drawing.SystemColors]::ControlText
        }
    }
    return [pscustomobject]@{
        HighContrast = $false; Window = [System.Drawing.Color]::FromArgb(250, 249, 247)
        Panel = [System.Drawing.Color]::White; Text = [System.Drawing.Color]::FromArgb(45, 45, 43)
        Muted = [System.Drawing.Color]::FromArgb(105, 102, 96); Accent = [System.Drawing.Color]::FromArgb(76, 151, 91)
        AccentText = [System.Drawing.Color]::White; Border = [System.Drawing.Color]::FromArgb(224, 222, 216)
        Good = [System.Drawing.Color]::FromArgb(42, 112, 72); Warning = [System.Drawing.Color]::FromArgb(130, 45, 35)
    }
}

function New-BitWreckedActivityState {
    param([int]$VisibleLimit = 500)
    return [pscustomobject]@{
        Events = New-Object System.Collections.ArrayList
        VisibleEvents = New-Object System.Collections.ArrayList
        VisibleLimit = [Math]::Max(10, $VisibleLimit)
        PersistentEnabled = $false
        PersistentPath = ''
        LogBox = $null
    }
}

function ConvertTo-BitWreckedSingleLogLine {
    param([string]$Text)
    $single = ([string]$Text -replace '[\r\n]+', ' | ' -replace '[\u0000-\u0008\u000B\u000C\u000E-\u001F]', '').Trim()
    if ([string]::IsNullOrWhiteSpace($single)) { return '(no detail)' }
    return $single
}

function Set-BitWreckedPersistentLog {
    param(
        [Parameter(Mandatory = $true)][object]$State,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][bool]$Enable,
        [string]$DisallowedRoot = ''
    )
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Choose a persistent log file first.' }
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $parent = Split-Path -Parent $fullPath
    $localParent = Resolve-BitWreckedLocalPath -Path $parent
    if (-not $localParent.IsAllowed -or -not (Test-Path -LiteralPath $localParent.Path -PathType Container)) {
        throw 'Persistent logging requires an existing folder on a local Windows drive.'
    }
    if (-not [string]::IsNullOrWhiteSpace($DisallowedRoot)) {
        $blocked = Resolve-BitWreckedLocalPath -Path $DisallowedRoot
        if ($blocked.IsAllowed) {
            $blockedPrefix = $blocked.Path.TrimEnd('\') + '\'
            if ($fullPath.StartsWith($blockedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw 'Choose a log location outside the selected game folder.'
            }
        }
    }
    $State.PersistentPath = $fullPath
    $State.PersistentEnabled = $Enable
    return $fullPath
}

function Add-BitWreckedActivity {
    param(
        [Parameter(Mandatory = $true)][object]$State,
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('info', 'success', 'warning', 'error')][string]$Severity = 'info'
    )
    $safeTag = ConvertTo-BitWreckedSingleLogLine -Text $Tag
    $safeMessage = ConvertTo-BitWreckedSingleLogLine -Text $Message
    $event = [pscustomobject]@{
        TimestampUtc = [datetime]::UtcNow.ToString('o')
        Tag = $safeTag
        Severity = $Severity
        Message = $safeMessage
        Line = "[$([datetime]::Now.ToString('HH:mm:ss'))] [$safeTag] $safeMessage"
    }
    [void]$State.Events.Add($event)
    [void]$State.VisibleEvents.Add($event)
    $trimmed = $false
    while ($State.VisibleEvents.Count -gt $State.VisibleLimit) {
        $State.VisibleEvents.RemoveAt(0)
        $trimmed = $true
    }
    $box = $State.LogBox
    if ($null -ne $box -and -not $box.IsDisposed) {
        if ($trimmed) {
            $box.Text = (@($State.VisibleEvents | ForEach-Object { $_.Line }) -join [Environment]::NewLine) + [Environment]::NewLine
        }
        else {
            $box.AppendText($event.Line + [Environment]::NewLine)
        }
        $box.SelectionStart = $box.TextLength
        $box.ScrollToCaret()
    }
    if ($State.PersistentEnabled -and -not [string]::IsNullOrWhiteSpace([string]$State.PersistentPath)) {
        $encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::AppendAllText([string]$State.PersistentPath, $event.Line + [Environment]::NewLine, $encoding)
    }
    return $event
}

function Test-BitWreckedValidationResultCurrent {
    param(
        [Parameter(Mandatory = $true)][object]$Result,
        [Parameter(Mandatory = $true)][string]$ActiveModuleId,
        [Parameter(Mandatory = $true)][string]$ActiveRequestId,
        [Parameter(Mandatory = $true)][long]$ContextGeneration,
        [Parameter(Mandatory = $true)][string]$SelectedGameRoot
    )
    if ([string]$Result.ModuleId -cne $ActiveModuleId) { return $false }
    if ([string]$Result.RequestId -cne $ActiveRequestId) { return $false }
    if ([long]$Result.ContextGeneration -ne $ContextGeneration) { return $false }
    return (Test-BitWreckedSamePath -First ([string]$Result.GameRoot) -Second $SelectedGameRoot)
}

function New-BitWreckedHostLabel {
    param(
        [string]$Text, [int]$Left, [int]$Top, [int]$Width, [int]$Height = 24,
        [float]$Size = 9, [switch]$Bold, [string]$AccessibleName = ''
    )
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $style = if ($Bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $label.Font = New-Object System.Drawing.Font([System.Drawing.SystemFonts]::MessageBoxFont.FontFamily, $Size, $style)
    $label.Location = New-Object System.Drawing.Point($Left, $Top)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.ForeColor = $script:BWHRuntime.Palette.Text
    $label.BackColor = [System.Drawing.Color]::Transparent
    $label.AccessibleName = if ([string]::IsNullOrWhiteSpace($AccessibleName)) { $Text } else { $AccessibleName }
    $label.AccessibleRole = [System.Windows.Forms.AccessibleRole]::StaticText
    $label.TabStop = $false
    return $label
}

function New-BitWreckedHostButton {
    param(
        [string]$Text, [int]$Left, [int]$Top, [int]$Width, [int]$Height,
        [string]$AccessibleName, [string]$AccessibleDescription, [int]$TabIndex
    )
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($Left, $Top)
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.Font = [System.Drawing.SystemFonts]::MessageBoxFont
    $button.AccessibleName = $AccessibleName
    $button.AccessibleDescription = $AccessibleDescription
    $button.TabIndex = $TabIndex
    if ($script:BWHRuntime.Palette.HighContrast) {
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    }
    else {
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $button.FlatAppearance.BorderColor = $script:BWHRuntime.Palette.Border
        $button.BackColor = $script:BWHRuntime.Palette.Panel
        $button.ForeColor = $script:BWHRuntime.Palette.Text
    }
    return $button
}

function Get-BitWreckedModuleContext {
    param(
        [Parameter(Mandatory = $true)][object]$Definition,
        [Parameter(Mandatory = $true)][System.Windows.Forms.Panel]$WorkspacePanel
    )
    $tag = [string]$Definition.DisplayName
    $logHook = {
        param($Message, $Severity)
        $level = if ([string]$Severity -in @('info', 'success', 'warning', 'error')) { [string]$Severity } else { 'info' }
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag $tag -Message ([string]$Message) -Severity $level)
    }.GetNewClosure()
    $refreshHook = {
        if ($null -ne $script:BWHRuntime.CurrentDefinition) {
            Show-BitWreckedModule -Definition $script:BWHRuntime.CurrentDefinition -ForceRender -LogNavigation:$false -ReturnFocus:$false
        }
    }
    return [pscustomobject]@{
        SelectedGameRoot = [string]$script:BWHRuntime.SelectedGameRoot
        WorkspacePanel = $WorkspacePanel
        ModuleSessionState = $script:BWHRuntime.Sessions[[string]$Definition.Id]
        Log = $logHook
        RequestUiRefresh = $refreshHook
    }
}

function Clear-BitWreckedPanel {
    param([System.Windows.Forms.Panel]$Panel)
    foreach ($control in @($Panel.Controls)) {
        [void]$Panel.Controls.Remove($control)
        $control.Dispose()
    }
}

function Test-BitWreckedModuleHasPendingValidation {
    param([string]$ModuleId)
    return @($script:BWHRuntime.PendingValidations | Where-Object { $_.Definition.Id -eq $ModuleId }).Count -gt 0
}

function Update-BitWreckedHostAction {
    if ($null -eq $script:BWHRuntime.CurrentDefinition) { return }
    $definition = $script:BWHRuntime.CurrentDefinition
    $page = $script:BWHRuntime.Pages[[string]$definition.Id]
    $context = Get-BitWreckedModuleContext -Definition $definition -WorkspacePanel $page
    $action = @(& $definition.GetActionState $context) | Select-Object -First 1
    $button = $script:BWHRuntime.Controls.ActionButton
    $button.Text = '&Validate Current Game Settings'
    $button.AccessibleName = "Validate $($definition.DisplayName) read-only"
    $button.AccessibleDescription = "Reads the selected local game folder for $($definition.DisplayName). It never changes game or mod files."
    $button.Enabled = [bool]$action.Enabled -and -not (Test-BitWreckedModuleHasPendingValidation -ModuleId $definition.Id)
}

function Show-BitWreckedModule {
    param(
        [Parameter(Mandatory = $true)][object]$Definition,
        [switch]$ForceRender,
        [bool]$LogNavigation = $true,
        [bool]$ReturnFocus = $true
    )
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $old = $script:BWHRuntime.CurrentDefinition
    if ($null -ne $old -and $old.Id -ne $Definition.Id) {
        $oldPage = $script:BWHRuntime.Pages[[string]$old.Id]
        if ($null -ne $oldPage) {
            $oldContext = Get-BitWreckedModuleContext -Definition $old -WorkspacePanel $oldPage
            & $old.Deactivate $oldContext
            $oldPage.Visible = $false
        }
        $script:BWHRuntime.ContextGeneration = [long]$script:BWHRuntime.ContextGeneration + 1
    }
    if (-not $script:BWHRuntime.Sessions.ContainsKey([string]$Definition.Id)) {
        $script:BWHRuntime.Sessions[[string]$Definition.Id] = & $Definition.NewSessionState
    }
    if (-not $script:BWHRuntime.Pages.ContainsKey([string]$Definition.Id)) {
        $page = New-Object System.Windows.Forms.Panel
        $page.Name = "ModulePage_$($Definition.Id)"
        $page.Location = New-Object System.Drawing.Point(0, 0)
        $page.Size = New-Object System.Drawing.Size(640, 300)
        $page.BackColor = $script:BWHRuntime.Palette.Panel
        $page.AccessibleName = "$($Definition.DisplayName) workspace"
        $page.AccessibleDescription = "$($Definition.Description) $($Definition.WriteBoundary)."
        $script:BWHRuntime.Controls.ModulePageHost.Controls.Add($page)
        $script:BWHRuntime.Pages[[string]$Definition.Id] = $page
        $ForceRender = $true
    }
    $page = $script:BWHRuntime.Pages[[string]$Definition.Id]
    $pageRoot = if ($script:BWHRuntime.PageRoots.ContainsKey([string]$Definition.Id)) { [string]$script:BWHRuntime.PageRoots[[string]$Definition.Id] } else { [string][char]0 }
    if (-not (Test-BitWreckedSamePath -First $pageRoot -Second ([string]$script:BWHRuntime.SelectedGameRoot))) { $ForceRender = $true }
    if ($ForceRender) {
        if ($page.Controls.Count -gt 0) {
            $disposeContext = Get-BitWreckedModuleContext -Definition $Definition -WorkspacePanel $page
            & $Definition.DisposeWorkspace $disposeContext
            Clear-BitWreckedPanel -Panel $page
        }
        $renderContext = Get-BitWreckedModuleContext -Definition $Definition -WorkspacePanel $page
        [void](& $Definition.RenderWorkspace $renderContext)
        $script:BWHRuntime.PageRoots[[string]$Definition.Id] = [string]$script:BWHRuntime.SelectedGameRoot
    }
    foreach ($otherPage in @($script:BWHRuntime.Pages.Values)) { $otherPage.Visible = $false }
    $page.Visible = $true
    $page.BringToFront()
    $script:BWHRuntime.CurrentDefinition = $Definition
    $stateLabel = Get-BitWreckedStateLabel -State $Definition.State
    $script:BWHRuntime.Controls.WorkspaceTitle.Text = "$($Definition.DisplayName) $($Definition.Version) - $stateLabel"
    $script:BWHRuntime.Controls.WorkspaceTitle.AccessibleName = "Active workspace: $($Definition.DisplayName), $stateLabel"
    $script:BWHRuntime.Controls.StatusText.Text = "Active module: $($Definition.DisplayName) - $stateLabel. Switching modules is navigation only."
    $script:BWHRuntime.Controls.StatusText.AccessibleName = "Active module $($Definition.DisplayName), state $stateLabel"
    Update-BitWreckedHostAction
    if ($LogNavigation -and $null -ne $old -and $old.Id -ne $Definition.Id) {
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag 'Host' -Message "Active module changed: $($old.DisplayName) -> $($Definition.DisplayName). Navigation only; no validation or file action ran.")
    }
    $watch.Stop()
    [void]$script:BWHRuntime.SwitchMeasurements.Add([double]$watch.Elapsed.TotalMilliseconds)
    if ($ReturnFocus) { [void]$script:BWHRuntime.Controls.ModuleSelector.Focus() }
}

function Set-BitWreckedSelectedGameRoot {
    param([Parameter(Mandatory = $true)][string]$Path, [switch]$Quiet)
    $resolved = Resolve-BitWreckedLocalPath -Path $Path
    if (-not $resolved.IsAllowed -or -not (Test-Path -LiteralPath $resolved.Path -PathType Container)) {
        throw $(if ($resolved.IsAllowed) { 'The selected local folder does not exist.' } else { $resolved.Reason })
    }
    if (Test-BitWreckedSamePath -First ([string]$script:BWHRuntime.SelectedGameRoot) -Second $resolved.Path) { return }
    $script:BWHRuntime.SelectedGameRoot = $resolved.Path
    $script:BWHRuntime.ContextGeneration = [long]$script:BWHRuntime.ContextGeneration + 1
    $script:BWHRuntime.Controls.GameRootText.Text = $resolved.Path
    $script:BWHRuntime.Controls.GameRootText.AccessibleName = "Selected game folder: $($resolved.Path)"
    if (-not $Quiet) {
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag 'Host' -Message 'Selected local game folder changed. No validation ran.')
    }
    if ($null -ne $script:BWHRuntime.CurrentDefinition) {
        Show-BitWreckedModule -Definition $script:BWHRuntime.CurrentDefinition -ForceRender -LogNavigation:$false -ReturnFocus:$false
    }
}

function Start-BitWreckedReadOnlyValidation {
    if ($null -eq $script:BWHRuntime.CurrentDefinition) { return }
    $definition = $script:BWHRuntime.CurrentDefinition
    $localRoot = Resolve-BitWreckedLocalPath -Path ([string]$script:BWHRuntime.SelectedGameRoot)
    if (-not $localRoot.IsAllowed) {
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag $definition.DisplayName -Message $localRoot.Reason -Severity 'warning')
        return
    }
    if (Test-BitWreckedModuleHasPendingValidation -ModuleId $definition.Id) { return }
    $request = New-BitWreckedValidationRequest -ModuleId $definition.Id -RequestId ([guid]::NewGuid().ToString('N')) -ContextGeneration ([long]$script:BWHRuntime.ContextGeneration) -GameRoot $localRoot.Path
    $powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $powershellPath
    $quote = [char]34
    $startInfo.Arguments = '-NoProfile -STA -File ' + $quote + $script:BitWreckedHostScriptPath + $quote + ' -HeadlessValidate'
    $startInfo.WorkingDirectory = $script:BitWreckedHostRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.EnvironmentVariables['BITWRECKED_MODULE_ID'] = [string]$request.ModuleId
    $startInfo.EnvironmentVariables['BITWRECKED_GAME_ROOT'] = [string]$request.GameRoot
    $startInfo.EnvironmentVariables['BITWRECKED_REQUEST_ID'] = [string]$request.RequestId
    $startInfo.EnvironmentVariables['BITWRECKED_CONTEXT_GENERATION'] = [string]$request.ContextGeneration
    if ($script:BWHRuntime.ValidationDelayMs -gt 0) {
        $startInfo.EnvironmentVariables['BITWRECKED_TEST_DELAY_MS'] = [string]$script:BWHRuntime.ValidationDelayMs
    }
    try {
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        if (-not $process.Start()) { throw 'The fixed local validation worker did not start.' }
        [void]$script:BWHRuntime.PendingValidations.Add([pscustomobject]@{
            Definition = $definition; Request = $request; Process = $process; StartedUtc = [datetime]::UtcNow
        })
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag $definition.DisplayName -Message 'Read-only validation started. The interface remains available; no game or mod files will be changed.')
        $script:BWHRuntime.Controls.StatusText.Text = "Active module: $($definition.DisplayName) - validating read-only in the background."
        Update-BitWreckedHostAction
    }
    catch {
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag $definition.DisplayName -Message "Validation worker unavailable: $($_.Exception.Message)" -Severity 'error')
    }
}

function Complete-BitWreckedValidation {
    param([Parameter(Mandatory = $true)][object]$Pending)
    $process = $Pending.Process
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $exitCode = $process.ExitCode
    $process.Dispose()
    if ($exitCode -ne 0 -and [string]::IsNullOrWhiteSpace($stdout)) {
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag $Pending.Definition.DisplayName -Message "Validation worker failed: $stderr" -Severity 'error')
        return
    }
    try { $result = $stdout.Trim() | ConvertFrom-Json }
    catch {
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag $Pending.Definition.DisplayName -Message "Validation result was unreadable: $($_.Exception.Message) $stderr" -Severity 'error')
        return
    }
    $current = Test-BitWreckedValidationResultCurrent -Result $result -ActiveModuleId ([string]$script:BWHRuntime.CurrentDefinition.Id) -ActiveRequestId ([string]$Pending.Request.RequestId) -ContextGeneration ([long]$script:BWHRuntime.ContextGeneration) -SelectedGameRoot ([string]$script:BWHRuntime.SelectedGameRoot)
    if (-not $current) {
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag 'Host' -Message "Discarded stale read-only result for $($Pending.Definition.DisplayName); module or folder context changed." -Severity 'warning')
        return
    }
    $page = $script:BWHRuntime.Pages[[string]$Pending.Definition.Id]
    $context = Get-BitWreckedModuleContext -Definition $Pending.Definition -WorkspacePanel $page
    & $Pending.Definition.ApplyValidationResult $context $result
    $resultSeverity = if ($result.Status -eq 'success') { 'success' } else { 'warning' }
    [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag $Pending.Definition.DisplayName -Message ([string]$result.Summary) -Severity $resultSeverity)
    foreach ($detail in @($result.Details)) {
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag $Pending.Definition.DisplayName -Message ([string]$detail))
    }
    Show-BitWreckedModule -Definition $Pending.Definition -ForceRender -LogNavigation:$false -ReturnFocus:$false
}

function Invoke-BitWreckedValidationPoll {
    for ($index = $script:BWHRuntime.PendingValidations.Count - 1; $index -ge 0; $index--) {
        $pending = $script:BWHRuntime.PendingValidations[$index]
        if (([datetime]::UtcNow - $pending.StartedUtc).TotalSeconds -gt 60 -and -not $pending.Process.HasExited) {
            $pending.Process.Kill()
            [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag $pending.Definition.DisplayName -Message 'Read-only validation exceeded 60 seconds and was stopped. No result was applied.' -Severity 'warning')
        }
        if ($pending.Process.HasExited) {
            $script:BWHRuntime.PendingValidations.RemoveAt($index)
            Complete-BitWreckedValidation -Pending $pending
        }
    }
    Update-BitWreckedHostAction
}

function Set-BitWreckedLogExpanded {
    param([bool]$Expanded)
    $script:BWHRuntime.LogExpanded = $Expanded
    $script:BWHRuntime.Controls.ActivityPanel.Visible = $Expanded
    $script:BWHRuntime.Controls.LogToggle.Text = if ($Expanded) { [char]0x25C0 } else { [char]0x25B6 }
    $script:BWHRuntime.Controls.LogToggle.AccessibleName = if ($Expanded) { 'Hide activity log' } else { 'Show activity log' }
    $width = if ($Expanded) { 1050 } else { 710 }
    $script:BWHRuntime.Form.ClientSize = New-Object System.Drawing.Size($width, 735)
}

function Get-BitWreckedDescendantControls {
    param([System.Windows.Forms.Control]$Parent)
    $all = New-Object System.Collections.ArrayList
    foreach ($child in @($Parent.Controls)) {
        [void]$all.Add($child)
        foreach ($nested in @(Get-BitWreckedDescendantControls -Parent $child)) { [void]$all.Add($nested) }
    }
    return @($all)
}

function Get-BitWreckedAccessibilityFindings {
    param([Parameter(Mandatory = $true)][System.Windows.Forms.Form]$Form)
    $findings = New-Object System.Collections.ArrayList
    if ($Form.AutoScaleMode -ne [System.Windows.Forms.AutoScaleMode]::Dpi) { [void]$findings.Add('Form AutoScaleMode is not Dpi.') }
    foreach ($control in @(Get-BitWreckedDescendantControls -Parent $Form)) {
        if (-not $control.Visible) { continue }
        $interactive = $control -is [System.Windows.Forms.Button] -or $control -is [System.Windows.Forms.ComboBox] -or $control -is [System.Windows.Forms.CheckBox] -or $control -is [System.Windows.Forms.TextBox] -or $control -is [System.Windows.Forms.RichTextBox]
        if ($interactive -and [string]::IsNullOrWhiteSpace([string]$control.AccessibleName)) {
            [void]$findings.Add("Interactive control '$($control.Name)' has no AccessibleName.")
        }
        if ($control -is [System.Windows.Forms.Label] -and -not [string]::IsNullOrWhiteSpace([string]$control.Text) -and [string]::IsNullOrWhiteSpace([string]$control.AccessibleName)) {
            [void]$findings.Add("Visible label '$($control.Text)' has no AccessibleName.")
        }
    }
    return @($findings)
}

function New-BitWreckedModuleHostRuntime {
    param(
        [switch]$ForSmokeTest,
        [string]$InitialGameRoot = '',
        [int]$ValidationDelayMs = 0
    )
    $loaded = Import-BitWreckedAllowlistedModules -ModuleHostRoot $script:BitWreckedHostRoot -TemplateRoot $script:BitWreckedTemplateRoot
    if (@($loaded.Definitions).Count -lt 1) {
        throw "No reviewed modules could be loaded: $(@($loaded.Errors) -join '; ')"
    }
    $script:BWHRuntime = [pscustomobject]@{
        Palette = Get-BitWreckedPalette
        Form = $null
        Definitions = @($loaded.Definitions)
        RuntimeModules = @($loaded.RuntimeModules)
        RegistryErrors = @($loaded.Errors)
        Sessions = @{}
        Pages = @{}
        PageRoots = @{}
        CurrentDefinition = $null
        SelectedGameRoot = ''
        ContextGeneration = [long]1
        PendingValidations = New-Object System.Collections.ArrayList
        ActivityState = New-BitWreckedActivityState
        Controls = @{}
        LogExpanded = $true
        SwitchMeasurements = New-Object System.Collections.ArrayList
        SmokeFailures = New-Object System.Collections.ArrayList
        ValidationDelayMs = $ValidationDelayMs
        LogoImage = $null
    }
    $palette = $script:BWHRuntime.Palette

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Bit Wrecked - 7DTD Module Host'
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.ClientSize = New-Object System.Drawing.Size(1050, 735)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    $form.MinimizeBox = $true
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $form.BackColor = $palette.Window
    $form.ForeColor = $palette.Text
    $form.Font = [System.Drawing.SystemFonts]::MessageBoxFont
    $form.KeyPreview = $true
    $form.AccessibleName = 'Bit Wrecked Module Host'
    $form.AccessibleDescription = 'Local read-only host for reviewed 7 Days to Die module workspaces.'
    $script:BWHRuntime.Form = $form

    $logoPath = Join-Path $script:BitWreckedTemplateRoot 'framework_reference_4.1.1\Support_Files_Do_Not_Edit\Assets\bit-wrecked-channel-avatar.png'
    if (Test-Path -LiteralPath $logoPath -PathType Leaf) {
        try {
            $stream = [System.IO.File]::Open($logoPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            try {
                $loadedImage = [System.Drawing.Image]::FromStream($stream)
                $script:BWHRuntime.LogoImage = New-Object System.Drawing.Bitmap($loadedImage)
                $loadedImage.Dispose()
            }
            finally { $stream.Dispose() }
            $logo = New-Object System.Windows.Forms.PictureBox
            $logo.Image = $script:BWHRuntime.LogoImage
            $logo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
            $logo.Location = New-Object System.Drawing.Point(30, 18)
            $logo.Size = New-Object System.Drawing.Size(62, 62)
            $logo.AccessibleName = 'Bit Wrecked logo'
            $logo.AccessibleRole = [System.Windows.Forms.AccessibleRole]::Graphic
            $form.Controls.Add($logo)
        }
        catch {
            [void]$script:BWHRuntime.SmokeFailures.Add("Logo could not load: $($_.Exception.Message)")
        }
    }

    $brand = New-BitWreckedHostLabel -Text 'Bit Wrecked' -Left 110 -Top 18 -Width 300 -Height 24 -Size 10 -Bold -AccessibleName 'Bit Wrecked'
    $title = New-BitWreckedHostLabel -Text '7DTD Module Host' -Left 110 -Top 42 -Width 540 -Height 34 -Size 18 -Bold -AccessibleName '7DTD Module Host'
    $subtitle = New-BitWreckedHostLabel -Text 'Local read-only infrastructure | Version 0.0.1' -Left 110 -Top 76 -Width 540 -Height 22 -Size 8 -AccessibleName 'Local read-only infrastructure, version 0.0.1'
    $form.Controls.AddRange(@($brand, $title, $subtitle))

    $moduleLabel = New-BitWreckedHostLabel -Text '&Module:' -Left 30 -Top 109 -Width 76 -Height 25 -Size 9 -Bold -AccessibleName 'Module selector label'
    $selector = New-Object System.Windows.Forms.ComboBox
    $selector.Name = 'ModuleSelector'
    $selector.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $selector.Location = New-Object System.Drawing.Point(108, 105)
    $selector.Size = New-Object System.Drawing.Size(557, 30)
    $selector.Font = [System.Drawing.SystemFonts]::MessageBoxFont
    $selector.AccessibleName = 'Active module selector'
    $selector.AccessibleDescription = 'Changes only the center workspace. It never validates or changes files.'
    $selector.TabIndex = 0
    $moduleLabel.UseMnemonic = $true
    foreach ($definition in $script:BWHRuntime.Definitions) {
        [void]$selector.Items.Add([pscustomobject]@{
            Label = "$($definition.DisplayName) $($definition.Version) - $(Get-BitWreckedStateLabel -State $definition.State)"
            Definition = $definition
        })
    }
    $selector.DisplayMember = 'Label'
    $form.Controls.AddRange(@($moduleLabel, $selector))

    $statusPanel = New-Object System.Windows.Forms.Panel
    $statusPanel.Location = New-Object System.Drawing.Point(30, 146)
    $statusPanel.Size = New-Object System.Drawing.Size(635, 61)
    $statusPanel.BackColor = $palette.Panel
    $statusPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $statusPanel.AccessibleName = 'Active module status'
    $statusDot = New-BitWreckedHostLabel -Text ([char]0x25CF) -Left 18 -Top 15 -Width 28 -Height 28 -Size 14 -AccessibleName 'Read-only status indicator'
    $statusDot.ForeColor = $palette.Accent
    $statusText = New-BitWreckedHostLabel -Text 'Loading reviewed module registry.' -Left 54 -Top 12 -Width 560 -Height 38 -Size 9 -Bold -AccessibleName 'Loading module status'
    $statusPanel.Controls.AddRange(@($statusDot, $statusText))
    $form.Controls.Add($statusPanel)

    $folderLabel = New-BitWreckedHostLabel -Text 'Game folder' -Left 30 -Top 218 -Width 120 -Height 22 -Size 8 -Bold -AccessibleName 'Game folder label'
    $pathText = New-Object System.Windows.Forms.TextBox
    $pathText.Name = 'SelectedGameRoot'
    $pathText.ReadOnly = $true
    $pathText.Text = 'No game folder selected - no game files inspected.'
    $pathText.Location = New-Object System.Drawing.Point(30, 240)
    $pathText.Size = New-Object System.Drawing.Size(472, 30)
    $pathText.BackColor = $palette.Panel
    $pathText.ForeColor = $palette.Text
    $pathText.AccessibleName = 'No game folder selected'
    $pathText.AccessibleDescription = 'Read-only display of the chosen local 7 Days to Die folder.'
    $pathText.TabIndex = 1
    $browse = New-BitWreckedHostButton -Text 'Choose &Game Folder' -Left 512 -Top 237 -Width 153 -Height 33 -AccessibleName 'Choose local game folder' -AccessibleDescription 'Selects a folder but does not validate it or change any files.' -TabIndex 2
    $form.Controls.AddRange(@($folderLabel, $pathText, $browse))

    $workspaceCard = New-Object System.Windows.Forms.Panel
    $workspaceCard.Location = New-Object System.Drawing.Point(30, 282)
    $workspaceCard.Size = New-Object System.Drawing.Size(650, 354)
    $workspaceCard.BackColor = $palette.Panel
    $workspaceCard.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $workspaceCard.AccessibleName = 'Active module center workspace'
    $workspaceTitle = New-BitWreckedHostLabel -Text 'Preparing Blank Framework' -Left 8 -Top 7 -Width 632 -Height 27 -Size 9 -Bold -AccessibleName 'Active workspace'
    $pageHost = New-Object System.Windows.Forms.Panel
    $pageHost.Name = 'ModulePageHost'
    $pageHost.Location = New-Object System.Drawing.Point(5, 39)
    $pageHost.Size = New-Object System.Drawing.Size(640, 300)
    $pageHost.BackColor = $palette.Panel
    $pageHost.AccessibleName = 'Interchangeable module content'
    $pageHost.AccessibleDescription = 'Only the selected reviewed module renders here.'
    $workspaceCard.Controls.AddRange(@($workspaceTitle, $pageHost))
    $form.Controls.Add($workspaceCard)

    $action = New-BitWreckedHostButton -Text '&Validate Current Game Settings' -Left 30 -Top 657 -Width 300 -Height 43 -AccessibleName 'Validate active module read-only' -AccessibleDescription 'Reads the selected local game folder without changing it.' -TabIndex 3
    $action.Enabled = $false
    $logToggle = New-BitWreckedHostButton -Text ([char]0x25C0) -Left 680 -Top 329 -Width 24 -Height 76 -AccessibleName 'Hide activity log' -AccessibleDescription 'Shows or hides the continuous in-memory tagged activity log.' -TabIndex 4
    $close = New-BitWreckedHostButton -Text '&Close' -Left 535 -Top 657 -Width 130 -Height 43 -AccessibleName 'Close Module Host' -AccessibleDescription 'Closes the local Module Host.' -TabIndex 8
    $form.Controls.AddRange(@($action, $logToggle, $close))

    $activityPanel = New-Object System.Windows.Forms.Panel
    $activityPanel.Location = New-Object System.Drawing.Point(716, 18)
    $activityPanel.Size = New-Object System.Drawing.Size(316, 682)
    $activityPanel.BackColor = $palette.Panel
    $activityPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $activityPanel.AccessibleName = 'Continuous activity log panel'
    $activityTitle = New-BitWreckedHostLabel -Text 'Activity Log / Session Context' -Left 12 -Top 10 -Width 290 -Height 25 -Size 9 -Bold -AccessibleName 'Activity log title'
    $activityBoundary = New-BitWreckedHostLabel -Text 'Runtime-only by default. Every entry is tagged.' -Left 12 -Top 36 -Width 290 -Height 22 -Size 7.5 -AccessibleName 'Activity log boundary'
    $persistCheck = New-Object System.Windows.Forms.CheckBox
    $persistCheck.Name = 'PersistentLogConsent'
    $persistCheck.Text = 'Enable persistent log'
    $persistCheck.Location = New-Object System.Drawing.Point(12, 63)
    $persistCheck.Size = New-Object System.Drawing.Size(155, 26)
    $persistCheck.ForeColor = $palette.Text
    $persistCheck.AccessibleName = 'Enable persistent activity logging'
    $persistCheck.AccessibleDescription = 'Requires a separately chosen local file and explicit confirmation. Off by default.'
    $persistCheck.TabIndex = 5
    $chooseLog = New-BitWreckedHostButton -Text 'Choose &Log File' -Left 174 -Top 59 -Width 128 -Height 31 -AccessibleName 'Choose persistent log file' -AccessibleDescription 'Selects a local log path. Choosing alone does not write.' -TabIndex 6
    $logPathLabel = New-BitWreckedHostLabel -Text 'Persistence off; no file selected.' -Left 12 -Top 94 -Width 290 -Height 38 -Size 7 -AccessibleName 'Persistent log is off'
    $logPathLabel.AutoEllipsis = $true
    $logBox = New-Object System.Windows.Forms.RichTextBox
    $logBox.Name = 'ActivityLog'
    $logBox.ReadOnly = $true
    $logBox.WordWrap = $true
    $logBox.DetectUrls = $false
    $logBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $logBox.Location = New-Object System.Drawing.Point(12, 137)
    $logBox.Size = New-Object System.Drawing.Size(290, 527)
    $logBox.BackColor = if ($palette.HighContrast) { [System.Drawing.SystemColors]::Window } else { [System.Drawing.Color]::FromArgb(247, 248, 246) }
    $logBox.ForeColor = if ($palette.HighContrast) { [System.Drawing.SystemColors]::WindowText } else { $palette.Text }
    $logBox.Font = New-Object System.Drawing.Font('Consolas', 8)
    $logBox.AccessibleName = 'Tagged activity log'
    $logBox.AccessibleDescription = 'Bounded view of the newest 500 entries; full history remains in memory for this session.'
    $logBox.TabIndex = 7
    $activityPanel.Controls.AddRange(@($activityTitle, $activityBoundary, $persistCheck, $chooseLog, $logPathLabel, $logBox))
    $form.Controls.Add($activityPanel)

    $script:BWHRuntime.ActivityState.LogBox = $logBox
    $script:BWHRuntime.Controls = @{
        ModuleSelector = $selector; StatusText = $statusText; GameRootText = $pathText
        BrowseButton = $browse; WorkspaceTitle = $workspaceTitle; ModulePageHost = $pageHost
        ActionButton = $action; LogToggle = $logToggle; CloseButton = $close
        ActivityPanel = $activityPanel; PersistentCheck = $persistCheck; ChooseLogButton = $chooseLog
        PersistentPathLabel = $logPathLabel; ActivityLog = $logBox; ChangingPersistence = $false
    }

    foreach ($registryError in @($script:BWHRuntime.RegistryErrors)) {
        [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag 'Host' -Message "Registry rejected a module: $registryError" -Severity 'error')
    }
    [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag 'Host' -Message 'Module Host 0.0.1 ready. Blank Framework selected; no game folder scan and no file write occurred.')

    if (-not [string]::IsNullOrWhiteSpace($InitialGameRoot)) { Set-BitWreckedSelectedGameRoot -Path $InitialGameRoot -Quiet }
    $selector.SelectedIndex = 0
    Show-BitWreckedModule -Definition $script:BWHRuntime.Definitions[0] -LogNavigation:$false -ReturnFocus:$false

    $selector.Add_SelectionChangeCommitted({
        $item = $script:BWHRuntime.Controls.ModuleSelector.SelectedItem
        if ($null -ne $item) { Show-BitWreckedModule -Definition $item.Definition }
    })
    $browse.Add_Click({
        $form = $script:BWHRuntime.Form
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = 'Choose the local 7 Days to Die folder. Selection alone performs no validation.'
        $dialog.ShowNewFolderButton = $false
        if (-not [string]::IsNullOrWhiteSpace([string]$script:BWHRuntime.SelectedGameRoot)) { $dialog.SelectedPath = $script:BWHRuntime.SelectedGameRoot }
        try {
            if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                try { Set-BitWreckedSelectedGameRoot -Path $dialog.SelectedPath }
                catch { [System.Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'Local folder unavailable', 'OK', 'Warning') | Out-Null }
            }
        }
        finally { $dialog.Dispose() }
    })
    $action.Add_Click({ Start-BitWreckedReadOnlyValidation })
    $logToggle.Add_Click({ Set-BitWreckedLogExpanded -Expanded (-not $script:BWHRuntime.LogExpanded); [void]$script:BWHRuntime.Controls.ModuleSelector.Focus() })
    $close.Add_Click({ $script:BWHRuntime.Form.Close() })
    $chooseLog.Add_Click({
        $form = $script:BWHRuntime.Form
        $logPathLabel = $script:BWHRuntime.Controls.PersistentPathLabel
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
        $dialog.Title = 'Choose an optional local activity log'
        $dialog.Filter = 'Text log (*.log)|*.log|Text file (*.txt)|*.txt'
        $dialog.AddExtension = $true
        $dialog.DefaultExt = 'log'
        $dialog.OverwritePrompt = $true
        try {
            if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                try {
                    [void](Set-BitWreckedPersistentLog -State $script:BWHRuntime.ActivityState -Path $dialog.FileName -Enable $false -DisallowedRoot $script:BWHRuntime.SelectedGameRoot)
                    $logPathLabel.Text = "Selected; persistence remains off: $($script:BWHRuntime.ActivityState.PersistentPath)"
                    $logPathLabel.AccessibleName = 'Persistent log path selected; writing remains off'
                }
                catch { [System.Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'Log path unavailable', 'OK', 'Warning') | Out-Null }
            }
        }
        finally { $dialog.Dispose() }
    })
    $persistCheck.Add_CheckedChanged({
        $form = $script:BWHRuntime.Form
        $persistCheck = $script:BWHRuntime.Controls.PersistentCheck
        $logPathLabel = $script:BWHRuntime.Controls.PersistentPathLabel
        if ($script:BWHRuntime.Controls.ChangingPersistence) { return }
        if ($persistCheck.Checked) {
            if ([string]::IsNullOrWhiteSpace([string]$script:BWHRuntime.ActivityState.PersistentPath)) {
                $script:BWHRuntime.Controls.ChangingPersistence = $true
                $persistCheck.Checked = $false
                $script:BWHRuntime.Controls.ChangingPersistence = $false
                [System.Windows.Forms.MessageBox]::Show($form, 'Choose a local log file first. Choosing a path will not enable writing.', 'Persistent log remains off', 'OK', 'Information') | Out-Null
                return
            }
            $newline = [Environment]::NewLine
            $prompt = 'Enable persistent activity logging to this one file?' + $newline + $newline + $script:BWHRuntime.ActivityState.PersistentPath + $newline + $newline + 'No game or mod file will be written.'
            $answer = [System.Windows.Forms.MessageBox]::Show($form, $prompt, 'Confirm sole write boundary', 'YesNo', 'Question')
            if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
                $script:BWHRuntime.Controls.ChangingPersistence = $true
                $persistCheck.Checked = $false
                $script:BWHRuntime.Controls.ChangingPersistence = $false
                return
            }
            try {
                [void](Set-BitWreckedPersistentLog -State $script:BWHRuntime.ActivityState -Path $script:BWHRuntime.ActivityState.PersistentPath -Enable $true -DisallowedRoot $script:BWHRuntime.SelectedGameRoot)
                $logPathLabel.Text = "Writing only to: $($script:BWHRuntime.ActivityState.PersistentPath)"
                $logPathLabel.AccessibleName = 'Persistent activity logging enabled'
                [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag 'Host' -Message 'Persistent activity logging enabled by explicit user confirmation.')
            }
            catch {
                $script:BWHRuntime.Controls.ChangingPersistence = $true
                $persistCheck.Checked = $false
                $script:BWHRuntime.Controls.ChangingPersistence = $false
                [System.Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'Persistent log unavailable', 'OK', 'Warning') | Out-Null
            }
        }
        else {
            $wasEnabled = $script:BWHRuntime.ActivityState.PersistentEnabled
            $script:BWHRuntime.ActivityState.PersistentEnabled = $false
            if ($wasEnabled) {
                $logPathLabel.Text = "Persistence off; saved file remains: $($script:BWHRuntime.ActivityState.PersistentPath)"
                $logPathLabel.AccessibleName = 'Persistent activity logging disabled'
                [void](Add-BitWreckedActivity -State $script:BWHRuntime.ActivityState -Tag 'Host' -Message 'Persistent activity logging disabled; runtime log continues.')
            }
        }
    })
    $form.Add_KeyDown({
        param($sender, $eventArgs)
        if ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape -and $script:BWHRuntime.LogExpanded) {
            Set-BitWreckedLogExpanded -Expanded $false
            [void]$script:BWHRuntime.Controls.ModuleSelector.Focus()
            $eventArgs.Handled = $true
            $eventArgs.SuppressKeyPress = $true
        }
    })

    $pollTimer = New-Object System.Windows.Forms.Timer
    $pollTimer.Interval = 100
    $pollTimer.Add_Tick({ Invoke-BitWreckedValidationPoll })
    $pollTimer.Start()
    $script:BWHRuntime.Controls.PollTimer = $pollTimer
    $form.Add_FormClosed({
        $script:BWHRuntime.Controls.PollTimer.Stop()
        $script:BWHRuntime.Controls.PollTimer.Dispose()
        foreach ($pending in @($script:BWHRuntime.PendingValidations)) {
            try {
                if (-not $pending.Process.HasExited) { $pending.Process.Kill() }
                $pending.Process.Dispose()
            }
            catch { }
        }
        foreach ($definition in @($script:BWHRuntime.Definitions)) {
            if ($script:BWHRuntime.Pages.ContainsKey([string]$definition.Id)) {
                $page = $script:BWHRuntime.Pages[[string]$definition.Id]
                $context = Get-BitWreckedModuleContext -Definition $definition -WorkspacePanel $page
                try { & $definition.DisposeWorkspace $context } catch { }
            }
        }
        if ($null -ne $script:BWHRuntime.LogoImage) { $script:BWHRuntime.LogoImage.Dispose() }
    })

    if ($ForSmokeTest) {
        $smokeTimer = New-Object System.Windows.Forms.Timer
        $smokeTimer.Interval = 150
        $script:BWHRuntime.Controls.SmokeState = [pscustomobject]@{ Step = 0 }
        $script:BWHRuntime.Controls.SmokeTimer = $smokeTimer
        $smokeTimer.Add_Tick({
            try {
                switch ($script:BWHRuntime.Controls.SmokeState.Step) {
                    0 {
                        $script:BWHRuntime.Controls.ModuleSelector.SelectedIndex = 1
                        Show-BitWreckedModule -Definition $script:BWHRuntime.Definitions[1] -ReturnFocus:$false
                    }
                    1 {
                        $script:BWHRuntime.Controls.ModuleSelector.SelectedIndex = 2
                        Show-BitWreckedModule -Definition $script:BWHRuntime.Definitions[2] -ReturnFocus:$false
                    }
                    2 {
                        $script:BWHRuntime.Controls.ModuleSelector.SelectedIndex = 0
                        Show-BitWreckedModule -Definition $script:BWHRuntime.Definitions[0] -ReturnFocus:$false
                    }
                    default {
                        if ($script:BWHRuntime.Pages.Count -ne 3) { [void]$script:BWHRuntime.SmokeFailures.Add('Smoke did not lazily render all three reviewed pages.') }
                        if ($script:BWHRuntime.CurrentDefinition.Id -ne 'blank_framework') { [void]$script:BWHRuntime.SmokeFailures.Add('Smoke did not return to Blank Framework.') }
                        if ($script:BWHRuntime.PendingValidations.Count -ne 0) { [void]$script:BWHRuntime.SmokeFailures.Add('Navigation unexpectedly started validation.') }
                        foreach ($finding in @(Get-BitWreckedAccessibilityFindings -Form $script:BWHRuntime.Form)) { [void]$script:BWHRuntime.SmokeFailures.Add($finding) }
                        $script:BWHRuntime.Controls.SmokeTimer.Stop()
                        $script:BWHRuntime.Form.Close()
                    }
                }
            }
            catch {
                [void]$script:BWHRuntime.SmokeFailures.Add($_.Exception.Message)
                $script:BWHRuntime.Controls.SmokeTimer.Stop()
                $script:BWHRuntime.Form.Close()
            }
            $script:BWHRuntime.Controls.SmokeState.Step++
        })
        $form.Add_Shown({ $script:BWHRuntime.Controls.SmokeTimer.Start() })
    }
    else {
        $form.Add_Shown({ [void]$script:BWHRuntime.Controls.ModuleSelector.Focus() })
    }
    return $script:BWHRuntime
}

if ($LibraryOnly) { return }

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
try {
    $runtime = New-BitWreckedModuleHostRuntime -ForSmokeTest:$SmokeTest -InitialGameRoot $TestGameRoot -ValidationDelayMs $TestValidationDelayMs
    [System.Windows.Forms.Application]::Run($runtime.Form)
    if ($SmokeTest) {
        $maxSwitch = if ($runtime.SwitchMeasurements.Count -gt 0) { ($runtime.SwitchMeasurements | Measure-Object -Maximum).Maximum } else { 0 }
        if ($runtime.SmokeFailures.Count -eq 0) {
            [Console]::Out.WriteLine("SMOKE_PASS modules=3 pages=$($runtime.Pages.Count) events=$($runtime.ActivityState.Events.Count) maxSwitchMs=$([Math]::Round([double]$maxSwitch, 2))")
            exit 0
        }
        [Console]::Error.WriteLine("SMOKE_FAIL $(@($runtime.SmokeFailures) -join ' | ')")
        exit 1
    }
}
catch {
    if ($SmokeTest) {
        [Console]::Error.WriteLine("SMOKE_FAIL $($_.Exception.Message)")
        exit 1
    }
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Bit Wrecked Module Host could not start', 'OK', 'Error') | Out-Null
    exit 1
}
