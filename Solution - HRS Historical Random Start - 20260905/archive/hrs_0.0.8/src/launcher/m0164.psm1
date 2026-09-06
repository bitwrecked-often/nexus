Set-StrictMode -Version 2.0

$corePath = Join-Path $PSScriptRoot 'm0161.psm1'
if (-not (Test-Path -LiteralPath $corePath -PathType Leaf)) {
    throw 'HRS_CORE_MODULE_MISSING'
}
Import-Module $corePath -Force -ErrorAction Stop

$script:HrsHistorySchema = 'hrs-history/v1'
$script:HrsRecoveryIndexSchema = 'hrs-recovery-index/v1'
$script:HrsRecoverySnapshotSchema = 'hrs-recovery-snapshot/v1'
$script:HrsHistoryMaximumBytes = 2MB
$script:HrsHistoryLineMaximumBytes = 4096
$script:HrsRecoveryIndexMaximumBytes = 262144
$script:HrsRecoverySnapshotMaximumBytes = 16384
$script:HrsRecoveryAttemptLimit = 5
$script:HrsAllowedHistoryActions = @(
    'Install', 'Update', 'Apply', 'Blocked', 'Failed', 'Cancelled', 'Reset',
    'Restore', 'LaunchRequest', 'RemoveFromGame', 'Snapshot'
)
$script:HrsAllowedHistoryOutcomes = @(
    'Succeeded', 'Failed', 'Blocked', 'Cancelled', 'Unavailable', 'Requested'
)
$script:HrsAllowedModes = @('Standard', 'Random')

function ConvertTo-HrsManagementJsonString {
    param([AllowEmptyString()] [string] $Value)

    return ConvertTo-Json -InputObject $Value -Compress
}

function Get-HrsManagementUtf8Bytes {
    param([Parameter(Mandatory = $true)] [string] $Text)

    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    return $utf8.GetBytes($Text)
}

function ConvertFrom-HrsManagementUtf8Bytes {
    param([Parameter(Mandatory = $true)] [byte[]] $Bytes)

    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    return $utf8.GetString($Bytes)
}

function ConvertFrom-HrsManagementJson {
    param([Parameter(Mandatory = $true)] [string] $Json)

    $command = Get-Command ConvertFrom-Json -ErrorAction Stop
    if ($command.Parameters.ContainsKey('DateKind')) {
        return ConvertFrom-Json -InputObject $Json -DateKind String
    }
    return ConvertFrom-Json -InputObject $Json
}

function Test-HrsManagementExactProperties {
    param(
        [Parameter(Mandatory = $true)] [psobject] $Value,
        [Parameter(Mandatory = $true)] [string[]] $Names
    )

    $actual = @($Value.PSObject.Properties.Name)
    if ($actual.Count -ne $Names.Count) { return $false }
    for ($index = 0; $index -lt $Names.Count; $index++) {
        if (-not [string]::Equals($actual[$index], $Names[$index], [System.StringComparison]::Ordinal)) {
            return $false
        }
    }
    return $true
}

function Test-HrsManagementUtcText {
    param([AllowEmptyString()] [string] $Value)

    $parsed = [datetime]::MinValue
    return [datetime]::TryParseExact(
        $Value,
        'yyyy-MM-ddTHH:mm:ss.fffZ',
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
            [System.Globalization.DateTimeStyles]::AdjustToUniversal,
        [ref] $parsed
    )
}

