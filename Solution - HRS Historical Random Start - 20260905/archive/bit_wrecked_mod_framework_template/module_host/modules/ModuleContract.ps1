# Bit Wrecked Module Host - explicit module contract and allowlisted registry.
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later

$script:BitWreckedModuleContractVersion = '0.0.1'
$script:BitWreckedModuleRequiredFields = @(
    'ContractVersion',
    'Id',
    'DisplayName',
    'Version',
    'State',
    'Description',
    'SupportedGameBuild',
    'Columns',
    'Capabilities',
    'NewSessionState',
    'RenderWorkspace',
    'GetActionState',
    'ValidateReadOnly',
    'ApplyValidationResult',
    'Deactivate',
    'DisposeWorkspace',
    'LineItemReference',
    'WriteBoundary',
    'RecoveryReference'
)

function New-BitWreckedValidationResult {
    param(
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [Parameter(Mandatory = $true)][string]$RequestId,
        [Parameter(Mandatory = $true)][long]$ContextGeneration,
        [Parameter(Mandatory = $true)][string]$GameRoot,
        [Parameter(Mandatory = $true)][ValidateSet('success', 'invalid', 'unavailable', 'cancelled', 'error')][string]$Status,
        [Parameter(Mandatory = $true)][string]$Summary,
        [array]$Details = @(),
        [object]$Observations = $null
    )

    return [pscustomobject]@{
        ModuleId = $ModuleId
        RequestId = $RequestId
        ContextGeneration = $ContextGeneration
        GameRoot = $GameRoot
        Status = $Status
        Summary = $Summary
        Details = @($Details)
        Observations = $Observations
        CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
        NoChangesMade = $true
    }
}

function New-BitWreckedValidationRequest {
    param(
        [Parameter(Mandatory = $true)][string]$ModuleId,
        [Parameter(Mandatory = $true)][string]$RequestId,
        [Parameter(Mandatory = $true)][long]$ContextGeneration,
        [Parameter(Mandatory = $true)][string]$GameRoot
    )

    return [pscustomobject]@{
        ModuleId = $ModuleId
        RequestId = $RequestId
        ContextGeneration = $ContextGeneration
        GameRoot = $GameRoot
        RequestedAtUtc = [DateTime]::UtcNow.ToString('o')
    }
}

