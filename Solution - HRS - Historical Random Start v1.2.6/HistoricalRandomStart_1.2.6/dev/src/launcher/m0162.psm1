Set-StrictMode -Version 2.0

$corePath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'm0161.psm1'
Import-Module $corePath -Force

$script:HrsDeploymentSchema = 'hrs-deployment-manifest/v1'
$script:HrsReleaseFolder = 'BitWrecked_HistoricalRandomStart'
$script:HrsStaticFiles = @('d0163.dll', 'ModInfo.xml')
$script:HrsBridgeFiles = @('policy.v1.json', 'policy.v2.json', 'result.v1.json')

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
            if ($leaf -ceq 'policy.v1.json' -or $leaf -ceq 'policy.v2.json') { try { $policy=Read-HrsPolicyFile -Path $file; if (($leaf -ceq 'policy.v2.json') -ne ($policy.schema -ceq 'hrs-policy/v2')) { throw 'POLICY_FILENAME_SCHEMA' } } catch { return [pscustomobject]@{ Valid=$false; State='Drift'; Reason='DEPLOYMENT_POLICY_INVALID'; RemovalPlan=@() } } }
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

function Test-HrsRemovalOwnership {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $GameRoot
    )

    $paths = Get-HrsBridgePaths -GameRoot $GameRoot

    if (-not [System.IO.Directory]::Exists($paths.ReleaseRoot)) {
        return [pscustomobject]@{
            Valid       = $true
            State       = 'NotInstalled'
            Reason      = 'RELEASE_ROOT_ABSENT'
            RemovalPlan = @()
            Paths       = $paths
        }
    }

    try {
        $directories = @(
            [System.IO.Directory]::EnumerateDirectories(
                $paths.ReleaseRoot,
                '*',
                [System.IO.SearchOption]::AllDirectories
            )
        )

        $files = @(
            [System.IO.Directory]::EnumerateFiles(
                $paths.ReleaseRoot,
                '*',
                [System.IO.SearchOption]::AllDirectories
            )
        )
    }
    catch {
        return [pscustomobject]@{
            Valid       = $false
            State       = 'InventoryFailed'
            Reason      = 'REMOVAL_ENUMERATION_FAILED'
            RemovalPlan = @()
            Paths       = $paths
        }
    }

    foreach ($directory in @($paths.ReleaseRoot) + $directories) {
        $attributes = [System.IO.File]::GetAttributes($directory)

        if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            return [pscustomobject]@{
                Valid       = $false
                State       = 'Conflict'
                Reason      = 'REMOVAL_REPARSE_POINT'
                RemovalPlan = @()
                Paths       = $paths
            }
        }
    }

    foreach ($directory in $directories) {
        if (-not [string]::Equals(
            $directory,
            $paths.BridgeRoot,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            return [pscustomobject]@{
                Valid       = $false
                State       = 'Conflict'
                Reason      = 'REMOVAL_UNKNOWN_DIRECTORY'
                RemovalPlan = @()
                Paths       = $paths
            }
        }
    }

    $plan = New-Object System.Collections.Generic.List[string]
    $modInfoPath = $null

    foreach ($file in $files) {
        $attributes = [System.IO.File]::GetAttributes($file)

        if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            return [pscustomobject]@{
                Valid       = $false
                State       = 'Conflict'
                Reason      = 'REMOVAL_FILE_REPARSE_POINT'
                RemovalPlan = @()
                Paths       = $paths
            }
        }

        $relative = $file.Substring($paths.ReleaseRoot.Length).TrimStart(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        ).Replace(
            [System.IO.Path]::DirectorySeparatorChar,
            '/'
        )

        if ($relative.StartsWith('Bridge/', [System.StringComparison]::Ordinal)) {
            $leaf = [System.IO.Path]::GetFileName($file)

            if ($script:HrsBridgeFiles -cnotcontains $leaf) {
                return [pscustomobject]@{
                    Valid       = $false
                    State       = 'Conflict'
                    Reason      = 'REMOVAL_UNKNOWN_BRIDGE_FILE'
                    RemovalPlan = @()
                    Paths       = $paths
                }
            }

            [void]$plan.Add($file)
            continue
        }

        if (@('d0163.dll', 'ModInfo.xml') -cnotcontains $relative) {
            return [pscustomobject]@{
                Valid       = $false
                State       = 'Conflict'
                Reason      = 'REMOVAL_UNKNOWN_FILE'
                RemovalPlan = @()
                Paths       = $paths
            }
        }

        if ($relative -ceq 'ModInfo.xml') {
            $modInfoPath = $file
        }

        [void]$plan.Add($file)
    }

    if ([string]::IsNullOrEmpty($modInfoPath) -or
        -not [System.IO.File]::Exists(
            [System.IO.Path]::Combine($paths.ReleaseRoot, 'd0163.dll')
        )) {
        return [pscustomobject]@{
            Valid       = $false
            State       = 'Incomplete'
            Reason      = 'REMOVAL_IDENTITY_FILES_MISSING'
            RemovalPlan = @()
            Paths       = $paths
        }
    }

    try {
        [xml]$modInfo = [System.IO.File]::ReadAllText($modInfoPath)

        $nameNode = @($modInfo.DocumentElement.ChildNodes | Where-Object {
    [string]::Equals($_.Name, 'Name', [System.StringComparison]::Ordinal)
}) | Select-Object -First 1

$name = if ($null -eq $nameNode) {
    ''
}
else {
    [string]$nameNode.GetAttribute('value')
}

        if (-not [string]::Equals(
            $name,
            'BitWrecked_HistoricalRandomStart',
            [System.StringComparison]::Ordinal
        )) {
            throw 'identity mismatch'
        }
    }
    catch {
        return [pscustomobject]@{
            Valid       = $false
            State       = 'Conflict'
            Reason      = 'REMOVAL_MODINFO_IDENTITY'
            RemovalPlan = @()
            Paths       = $paths
        }
    }

    return [pscustomobject]@{
        Valid       = $true
        State       = 'Owned'
        Reason      = 'REMOVAL_OWNERSHIP_CONFIRMED'
        RemovalPlan = @($plan | Sort-Object -Descending)
        Paths       = $paths
    }
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
    $ownership = Test-HrsRemovalOwnership -GameRoot $GameRoot
    if (-not $ownership.Valid) { throw $ownership.Reason }
    if ($ownership.State -eq 'NotInstalled') { return [pscustomobject]@{ Removed=$true; Reason='ALREADY_REMOVED'; RemovedFiles=0 } }
    if ($ownership.State -ne 'Owned') { throw 'REMOVAL_OWNERSHIP_REQUIRED' }

    $removed = 0
    foreach ($file in @($ownership.RemovalPlan)) {
        [System.IO.File]::Delete($file)
        $removed++
    }
    if ([System.IO.Directory]::Exists($ownership.Paths.BridgeRoot) -and @([System.IO.Directory]::EnumerateFileSystemEntries($ownership.Paths.BridgeRoot)).Count -eq 0) { [System.IO.Directory]::Delete($ownership.Paths.BridgeRoot, $false) }
    if ([System.IO.Directory]::Exists($ownership.Paths.ReleaseRoot) -and @([System.IO.Directory]::EnumerateFileSystemEntries($ownership.Paths.ReleaseRoot)).Count -eq 0) { [System.IO.Directory]::Delete($ownership.Paths.ReleaseRoot, $false) }

    $verify = Test-HrsRemovalOwnership -GameRoot $GameRoot
    if (-not $verify.Valid -or $verify.State -ne 'NotInstalled') { throw 'REMOVE_READBACK_FAILED' }
    return [pscustomobject]@{ Removed=$true; Reason='REMOVED_FROM_GAME'; RemovedFiles=$removed }
}

