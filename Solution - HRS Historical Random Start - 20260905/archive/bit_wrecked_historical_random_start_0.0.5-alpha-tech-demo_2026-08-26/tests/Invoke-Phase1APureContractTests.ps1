$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Phase1A.ContractModel.psm1') -Force

$base = [ordered]@{
    mode='Random'; buildMatch=$true; targetMatch=$true; eacEnabled=$false;
    isServer=$true; executionType='LocalSinglePlayer'; lifecycle='NewGame';
    entityResolved=$true; markerApiAvailable=$true; markerState='Absent';
    reservationSucceeded=$true; spawnListAvailable=$true;
    candidateDefined=$true; candidateInvalid=$false; postSpawnContextValid=$true;
    observerAvailable=$true; containingChunkLoaded=$true;
    candidateSafe=$true; placementSucceeded=$true; atomicSemanticUnchanged=$true;
    finalPositionVerified=$true; completionSucceeded=$true
}

function New-Case([hashtable]$changes) {
    $copy = [ordered]@{}
    foreach ($key in $base.Keys) { $copy[$key] = $base[$key] }
    foreach ($key in $changes.Keys) { $copy[$key] = $changes[$key] }
    return [pscustomobject]$copy
}

$cases = @(
    @{id='P1A-001-standard-noop'; changes=@{mode='Standard'}; reason='P1A_STANDARD_NOOP'; reserve=$false; select=$false; place=$false; complete=$false},
    @{id='P1A-002-loaded-rejected'; changes=@{lifecycle='LoadedGame'}; reason='P1A_LIFECYCLE_REJECTED'; reserve=$false; select=$false; place=$false; complete=$false},
    @{id='P1A-003-multiplayer-rejected'; changes=@{executionType='ListenServer'}; reason='P1A_EXECUTION_REJECTED'; reserve=$false; select=$false; place=$false; complete=$false},
    @{id='P1A-004-eac-rejected'; changes=@{eacEnabled=$true}; reason='P1A_EAC_REJECTED'; reserve=$false; select=$false; place=$false; complete=$false},
    @{id='P1A-005-reserved-consumed'; changes=@{markerState='Reserved'}; reason='P1A_MARKER_CONSUMED_OR_INVALID'; reserve=$false; select=$false; place=$false; complete=$false},
    @{id='P1A-006-completed-consumed'; changes=@{markerState='Completed'}; reason='P1A_MARKER_CONSUMED_OR_INVALID'; reserve=$false; select=$false; place=$false; complete=$false},
    @{id='P1A-007-reservation-before-selection'; changes=@{reservationSucceeded=$false}; reason='P1A_RESERVATION_FAILED'; reserve=$true; select=$false; place=$false; complete=$false},
    @{id='P1A-008-list-unavailable'; changes=@{spawnListAvailable=$false}; reason='P1A_SPAWN_LIST_UNAVAILABLE'; reserve=$true; select=$false; place=$false; complete=$false},
    @{id='P1A-009-undefined-consumes'; changes=@{candidateDefined=$false}; reason='P1A_CANDIDATE_UNDEFINED'; reserve=$true; select=$true; place=$false; complete=$false},
    @{id='P1A-010-invalid-consumes'; changes=@{candidateInvalid=$true}; reason='P1A_CANDIDATE_INVALID'; reserve=$true; select=$true; place=$false; complete=$false},
    @{id='P1A-010a-deferred-context-changed'; changes=@{postSpawnContextValid=$false}; reason='P1A_DEFERRED_CONTEXT_CHANGED'; reserve=$true; select=$true; place=$false; complete=$false},
    @{id='P1A-010b-observer-unavailable'; changes=@{observerAvailable=$false}; reason='P1A_OBSERVER_UNAVAILABLE'; reserve=$true; select=$true; place=$false; complete=$false},
    @{id='P1A-010c-atomic-semantic-changed'; changes=@{atomicSemanticUnchanged=$false}; reason='P1A_SEMANTIC_CHANGED'; reserve=$true; select=$true; place=$true; complete=$false},
    @{id='P1A-011-postplacement-chunk-timeout'; changes=@{containingChunkLoaded=$false}; reason='P1A_POSTPLACEMENT_CHUNK_TIMEOUT'; reserve=$true; select=$true; place=$true; complete=$false},
    @{id='P1A-012-postplacement-unsafe'; changes=@{candidateSafe=$false}; reason='P1A_POSTPLACEMENT_UNSAFE'; reserve=$true; select=$true; place=$true; complete=$false},
    @{id='P1A-013-placement-fails'; changes=@{placementSucceeded=$false}; reason='P1A_PLACEMENT_FAILED'; reserve=$true; select=$true; place=$true; complete=$false},
    @{id='P1A-014-verification-fails'; changes=@{finalPositionVerified=$false}; reason='P1A_PLACEMENT_UNVERIFIED'; reserve=$true; select=$true; place=$true; complete=$false},
    @{id='P1A-015-completion-fails'; changes=@{completionSucceeded=$false}; reason='P1A_COMPLETION_FAILED'; reserve=$true; select=$true; place=$true; complete=$true},
    @{id='P1A-016-success'; changes=@{}; reason='P1A_COMPLETED'; reserve=$true; select=$true; place=$true; complete=$true}
)