function Resolve-BitWreckedLocalPath {
    param([AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return [pscustomobject]@{ IsAllowed = $false; Path = ''; Reason = 'No local folder was selected.' }
    }
    if ($Path.StartsWith('\\') -or $Path.StartsWith('//') -or $Path.StartsWith('\\?\') -or $Path.StartsWith('\\.\')) {
        return [pscustomobject]@{ IsAllowed = $false; Path = ''; Reason = 'Network and device paths are outside this local-only host boundary.' }
    }

    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
        $root = [System.IO.Path]::GetPathRoot($fullPath)
        if ([string]::IsNullOrWhiteSpace($root) -or $root -notmatch '^[A-Za-z]:\\$') {
            return [pscustomobject]@{ IsAllowed = $false; Path = ''; Reason = 'Select an absolute folder on a local Windows drive.' }
        }
        $drive = New-Object System.IO.DriveInfo($root)
        if ($drive.DriveType -eq [System.IO.DriveType]::Network) {
            return [pscustomobject]@{ IsAllowed = $false; Path = ''; Reason = 'Network drives are outside this local-only host boundary.' }
        }
        return [pscustomobject]@{ IsAllowed = $true; Path = $fullPath.TrimEnd('\'); Reason = '' }
    }
    catch {
        return [pscustomobject]@{ IsAllowed = $false; Path = ''; Reason = "The selected local path is invalid: $($_.Exception.Message)" }
    }
}

function Test-BitWreckedSamePath {
    param([string]$First, [string]$Second)

    $firstResolved = Resolve-BitWreckedLocalPath -Path $First
    $secondResolved = Resolve-BitWreckedLocalPath -Path $Second
    if ($firstResolved.IsAllowed -and $secondResolved.IsAllowed) {
        return [string]::Equals($firstResolved.Path, $secondResolved.Path, [System.StringComparison]::OrdinalIgnoreCase)
    }
    return [string]::Equals([string]$First, [string]$Second, [System.StringComparison]::Ordinal)
}

function Test-BitWreckedDocumentReference {
    param(
        [Parameter(Mandatory = $true)][string]$Reference,
        [Parameter(Mandatory = $true)][string]$TemplateRoot
    )

    if ($Reference -eq 'none') {
        return $true
    }

    try {
        $solutionsRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $TemplateRoot))
        $candidate = [System.IO.Path]::GetFullPath((Join-Path $TemplateRoot $Reference))
        $prefix = $solutionsRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
        if (-not $candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $false
        }
        return (Test-Path -LiteralPath $candidate -PathType Leaf)
    }
    catch {
        return $false
    }
}

function Test-BitWreckedModuleDefinition {
    param(
        [Parameter(Mandatory = $true)][object]$Definition,
        [Parameter(Mandatory = $true)][string]$TemplateRoot
    )

    $errors = New-Object System.Collections.ArrayList
    if ($null -eq $Definition) {
        [void]$errors.Add('Factory returned no definition.')
        return [pscustomobject]@{ IsValid = $false; Errors = @($errors) }
    }

    $propertyNames = @($Definition.PSObject.Properties.Name)
    foreach ($field in $script:BitWreckedModuleRequiredFields) {
        if ($field -notin $propertyNames) {
            [void]$errors.Add("Missing required field: $field")
        }
    }
    if ($errors.Count -gt 0) {
        return [pscustomobject]@{ IsValid = $false; Errors = @($errors) }
    }

    if ($Definition.ContractVersion -ne $script:BitWreckedModuleContractVersion) {
        [void]$errors.Add("Unsupported contract version: $($Definition.ContractVersion)")
    }
    if ([string]$Definition.Id -notmatch '^[a-z0-9][a-z0-9_]{2,63}$') {
        [void]$errors.Add("Invalid module ID: $($Definition.Id)")
    }
    if ([string]$Definition.State -notin @('design', 'read_only')) {
        [void]$errors.Add("Invalid module state: $($Definition.State)")
    }
    if ([string]$Definition.WriteBoundary -ne 'none in this build') {
        [void]$errors.Add("Initial module write boundary must be 'none in this build'.")
    }

    foreach ($textField in @('DisplayName', 'Version', 'Description', 'SupportedGameBuild')) {
        if ([string]::IsNullOrWhiteSpace([string]$Definition.$textField)) {
            [void]$errors.Add("Required text field is empty: $textField")
        }
    }
    if (@($Definition.Columns).Count -ne 5) {
        [void]$errors.Add('Every initial module must declare exactly five center columns.')
    }

    $hookFields = @(
        'NewSessionState',
        'RenderWorkspace',
        'GetActionState',
        'ValidateReadOnly',
        'ApplyValidationResult',
        'Deactivate',
        'DisposeWorkspace'
    )
    foreach ($hook in $hookFields) {
        if ($Definition.$hook -isnot [scriptblock]) {
            [void]$errors.Add("Hook is not a scriptblock: $hook")
        }
    }

    $capabilities = @($Definition.Capabilities)
    $allowedCapabilities = @('render', 'validate_read_only')
    foreach ($requiredCapability in $allowedCapabilities) {
        if ($requiredCapability -notin $capabilities) {
            [void]$errors.Add("Missing required capability: $requiredCapability")
        }
    }
    foreach ($capability in $capabilities) {
        if ([string]$capability -notin $allowedCapabilities) {
            [void]$errors.Add("Unknown or forbidden initial capability: $capability")
        }
    }
    if ($capabilities.Count -ne $allowedCapabilities.Count) {
        [void]$errors.Add('Initial modules must declare exactly render and validate_read_only capabilities.')
    }

    foreach ($referenceField in @('LineItemReference', 'RecoveryReference')) {
        if (-not (Test-BitWreckedDocumentReference -Reference ([string]$Definition.$referenceField) -TemplateRoot $TemplateRoot)) {
            [void]$errors.Add("Missing or out-of-scope document reference: $referenceField = $($Definition.$referenceField)")
        }
    }

    if ($Definition.NewSessionState -is [scriptblock]) {
        try {
            $session = & $Definition.NewSessionState
            if ($null -eq $session -or $session -isnot [System.Collections.IDictionary]) {
                [void]$errors.Add('NewSessionState must return a data-only dictionary.')
            }
        }
        catch {
            [void]$errors.Add("NewSessionState failed: $($_.Exception.Message)")
        }
    }

    if ($Definition.GetActionState -is [scriptblock]) {
        try {
            $dummyState = [ordered]@{ LastValidation = $null; LastGameRoot = ''; RenderCount = 0 }
            $dummyContext = [pscustomobject]@{
                SelectedGameRoot = ''
                WorkspacePanel = $null
                ModuleSessionState = $dummyState
                Log = { param($Message, $Severity) }
                RequestUiRefresh = { }
            }
            $actions = @(& $Definition.GetActionState $dummyContext)
            if ($actions.Count -ne 1) {
                [void]$errors.Add('Initial modules must expose exactly one action descriptor.')
            }
            elseif (@('Id', 'Label', 'Kind', 'Visible', 'Enabled', 'UnavailableReason') | Where-Object { $_ -notin @($actions[0].PSObject.Properties.Name) }) {
                [void]$errors.Add('GetActionState returned an incomplete action descriptor.')
            }
            elseif ([string]$actions[0].Id -ne 'validate' -or [string]$actions[0].Kind -ne 'read_only' -or -not [bool]$actions[0].Visible) {
                [void]$errors.Add('Initial modules may expose only the visible read-only validate action.')
            }
        }
        catch {
            [void]$errors.Add("GetActionState failed: $($_.Exception.Message)")
        }
    }

    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = @($errors)
    }
}

