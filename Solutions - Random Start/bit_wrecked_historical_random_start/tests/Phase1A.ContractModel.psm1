Set-StrictMode -Version Latest

function Get-Phase1ADecision {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [psobject] $Case)

    $result = [ordered]@{
        reason = 'P1A_FAIL_CLOSED'
        reserveMarker = $false
        selectCandidate = $false
        placePlayer = $false
        completeMarker = $false
        finalMarker = [string]$Case.markerState
    }

    if ($Case.mode -eq 'Standard') { $result.reason = 'P1A_STANDARD_NOOP'; return [pscustomobject]$result }
    if ($Case.mode -ne 'Random') { $result.reason = 'P1A_MODE_INVALID'; return [pscustomobject]$result }
    if (-not $Case.buildMatch) { $result.reason = 'P1A_BUILD_MISMATCH'; return [pscustomobject]$result }
    if (-not $Case.targetMatch) { $result.reason = 'P1A_TARGET_MISMATCH'; return [pscustomobject]$result }
    if ($Case.eacEnabled) { $result.reason = 'P1A_EAC_REJECTED'; return [pscustomobject]$result }
    if (-not $Case.isServer) { $result.reason = 'P1A_NOT_SERVER'; return [pscustomobject]$result }
    if ($Case.executionType -ne 'LocalSinglePlayer') { $result.reason = 'P1A_EXECUTION_REJECTED'; return [pscustomobject]$result }
    if ($Case.lifecycle -ne 'NewGame') { $result.reason = 'P1A_LIFECYCLE_REJECTED'; return [pscustomobject]$result }
    if (-not $Case.entityResolved) { $result.reason = 'P1A_ENTITY_UNRESOLVED'; return [pscustomobject]$result }
    if (-not $Case.markerApiAvailable) { $result.reason = 'P1A_MARKER_API_UNAVAILABLE'; return [pscustomobject]$result }
    if ($Case.markerState -ne 'Absent') { $result.reason = 'P1A_MARKER_CONSUMED_OR_INVALID'; return [pscustomobject]$result }

    $result.reserveMarker = $true
    if (-not $Case.reservationSucceeded) { $result.reason = 'P1A_RESERVATION_FAILED'; return [pscustomobject]$result }
    $result.finalMarker = 'Reserved'

    if (-not $Case.spawnListAvailable) { $result.reason = 'P1A_SPAWN_LIST_UNAVAILABLE'; return [pscustomobject]$result }
    $result.selectCandidate = $true
    if (-not $Case.candidateDefined) { $result.reason = 'P1A_CANDIDATE_UNDEFINED'; return [pscustomobject]$result }
    if ($Case.candidateInvalid) { $result.reason = 'P1A_CANDIDATE_INVALID'; return [pscustomobject]$result }
    if (-not $Case.postSpawnContextValid) { $result.reason = 'P1A_DEFERRED_CONTEXT_CHANGED'; return [pscustomobject]$result }
    if (-not $Case.observerAvailable) { $result.reason = 'P1A_OBSERVER_UNAVAILABLE'; return [pscustomobject]$result }
    $result.placePlayer = $true
    if (-not $Case.placementSucceeded) { $result.reason = 'P1A_PLACEMENT_FAILED'; return [pscustomobject]$result }
    if (-not $Case.atomicSemanticUnchanged) { $result.reason = 'P1A_SEMANTIC_CHANGED'; return [pscustomobject]$result }
    if (-not $Case.containingChunkLoaded) { $result.reason = 'P1A_POSTPLACEMENT_CHUNK_TIMEOUT'; return [pscustomobject]$result }
    if (-not $Case.candidateSafe) { $result.reason = 'P1A_POSTPLACEMENT_UNSAFE'; return [pscustomobject]$result }
    if (-not $Case.finalPositionVerified) { $result.reason = 'P1A_PLACEMENT_UNVERIFIED'; return [pscustomobject]$result }

    $result.completeMarker = $true
    if (-not $Case.completionSucceeded) { $result.reason = 'P1A_COMPLETION_FAILED'; return [pscustomobject]$result }
    $result.finalMarker = 'Completed'
    $result.reason = 'P1A_COMPLETED'
    return [pscustomobject]$result
}

function Get-Phase1AMarkerObservationDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Lifecycle,
        [Parameter(Mandatory = $true)] [string] $MarkerState
    )

    if ($Lifecycle -eq 'LoadedGame') {
        return [pscustomobject]@{
            reason = "MARKER_RELOAD_$($MarkerState.ToUpperInvariant())"
            readMarker = $true
            writeMarker = $false
        }
    }
    if ($Lifecycle -ne 'NewGame') {
        return [pscustomobject]@{
            reason = 'MARKER_LIFECYCLE_REJECTED'
            readMarker = $false
            writeMarker = $false
        }
    }
    return [pscustomobject]@{
        reason = 'MARKER_NEWGAME_EVALUATE'
        readMarker = $true
        writeMarker = ($MarkerState -eq 'Absent')
    }
}

Export-ModuleMember -Function Get-Phase1ADecision, Get-Phase1AMarkerObservationDecision