function Test-HrsManagementReasonCode {
    param([AllowEmptyString()] [string] $Value)

    return $Value.Length -ge 2 -and $Value.Length -le 64 -and
        [regex]::IsMatch(
            $Value,
            '^[A-Z][A-Z0-9_]+$',
            [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
}

function Test-HrsManagementCorrelationId {
    param([AllowEmptyString()] [string] $Value)

    return [regex]::IsMatch(
        $Value,
        '^hrs-[0-9a-f]{32}$',
        [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
}

function Test-HrsManagementSnapshotId {
    param([AllowEmptyString()] [string] $Value)

    return [regex]::IsMatch(
        $Value,
        '^snapshot-[0-9a-f]{32}$',
        [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
}

function Get-HrsManagementCanonicalPath {
    param([Parameter(Mandatory = $true)] [string] $Path)

    return [System.IO.Path]::GetFullPath($Path).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
}

function Test-HrsManagementPathContained {
    param(
        [Parameter(Mandatory = $true)] [string] $Parent,
        [Parameter(Mandatory = $true)] [string] $Child
    )

    $parentPath = (Get-HrsManagementCanonicalPath -Path $Parent) +
        [System.IO.Path]::DirectorySeparatorChar
    $childPath = Get-HrsManagementCanonicalPath -Path $Child
    return $childPath.StartsWith($parentPath, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-HrsManagementExistingReparsePoint {
    param(
        [Parameter(Mandatory = $true)] [string] $Candidate,
        [Parameter(Mandatory = $true)] [string] $Boundary
    )

    $boundaryPath = Get-HrsManagementCanonicalPath -Path $Boundary
    $current = Get-HrsManagementCanonicalPath -Path $Candidate
    while (-not [string]::IsNullOrEmpty($current)) {
        if (-not [string]::Equals($current, $boundaryPath, [System.StringComparison]::OrdinalIgnoreCase) -and
            -not (Test-HrsManagementPathContained -Parent $boundaryPath -Child $current)) {
            return $true
        }
        if ([System.IO.File]::Exists($current) -or [System.IO.Directory]::Exists($current)) {
            $attributes = [System.IO.File]::GetAttributes($current)
            if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                return $true
            }
        }
        if ([string]::Equals($current, $boundaryPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $current) { return $true }
        $current = $parent
    }
    return $false
}

function Get-HrsSafeManagementPaths {
    param(
        [Parameter(Mandatory = $true)] [string] $ManagerRoot,
        [switch] $CreateStateRoot
    )

    $paths = if ($CreateStateRoot) {
        Initialize-HrsManagerState -ManagerRoot $ManagerRoot
    }
    else {
        Get-HrsManagerStatePaths -ManagerRoot $ManagerRoot
    }
    if (-not [System.IO.Directory]::Exists($paths.SupportRoot)) {
        throw 'MANAGER_SUPPORT_ROOT_MISSING'
    }
    foreach ($candidate in @(
        $paths.StateRoot,
        $paths.HistoryPath,
        $paths.RecoveryIndexPath,
        $paths.SnapshotRoot
    )) {
        if (-not (Test-HrsManagementPathContained -Parent $paths.SupportRoot -Child $candidate)) {
            throw 'MANAGEMENT_PATH_ESCAPE'
        }
        if (Test-HrsManagementExistingReparsePoint -Candidate $candidate -Boundary $paths.SupportRoot) {
            throw 'MANAGEMENT_REPARSE_POINT'
        }
    }
    return $paths
}

function Read-HrsManagementUtf8File {
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [long] $MaximumBytes,
        [Parameter(Mandatory = $true)] [string] $MissingReason,
        [Parameter(Mandatory = $true)] [string] $OversizeReason,
        [Parameter(Mandatory = $true)] [string] $BomReason,
        [Parameter(Mandatory = $true)] [string] $Utf8Reason
    )

    if (-not [System.IO.File]::Exists($Path)) { throw $MissingReason }
    $info = New-Object System.IO.FileInfo($Path)
    if ($info.Length -gt $MaximumBytes) { throw $OversizeReason }
    $bytes = [System.IO.File]::ReadAllBytes($info.FullName)
    if ($bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw $BomReason
    }
    try {
        return ConvertFrom-HrsManagementUtf8Bytes -Bytes $bytes
    }
    catch {
        throw $Utf8Reason
    }
}

function ConvertTo-HrsHistoryLine {
    param([Parameter(Mandatory = $true)] [psobject] $Entry)

    return '{"schema":' + (ConvertTo-HrsManagementJsonString $Entry.schema) +
        ',"correlationId":' + (ConvertTo-HrsManagementJsonString $Entry.correlationId) +
        ',"observedUtc":' + (ConvertTo-HrsManagementJsonString $Entry.observedUtc) +
        ',"action":' + (ConvertTo-HrsManagementJsonString $Entry.action) +
        ',"outcome":' + (ConvertTo-HrsManagementJsonString $Entry.outcome) +
        ',"reason":' + (ConvertTo-HrsManagementJsonString $Entry.reason) +
        ',"gameName":' + (ConvertTo-HrsManagementJsonString $Entry.gameName) +
        ',"revision":' + ([UInt64]$Entry.revision).ToString([System.Globalization.CultureInfo]::InvariantCulture) +
        ',"mode":' + (ConvertTo-HrsManagementJsonString $Entry.mode) + '}'
}

function ConvertFrom-HrsHistoryLine {
    param([Parameter(Mandatory = $true)] [string] $Line)

    if ((Get-HrsManagementUtf8Bytes -Text $Line).Length -gt $script:HrsHistoryLineMaximumBytes) {
        throw 'HISTORY_LINE_OVERSIZE'
    }
    if ($Line.IndexOf("`r", [System.StringComparison]::Ordinal) -ge 0) {
        throw 'HISTORY_LINE_NONCANONICAL'
    }
    try { $parsed = ConvertFrom-HrsManagementJson -Json $Line } catch { throw 'HISTORY_LINE_JSON' }
    $names = @(
        'schema', 'correlationId', 'observedUtc', 'action', 'outcome',
        'reason', 'gameName', 'revision', 'mode'
    )
    if (-not (Test-HrsManagementExactProperties -Value $parsed -Names $names)) {
        throw 'HISTORY_LINE_FIELDS'
    }
    if (-not [string]::Equals([string]$parsed.schema, $script:HrsHistorySchema, [System.StringComparison]::Ordinal)) {
        throw 'HISTORY_LINE_SCHEMA'
    }
    if (-not (Test-HrsManagementCorrelationId -Value ([string]$parsed.correlationId))) {
        throw 'HISTORY_LINE_CORRELATION'
    }
    if (-not (Test-HrsManagementUtcText -Value ([string]$parsed.observedUtc))) {
        throw 'HISTORY_LINE_TIMESTAMP'
    }
    if ($script:HrsAllowedHistoryActions -cnotcontains [string]$parsed.action) {
        throw 'HISTORY_LINE_ACTION'
    }
    if ($script:HrsAllowedHistoryOutcomes -cnotcontains [string]$parsed.outcome) {
        throw 'HISTORY_LINE_OUTCOME'
    }
    if (-not (Test-HrsManagementReasonCode -Value ([string]$parsed.reason))) {
        throw 'HISTORY_LINE_REASON'
    }
    $gameName = [string]$parsed.gameName
    if (-not [string]::IsNullOrEmpty($gameName)) {
        $nameCheck = Test-HrsExactGameName -GameName $gameName
        if (-not $nameCheck.Valid) { throw 'HISTORY_LINE_GAME_NAME' }
    }
    $revision = [UInt64]0
    if (-not [UInt64]::TryParse(
        [string]$parsed.revision,
        [System.Globalization.NumberStyles]::None,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$revision
    )) { throw 'HISTORY_LINE_REVISION' }
    $mode = [string]$parsed.mode
    if (-not [string]::IsNullOrEmpty($mode) -and $script:HrsAllowedModes -cnotcontains $mode) {
        throw 'HISTORY_LINE_MODE'
    }
    $entry = [pscustomobject][ordered]@{
        schema = $script:HrsHistorySchema
        correlationId = [string]$parsed.correlationId
        observedUtc = [string]$parsed.observedUtc
        action = [string]$parsed.action
        outcome = [string]$parsed.outcome
        reason = [string]$parsed.reason
        gameName = $gameName
        revision = $revision
        mode = $mode
    }
    if (-not [string]::Equals(
        (ConvertTo-HrsHistoryLine -Entry $entry),
        $Line,
        [System.StringComparison]::Ordinal
    )) { throw 'HISTORY_LINE_NONCANONICAL' }
    return $entry
}

function Read-HrsHistory {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $ManagerRoot)

    $paths = Get-HrsSafeManagementPaths -ManagerRoot $ManagerRoot
    if (-not [System.IO.File]::Exists($paths.HistoryPath)) {
        return [pscustomobject]@{
            Entries = @()
            TornFinalLine = $false
            Reason = 'HISTORY_EMPTY'
        }
    }
    $text = Read-HrsManagementUtf8File `
        -Path $paths.HistoryPath `
        -MaximumBytes $script:HrsHistoryMaximumBytes `
        -MissingReason 'HISTORY_MISSING' `
        -OversizeReason 'HISTORY_OVERSIZE' `
        -BomReason 'HISTORY_BOM_FORBIDDEN' `
        -Utf8Reason 'HISTORY_UTF8_INVALID'
    if ($text.Length -eq 0) {
        return [pscustomobject]@{
            Entries = @()
            TornFinalLine = $false
            Reason = 'HISTORY_EMPTY'
        }
    }
    $endsWithLf = $text.EndsWith("`n", [System.StringComparison]::Ordinal)
    $segments = [regex]::Split($text, "`n")
    $lineCount = if ($endsWithLf) { $segments.Count - 1 } else { $segments.Count - 1 }
    $entries = New-Object System.Collections.Generic.List[object]
    for ($index = 0; $index -lt $lineCount; $index++) {
        if ([string]::IsNullOrEmpty($segments[$index])) {
            throw "HISTORY_LINE_EMPTY:$($index + 1)"
        }
        try {
            [void]$entries.Add((ConvertFrom-HrsHistoryLine -Line $segments[$index]))
        }
        catch {
            throw "HISTORY_LINE_INVALID:$($index + 1):$($_.Exception.Message)"
        }
    }
    return [pscustomobject]@{
        Entries = $entries.ToArray()
        TornFinalLine = (-not $endsWithLf)
        Reason = $(if ($endsWithLf) { 'HISTORY_VALID' } else { 'HISTORY_TORN_FINAL_LINE' })
    }
}

function New-HrsEmptyRecoveryIndex {
    return [pscustomobject][ordered]@{
        schema = $script:HrsRecoveryIndexSchema
        highestRevision = [UInt64]0
        attempts = @()
    }
}

function Test-HrsRecoveryAttemptObject {
    param([Parameter(Mandatory = $true)] [psobject] $Attempt)

    $names = @(
        'correlationId', 'capturedUtc', 'outcome', 'reason', 'gameName',
        'revision', 'mode', 'knownGood', 'snapshotId'
    )
    if (-not (Test-HrsManagementExactProperties -Value $Attempt -Names $names)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_FIELDS'; Attempt = $null }
    }
    $correlationId = [string]$Attempt.correlationId
    if (-not (Test-HrsManagementCorrelationId -Value $correlationId)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_CORRELATION'; Attempt = $null }
    }
    $capturedUtc = [string]$Attempt.capturedUtc
    if (-not (Test-HrsManagementUtcText -Value $capturedUtc)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_TIMESTAMP'; Attempt = $null }
    }
    $outcome = [string]$Attempt.outcome
    if ($script:HrsAllowedHistoryOutcomes -cnotcontains $outcome) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_OUTCOME'; Attempt = $null }
    }
    $reason = [string]$Attempt.reason
    if (-not (Test-HrsManagementReasonCode -Value $reason)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_REASON'; Attempt = $null }
    }
    $gameName = [string]$Attempt.gameName
    if (-not [string]::IsNullOrEmpty($gameName)) {
        $nameCheck = Test-HrsExactGameName -GameName $gameName
        if (-not $nameCheck.Valid) {
            return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_GAME_NAME'; Attempt = $null }
        }
    }
    $revision = [UInt64]0
    if (-not [UInt64]::TryParse(
        [string]$Attempt.revision,
        [System.Globalization.NumberStyles]::None,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$revision
    )) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_REVISION'; Attempt = $null }
    }
    $mode = [string]$Attempt.mode
    if (-not [string]::IsNullOrEmpty($mode) -and $script:HrsAllowedModes -cnotcontains $mode) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_MODE'; Attempt = $null }
    }
    if ($Attempt.knownGood -isnot [bool]) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_KNOWN_GOOD_TYPE'; Attempt = $null }
    }
    $knownGood = [bool]$Attempt.knownGood
    $snapshotId = [string]$Attempt.snapshotId
    if ($knownGood) {
        if (-not [string]::Equals($outcome, 'Succeeded', [System.StringComparison]::Ordinal) -or
            -not (Test-HrsManagementSnapshotId -Value $snapshotId) -or
            [string]::IsNullOrEmpty($gameName) -or
            $script:HrsAllowedModes -cnotcontains $mode -or
            $revision -lt 1) {
            return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_KNOWN_GOOD_INVALID'; Attempt = $null }
        }
    }
    elseif (-not [string]::IsNullOrEmpty($snapshotId)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_UNOWNED_SNAPSHOT'; Attempt = $null }
    }
    $normalized = [pscustomobject][ordered]@{
        correlationId = $correlationId
        capturedUtc = $capturedUtc
        outcome = $outcome
        reason = $reason
        gameName = $gameName
        revision = $revision
        mode = $mode
        knownGood = $knownGood
        snapshotId = $snapshotId
    }
    return [pscustomobject]@{ Valid = $true; Reason = 'RECOVERY_ATTEMPT_VALID'; Attempt = $normalized }
}

function Test-HrsRecoveryIndexObject {
    param([Parameter(Mandatory = $true)] [psobject] $Index)

    if (-not (Test-HrsManagementExactProperties -Value $Index -Names @('schema', 'highestRevision', 'attempts'))) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_INDEX_FIELDS'; Index = $null }
    }
    if (-not [string]::Equals([string]$Index.schema, $script:HrsRecoveryIndexSchema, [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_INDEX_SCHEMA'; Index = $null }
    }
    $highestRevision = [UInt64]0
    if (-not [UInt64]::TryParse(
        [string]$Index.highestRevision,
        [System.Globalization.NumberStyles]::None,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$highestRevision
    )) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_INDEX_REVISION'; Index = $null }
    }
    $attemptValues = @($Index.attempts)
    if ($attemptValues.Count -gt $script:HrsRecoveryAttemptLimit) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_INDEX_ATTEMPT_LIMIT'; Index = $null }
    }
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $attempts = New-Object System.Collections.Generic.List[object]
    foreach ($attemptValue in $attemptValues) {
        $validated = Test-HrsRecoveryAttemptObject -Attempt $attemptValue
        if (-not $validated.Valid) {
            return [pscustomobject]@{ Valid = $false; Reason = $validated.Reason; Index = $null }
        }
        if (-not $seen.Add($validated.Attempt.correlationId)) {
            return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_INDEX_DUPLICATE_ATTEMPT'; Index = $null }
        }
        if ($validated.Attempt.revision -gt $highestRevision) {
            return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_INDEX_REVISION_REGRESSION'; Index = $null }
        }
        [void]$attempts.Add($validated.Attempt)
    }
    $normalized = [pscustomobject][ordered]@{
        schema = $script:HrsRecoveryIndexSchema
        highestRevision = $highestRevision
        attempts = $attempts.ToArray()
    }
    return [pscustomobject]@{ Valid = $true; Reason = 'RECOVERY_INDEX_VALID'; Index = $normalized }
}

function ConvertTo-HrsRecoveryAttemptJson {
    param([Parameter(Mandatory = $true)] [psobject] $Attempt)

    return '{"correlationId":' + (ConvertTo-HrsManagementJsonString $Attempt.correlationId) +
        ',"capturedUtc":' + (ConvertTo-HrsManagementJsonString $Attempt.capturedUtc) +
        ',"outcome":' + (ConvertTo-HrsManagementJsonString $Attempt.outcome) +
        ',"reason":' + (ConvertTo-HrsManagementJsonString $Attempt.reason) +
        ',"gameName":' + (ConvertTo-HrsManagementJsonString $Attempt.gameName) +
        ',"revision":' + ([UInt64]$Attempt.revision).ToString([System.Globalization.CultureInfo]::InvariantCulture) +
        ',"mode":' + (ConvertTo-HrsManagementJsonString $Attempt.mode) +
        ',"knownGood":' + $(if ([bool]$Attempt.knownGood) { 'true' } else { 'false' }) +
        ',"snapshotId":' + (ConvertTo-HrsManagementJsonString $Attempt.snapshotId) + '}'
}

function ConvertTo-HrsRecoveryIndexJson {
    param([Parameter(Mandatory = $true)] [psobject] $Index)

    $validated = Test-HrsRecoveryIndexObject -Index $Index
    if (-not $validated.Valid) { throw $validated.Reason }
    $attemptJson = @($validated.Index.attempts | ForEach-Object {
        ConvertTo-HrsRecoveryAttemptJson -Attempt $_
    })
    return '{"schema":' + (ConvertTo-HrsManagementJsonString $script:HrsRecoveryIndexSchema) +
        ',"highestRevision":' + $validated.Index.highestRevision.ToString([System.Globalization.CultureInfo]::InvariantCulture) +
        ',"attempts":[' + ($attemptJson -join ',') + ']}'
}

function ConvertFrom-HrsRecoveryIndexJson {
    param([Parameter(Mandatory = $true)] [string] $Json)

    if ((Get-HrsManagementUtf8Bytes -Text $Json).Length -gt $script:HrsRecoveryIndexMaximumBytes) {
        throw 'RECOVERY_INDEX_OVERSIZE'
    }
    try { $parsed = ConvertFrom-HrsManagementJson -Json $Json } catch { throw 'RECOVERY_INDEX_JSON' }
    $validated = Test-HrsRecoveryIndexObject -Index $parsed
    if (-not $validated.Valid) { throw $validated.Reason }
    $canonical = ConvertTo-HrsRecoveryIndexJson -Index $validated.Index
    if (-not [string]::Equals($canonical, $Json, [System.StringComparison]::Ordinal)) {
        throw 'RECOVERY_INDEX_NONCANONICAL'
    }
    return $validated.Index
}

function Read-HrsRecoveryIndex {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $ManagerRoot)

    $paths = Get-HrsSafeManagementPaths -ManagerRoot $ManagerRoot
    if (-not [System.IO.File]::Exists($paths.RecoveryIndexPath)) {
        return New-HrsEmptyRecoveryIndex
    }
    $json = Read-HrsManagementUtf8File `
        -Path $paths.RecoveryIndexPath `
        -MaximumBytes $script:HrsRecoveryIndexMaximumBytes `
        -MissingReason 'RECOVERY_INDEX_MISSING' `
        -OversizeReason 'RECOVERY_INDEX_OVERSIZE' `
        -BomReason 'RECOVERY_INDEX_BOM_FORBIDDEN' `
        -Utf8Reason 'RECOVERY_INDEX_UTF8_INVALID'
    return ConvertFrom-HrsRecoveryIndexJson -Json $json
}

