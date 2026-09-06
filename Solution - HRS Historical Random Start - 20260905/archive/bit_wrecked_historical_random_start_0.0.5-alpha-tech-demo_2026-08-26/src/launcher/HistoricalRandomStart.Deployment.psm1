Set-StrictMode -Version 2.0

$corePath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'HistoricalRandomStart.Core.psm1'
Import-Module $corePath -Force

$script:HrsDeploymentSchema = 'hrs-deployment-manifest/v1'
$script:HrsReleaseFolder = 'BitWrecked_HistoricalRandomStart'
$script:HrsStaticFiles = @('HistoricalRandomStart.dll', 'ModInfo.xml')
$script:HrsBridgeFiles = @('policy.v1.json', 'result.v1.json')

function Get-HrsFileSha256 {
    param([Parameter(Mandatory = $true)] [string] $Path)

    $stream = [System.IO.File]::OpenRead($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '') }
    finally { $sha.Dispose(); $stream.Dispose() }
}

function New-HrsDeploymentManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $PayloadRoot,
        [Parameter(Mandatory = $true)] [string] $ReleaseVersion
    )

    if ($ReleaseVersion -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-z0-9.-]+)?$') { throw 'DEPLOYMENT_VERSION_INVALID' }
    $root = [System.IO.Path]::GetFullPath($PayloadRoot)
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($relative in $script:HrsStaticFiles) {
        $path = [System.IO.Path]::Combine($root, $relative)
        if (-not [System.IO.File]::Exists($path)) { throw "DEPLOYMENT_FILE_MISSING_$($relative.ToUpperInvariant().Replace('.', '_'))" }
        $info = New-Object System.IO.FileInfo($path)
        [void]$entries.Add([pscustomobject][ordered]@{
            path = $relative
            bytes = [UInt64]$info.Length
            sha256 = Get-HrsFileSha256 -Path $info.FullName
        })
    }
    return [pscustomobject][ordered]@{
        schema = $script:HrsDeploymentSchema
        releaseVersion = $ReleaseVersion
        releaseFolder = $script:HrsReleaseFolder
        files = $entries.ToArray()
    }
}