function Invoke-HrsInstallAndApply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$PayloadRoot,
        [Parameter(Mandatory=$true)][psobject]$Policy,
        [Parameter(Mandatory=$true)][string]$ReleaseVersion
    )

    $mutation=Test-HrsMutationAllowed -ProcessState (Get-HrsProcessState)
    if(-not $mutation.Allowed){throw $mutation.Reason}
    $manifest=New-HrsDeploymentManifest -PayloadRoot $PayloadRoot -ReleaseVersion $ReleaseVersion
    $before=Test-HrsDeploymentInventory -GameRoot $GameRoot -Manifest $manifest
    $deployRequired=$false
    $overwrite=$false
    if($before.Valid -and $before.State -eq 'InstalledValid') { }
    elseif($before.Valid -and $before.State -eq 'NotInstalled') { $deployRequired=$true }
    elseif(-not $before.Valid -and $before.State -eq 'Drift' -and
        $before.Reason -eq 'DEPLOYMENT_STATIC_FILE_DRIFT') {
        $ownership=Test-HrsRemovalOwnership -GameRoot $GameRoot
        if(-not $ownership.Valid -or $ownership.State -ne 'Owned') {
            throw "Release upgrade blocked because the existing installation could not be confirmed as Historical Random Start: $($ownership.Reason)"
        }
        $deployRequired=$true
        $overwrite=$true
    }
    else { throw "Release destination is not safe to install or upgrade: $($before.Reason)" }

    $paths=Get-HrsBridgePaths -GameRoot $GameRoot
    $targets=@(
        [IO.Path]::Combine($paths.ReleaseRoot,'d0163.dll'),
        [IO.Path]::Combine($paths.ReleaseRoot,'ModInfo.xml'),
        $paths.PolicyPath,
        $paths.LegacyPolicyPath
    )
    $backupRoot=[IO.Path]::Combine([IO.Path]::GetTempPath(),
        'hrs126-apply-'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($backupRoot)
    $snapshots=New-Object System.Collections.Generic.List[object]
    $keepBackup=$false
    $mutationStarted=$false
    try {
        for($i=0;$i -lt $targets.Count;$i++) {
            $target=$targets[$i]
            $existed=[IO.File]::Exists($target)
            $backup=[IO.Path]::Combine($backupRoot,"$i.bin")
            $hash=''
            if($existed) {
                [IO.File]::Copy($target,$backup,$false)
                $hash=Get-HrsFileSha256 -Path $backup
            }
            [void]$snapshots.Add([pscustomobject]@{
                Target=$target;Backup=$backup;Existed=$existed;Hash=$hash
            })
        }
        $mutation=Test-HrsMutationAllowed -ProcessState (Get-HrsProcessState)
        if(-not $mutation.Allowed){throw $mutation.Reason}
        $mutationStarted=$true
        if($deployRequired) {
            [void][IO.Directory]::CreateDirectory($paths.ReleaseRoot)
            [void][IO.Directory]::CreateDirectory($paths.BridgeRoot)
            [IO.File]::Copy((Join-Path $PayloadRoot 'd0163.dll'),$targets[0],$overwrite)
            [IO.File]::Copy((Join-Path $PayloadRoot 'ModInfo.xml'),$targets[1],$overwrite)
            $after=Test-HrsDeploymentInventory -GameRoot $GameRoot -Manifest $manifest
            if(-not $after.Valid -or $after.State -ne 'InstalledValid') {
                throw "Release installation verification failed: $($after.Reason)"
            }
        }
        [void][IO.Directory]::CreateDirectory($paths.BridgeRoot)
        $written=Write-HrsAppliedPolicy -GameRoot $GameRoot -Policy $Policy
        return [pscustomobject]@{ Policy=$written;Manifest=$manifest;Deployed=$deployRequired;Upgraded=$overwrite }
    }
    catch {
        $failure=$_.Exception.Message
        if($mutationStarted) {
            try {
                foreach($snapshot in $snapshots) {
                    if($snapshot.Existed) {
                        if((Get-HrsFileSha256 -Path $snapshot.Backup) -cne $snapshot.Hash) {
                            throw 'APPLY_BACKUP_CHANGED'
                        }
                        [IO.File]::Copy($snapshot.Backup,$snapshot.Target,$true)
                        if((Get-HrsFileSha256 -Path $snapshot.Target) -cne $snapshot.Hash) {
                            throw 'APPLY_RESTORE_MISMATCH'
                        }
                    }
                    elseif([IO.File]::Exists($snapshot.Target)) {
                        [IO.File]::Delete($snapshot.Target)
                    }
                }
                if([IO.Directory]::Exists($paths.BridgeRoot) -and
                    @([IO.Directory]::EnumerateFileSystemEntries($paths.BridgeRoot)).Count -eq 0) {
                    [IO.Directory]::Delete($paths.BridgeRoot,$false)
                }
                if([IO.Directory]::Exists($paths.ReleaseRoot) -and
                    @([IO.Directory]::EnumerateFileSystemEntries($paths.ReleaseRoot)).Count -eq 0) {
                    [IO.Directory]::Delete($paths.ReleaseRoot,$false)
                }
            }
            catch {
                $keepBackup=$true
                throw "APPLY_RECOVERY_FAILED: $failure; backup: $backupRoot; restore: $($_.Exception.Message)"
            }
            throw "APPLY_ROLLED_BACK: $failure"
        }
        throw
    }
    finally {
        if(-not $keepBackup) {
            foreach($snapshot in $snapshots) {
                if([IO.File]::Exists($snapshot.Backup)){[IO.File]::Delete($snapshot.Backup)}
            }
            if([IO.Directory]::Exists($backupRoot) -and
                @([IO.Directory]::EnumerateFileSystemEntries($backupRoot)).Count -eq 0) {
                [IO.Directory]::Delete($backupRoot,$false)
            }
        }
    }
}

