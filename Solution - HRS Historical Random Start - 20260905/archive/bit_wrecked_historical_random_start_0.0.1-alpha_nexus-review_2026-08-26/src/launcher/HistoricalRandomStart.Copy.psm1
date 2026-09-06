Set-StrictMode -Version 2.0

function Get-HrsCopyCatalog {
    return @(
        [pscustomobject]@{ Key='GameName'; Label='New Game Name'; Tooltip='Enter the exact name you will use when creating the game'; AccessibleDescription='Exact new-game name used to associate the Standard or Random policy'; Essential=$false; Placement='Control' },
        [pscustomobject]@{ Key='Standard'; Label='Standard'; Tooltip="Use the game's normal starting location"; AccessibleDescription='Disable Historical Random Start for this exact game when Apply is confirmed'; Essential=$false; Placement='Control' },
        [pscustomobject]@{ Key='Random'; Label='Random'; Tooltip="Use one guarded location from the game's authored start list"; AccessibleDescription='Enable one guarded random authored starting location for a genuinely new player'; Essential=$false; Placement='Control' },
        [pscustomobject]@{ Key='Apply'; Label='Apply'; Tooltip='Apply this start policy to the exact new game'; AccessibleDescription='Validate, confirm, write, and verify the selected policy without launching the game'; Essential=$false; Placement='Control' },
        [pscustomobject]@{ Key='LaunchGame'; Label='Launch Game'; Tooltip='Launch the game without changing its configuration'; AccessibleDescription='Launch 7 Days to Die by direct user action; Steam must already be running'; Essential=$false; Placement='Control' },
        [pscustomobject]@{ Key='Recovery'; Label='Recovery'; Tooltip='Review local recovery options and recent attempts'; AccessibleDescription='Open Default, recent snapshot attempts, validation state, and simple changes'; Essential=$false; Placement='Control' },
        [pscustomobject]@{ Key='ShowChanges'; Label='Show Changes'; Tooltip='Compare the current and previous applied configurations'; AccessibleDescription='Show a read-only plain-language comparison without changing the game'; Essential=$false; Placement='Control' },
        [pscustomobject]@{ Key='RestoreLast'; Label='Restore Last Change'; Tooltip='Restore the most recent validated configuration'; AccessibleDescription='Revalidate and confirm the prior known-good configuration before applying it'; Essential=$false; Placement='Control' },
        [pscustomobject]@{ Key='RestoreDefault'; Label='Restore to Default'; Tooltip='Disable Historical Random Start while keeping the mod installed'; AccessibleDescription='Confirm a default policy restore without changing saves, worlds, or progress'; Essential=$false; Placement='Control' },
        [pscustomobject]@{ Key='RemoveFromGame'; Label='Remove from Game'; Tooltip='Remove only Historical Random Start from the game'; AccessibleDescription='Remove verified deployed solution files while retaining the portable manager and history'; Essential=$false; Placement='Details' },
        [pscustomobject]@{ Key='StatusIncomplete'; Label='Configuration incomplete — mod not enabled'; Tooltip=''; AccessibleDescription='Historical Random Start is not enabled; Launch Game remains available'; Essential=$true; Placement='UpperStatus' },
        [pscustomobject]@{ Key='StatusStandard'; Label='Standard — Historical Random Start not enabled'; Tooltip=''; AccessibleDescription='The exact game uses its normal starting location'; Essential=$true; Placement='UpperStatus' },
        [pscustomobject]@{ Key='StatusRandom'; Label='Historical Random Start enabled — confirmed'; Tooltip=''; AccessibleDescription='Random policy was written and read back for the exact game'; Essential=$true; Placement='UpperStatus' },
        [pscustomobject]@{ Key='StatusRunning'; Label='Game is running — changes unavailable'; Tooltip=''; AccessibleDescription='Close the game before Apply, Restore, Reset, or Remove from Game'; Essential=$true; Placement='UpperStatus' },
        [pscustomobject]@{ Key='StatusConflict'; Label='Existing installation requires review'; Tooltip=''; AccessibleDescription='The owned destination contains drift, unknown files, or an identity collision'; Essential=$true; Placement='UpperStatus' },
        [pscustomobject]@{ Key='StatusLane'; Label='Runtime lane unconfirmed'; Tooltip=''; AccessibleDescription='The approved normal non-EAC runtime lane has not been positively confirmed'; Essential=$true; Placement='UpperStatus' }
    )
}

function Test-HrsCopyCatalog {
    $items = @(Get-HrsCopyCatalog)
    $keys = @($items | ForEach-Object { $_.Key })
    if (@($keys | Select-Object -Unique).Count -ne $keys.Count) { return [pscustomobject]@{ Valid=$false; Reason='COPY_DUPLICATE_KEY' } }
    foreach ($item in $items) {
        if ([string]::IsNullOrWhiteSpace([string]$item.Label)) { return [pscustomobject]@{ Valid=$false; Reason='COPY_LABEL_MISSING' } }
        if ([string]::IsNullOrWhiteSpace([string]$item.AccessibleDescription)) { return [pscustomobject]@{ Valid=$false; Reason='COPY_ACCESSIBLE_DESCRIPTION_MISSING' } }
        if ([bool]$item.Essential) {
            if (-not [string]::Equals([string]$item.Placement, 'UpperStatus', [System.StringComparison]::Ordinal)) { return [pscustomobject]@{ Valid=$false; Reason='COPY_ESSENTIAL_NOT_VISIBLE' } }
        }
        elseif ([string]$item.Tooltip -and ([string]$item.Tooltip).Length -gt 75) { return [pscustomobject]@{ Valid=$false; Reason='COPY_TOOLTIP_TOO_LONG' } }
    }
    return [pscustomobject]@{ Valid=$true; Reason='COPY_VALID'; Count=$items.Count }
}

Export-ModuleMember -Function 'Get-HrsCopyCatalog', 'Test-HrsCopyCatalog'
