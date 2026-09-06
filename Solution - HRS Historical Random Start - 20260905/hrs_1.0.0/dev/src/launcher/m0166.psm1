Set-StrictMode -Version 2.0

function New-HrsCoreDecisionResult {
    param(
        [string] $Peg,
        [string] $Outcome,
        [string] $Reason,
        [string] $MarkerState,
        [bool] $ReserveMarker = $false,
        [bool] $SelectCandidate = $false,
        [bool] $PlacePlayer = $false
    )

    return [pscustomobject][ordered]@{
        peg = $Peg
        outcome = $Outcome
        reason = $Reason
        markerState = $MarkerState
        reserveMarker = $ReserveMarker
        selectCandidate = $SelectCandidate
        placePlayer = $PlacePlayer
    }
}

function Get-HrsCoreDecision {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [psobject] $Case)

    $required = @(
        'buildCompatible', 'authorityConfirmed', 'localSinglePlayer',
        'runtimeLaneConfirmed', 'policyValid', 'targetMatch', 'lifecycle',
        'markerState', 'mode', 'entityResolved', 'markerApiAvailable'
    )
    $actual = @($Case.PSObject.Properties.Name)
    foreach ($field in $required) {
        if ($actual -cnotcontains $field) {
            return New-HrsCoreDecisionResult -Peg 'PEG-02' -Outcome 'REJECTED' -Reason 'CASE_FIELD_MISSING' -MarkerState 'NOT_APPLICABLE'
        }
    }

    # This object is an authority boundary, not a convenience parameter bag.
    # Unknown fields and PowerShell's usual string-to-Boolean coercion must not
    # be able to grant the Random path.
    if ($actual.Count -ne $required.Count) {
        return New-HrsCoreDecisionResult -Peg 'PEG-02' -Outcome 'REJECTED' -Reason 'CASE_FIELD_UNKNOWN' -MarkerState 'NOT_APPLICABLE'
    }
    foreach ($field in @(
        'buildCompatible', 'authorityConfirmed', 'localSinglePlayer',
        'runtimeLaneConfirmed', 'policyValid', 'targetMatch',
        'entityResolved', 'markerApiAvailable'
    )) {
        if ($Case.$field -isnot [bool]) {
            return New-HrsCoreDecisionResult -Peg 'PEG-02' -Outcome 'REJECTED' -Reason 'CASE_FIELD_TYPE' -MarkerState 'NOT_APPLICABLE'
        }
    }
    foreach ($field in @('lifecycle', 'markerState', 'mode')) {
        if ($Case.$field -isnot [string]) {
            return New-HrsCoreDecisionResult -Peg 'PEG-02' -Outcome 'REJECTED' -Reason 'CASE_FIELD_TYPE' -MarkerState 'NOT_APPLICABLE'
        }
    }

    if (-not [bool]$Case.buildCompatible -or -not [bool]$Case.authorityConfirmed -or -not [bool]$Case.localSinglePlayer) {
        return New-HrsCoreDecisionResult -Peg 'PEG-01' -Outcome 'INCOMPATIBLE' -Reason 'ENVIRONMENT_INCOMPATIBLE' -MarkerState 'NOT_APPLICABLE'
    }
    if (-not [bool]$Case.runtimeLaneConfirmed) {
        return New-HrsCoreDecisionResult -Peg 'PEG-01E' -Outcome 'INCOMPATIBLE' -Reason 'RUNTIME_LANE_UNCONFIRMED' -MarkerState 'NOT_APPLICABLE'
    }
    if (-not [bool]$Case.policyValid -or @('Standard', 'Random', 'RandomSafe') -cnotcontains ([string]$Case.mode)) {
        return New-HrsCoreDecisionResult -Peg 'PEG-02' -Outcome 'REJECTED' -Reason 'POLICY_REJECTED' -MarkerState 'NOT_APPLICABLE'
    }
    if (-not [bool]$Case.targetMatch) {
        return New-HrsCoreDecisionResult -Peg 'PEG-03' -Outcome 'REJECTED' -Reason 'GAME_NAME_MISMATCH' -MarkerState 'ABSENT'
    }
    if (-not [string]::Equals([string]$Case.lifecycle, 'NewGame', [System.StringComparison]::Ordinal)) {
        return New-HrsCoreDecisionResult -Peg 'PEG-08' -Outcome 'REJECTED' -Reason 'LIFECYCLE_REJECTED' -MarkerState ([string]$Case.markerState)
    }
    if (-not [bool]$Case.entityResolved) {
        return New-HrsCoreDecisionResult -Peg 'PEG-01' -Outcome 'REJECTED' -Reason 'ENTITY_UNRESOLVED' -MarkerState 'NOT_APPLICABLE'
    }
    if (-not [bool]$Case.markerApiAvailable) {
        return New-HrsCoreDecisionResult -Peg 'PEG-01' -Outcome 'REJECTED' -Reason 'MARKER_API_UNAVAILABLE' -MarkerState 'NOT_APPLICABLE'
    }

    $marker = [string]$Case.markerState
    if ($marker -eq 'Invalid') {
        return New-HrsCoreDecisionResult -Peg 'PEG-13' -Outcome 'REJECTED' -Reason 'MARKER_INVALID' -MarkerState 'INVALID'
    }
    if ($marker -eq 'Reserved') {
        return New-HrsCoreDecisionResult -Peg 'PEG-11' -Outcome 'RESERVED' -Reason 'MARKER_CONSUMED' -MarkerState 'RESERVED'
    }
    if ($marker -eq 'Completed') {
        return New-HrsCoreDecisionResult -Peg 'PEG-12' -Outcome 'COMPLETED' -Reason 'MARKER_CONSUMED' -MarkerState 'COMPLETED'
    }
    if ($marker -ne 'Absent') {
        return New-HrsCoreDecisionResult -Peg 'PEG-13' -Outcome 'REJECTED' -Reason 'MARKER_INVALID' -MarkerState 'INVALID'
    }

    if ([string]::Equals([string]$Case.mode, 'Standard', [System.StringComparison]::Ordinal)) {
        return New-HrsCoreDecisionResult -Peg 'PEG-04' -Outcome 'BYPASSED' -Reason 'STANDARD_BYPASS' -MarkerState 'NOT_APPLICABLE'
    }
    return New-HrsCoreDecisionResult -Peg 'PEG-05' -Outcome 'PERMITTED' -Reason 'RANDOM_FIRST_ARRIVAL_PERMITTED' -MarkerState 'ABSENT' -ReserveMarker $true -SelectCandidate $true -PlacePlayer $true
}