function Test-HrsLaunchInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][psobject]$Manifest,
        [Parameter(Mandatory=$true)][psobject]$ProcessState
    )

    $allowed=Test-HrsLaunchAllowed -ProcessState $ProcessState
    if(-not $allowed.Allowed){throw $allowed.Reason}
    $inventory=Test-HrsDeploymentInventory -GameRoot $GameRoot -Manifest $Manifest
    if(-not $inventory.Valid -or $inventory.State -ne 'InstalledValid') {
        throw "LAUNCH_INSTALLATION_INVALID: $($inventory.Reason)"
    }
    $configured=Read-HrsConfiguredPolicy -GameRoot $GameRoot
    if($null -eq $configured -or $configured.schema -cne 'hrs-policy/v2') {
        throw 'LAUNCH_V2_POLICY_REQUIRED'
    }
    $exe=[IO.Path]::Combine($inventory.Paths.GameRoot,'7DaysToDie.exe')
    if(-not [IO.File]::Exists($exe)){throw 'GAME_EXECUTABLE_MISSING'}
    return [pscustomobject]@{Executable=$exe;WorkingDirectory=$inventory.Paths.GameRoot;Policy=$configured}
}

Export-ModuleMember -Function @(
    'New-HrsDeploymentManifest', 'Test-HrsDeploymentManifest',
    'Test-HrsDeploymentInventory', 'Test-HrsRemovalOwnership',
    'Invoke-HrsRemoveFromGame', 'Invoke-HrsInstallAndApply',
    'Test-HrsLaunchInstallation'
)
