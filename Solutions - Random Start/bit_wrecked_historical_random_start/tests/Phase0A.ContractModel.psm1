Set-StrictMode -Version 2.0

function New-HrsDecisionResult {
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Scenario
    )

    return [ordered]@{
        Outcome              = 'Rejected'
        Reason               = 'INPUT_INVALID'
        Eligible             = $false
        MarkerAfter          = [string] $Scenario.MarkerState
        ReservationWrites    = 0
        SelectionAttempts    = 0
        PlacementAttempts    = 0
        CompletionWrites     = 0
        PositionChanged      = $false
        ForbiddenSideEffects = 0
    }
}

function Complete-HrsDecision {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Result
    )

    return [pscustomobject] $Result
}

function Get-Alpha6CoreDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Scenario
    )

    $required = @(
        'Phase', 'BuildCompatible', 'TargetMatched', 'EacState', 'Activation',
        'Mode', 'Authority', 'Lifecycle', 'EntityResolved',
        'DuplicateObserved', 'MarkerState', 'ReservationResult', 'SpawnList',
        'Candidate', 'PlacementResult', 'CompletionResult'
    )

    $scenarioProperties = @($Scenario.PSObject.Properties.Name)
    foreach ($requiredName in $required) {
        if ($scenarioProperties -notcontains $requiredName) {
            throw "Missing scenario field: $requiredName"
        }
    }

    $result = New-HrsDecisionResult -Scenario $Scenario

    if ([string] $Scenario.Phase -eq 'Observation') {
        if (-not [bool] $Scenario.BuildCompatible) {
            $result['Reason'] = 'OBS_BUILD_MISMATCH'
            return Complete-HrsDecision -Result $result
        }
        if (-not [bool] $Scenario.TargetMatched) {
            $result['Reason'] = 'OBS_TARGET_MISMATCH'
            return Complete-HrsDecision -Result $result
        }
        if ([string] $Scenario.EacState -ne 'Disabled') {
            $result['Reason'] = 'OBS_EAC_NOT_DISABLED'
            return Complete-HrsDecision -Result $result
        }
        if ([string] $Scenario.Authority -ne 'Server') {
            $result['Reason'] = 'OBS_NOT_SERVER'
            return Complete-HrsDecision -Result $result
        }
        if ([string] $Scenario.Lifecycle -notin @('NewGame', 'EnterMultiplayer')) {
            $result['Reason'] = 'OBS_LIFECYCLE_REJECTED'
            return Complete-HrsDecision -Result $result
        }
        if (-not [bool] $Scenario.EntityResolved) {
            $result['Reason'] = 'OBS_ENTITY_UNRESOLVED'
            return Complete-HrsDecision -Result $result
        }
        if ([bool] $Scenario.DuplicateObserved) {
            $result['Reason'] = 'OBS_DUPLICATE_SUPPRESSED'
            return Complete-HrsDecision -Result $result
        }

        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'OBS_ELIGIBLE_NEW_CHARACTER'
        $result['Eligible'] = $true
        return Complete-HrsDecision -Result $result
    }

    if ([string] $Scenario.Phase -ne 'Core') {
        return Complete-HrsDecision -Result $result
    }

    if (-not [bool] $Scenario.BuildCompatible) {
        $result['Reason'] = 'BUILD_MISMATCH'
        return Complete-HrsDecision -Result $result
    }
    if (-not [bool] $Scenario.TargetMatched) {
        $result['Reason'] = 'TARGET_MISMATCH'
        return Complete-HrsDecision -Result $result
    }
    if ([string] $Scenario.EacState -ne 'Disabled') {
        $result['Reason'] = 'EAC_NOT_DISABLED'
        return Complete-HrsDecision -Result $result
    }

    if ([string] $Scenario.Activation -eq 'Bypassed') {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'POLICY_BYPASSED'
        return Complete-HrsDecision -Result $result
    }
    if ([string] $Scenario.Activation -ne 'Active') {
        $result['Reason'] = 'POLICY_ACTIVATION_INVALID'
        return Complete-HrsDecision -Result $result
    }

    if ([string] $Scenario.Mode -eq 'Vanilla') {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'STANDARD_EXACT_NOOP'
        return Complete-HrsDecision -Result $result
    }
    if ([string] $Scenario.Mode -ne 'Random') {
        $result['Reason'] = 'POLICY_MODE_INVALID'
        return Complete-HrsDecision -Result $result
    }

    if ([string] $Scenario.Authority -ne 'Server') {
        $result['Reason'] = 'AUTHORITY_NOT_SERVER'
        return Complete-HrsDecision -Result $result
    }
    if ([string] $Scenario.Lifecycle -notin @('NewGame', 'EnterMultiplayer')) {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'LIFECYCLE_NOT_NEW_CHARACTER'
        return Complete-HrsDecision -Result $result
    }
    if (-not [bool] $Scenario.EntityResolved) {
        $result['Reason'] = 'ENTITY_UNRESOLVED'
        return Complete-HrsDecision -Result $result
    }
    if ([bool] $Scenario.DuplicateObserved) {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'DUPLICATE_SUPPRESSED'
        return Complete-HrsDecision -Result $result
    }

    switch ([string] $Scenario.MarkerState) {
        'Unavailable' {
            $result['Outcome'] = 'VanillaFallback'
            $result['Reason'] = 'MARKER_API_UNAVAILABLE'
            return Complete-HrsDecision -Result $result
        }
        'Reserved' {
            $result['Outcome'] = 'VanillaFallback'
            $result['Reason'] = 'MARKER_ALREADY_RESERVED'
            return Complete-HrsDecision -Result $result
        }
        'Completed' {
            $result['Outcome'] = 'VanillaFallback'
            $result['Reason'] = 'MARKER_ALREADY_COMPLETED'
            return Complete-HrsDecision -Result $result
        }
        'Invalid' {
            $result['MarkerAfter'] = 'Invalid'
            $result['Reason'] = 'MARKER_INVALID'
            return Complete-HrsDecision -Result $result
        }
        'Malformed' {
            $result['MarkerAfter'] = 'Invalid'
            $result['Reason'] = 'MARKER_INVALID'
            return Complete-HrsDecision -Result $result
        }
        'Absent' { }
        default {
            $result['MarkerAfter'] = 'Invalid'
            $result['Reason'] = 'MARKER_INVALID'
            return Complete-HrsDecision -Result $result
        }
    }

    $result['ReservationWrites'] = 1
    if ([string] $Scenario.ReservationResult -ne 'Success') {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'RESERVATION_WRITE_FAILED'
        return Complete-HrsDecision -Result $result
    }

    $result['Eligible'] = $true
    $result['MarkerAfter'] = 'Reserved'

    if ([string] $Scenario.SpawnList -eq 'Unavailable') {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'SPAWN_LIST_UNAVAILABLE'
        return Complete-HrsDecision -Result $result
    }
    if ([string] $Scenario.SpawnList -eq 'Empty') {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'SPAWN_LIST_EMPTY'
        return Complete-HrsDecision -Result $result
    }
    if ([string] $Scenario.SpawnList -ne 'Available') {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'SPAWN_LIST_UNAVAILABLE'
        return Complete-HrsDecision -Result $result
    }

    $result['SelectionAttempts'] = 1
    $candidateReasons = @{
        Undefined        = 'CANDIDATE_UNDEFINED'
        Invalid          = 'CANDIDATE_INVALID'
        OutOfBounds      = 'CANDIDATE_OUT_OF_BOUNDS'
        ChunkUnavailable = 'CANDIDATE_CHUNK_UNAVAILABLE'
        Unsafe           = 'CANDIDATE_UNSAFE'
    }
    $candidateName = [string] $Scenario.Candidate
    if ($candidateReasons.ContainsKey($candidateName)) {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = $candidateReasons[$candidateName]
        return Complete-HrsDecision -Result $result
    }
    if ($candidateName -ne 'Valid') {
        $result['Outcome'] = 'VanillaFallback'
        $result['Reason'] = 'CANDIDATE_INVALID'
        return Complete-HrsDecision -Result $result
    }

    if ([string] $Scenario.PlacementResult -eq 'NotAttempted') {
        $result['Reason'] = 'PLACEMENT_NOT_ATTEMPTED'
        return Complete-HrsDecision -Result $result
    }

    $result['PlacementAttempts'] = 1
    if ([string] $Scenario.PlacementResult -eq 'Throws') {
        $result['Reason'] = 'PLACEMENT_THROW'
        return Complete-HrsDecision -Result $result
    }
    if ([string] $Scenario.PlacementResult -ne 'Verified') {
        $result['Reason'] = 'PLACEMENT_UNVERIFIED'
        return Complete-HrsDecision -Result $result
    }

    $result['PositionChanged'] = $true
    $result['CompletionWrites'] = 1
    if ([string] $Scenario.CompletionResult -ne 'Success') {
        $result['Reason'] = 'COMPLETION_WRITE_FAILED'
        return Complete-HrsDecision -Result $result
    }

    $result['Outcome'] = 'Relocated'
    $result['Reason'] = 'CORE_RELOCATION_COMPLETED'
    $result['MarkerAfter'] = 'Completed'
    return Complete-HrsDecision -Result $result
}