function Get-HrsManagerCapabilities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [psobject] $ProcessState,
        [bool] $GameRootValid,
        [bool] $ExactNameValid,
        [bool] $CapsuleInstalled,
        [bool] $CapsuleOwnershipValid,
        [bool] $PolicyValid,
        [bool] $RestoreTargetValid
    )

    $gameClosed = [string]::Equals([string]$ProcessState.Game, 'Closed', [System.StringComparison]::Ordinal)
    $steamRunning = [string]::Equals([string]$ProcessState.Steam, 'Running', [System.StringComparison]::Ordinal)
    return [pscustomobject][ordered]@{
        canView = $true
        canValidate = $gameClosed
        canApply = $gameClosed -and $GameRootValid -and $ExactNameValid -and $CapsuleInstalled -and $CapsuleOwnershipValid
        canRestore = $gameClosed -and $GameRootValid -and $CapsuleInstalled -and $CapsuleOwnershipValid -and $RestoreTargetValid
        canRestoreDefault = $gameClosed -and $GameRootValid -and $CapsuleInstalled -and $CapsuleOwnershipValid
        canRemoveFromGame = $gameClosed -and $GameRootValid -and $CapsuleInstalled -and $CapsuleOwnershipValid
        launchVisible = $true
        canLaunch = $gameClosed -and $steamRunning
        configurationComplete = $GameRootValid -and $ExactNameValid -and $PolicyValid -and $CapsuleInstalled -and $CapsuleOwnershipValid
        mutationBlockReason = $(
            if ($gameClosed) { '' }
            elseif ([string]::Equals([string]$ProcessState.Game, 'Running', [System.StringComparison]::Ordinal)) { 'GAME_RUNNING' }
            else { 'GAME_STATE_UNCONFIRMED' }
        )
        launchBlockReason = $(
            if (-not $gameClosed) { if ([string]::Equals([string]$ProcessState.Game, 'Running', [System.StringComparison]::Ordinal)) { 'GAME_ALREADY_RUNNING' } else { 'GAME_STATE_UNCONFIRMED' } }
            elseif (-not $steamRunning) { if ([string]::Equals([string]$ProcessState.Steam, 'Closed', [System.StringComparison]::Ordinal)) { 'STEAM_NOT_RUNNING' } else { 'STEAM_STATE_UNCONFIRMED' } }
            else { '' }
        )
    }
}

Export-ModuleMember -Function 'Get-HrsCoreDecision', 'Get-HrsManagerCapabilities'