function Write-HrsRecoveryIndex {
    param(
        [Parameter(Mandatory = $true)] [string] $ManagerRoot,
        [Parameter(Mandatory = $true)] [psobject] $Index
    )

    $paths = Get-HrsSafeManagementPaths -ManagerRoot $ManagerRoot -CreateStateRoot
    $json = ConvertTo-HrsRecoveryIndexJson -Index $Index
    Write-HrsAtomicUtf8File `
        -Path $paths.RecoveryIndexPath `
        -Text $json `
        -AllowedRoot $paths.StateRoot `
        -ReadbackValidator {
            param($readbackPath)
            $readbackJson = Read-HrsManagementUtf8File `
                -Path $readbackPath `
                -MaximumBytes $script:HrsRecoveryIndexMaximumBytes `
                -MissingReason 'RECOVERY_INDEX_MISSING' `
                -OversizeReason 'RECOVERY_INDEX_OVERSIZE' `
                -BomReason 'RECOVERY_INDEX_BOM_FORBIDDEN' `
                -Utf8Reason 'RECOVERY_INDEX_UTF8_INVALID'
            [void](ConvertFrom-HrsRecoveryIndexJson -Json $readbackJson)
        }
}

function Test-HrsRecoverySnapshotObject {
    param([Parameter(Mandatory = $true)] [psobject] $Snapshot)

    if (-not (Test-HrsManagementExactProperties -Value $Snapshot -Names @(
        'schema', 'snapshotId', 'correlationId', 'capturedUtc', 'policy'
    ))) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_SNAPSHOT_FIELDS'; Snapshot = $null }
    }
    if (-not [string]::Equals([string]$Snapshot.schema, $script:HrsRecoverySnapshotSchema, [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_SNAPSHOT_SCHEMA'; Snapshot = $null }
    }
    $snapshotId = [string]$Snapshot.snapshotId
    if (-not (Test-HrsManagementSnapshotId -Value $snapshotId)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_SNAPSHOT_ID'; Snapshot = $null }
    }
    $correlationId = [string]$Snapshot.correlationId
    if (-not (Test-HrsManagementCorrelationId -Value $correlationId)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_SNAPSHOT_CORRELATION'; Snapshot = $null }
    }
    $capturedUtc = [string]$Snapshot.capturedUtc
    if (-not (Test-HrsManagementUtcText -Value $capturedUtc)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_SNAPSHOT_TIMESTAMP'; Snapshot = $null }
    }
    try {
        $policy = ConvertFrom-HrsPolicyJson -Json (ConvertTo-Json -InputObject $Snapshot.policy -Compress)
    }
    catch {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_SNAPSHOT_POLICY'; Snapshot = $null }
    }
    $normalized = [pscustomobject][ordered]@{
        schema = $script:HrsRecoverySnapshotSchema
        snapshotId = $snapshotId
        correlationId = $correlationId
        capturedUtc = $capturedUtc
        policy = $policy
    }
    return [pscustomobject]@{ Valid = $true; Reason = 'RECOVERY_SNAPSHOT_VALID'; Snapshot = $normalized }
}

function ConvertTo-HrsRecoverySnapshotJson {
    param([Parameter(Mandatory = $true)] [psobject] $Snapshot)

    $validated = Test-HrsRecoverySnapshotObject -Snapshot $Snapshot
    if (-not $validated.Valid) { throw $validated.Reason }
    return '{"schema":' + (ConvertTo-HrsManagementJsonString $script:HrsRecoverySnapshotSchema) +
        ',"snapshotId":' + (ConvertTo-HrsManagementJsonString $validated.Snapshot.snapshotId) +
        ',"correlationId":' + (ConvertTo-HrsManagementJsonString $validated.Snapshot.correlationId) +
        ',"capturedUtc":' + (ConvertTo-HrsManagementJsonString $validated.Snapshot.capturedUtc) +
        ',"policy":' + (ConvertTo-HrsPolicyJson -Policy $validated.Snapshot.policy) + '}'
}

function ConvertFrom-HrsRecoverySnapshotJson {
    param([Parameter(Mandatory = $true)] [string] $Json)

    if ((Get-HrsManagementUtf8Bytes -Text $Json).Length -gt $script:HrsRecoverySnapshotMaximumBytes) {
        throw 'RECOVERY_SNAPSHOT_OVERSIZE'
    }
    try { $parsed = ConvertFrom-HrsManagementJson -Json $Json } catch { throw 'RECOVERY_SNAPSHOT_JSON' }
    $validated = Test-HrsRecoverySnapshotObject -Snapshot $parsed
    if (-not $validated.Valid) { throw $validated.Reason }
    $canonical = ConvertTo-HrsRecoverySnapshotJson -Snapshot $validated.Snapshot
    if (-not [string]::Equals($canonical, $Json, [System.StringComparison]::Ordinal)) {
        throw 'RECOVERY_SNAPSHOT_NONCANONICAL'
    }
    return $validated.Snapshot
}

function Get-HrsRecoverySnapshotPath {
    param(
        [Parameter(Mandatory = $true)] [psobject] $Paths,
        [Parameter(Mandatory = $true)] [string] $SnapshotId
    )

    if (-not (Test-HrsManagementSnapshotId -Value $SnapshotId)) {
        throw 'RECOVERY_SNAPSHOT_ID'
    }
    $path = [System.IO.Path]::Combine($Paths.SnapshotRoot, "$SnapshotId.json")
    if (-not (Test-HrsManagementPathContained -Parent $Paths.SnapshotRoot -Child $path)) {
        throw 'RECOVERY_SNAPSHOT_PATH_ESCAPE'
    }
    return $path
}

function Write-HrsRecoverySnapshot {
    param(
        [Parameter(Mandatory = $true)] [string] $ManagerRoot,
        [Parameter(Mandatory = $true)] [psobject] $Snapshot
    )

    $paths = Get-HrsSafeManagementPaths -ManagerRoot $ManagerRoot -CreateStateRoot
    if (-not [System.IO.Directory]::Exists($paths.SnapshotRoot)) {
        [void][System.IO.Directory]::CreateDirectory($paths.SnapshotRoot)
    }
    $paths = Get-HrsSafeManagementPaths -ManagerRoot $ManagerRoot
    $path = Get-HrsRecoverySnapshotPath -Paths $paths -SnapshotId $Snapshot.snapshotId
    if ([System.IO.File]::Exists($path)) { throw 'RECOVERY_SNAPSHOT_COLLISION' }
    $json = ConvertTo-HrsRecoverySnapshotJson -Snapshot $Snapshot
    Write-HrsAtomicUtf8File `
        -Path $path `
        -Text $json `
        -AllowedRoot $paths.SnapshotRoot `
        -ReadbackValidator {
            param($readbackPath)
            $readbackJson = Read-HrsManagementUtf8File `
                -Path $readbackPath `
                -MaximumBytes $script:HrsRecoverySnapshotMaximumBytes `
                -MissingReason 'RECOVERY_SNAPSHOT_MISSING' `
                -OversizeReason 'RECOVERY_SNAPSHOT_OVERSIZE' `
                -BomReason 'RECOVERY_SNAPSHOT_BOM_FORBIDDEN' `
                -Utf8Reason 'RECOVERY_SNAPSHOT_UTF8_INVALID'
            [void](ConvertFrom-HrsRecoverySnapshotJson -Json $readbackJson)
        }
    return $path
}

function Read-HrsRecoverySnapshot {
    param(
        [Parameter(Mandatory = $true)] [string] $ManagerRoot,
        [Parameter(Mandatory = $true)] [string] $SnapshotId
    )

    $paths = Get-HrsSafeManagementPaths -ManagerRoot $ManagerRoot
    if (-not [System.IO.Directory]::Exists($paths.SnapshotRoot)) {
        throw 'RECOVERY_SNAPSHOT_ROOT_MISSING'
    }
    $path = Get-HrsRecoverySnapshotPath -Paths $paths -SnapshotId $SnapshotId
    if (Test-HrsManagementExistingReparsePoint -Candidate $path -Boundary $paths.SupportRoot) {
        throw 'MANAGEMENT_REPARSE_POINT'
    }
    $json = Read-HrsManagementUtf8File `
        -Path $path `
        -MaximumBytes $script:HrsRecoverySnapshotMaximumBytes `
        -MissingReason 'RECOVERY_SNAPSHOT_MISSING' `
        -OversizeReason 'RECOVERY_SNAPSHOT_OVERSIZE' `
        -BomReason 'RECOVERY_SNAPSHOT_BOM_FORBIDDEN' `
        -Utf8Reason 'RECOVERY_SNAPSHOT_UTF8_INVALID'
    return ConvertFrom-HrsRecoverySnapshotJson -Json $json
}

function Test-HrsRecoverySnapshotAgainstAttempt {
    param(
        [Parameter(Mandatory = $true)] [string] $ManagerRoot,
        [Parameter(Mandatory = $true)] [psobject] $Attempt
    )

    if (-not [bool]$Attempt.knownGood) {
        return [pscustomobject]@{ Valid = $false; Reason = $Attempt.reason; Snapshot = $null }
    }
    try {
        $snapshot = Read-HrsRecoverySnapshot -ManagerRoot $ManagerRoot -SnapshotId $Attempt.snapshotId
    }
    catch {
        return [pscustomobject]@{ Valid = $false; Reason = 'SNAPSHOT_UNAVAILABLE'; Snapshot = $null }
    }
    if (-not [string]::Equals($snapshot.snapshotId, $Attempt.snapshotId, [System.StringComparison]::Ordinal) -or
        -not [string]::Equals($snapshot.correlationId, $Attempt.correlationId, [System.StringComparison]::Ordinal) -or
        -not [string]::Equals($snapshot.capturedUtc, $Attempt.capturedUtc, [System.StringComparison]::Ordinal) -or
        -not [string]::Equals($snapshot.policy.gameName, $Attempt.gameName, [System.StringComparison]::Ordinal) -or
        -not [string]::Equals($snapshot.policy.mode, $Attempt.mode, [System.StringComparison]::Ordinal) -or
        [UInt64]$snapshot.policy.revision -ne [UInt64]$Attempt.revision) {
        return [pscustomobject]@{ Valid = $false; Reason = 'SNAPSHOT_METADATA_MISMATCH'; Snapshot = $null }
    }
    return [pscustomobject]@{ Valid = $true; Reason = 'SNAPSHOT_READY'; Snapshot = $snapshot }
}

function Remove-HrsDroppedSnapshots {
    param(
        [Parameter(Mandatory = $true)] [string] $ManagerRoot,
        [Parameter(Mandatory = $true)] [AllowEmptyCollection()] [object[]] $DroppedAttempts,
        [Parameter(Mandatory = $true)] [AllowEmptyCollection()] [object[]] $RetainedAttempts
    )

    if ($DroppedAttempts.Count -eq 0) {
        return [pscustomobject]@{ Removed = 0; Pending = 0 }
    }
    $paths = Get-HrsSafeManagementPaths -ManagerRoot $ManagerRoot
    if (-not [System.IO.Directory]::Exists($paths.SnapshotRoot)) {
        return [pscustomobject]@{ Removed = 0; Pending = 0 }
    }
    $retainedIds = @($RetainedAttempts | Where-Object { $_.knownGood } | ForEach-Object { $_.snapshotId })
    $removed = 0
    $pending = 0
    foreach ($attempt in $DroppedAttempts) {
        if (-not [bool]$attempt.knownGood -or [string]::IsNullOrEmpty([string]$attempt.snapshotId) -or
            $retainedIds -ccontains [string]$attempt.snapshotId) {
            continue
        }
        try {
            $path = Get-HrsRecoverySnapshotPath -Paths $paths -SnapshotId ([string]$attempt.snapshotId)
            if (Test-HrsManagementExistingReparsePoint -Candidate $path -Boundary $paths.SupportRoot) {
                throw 'MANAGEMENT_REPARSE_POINT'
            }
            if ([System.IO.File]::Exists($path)) {
                [System.IO.File]::Delete($path)
                $removed++
            }
        }
        catch {
            $pending++
        }
    }
    return [pscustomobject]@{ Removed = $removed; Pending = $pending }
}

function Add-HrsRecoveryAttempt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $ManagerRoot,
        [Parameter(Mandatory = $true)] [string] $Outcome,
        [Parameter(Mandatory = $true)] [string] $Reason,
        [string] $CorrelationId = (New-HrsCorrelationId),
        [string] $GameName = '',
        [UInt64] $Revision = 0,
        [string] $Mode = '',
        [switch] $KnownGood,
        [psobject] $Policy = $null,
        [datetime] $CapturedUtc = ([datetime]::UtcNow)
    )

    if ($script:HrsAllowedHistoryOutcomes -cnotcontains $Outcome) { throw 'RECOVERY_ATTEMPT_OUTCOME' }
    if (-not (Test-HrsManagementReasonCode -Value $Reason)) { throw 'RECOVERY_ATTEMPT_REASON' }
    if (-not (Test-HrsManagementCorrelationId -Value $CorrelationId)) { throw 'RECOVERY_ATTEMPT_CORRELATION' }
    if ($KnownGood) {
        if (-not [string]::Equals($Outcome, 'Succeeded', [System.StringComparison]::Ordinal) -or $null -eq $Policy) {
            throw 'RECOVERY_KNOWN_GOOD_REQUIRES_SUCCESS_POLICY'
        }
        $policyValidation = Test-HrsPolicyObject -Policy $Policy
        if (-not $policyValidation.Valid) { throw 'RECOVERY_POLICY_INVALID' }
        $Policy = $policyValidation.Policy
        if (-not [string]::IsNullOrEmpty($GameName) -and
            -not [string]::Equals($GameName, $Policy.gameName, [System.StringComparison]::Ordinal)) {
            throw 'RECOVERY_POLICY_GAME_MISMATCH'
        }
        if ($Revision -ne 0 -and $Revision -ne [UInt64]$Policy.revision) {
            throw 'RECOVERY_POLICY_REVISION_MISMATCH'
        }
        if (-not [string]::IsNullOrEmpty($Mode) -and
            -not [string]::Equals($Mode, $Policy.mode, [System.StringComparison]::Ordinal)) {
            throw 'RECOVERY_POLICY_MODE_MISMATCH'
        }
        $GameName = $Policy.gameName
        $Revision = [UInt64]$Policy.revision
        $Mode = $Policy.mode
    }
    elseif ($null -ne $Policy -or [string]::Equals($Outcome, 'Succeeded', [System.StringComparison]::Ordinal)) {
        throw 'RECOVERY_SUCCESS_REQUIRES_KNOWN_GOOD'
    }
    if (-not [string]::IsNullOrEmpty($GameName)) {
        $nameCheck = Test-HrsExactGameName -GameName $GameName
        if (-not $nameCheck.Valid) { throw 'RECOVERY_ATTEMPT_GAME_NAME' }
    }
    if (-not [string]::IsNullOrEmpty($Mode) -and $script:HrsAllowedModes -cnotcontains $Mode) {
        throw 'RECOVERY_ATTEMPT_MODE'
    }
    $capturedText = $CapturedUtc.ToUniversalTime().ToString(
        'yyyy-MM-ddTHH:mm:ss.fffZ',
        [System.Globalization.CultureInfo]::InvariantCulture
    )
    $index = Read-HrsRecoveryIndex -ManagerRoot $ManagerRoot
    if (@($index.attempts | Where-Object {
        [string]::Equals($_.correlationId, $CorrelationId, [System.StringComparison]::Ordinal)
    }).Count -gt 0) { throw 'RECOVERY_ATTEMPT_COLLISION' }
    $snapshotId = if ($KnownGood) { 'snapshot-' + $CorrelationId.Substring(4) } else { '' }
    $snapshotPath = $null
    if ($KnownGood) {
        $snapshot = [pscustomobject][ordered]@{
            schema = $script:HrsRecoverySnapshotSchema
            snapshotId = $snapshotId
            correlationId = $CorrelationId
            capturedUtc = $capturedText
            policy = $Policy
        }
        $snapshotPath = Write-HrsRecoverySnapshot -ManagerRoot $ManagerRoot -Snapshot $snapshot
    }
    $attempt = [pscustomobject][ordered]@{
        correlationId = $CorrelationId
        capturedUtc = $capturedText
        outcome = $Outcome
        reason = $Reason
        gameName = $GameName
        revision = $Revision
        mode = $Mode
        knownGood = [bool]$KnownGood
        snapshotId = $snapshotId
    }
    $allAttempts = @($attempt) + @($index.attempts)
    $retained = @($allAttempts | Select-Object -First $script:HrsRecoveryAttemptLimit)
    $dropped = @($allAttempts | Select-Object -Skip $script:HrsRecoveryAttemptLimit)
    $highestRevision = [UInt64]$index.highestRevision
    if ($Revision -gt $highestRevision) { $highestRevision = $Revision }
    $updated = [pscustomobject][ordered]@{
        schema = $script:HrsRecoveryIndexSchema
        highestRevision = $highestRevision
        attempts = $retained
    }
    try {
        Write-HrsRecoveryIndex -ManagerRoot $ManagerRoot -Index $updated
    }
    catch {
        if ($null -ne $snapshotPath -and [System.IO.File]::Exists($snapshotPath)) {
            [System.IO.File]::Delete($snapshotPath)
        }
        throw
    }
    $history = Add-HrsHistoryEvent `
        -ManagerRoot $ManagerRoot `
        -Action 'Snapshot' `
        -Outcome $Outcome `
        -Reason $Reason `
        -CorrelationId $CorrelationId `
        -GameName $GameName `
        -Revision $Revision `
        -Mode $Mode
    $cleanup = Remove-HrsDroppedSnapshots `
        -ManagerRoot $ManagerRoot `
        -DroppedAttempts $dropped `
        -RetainedAttempts $retained
    return [pscustomobject]@{
        Attempt = $attempt
        HistoryEvent = $history
        RemovedOldSnapshots = $cleanup.Removed
        CleanupPending = $cleanup.Pending
    }
}

function Get-HrsRecoveryView {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $ManagerRoot)

    $index = Read-HrsRecoveryIndex -ManagerRoot $ManagerRoot
    $items = New-Object System.Collections.Generic.List[object]
    [void]$items.Add([pscustomobject]@{
        Kind = 'Default'
        Id = 'Default'
        CapturedUtc = ''
        Outcome = 'Available'
        Reason = 'DEFAULT_AVAILABLE'
        GameName = ''
        Revision = [UInt64]0
        Mode = 'Standard'
        Available = $true
    })
    foreach ($attempt in @($index.attempts)) {
        $revalidation = Test-HrsRecoverySnapshotAgainstAttempt `
            -ManagerRoot $ManagerRoot `
            -Attempt $attempt
        [void]$items.Add([pscustomobject]@{
            Kind = 'Attempt'
            Id = $attempt.correlationId
            CapturedUtc = $attempt.capturedUtc
            Outcome = $attempt.outcome
            Reason = $revalidation.Reason
            GameName = $attempt.gameName
            Revision = [UInt64]$attempt.revision
            Mode = $attempt.mode
            Available = [bool]$revalidation.Valid
        })
    }
    return [pscustomobject]@{
        HighestRevision = [UInt64]$index.highestRevision
        Items = $items.ToArray()
    }
}

function Get-HrsSimplePolicyDiff {
    [CmdletBinding()]
    param(
        [psobject] $CurrentPolicy = $null,
        [Parameter(Mandatory = $true)] [psobject] $TargetPolicy
    )

    $targetValidation = Test-HrsPolicyObject -Policy $TargetPolicy
    if (-not $targetValidation.Valid) { throw 'RECOVERY_TARGET_POLICY_INVALID' }
    $target = $targetValidation.Policy
    $current = $null
    if ($null -ne $CurrentPolicy) {
        $currentValidation = Test-HrsPolicyObject -Policy $CurrentPolicy
        if (-not $currentValidation.Valid) { throw 'RECOVERY_CURRENT_POLICY_INVALID' }
        $current = $currentValidation.Policy
    }
    $changes = New-Object System.Collections.Generic.List[object]
    $beforeGame = if ($null -eq $current) { 'Not configured' } else { $current.gameName }
    $beforeMode = if ($null -eq $current) { 'Not configured' } else { $current.mode }
    if (-not [string]::Equals($beforeGame, $target.gameName, [System.StringComparison]::Ordinal)) {
        [void]$changes.Add([pscustomobject]@{ Field = 'Game'; Before = $beforeGame; After = $target.gameName })
    }
    if (-not [string]::Equals($beforeMode, $target.mode, [System.StringComparison]::Ordinal)) {
        [void]$changes.Add([pscustomobject]@{ Field = 'Start mode'; Before = $beforeMode; After = $target.mode })
    }
    return [pscustomobject]@{
        Changed = $changes.Count -gt 0
        Changes = $changes.ToArray()
        Summary = $(if ($changes.Count -gt 0) { 'Configuration will change' } else { 'No configuration changes' })
    }
}

function Get-HrsNextRecoveryRevision {
    param(
        [Parameter(Mandatory = $true)] [UInt64] $HighestRevision,
        [UInt64] $CurrentRevision = 0,
        [UInt64] $TargetRevision = 0
    )

    $maximum = $HighestRevision
    if ($CurrentRevision -gt $maximum) { $maximum = $CurrentRevision }
    if ($TargetRevision -gt $maximum) { $maximum = $TargetRevision }
    if ($maximum -eq [UInt64]::MaxValue) { throw 'RECOVERY_REVISION_EXHAUSTED' }
    return [UInt64]($maximum + 1)
}

function Get-HrsRestorePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $ManagerRoot,
        [Parameter(Mandatory = $true)] [string] $AttemptId,
        [psobject] $CurrentPolicy = $null,
        [string] $DefaultGameName = ''
    )

    $current = $null
    $currentRevision = [UInt64]0
    if ($null -ne $CurrentPolicy) {
        $currentValidation = Test-HrsPolicyObject -Policy $CurrentPolicy
        if (-not $currentValidation.Valid) {
            return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_CURRENT_POLICY_INVALID'; Policy = $null; Diff = $null; NoWrite = $false }
        }
        $current = $currentValidation.Policy
        $currentRevision = [UInt64]$current.revision
    }
    $index = Read-HrsRecoveryIndex -ManagerRoot $ManagerRoot
    if ([string]::Equals($AttemptId, 'Default', [System.StringComparison]::Ordinal)) {
        $gameName = if ($null -ne $current) { $current.gameName } else { $DefaultGameName }
        if ([string]::IsNullOrEmpty($gameName)) {
            return [pscustomobject]@{
                Valid = $true
                Reason = 'DEFAULT_ALREADY_ACTIVE'
                Policy = $null
                Diff = [pscustomobject]@{ Changed = $false; Changes = @(); Summary = 'No configuration changes' }
                NoWrite = $true
            }
        }
        $nameCheck = Test-HrsExactGameName -GameName $gameName
        if (-not $nameCheck.Valid) {
            return [pscustomobject]@{ Valid = $false; Reason = 'DEFAULT_GAME_NAME_INVALID'; Policy = $null; Diff = $null; NoWrite = $false }
        }
        $revision = Get-HrsNextRecoveryRevision `
            -HighestRevision ([UInt64]$index.highestRevision) `
            -CurrentRevision $currentRevision
        $policy = New-HrsPolicy -Revision $revision -GameName $nameCheck.Canonical -Mode 'Standard'
        return [pscustomobject]@{
            Valid = $true
            Reason = 'DEFAULT_RESTORE_READY'
            Policy = $policy
            Diff = Get-HrsSimplePolicyDiff -CurrentPolicy $current -TargetPolicy $policy
            NoWrite = $false
        }
    }
    if (-not (Test-HrsManagementCorrelationId -Value $AttemptId)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_ID_INVALID'; Policy = $null; Diff = $null; NoWrite = $false }
    }
    $matches = @($index.attempts | Where-Object {
        [string]::Equals($_.correlationId, $AttemptId, [System.StringComparison]::Ordinal)
    })
    if ($matches.Count -ne 1) {
        return [pscustomobject]@{ Valid = $false; Reason = 'RECOVERY_ATTEMPT_NOT_FOUND'; Policy = $null; Diff = $null; NoWrite = $false }
    }
    $attempt = $matches[0]
    $revalidation = Test-HrsRecoverySnapshotAgainstAttempt `
        -ManagerRoot $ManagerRoot `
        -Attempt $attempt
    if (-not $revalidation.Valid) {
        return [pscustomobject]@{ Valid = $false; Reason = $revalidation.Reason; Policy = $null; Diff = $null; NoWrite = $false }
    }
    $revision = Get-HrsNextRecoveryRevision `
        -HighestRevision ([UInt64]$index.highestRevision) `
        -CurrentRevision $currentRevision `
        -TargetRevision ([UInt64]$revalidation.Snapshot.policy.revision)
    $restoredPolicy = New-HrsPolicy `
        -Revision $revision `
        -GameName $revalidation.Snapshot.policy.gameName `
        -Mode $revalidation.Snapshot.policy.mode
    return [pscustomobject]@{
        Valid = $true
        Reason = 'RESTORE_READY'
        Policy = $restoredPolicy
        Diff = Get-HrsSimplePolicyDiff -CurrentPolicy $current -TargetPolicy $restoredPolicy
        NoWrite = $false
    }
}

Export-ModuleMember -Function @(
    'Read-HrsHistory',
    'Read-HrsRecoveryIndex',
    'Add-HrsRecoveryAttempt',
    'Get-HrsRecoveryView',
    'Get-HrsSimplePolicyDiff',
    'Get-HrsRestorePlan'
)