function Test-HrsDeploymentManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [psobject] $Manifest)

    $required = @('schema', 'releaseVersion', 'releaseFolder', 'files')
    $actual = @($Manifest.PSObject.Properties.Name)
    if ($actual.Count -ne $required.Count) { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_FIELD_COUNT' } }
    foreach ($field in $required) { if ($actual -cnotcontains $field) { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_FIELD_MISSING' } } }
    if (-not [string]::Equals([string]$Manifest.schema, $script:HrsDeploymentSchema, [System.StringComparison]::Ordinal)) { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_SCHEMA' } }
    if ([string]$Manifest.releaseVersion -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-z0-9.-]+)?$') { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_VERSION' } }
    if (-not [string]::Equals([string]$Manifest.releaseFolder, $script:HrsReleaseFolder, [System.StringComparison]::Ordinal)) { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_FOLDER' } }
    $files = @($Manifest.files)
    if ($files.Count -ne $script:HrsStaticFiles.Count) { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_FILE_COUNT' } }
    foreach ($relative in $script:HrsStaticFiles) {
        $matches = @($files | Where-Object { [string]::Equals([string]$_.path, $relative, [System.StringComparison]::Ordinal) })
        if ($matches.Count -ne 1) { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_FILE_SET' } }
        $entry = $matches[0]
        $entryFields = @($entry.PSObject.Properties.Name)
        if ($entryFields.Count -ne 3 -or $entryFields -cnotcontains 'path' -or $entryFields -cnotcontains 'bytes' -or $entryFields -cnotcontains 'sha256') { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_ENTRY_SHAPE' } }
        if ($entry.bytes -isnot [UInt64] -or [UInt64]$entry.bytes -lt 1) { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_BYTES' } }
        if ([string]$entry.sha256 -cnotmatch '^[0-9A-F]{64}$') { return [pscustomobject]@{ Valid=$false; Reason='DEPLOYMENT_MANIFEST_HASH' } }
    }
    return [pscustomobject]@{ Valid=$true; Reason='DEPLOYMENT_MANIFEST_VALID' }
}

function Test-HrsDeploymentInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $GameRoot,
        [Parameter(Mandatory = $true)] [psobject] $Manifest
    )

    $manifestCheck = Test-HrsDeploymentManifest -Manifest $Manifest
    if (-not $manifestCheck.Valid) { return [pscustomobject]@{ Valid=$false; State='ManifestInvalid'; Reason=$manifestCheck.Reason; RemovalPlan=@() } }
    $bridgeCheck = Test-HrsBridgePaths -GameRoot $GameRoot
    if (-not $bridgeCheck.Valid -and $bridgeCheck.Reason -ne 'BRIDGE_UNKNOWN_ENTRY') { return [pscustomobject]@{ Valid=$false; State='PathInvalid'; Reason=$bridgeCheck.Reason; RemovalPlan=@() } }
    $paths = $bridgeCheck.Paths
    if (-not [System.IO.Directory]::Exists($paths.ReleaseRoot)) { return [pscustomobject]@{ Valid=$true; State='NotInstalled'; Reason='RELEASE_ROOT_ABSENT'; RemovalPlan=@() } }

    try {
        $directories = @([System.IO.Directory]::EnumerateDirectories($paths.ReleaseRoot, '*', [System.IO.SearchOption]::AllDirectories))
        $files = @([System.IO.Directory]::EnumerateFiles($paths.ReleaseRoot, '*', [System.IO.SearchOption]::AllDirectories))
    }
    catch { return [pscustomobject]@{ Valid=$false; State='InventoryFailed'; Reason='DEPLOYMENT_ENUMERATION_FAILED'; RemovalPlan=@() } }

    foreach ($directory in @($paths.ReleaseRoot) + $directories) {
        $attributes = [System.IO.File]::GetAttributes($directory)
        if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return [pscustomobject]@{ Valid=$false; State='Conflict'; Reason='DEPLOYMENT_REPARSE_POINT'; RemovalPlan=@() } }
    }
    $allowedDirectories = @($paths.BridgeRoot)
    foreach ($directory in $directories) {
        if (-not ($allowedDirectories | Where-Object { [string]::Equals($_, $directory, [System.StringComparison]::OrdinalIgnoreCase) })) { return [pscustomobject]@{ Valid=$false; State='Conflict'; Reason='DEPLOYMENT_UNKNOWN_DIRECTORY'; RemovalPlan=@() } }
    }

    $manifestEntries = @($Manifest.files)
    $plan = New-Object System.Collections.Generic.List[string]
    foreach ($file in $files) {
        $attributes = [System.IO.File]::GetAttributes($file)
        if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return [pscustomobject]@{ Valid=$false; State='Conflict'; Reason='DEPLOYMENT_FILE_REPARSE_POINT'; RemovalPlan=@() } }
        $relative = $file.Substring($paths.ReleaseRoot.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar).Replace([System.IO.Path]::DirectorySeparatorChar, '/')
        if ($relative.StartsWith('Bridge/', [System.StringComparison]::Ordinal)) {
            $leaf = [System.IO.Path]::GetFileName($file)
            if ($script:HrsBridgeFiles -cnotcontains $leaf) { return [pscustomobject]@{ Valid=$false; State='Conflict'; Reason='DEPLOYMENT_UNKNOWN_BRIDGE_FILE'; RemovalPlan=@() } }
            if ($leaf -ceq 'policy.v1.json') { try { [void](Read-HrsPolicyFile -Path $file) } catch { return [pscustomobject]@{ Valid=$false; State='Drift'; Reason='DEPLOYMENT_POLICY_INVALID'; RemovalPlan=@() } } }
            if ($leaf -ceq 'result.v1.json') { try { [void](Read-HrsResultFile -Path $file) } catch { return [pscustomobject]@{ Valid=$false; State='Drift'; Reason='DEPLOYMENT_RESULT_INVALID'; RemovalPlan=@() } } }
            [void]$plan.Add($file)
            continue
        }
        $entry = @($manifestEntries | Where-Object { [string]::Equals([string]$_.path, $relative, [System.StringComparison]::Ordinal) })
        if ($entry.Count -ne 1) { return [pscustomobject]@{ Valid=$false; State='Conflict'; Reason='DEPLOYMENT_UNKNOWN_FILE'; RemovalPlan=@() } }
        $info = New-Object System.IO.FileInfo($file)
        if ([UInt64]$info.Length -ne [UInt64]$entry[0].bytes -or -not [string]::Equals((Get-HrsFileSha256 -Path $file), [string]$entry[0].sha256, [System.StringComparison]::Ordinal)) { return [pscustomobject]@{ Valid=$false; State='Drift'; Reason='DEPLOYMENT_STATIC_FILE_DRIFT'; RemovalPlan=@() } }
        [void]$plan.Add($file)
    }

    foreach ($relative in $script:HrsStaticFiles) {
        $expected = [System.IO.Path]::Combine($paths.ReleaseRoot, $relative)
        if (-not [System.IO.File]::Exists($expected)) { return [pscustomobject]@{ Valid=$false; State='Incomplete'; Reason='DEPLOYMENT_STATIC_FILE_MISSING'; RemovalPlan=@() } }
    }
    return [pscustomobject]@{ Valid=$true; State='InstalledValid'; Reason='DEPLOYMENT_INVENTORY_VALID'; RemovalPlan=@($plan | Sort-Object -Descending); Paths=$paths }
}

function Get-HrsDeploymentUiDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [psobject] $Inventory,
        [Parameter(Mandatory = $true)] [bool] $ApprovedPayloadAvailable
    )

    $state = [string]$Inventory.State
    if ($Inventory.Valid -and $state -ceq 'InstalledValid') {
        return [pscustomobject]@{ ApplyAllowed=$true; InstallRequired=$false; Status='Installed payload verified'; Reason=[string]$Inventory.Reason }
    }
    if ($Inventory.Valid -and $state -ceq 'NotInstalled') {
        if ($ApprovedPayloadAvailable) {
            return [pscustomobject]@{ ApplyAllowed=$true; InstallRequired=$true; Status='Verified payload available - installation required'; Reason=[string]$Inventory.Reason }
        }
        return [pscustomobject]@{ ApplyAllowed=$false; InstallRequired=$false; Status='Not installed - approved payload unavailable'; Reason='APPROVED_PAYLOAD_UNAVAILABLE' }
    }

    $statusByState = @{
        Incomplete = 'Installed payload incomplete'
        Drift = 'Installed payload stale, altered, or invalid'
        Conflict = 'Installed payload contains unknown or unsafe content'
        ManifestInvalid = 'Approved deployment manifest is invalid'
        PathInvalid = 'Game or deployment path cannot be verified'
        InventoryFailed = 'Installed payload inventory failed'
    }
    $statusText = if ($statusByState.ContainsKey($state)) { $statusByState[$state] } else { 'Installed payload cannot be verified' }
    return [pscustomobject]@{ ApplyAllowed=$false; InstallRequired=$false; Status=$statusText; Reason=[string]$Inventory.Reason }
}

function Write-HrsPolicyAfterDeploymentValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $GameRoot,
        [Parameter(Mandatory = $true)] [psobject] $Manifest,
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [string] $AllowedRoot,
        [Parameter(Mandatory = $true)] [psobject] $Policy
    )

    $inventory = Test-HrsDeploymentInventory -GameRoot $GameRoot -Manifest $Manifest
    if (-not $inventory.Valid -or $inventory.State -cne 'InstalledValid') {
        throw "DEPLOYMENT_POLICY_WRITE_BLOCKED:$($inventory.State):$($inventory.Reason)"
    }
    return Write-HrsPolicyFile -Path $Path -AllowedRoot $AllowedRoot -Policy $Policy
}

function Invoke-HrsRemoveFromGame {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $GameRoot,
        [Parameter(Mandatory = $true)] [psobject] $Manifest,
        [Parameter(Mandatory = $true)] [psobject] $ProcessState,
        [switch] $Confirmed
    )

    if (-not $Confirmed) { throw 'REMOVE_CONFIRMATION_REQUIRED' }
    $mutation = Test-HrsMutationAllowed -ProcessState $ProcessState
    if (-not $mutation.Allowed) { throw $mutation.Reason }
    $inventory = Test-HrsDeploymentInventory -GameRoot $GameRoot -Manifest $Manifest
    if (-not $inventory.Valid) { throw $inventory.Reason }
    if ($inventory.State -eq 'NotInstalled') { return [pscustomobject]@{ Removed=$true; Reason='ALREADY_REMOVED'; RemovedFiles=0 } }

    $removed = 0
    foreach ($file in @($inventory.RemovalPlan)) {
        [System.IO.File]::Delete($file)
        $removed++
    }
    if ([System.IO.Directory]::Exists($inventory.Paths.BridgeRoot) -and @([System.IO.Directory]::EnumerateFileSystemEntries($inventory.Paths.BridgeRoot)).Count -eq 0) { [System.IO.Directory]::Delete($inventory.Paths.BridgeRoot, $false) }
    if ([System.IO.Directory]::Exists($inventory.Paths.ReleaseRoot) -and @([System.IO.Directory]::EnumerateFileSystemEntries($inventory.Paths.ReleaseRoot)).Count -eq 0) { [System.IO.Directory]::Delete($inventory.Paths.ReleaseRoot, $false) }
    $verify = Test-HrsDeploymentInventory -GameRoot $GameRoot -Manifest $Manifest
    if (-not $verify.Valid -or $verify.State -ne 'NotInstalled') { throw 'REMOVE_READBACK_FAILED' }
    return [pscustomobject]@{ Removed=$true; Reason='REMOVED_FROM_GAME'; RemovedFiles=$removed }
}

Export-ModuleMember -Function @(
    'New-HrsDeploymentManifest', 'Test-HrsDeploymentManifest',
    'Test-HrsDeploymentInventory', 'Get-HrsDeploymentUiDecision',
    'Write-HrsPolicyAfterDeploymentValidation', 'Invoke-HrsRemoveFromGame'
)