function Test-HrsPathWithin {
    param(
        [Parameter(Mandatory = $true)] [string] $Candidate,
        [Parameter(Mandatory = $true)] [string] $Parent
    )

    if ($Candidate.Equals($Parent, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $prefix = $Parent.TrimEnd([char[]] "\/") + [System.IO.Path]::DirectorySeparatorChar
    return $Candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-HrsPureCanonicalPath {
    param([string] $Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }
    if ($Value.StartsWith('\\') -or $Value.StartsWith('//')) {
        return $null
    }
    if ($Value -match '(^|[\\/])\.\.([\\/]|$)' -or $Value -match '[*?<>|"]') {
        return $null
    }
    if (-not [System.IO.Path]::IsPathRooted($Value)) {
        return $null
    }

    try {
        $full = [System.IO.Path]::GetFullPath($Value).TrimEnd([char[]] "\/")
    }
    catch {
        return $null
    }

    if (-not $full.Equals($Value.TrimEnd([char[]] "\/"), [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    return $full
}

function Test-Phase1TargetRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [psobject] $Record,
        [Parameter(Mandatory = $true)] [string] $LiveGameRoot,
        [Parameter(Mandatory = $true)] [psobject] $ExpectedFingerprint
    )

    $requiredTop = @(
        'schemaVersion', 'recordPurpose', 'targetId', 'deploymentClass',
        'gameRootCanonical', 'buildStageRootCanonical', 'saveRootCanonical',
        'worldName', 'gameName', 'worldGuid', 'executionType', 'eacState',
        'expectedFingerprint', 'backup', 'createdUtc', 'expiresUtc'
    )
    $allowedTop = @($requiredTop) + @('ownerApproval')
    $topNames = @($Record.PSObject.Properties.Name)
    if (@($topNames | Where-Object { $allowedTop -notcontains $_ }).Count -gt 0) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_SCHEMA_UNKNOWN_FIELD' }
    }
    if (@($requiredTop | Where-Object { $topNames -notcontains $_ }).Count -gt 0) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_SCHEMA_MISSING_FIELD' }
    }

    if ([int] $Record.schemaVersion -ne 1 -or [string] $Record.recordPurpose -ne 'Phase1Observation') {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_SCHEMA_VERSION' }
    }
    $deploymentClass = [string] $Record.deploymentClass
    if ($deploymentClass -notin @('DisposableStagedCopy', 'OwnerDesignatedDisposableLiveInstall')) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_DEPLOYMENT_CLASS' }
    }
    $ownerApprovalProperty = $Record.PSObject.Properties['ownerApproval']
    if ($deploymentClass -eq 'OwnerDesignatedDisposableLiveInstall') {
        if ($null -eq $ownerApprovalProperty) {
            return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_OWNER_APPROVAL_REQUIRED' }
        }

        $allowedOwnerApproval = @(
            'approvedForPrivateObservationLab', 'approvalScope', 'approvedUtc',
            'ownedModFolderName', 'externalBuildStageRequired', 'newGameOnly',
            'protectExistingSavesAndWorlds', 'protectExistingMods',
            'protectProjectWorkspace', 'wipeRequiresSeparateApproval',
            'copyAndLoadRequireExactArtifactApproval'
        )
        $ownerApprovalNames = @($Record.ownerApproval.PSObject.Properties.Name)
        if (@($ownerApprovalNames | Where-Object { $allowedOwnerApproval -notcontains $_ }).Count -gt 0 -or
            @($allowedOwnerApproval | Where-Object { $ownerApprovalNames -notcontains $_ }).Count -gt 0) {
            return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_OWNER_APPROVAL_SHAPE' }
        }

        $requiredTrueFields = @(
            'approvedForPrivateObservationLab', 'externalBuildStageRequired',
            'newGameOnly', 'protectExistingSavesAndWorlds', 'protectExistingMods',
            'protectProjectWorkspace', 'wipeRequiresSeparateApproval',
            'copyAndLoadRequireExactArtifactApproval'
        )
        foreach ($fieldName in $requiredTrueFields) {
            $fieldValue = $Record.ownerApproval.$fieldName
            if ($fieldValue -isnot [bool] -or -not $fieldValue) {
                return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_OWNER_APPROVAL_INVALID' }
            }
        }
        if ([string] $Record.ownerApproval.approvalScope -cne 'Phase1ObservationPrivateLab' -or
            [string] $Record.ownerApproval.ownedModFolderName -cne 'BitWrecked_HistoricalRandomStart_DEV') {
            return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_OWNER_APPROVAL_INVALID' }
        }
    }
    elseif ($null -ne $ownerApprovalProperty) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_OWNER_APPROVAL_UNEXPECTED' }
    }
    if ([string] $Record.targetId -notmatch '^BW-HRS-DEV-[A-Z0-9-]{1,32}$') {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_ID_INVALID' }
    }

    $rawPaths = @(
        [string] $Record.gameRootCanonical,
        [string] $Record.buildStageRootCanonical,
        [string] $Record.saveRootCanonical,
        [string] $Record.backup.backupRootCanonical
    )
    if (@($rawPaths | Where-Object { $_.StartsWith('\\') -or $_.StartsWith('//') }).Count -gt 0) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_PATH_UNC' }
    }

    $gameRoot = Resolve-HrsPureCanonicalPath -Value ([string] $Record.gameRootCanonical)
    $buildStageRoot = Resolve-HrsPureCanonicalPath -Value ([string] $Record.buildStageRootCanonical)
    $saveRoot = Resolve-HrsPureCanonicalPath -Value ([string] $Record.saveRootCanonical)
    $backupRoot = Resolve-HrsPureCanonicalPath -Value ([string] $Record.backup.backupRootCanonical)
    $liveRoot = Resolve-HrsPureCanonicalPath -Value $LiveGameRoot
    if ($null -eq $gameRoot -or $null -eq $buildStageRoot -or $null -eq $saveRoot -or
        $null -eq $backupRoot -or $null -eq $liveRoot) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_PATH_INVALID' }
    }

    if ($deploymentClass -eq 'OwnerDesignatedDisposableLiveInstall') {
        if (-not $gameRoot.Equals($liveRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_OWNER_LAB_ROOT_MISMATCH' }
        }
        if ((Test-HrsPathWithin -Candidate $saveRoot -Parent $liveRoot) -or
            (Test-HrsPathWithin -Candidate $backupRoot -Parent $liveRoot)) {
            return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_INSIDE_LIVE_ROOT' }
        }
    }
    elseif ((Test-HrsPathWithin -Candidate $gameRoot -Parent $liveRoot) -or
        (Test-HrsPathWithin -Candidate $saveRoot -Parent $liveRoot) -or
        (Test-HrsPathWithin -Candidate $backupRoot -Parent $liveRoot)) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_INSIDE_LIVE_ROOT' }
    }
    if ((Test-HrsPathWithin -Candidate $buildStageRoot -Parent $liveRoot) -or
        (Test-HrsPathWithin -Candidate $liveRoot -Parent $buildStageRoot) -or
        (Test-HrsPathWithin -Candidate $buildStageRoot -Parent $gameRoot) -or
        (Test-HrsPathWithin -Candidate $gameRoot -Parent $buildStageRoot) -or
        (Test-HrsPathWithin -Candidate $buildStageRoot -Parent $saveRoot) -or
        (Test-HrsPathWithin -Candidate $saveRoot -Parent $buildStageRoot) -or
        (Test-HrsPathWithin -Candidate $buildStageRoot -Parent $backupRoot) -or
        (Test-HrsPathWithin -Candidate $backupRoot -Parent $buildStageRoot)) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_BUILD_STAGE_NOT_SEPARATE' }
    }
    if ((Test-HrsPathWithin -Candidate $backupRoot -Parent $gameRoot) -or
        (Test-HrsPathWithin -Candidate $backupRoot -Parent $saveRoot)) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_BACKUP_NOT_SEPARATE' }
    }

    foreach ($nameValue in @([string] $Record.worldName, [string] $Record.gameName)) {
        if ([string]::IsNullOrWhiteSpace($nameValue) -or $nameValue.Length -gt 80 -or
            $nameValue -match '[\\/:*?"<>|]' -or $nameValue -match '[\x00-\x1F]') {
            return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_NAME_INVALID' }
        }
    }

    if ($null -ne $Record.worldGuid -and -not [string]::IsNullOrWhiteSpace([string] $Record.worldGuid)) {
        $parsedGuid = [guid]::Empty
        if (-not [guid]::TryParse([string] $Record.worldGuid, [ref] $parsedGuid)) {
            return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_WORLD_GUID_INVALID' }
        }
    }
    if ([string] $Record.executionType -notin @('LocalSinglePlayer', 'ListenServer')) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_EXECUTION_NOT_FIRST_LANE' }
    }
    if ([string] $Record.eacState -ne 'Disabled') {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_EAC_NOT_DISABLED' }
    }

    $fingerprintNames = @($Record.expectedFingerprint.PSObject.Properties.Name)
    $allowedFingerprint = @('gameDisplayVersion', 'steamBuildId', 'unityVersion', 'assemblyCSharpSha256', 'assemblyCSharpMvid')
    if (@($fingerprintNames | Where-Object { $allowedFingerprint -notcontains $_ }).Count -gt 0 -or
        @($allowedFingerprint | Where-Object { $fingerprintNames -notcontains $_ }).Count -gt 0) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_FINGERPRINT_SHAPE' }
    }
    foreach ($fingerprintField in $allowedFingerprint) {
        if ([string] $Record.expectedFingerprint.$fingerprintField -cne [string] $ExpectedFingerprint.$fingerprintField) {
            return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_FINGERPRINT_MISMATCH' }
        }
    }

    $backupNames = @($Record.backup.PSObject.Properties.Name)
    $allowedBackup = @('backupRootCanonical', 'manifestSha256', 'createdUtc', 'recoverable')
    if (@($backupNames | Where-Object { $allowedBackup -notcontains $_ }).Count -gt 0 -or
        @($allowedBackup | Where-Object { $backupNames -notcontains $_ }).Count -gt 0) {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_BACKUP_SHAPE' }
    }
    if (-not [bool] $Record.backup.recoverable -or [string] $Record.backup.manifestSha256 -notmatch '^[A-F0-9]{64}$') {
        return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_BACKUP_INVALID' }
    }

    $dateValues = @($Record.backup.createdUtc, $Record.createdUtc, $Record.expiresUtc)
    if ($deploymentClass -eq 'OwnerDesignatedDisposableLiveInstall') {
        $dateValues += @($Record.ownerApproval.approvedUtc)
    }
    foreach ($dateValue in $dateValues) {
        if ($dateValue -is [DateTime]) {
            if ($dateValue.Kind -ne [DateTimeKind]::Utc) {
                return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_TIMESTAMP_INVALID' }
            }
            continue
        }
        if ($dateValue -is [DateTimeOffset]) {
            if ($dateValue.Offset -ne [TimeSpan]::Zero) {
                return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_TIMESTAMP_INVALID' }
            }
            continue
        }

        $dateText = [string] $dateValue
        $parsedDate = [DateTimeOffset]::MinValue
        if (-not $dateText.EndsWith('Z', [System.StringComparison]::Ordinal) -or
            -not [DateTimeOffset]::TryParse($dateText, [ref] $parsedDate) -or
            $parsedDate.Offset -ne [TimeSpan]::Zero) {
            return [pscustomobject] @{ IsValid = $false; Reason = 'TARGET_TIMESTAMP_INVALID' }
        }
    }

    return [pscustomobject] @{ IsValid = $true; Reason = 'TARGET_OK' }
}

Export-ModuleMember -Function Get-Alpha6CoreDecision, Test-Phase1TargetRecord