function Import-BitWreckedAllowlistedModules {
    param(
        [Parameter(Mandatory = $true)][string]$ModuleHostRoot,
        [Parameter(Mandatory = $true)][string]$TemplateRoot
    )

    $modulesRoot = Join-Path $ModuleHostRoot 'modules'
    $allowlist = @(
        [pscustomobject]@{ File = 'BlankFramework.Module.ps1'; Factory = 'New-BlankFrameworkModule' },
        [pscustomobject]@{ File = 'WastelandAnimals411.ReadOnly.Module.ps1'; Factory = 'New-WastelandAnimals411ReadOnlyModule' },
        [pscustomobject]@{ File = 'OffenseWeaponsDesign.Module.ps1'; Factory = 'New-OffenseWeaponsDesignModule' }
    )

    $definitions = New-Object System.Collections.ArrayList
    $errors = New-Object System.Collections.ArrayList
    $runtimeModules = New-Object System.Collections.ArrayList
    foreach ($entry in $allowlist) {
        $moduleFile = Join-Path $modulesRoot $entry.File
        if (-not (Test-Path -LiteralPath $moduleFile -PathType Leaf)) {
            [void]$errors.Add("Allowlisted module file is missing: $($entry.File)")
            continue
        }

        try {
            # Load each reviewed file into its own isolated session state.  Adapter
            # hook scriptblocks remain bound to that state, so their private pure
            # helpers remain callable without exporting functions globally.
            $runtimeName = 'BitWrecked_{0}_{1}' -f ([IO.Path]::GetFileNameWithoutExtension($entry.File) -replace '[^A-Za-z0-9_]', '_'), ([guid]::NewGuid().ToString('N'))
            $runtimeModule = New-Module -Name $runtimeName -ScriptBlock {
                param([string]$ReviewedModuleFile)
                . $ReviewedModuleFile
            } -ArgumentList $moduleFile
            $definition = & $runtimeModule {
                param([string]$ReviewedFactory)
                $factoryCommand = Get-Command -Name $ReviewedFactory -CommandType Function -ErrorAction Stop
                & $factoryCommand
            } $entry.Factory
            $validation = Test-BitWreckedModuleDefinition -Definition $definition -TemplateRoot $TemplateRoot
            if (-not $validation.IsValid) {
                [void]$errors.Add("Rejected $($entry.File): $($validation.Errors -join '; ')")
                continue
            }
            if (@($definitions | Where-Object { $_.Id -eq $definition.Id }).Count -gt 0) {
                [void]$errors.Add("Rejected duplicate module ID: $($definition.Id)")
                continue
            }
            [void]$definitions.Add($definition)
            [void]$runtimeModules.Add($runtimeModule)
        }
        catch {
            [void]$errors.Add("Failed to load $($entry.File): $($_.Exception.Message)")
        }
    }

    return [pscustomobject]@{
        Definitions = @($definitions)
        Errors = @($errors)
        AllowlistedFiles = @($allowlist.File)
        RuntimeModules = @($runtimeModules)
    }
}