$pass=0; $fail=0
foreach($test in $cases) {
    $actual=Get-Phase1ADecision (New-Case $test.changes)
    $ok=$actual.reason-eq$test.reason -and $actual.reserveMarker-eq$test.reserve -and
        $actual.selectCandidate-eq$test.select -and $actual.placePlayer-eq$test.place -and
        $actual.completeMarker-eq$test.complete
    if($ok){Write-Output "PASS $($test.id)";$pass++}else{Write-Output "FAIL $($test.id)";$actual|ConvertTo-Json -Compress;$fail++}
}

$markerCases = @(
    @{id='P1A-M01-reload-reserved-readonly'; lifecycle='LoadedGame'; marker='Reserved'; reason='MARKER_RELOAD_RESERVED'; read=$true; write=$false},
    @{id='P1A-M02-reload-absent-readonly'; lifecycle='LoadedGame'; marker='Absent'; reason='MARKER_RELOAD_ABSENT'; read=$true; write=$false},
    @{id='P1A-M03-reload-invalid-readonly'; lifecycle='LoadedGame'; marker='Invalid'; reason='MARKER_RELOAD_INVALID'; read=$true; write=$false},
    @{id='P1A-M04-death-no-marker-access'; lifecycle='Died'; marker='Reserved'; reason='MARKER_LIFECYCLE_REJECTED'; read=$false; write=$false},
    @{id='P1A-M05-newgame-absent-write-eligible'; lifecycle='NewGame'; marker='Absent'; reason='MARKER_NEWGAME_EVALUATE'; read=$true; write=$true},
    @{id='P1A-M06-newgame-consumed-no-write'; lifecycle='NewGame'; marker='Reserved'; reason='MARKER_NEWGAME_EVALUATE'; read=$true; write=$false}
)
foreach($test in $markerCases) {
    $actual = Get-Phase1AMarkerObservationDecision -Lifecycle $test.lifecycle -MarkerState $test.marker
    $ok = $actual.reason -eq $test.reason -and $actual.readMarker -eq $test.read -and
        $actual.writeMarker -eq $test.write
    if($ok){Write-Output "PASS $($test.id)";$pass++}else{Write-Output "FAIL $($test.id)";$actual|ConvertTo-Json -Compress;$fail++}
}

$settlingCases = @(
    @{
        id='P1A-V01-transient-vertical-settling-stable-success'
        samples=@(
            [pscustomobject]@{grounded=$false; withinTolerance=$false; deadlineExpired=$false},
            [pscustomobject]@{grounded=$true; withinTolerance=$true; deadlineExpired=$false},
            [pscustomobject]@{grounded=$true; withinTolerance=$true; deadlineExpired=$false}
        )
        reason='P1A_COMPLETED'; completed=$true; processed=3; stable=2
    },
    @{
        id='P1A-V02-stale-early-sample-does-not-complete'
        samples=@(
            [pscustomobject]@{grounded=$true; withinTolerance=$true; deadlineExpired=$false},
            [pscustomobject]@{grounded=$false; withinTolerance=$false; deadlineExpired=$true}
        )
        reason='P1A_PLACEMENT_UNVERIFIED'; completed=$false; processed=2; stable=0
    },
    @{
        id='P1A-V03-persistent-mismatch-deadline-fails'
        samples=@(
            [pscustomobject]@{grounded=$false; withinTolerance=$false; deadlineExpired=$false},
            [pscustomobject]@{grounded=$true; withinTolerance=$false; deadlineExpired=$true}
        )
        reason='P1A_PLACEMENT_UNVERIFIED'; completed=$false; processed=2; stable=0
    },
    @{
        id='P1A-V04-no-second-placement-or-reroll'
        samples=@(
            [pscustomobject]@{grounded=$false; withinTolerance=$false; deadlineExpired=$false},
            [pscustomobject]@{grounded=$true; withinTolerance=$true; deadlineExpired=$false},
            [pscustomobject]@{grounded=$true; withinTolerance=$true; deadlineExpired=$false}
        )
        reason='P1A_COMPLETED'; completed=$true; processed=3; stable=2
    },
    @{
        id='P1A-V05-complete-only-after-consecutive-stable-grounded'
        samples=@(
            [pscustomobject]@{grounded=$true; withinTolerance=$true; deadlineExpired=$false},
            [pscustomobject]@{grounded=$false; withinTolerance=$true; deadlineExpired=$false},
            [pscustomobject]@{grounded=$true; withinTolerance=$true; deadlineExpired=$false},
            [pscustomobject]@{grounded=$true; withinTolerance=$true; deadlineExpired=$false}
        )
        reason='P1A_COMPLETED'; completed=$true; processed=4; stable=2
    }
)
foreach($test in $settlingCases) {
    $actual = Get-Phase1ASettlingVerificationDecision -Samples $test.samples
    $ok = $actual.reason -eq $test.reason -and $actual.completed -eq $test.completed -and
        $actual.samplesProcessed -eq $test.processed -and $actual.stableSamples -eq $test.stable -and
        $actual.selectCalls -eq 1 -and $actual.placementCalls -eq 1
    if($ok){Write-Output "PASS $($test.id)";$pass++}else{Write-Output "FAIL $($test.id)";$actual|ConvertTo-Json -Compress;$fail++}
}
Write-Output "PHASE1A_SUMMARY pass=$pass fail=$fail"
if($fail){exit 1}