function Invoke-BitWreckedModuleValidation {
    param(
        [Parameter(Mandatory = $true)][object]$Definition,
        [Parameter(Mandatory = $true)][object]$Request
    )

    try {
        $result = & $Definition.ValidateReadOnly $Request
        $requiredResultFields = @(
            'ModuleId', 'RequestId', 'ContextGeneration', 'GameRoot', 'Status',
            'Summary', 'Details', 'Observations', 'CompletedAtUtc', 'NoChangesMade'
        )
        foreach ($field in $requiredResultFields) {
            if ($field -notin @($result.PSObject.Properties.Name)) {
                throw "Validation result omitted required field: $field"
            }
        }
        if ([string]$result.ModuleId -cne [string]$Request.ModuleId) {
            throw 'Validation result ModuleId did not match its request.'
        }
        if ([string]$result.RequestId -cne [string]$Request.RequestId) {
            throw 'Validation result RequestId did not match its request.'
        }
        if ([long]$result.ContextGeneration -ne [long]$Request.ContextGeneration) {
            throw 'Validation result ContextGeneration did not match its request.'
        }
        if (-not (Test-BitWreckedSamePath -First ([string]$result.GameRoot) -Second ([string]$Request.GameRoot))) {
            throw 'Validation result GameRoot did not match its request.'
        }
        if ([string]$result.Status -notin @('success', 'invalid', 'unavailable', 'cancelled', 'error')) {
            throw "Validation result used an unsupported status: $($result.Status)"
        }
        if ([string]::IsNullOrWhiteSpace([string]$result.Summary)) {
            throw 'Validation result Summary was empty.'
        }
        $completed = [datetimeoffset]::MinValue
        if (-not [datetimeoffset]::TryParse([string]$result.CompletedAtUtc, [ref]$completed)) {
            throw 'Validation result CompletedAtUtc was not a valid timestamp.'
        }
        if ($result.NoChangesMade -isnot [bool] -or $result.NoChangesMade -ne $true) {
            throw 'Initial host rejected a validation result that did not affirm NoChangesMade.'
        }
        return $result
    }
    catch {
        return New-BitWreckedValidationResult `
            -ModuleId ([string]$Request.ModuleId) `
            -RequestId ([string]$Request.RequestId) `
            -ContextGeneration ([long]$Request.ContextGeneration) `
            -GameRoot ([string]$Request.GameRoot) `
            -Status 'error' `
            -Summary "Read-only validation failed: $($_.Exception.Message)" `
            -Details @('No changes were made.')
    }
}

function New-BitWreckedWorkspaceLabel {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][int]$Left,
        [Parameter(Mandatory = $true)][int]$Top,
        [Parameter(Mandatory = $true)][int]$Width,
        [int]$Height = 22,
        [string]$AccessibleName = '',
        [string]$Align = 'MiddleCenter',
        [float]$FontSize = 8.0,
        [bool]$Bold = $false
    )

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $style = if ($Bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $fontFamily = [System.Drawing.SystemFonts]::MessageBoxFont.FontFamily
    $label.Font = New-Object System.Drawing.Font($fontFamily, $FontSize, $style)
    $label.ForeColor = if ([System.Windows.Forms.SystemInformation]::HighContrast) { [System.Drawing.SystemColors]::ControlText } else { [System.Drawing.Color]::FromArgb(72, 72, 69) }
    $label.Location = New-Object System.Drawing.Point($Left, $Top)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.TextAlign = [System.Drawing.ContentAlignment]$Align
    if (-not [string]::IsNullOrWhiteSpace($AccessibleName)) {
        $label.AccessibleName = $AccessibleName
    }
    $label.AccessibleRole = if ($AccessibleName.StartsWith('Column:', [System.StringComparison]::OrdinalIgnoreCase)) { [System.Windows.Forms.AccessibleRole]::ColumnHeader } else { [System.Windows.Forms.AccessibleRole]::StaticText }
    $label.TabStop = $false
    return $label
}
