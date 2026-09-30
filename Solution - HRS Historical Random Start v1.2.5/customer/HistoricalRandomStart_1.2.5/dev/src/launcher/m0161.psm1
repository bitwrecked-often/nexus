Set-StrictMode -Version 2.0

$script:HrsPolicySchema = 'hrs-policy/v2'
$script:HrsLegacyPolicySchema = 'hrs-policy/v1'
$script:HrsResultSchema = 'hrs-result/v1'
$script:HrsHistorySchema = 'hrs-history/v1'
$script:HrsRecoverySchema = 'hrs-recovery-index/v1'
$script:HrsReleaseFolderName = 'BitWrecked_HistoricalRandomStart'
$script:HrsStateFolderName = 'HistoricalRandomStart_State'
$script:HrsMaximumBridgeBytes = 4096
$script:HrsMaximumHistoryReasonLength = 160
$script:HrsAllowedModes = @('Standard', 'Random', 'RandomSafe')
$script:HrsAllowedOutcomes = @('BYPASSED', 'RESERVED', 'COMPLETED', 'FAILED', 'INCOMPATIBLE', 'REJECTED')
$script:HrsAllowedMarkerStates = @('ABSENT', 'RESERVED', 'COMPLETED', 'INVALID', 'NOT_APPLICABLE')
$script:HrsAllowedResultReasons = @(
    'STANDARD_BYPASS', 'PLACEMENT_DEFERRED', 'RELOCATION_COMPLETED',
    'BUILD_MISMATCH', 'RUNTIME_LANE_UNCONFIRMED', 'POLICY_MISSING',
    'POLICY_REJECTED', 'GAME_NAME_MISMATCH', 'NOT_SERVER',
    'EXECUTION_REJECTED', 'LIFECYCLE_REJECTED', 'ENTITY_UNRESOLVED',
    'MARKER_API_UNAVAILABLE', 'MARKER_CONSUMED', 'MARKER_INVALID',
    'RESERVATION_FAILED', 'SPAWN_LIST_UNAVAILABLE', 'CANDIDATE_UNDEFINED',
    'CANDIDATE_INVALID', 'CANDIDATE_OUT_OF_BOUNDS', 'OBSERVER_UNAVAILABLE',
    'PLACEMENT_FAILED', 'SEMANTIC_CHANGED', 'VERIFY_CONTEXT_FAILED',
    'VERIFY_CHUNK_TIMEOUT', 'VERIFY_UNSAFE', 'VERIFY_POSITION_MISMATCH',
    'COMPLETION_FAILED', 'INTERNAL_FAILURE', 'POI_POOL_EMPTY',
    'TRADER_POOL_EMPTY', 'TRADER_METADATA_UNAVAILABLE',
    'REQUESTED_BIOME_ABSENT', 'WEIGHTED_POOL_EMPTY', 'POI_SAFETY_EXHAUSTED'
)
$script:HrsAllowedHistoryActions = @(
    'Install', 'Update', 'Apply', 'Blocked', 'Failed', 'Cancelled', 'Reset',
    'Restore', 'LaunchRequest', 'RemoveFromGame', 'Snapshot'
)

function ConvertTo-HrsJsonString {
    param([AllowEmptyString()] [string] $Value)

    return (ConvertTo-Json -InputObject $Value -Compress)
}

function Get-HrsSha256Hex {
    param([Parameter(Mandatory = $true)] [byte[]] $Bytes)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function Get-HrsUtf8Bytes {
    param([Parameter(Mandatory = $true)] [string] $Text)

    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    return $utf8.GetBytes($Text)
}

function ConvertFrom-HrsUtf8Bytes {
    param([Parameter(Mandatory = $true)] [byte[]] $Bytes)

    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    return $utf8.GetString($Bytes)
}

function Test-HrsExactGameName {
    [CmdletBinding()]
    param([AllowEmptyString()] [string] $GameName)

    if ([string]::IsNullOrWhiteSpace($GameName)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'GAME_NAME_REQUIRED'; Canonical = '' }
    }
    if ($GameName.Length -gt 64) {
        return [pscustomobject]@{ Valid = $false; Reason = 'GAME_NAME_TOO_LONG'; Canonical = '' }
    }
    if ($GameName -ne $GameName.Trim()) {
        return [pscustomobject]@{ Valid = $false; Reason = 'GAME_NAME_OUTER_WHITESPACE'; Canonical = '' }
    }
    if ($GameName -eq '.' -or $GameName -eq '..') {
        return [pscustomobject]@{ Valid = $false; Reason = 'GAME_NAME_RESERVED'; Canonical = '' }
    }
    if ($GameName.EndsWith('.', [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'GAME_NAME_TRAILING_DOT'; Canonical = '' }
    }
    $deviceStem = $GameName.Split('.')[0]
    if ($deviceStem -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') {
        return [pscustomobject]@{ Valid = $false; Reason = 'GAME_NAME_DEVICE_RESERVED'; Canonical = '' }
    }
    foreach ($character in $GameName.ToCharArray()) {
        if ([char]::IsControl($character) -or [System.IO.Path]::GetInvalidFileNameChars() -contains $character) {
            return [pscustomobject]@{ Valid = $false; Reason = 'GAME_NAME_INVALID_CHARACTER'; Canonical = '' }
        }
    }
    $canonical = $GameName.Normalize([System.Text.NormalizationForm]::FormC)
    if (-not [string]::Equals($canonical, $GameName, [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'GAME_NAME_NONCANONICAL'; Canonical = $canonical }
    }
    return [pscustomobject]@{ Valid = $true; Reason = 'GAME_NAME_VALID'; Canonical = $canonical }
}

function Get-HrsLegacyPolicyDigestInput {
    param(
        [Parameter(Mandatory = $true)] [UInt64] $Revision,
        [Parameter(Mandatory = $true)] [string] $GameName,
        [Parameter(Mandatory = $true)] [ValidateSet('Standard', 'Random', 'RandomSafe')] [string] $Mode,
        [Parameter(Mandatory = $true)] [bool] $Enabled,
        [Parameter(Mandatory = $true)] [string] $WrittenUtc
    )

    return @(
        $script:HrsLegacyPolicySchema,
        $Revision.ToString([System.Globalization.CultureInfo]::InvariantCulture),
        $GameName,
        $Mode,
        $(if ($Enabled) { 'true' } else { 'false' }),
        $WrittenUtc
    ) -join "`n"
}

function New-HrsLegacyPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [UInt64] $Revision,
        [Parameter(Mandatory = $true)] [string] $GameName,
        [Parameter(Mandatory = $true)] [ValidateSet('Standard', 'Random', 'RandomSafe')] [string] $Mode,
        [datetime] $WrittenUtc = ([datetime]::UtcNow)
    )

    if ($Revision -lt 1) { throw 'Policy revision must be at least 1.' }
    $nameCheck = Test-HrsExactGameName -GameName $GameName
    if (-not $nameCheck.Valid) { throw "Invalid exact game name: $($nameCheck.Reason)." }
    $enabled = $Mode -ne 'Standard'
    $utcText = $WrittenUtc.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [System.Globalization.CultureInfo]::InvariantCulture)
    $digestInput = Get-HrsLegacyPolicyDigestInput -Revision $Revision -GameName $nameCheck.Canonical -Mode $Mode -Enabled $enabled -WrittenUtc $utcText
    $digest = Get-HrsSha256Hex -Bytes (Get-HrsUtf8Bytes -Text $digestInput)

    return [pscustomobject][ordered]@{
        schema = $script:HrsLegacyPolicySchema
        revision = $Revision
        gameName = $nameCheck.Canonical
        mode = $Mode
        enabled = $enabled
        writtenUtc = $utcText
        policyDigest = $digest
    }
}

function ConvertTo-HrsLegacyPolicyJson {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [psobject] $Policy)

    $validated = Test-HrsLegacyPolicyObject -Policy $Policy
    if (-not $validated.Valid) { throw "Policy is invalid: $($validated.Reason)." }
    $p = $validated.Policy
    return '{"schema":' + (ConvertTo-HrsJsonString $p.schema) +
        ',"revision":' + $p.revision.ToString([System.Globalization.CultureInfo]::InvariantCulture) +
        ',"gameName":' + (ConvertTo-HrsJsonString $p.gameName) +
        ',"mode":' + (ConvertTo-HrsJsonString $p.mode) +
        ',"enabled":' + $(if ($p.enabled) { 'true' } else { 'false' }) +
        ',"writtenUtc":' + (ConvertTo-HrsJsonString $p.writtenUtc) +
        ',"policyDigest":' + (ConvertTo-HrsJsonString $p.policyDigest) + '}'
}

function Test-HrsLegacyPolicyObject {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [psobject] $Policy)

    $required = @('schema', 'revision', 'gameName', 'mode', 'enabled', 'writtenUtc', 'policyDigest')
    $actual = @($Policy.PSObject.Properties.Name)
    if ($actual.Count -ne $required.Count) {
        return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_FIELD_COUNT'; Policy = $null }
    }
    foreach ($name in $required) {
        if ($actual -cnotcontains $name) {
            return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_FIELD_MISSING'; Policy = $null }
        }
    }
    if (-not [string]::Equals([string]$Policy.schema, $script:HrsLegacyPolicySchema, [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_SCHEMA'; Policy = $null }
    }
    if ($Policy.revision -isnot [UInt64]) {
        return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_REVISION'; Policy = $null }
    }
    $revision = [UInt64]$Policy.revision
    if ($revision -lt 1) { return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_REVISION'; Policy = $null } }
    $nameCheck = Test-HrsExactGameName -GameName ([string]$Policy.gameName)
    if (-not $nameCheck.Valid) {
        return [pscustomobject]@{ Valid = $false; Reason = $nameCheck.Reason; Policy = $null }
    }
    $mode = [string]$Policy.mode
    if ($script:HrsAllowedModes -cnotcontains $mode) {
        return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_MODE'; Policy = $null }
    }
    if ($Policy.enabled -isnot [bool]) {
        return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_ENABLED_TYPE'; Policy = $null }
    }
    $enabled = [bool]$Policy.enabled
    if (($mode -ne 'Standard') -ne $enabled) {
        return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_MODE_ENABLED_MISMATCH'; Policy = $null }
    }
    $written = [datetime]::MinValue
    if (-not [datetime]::TryParseExact([string]$Policy.writtenUtc, 'yyyy-MM-ddTHH:mm:ss.fffZ', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$written)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_TIMESTAMP'; Policy = $null }
    }
    $digest = ([string]$Policy.policyDigest).ToUpperInvariant()
    if ($digest -notmatch '^[0-9A-F]{64}$') {
        return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_DIGEST_FORMAT'; Policy = $null }
    }
    $digestInput = Get-HrsLegacyPolicyDigestInput -Revision $revision -GameName $nameCheck.Canonical -Mode $mode -Enabled $enabled -WrittenUtc ([string]$Policy.writtenUtc)
    $expected = Get-HrsSha256Hex -Bytes (Get-HrsUtf8Bytes -Text $digestInput)
    if (-not [string]::Equals($expected, $digest, [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ Valid = $false; Reason = 'POLICY_DIGEST_MISMATCH'; Policy = $null }
    }
    $normalized = [pscustomobject][ordered]@{
        schema = $script:HrsLegacyPolicySchema
        revision = $revision
        gameName = $nameCheck.Canonical
        mode = $mode
        enabled = $enabled
        writtenUtc = [string]$Policy.writtenUtc
        policyDigest = $digest
    }
    return [pscustomobject]@{ Valid = $true; Reason = 'POLICY_VALID'; Policy = $normalized }
}

function ConvertFrom-HrsLegacyPolicyJson {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $Json)

    $bytes = Get-HrsUtf8Bytes -Text $Json
    if ($bytes.Length -gt $script:HrsMaximumBridgeBytes) { throw 'POLICY_OVERSIZE' }
    $shape = '^\{"schema":"(?<schema>[^"\\]*)","revision":(?<revision>[0-9]+),"gameName":"(?<gameName>[^"\\]*)","mode":"(?<mode>[^"\\]*)","enabled":(?<enabled>true|false),"writtenUtc":"(?<writtenUtc>[^"\\]*)","policyDigest":"(?<policyDigest>[0-9A-Fa-f]{64})"\}$'
    $match = [regex]::Match($Json, $shape, [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
    if (-not $match.Success) { throw 'POLICY_JSON_SHAPE' }
    $parsed = [pscustomobject][ordered]@{
        schema = $match.Groups['schema'].Value
        revision = [UInt64]::Parse($match.Groups['revision'].Value, [System.Globalization.CultureInfo]::InvariantCulture)
        gameName = $match.Groups['gameName'].Value
        mode = $match.Groups['mode'].Value
        enabled = $match.Groups['enabled'].Value -eq 'true'
        writtenUtc = $match.Groups['writtenUtc'].Value
        policyDigest = $match.Groups['policyDigest'].Value
    }
    $validated = Test-HrsLegacyPolicyObject -Policy $parsed
    if (-not $validated.Valid) { throw $validated.Reason }
    if ((ConvertTo-HrsLegacyPolicyJson -Policy $validated.Policy) -cne $Json) { throw 'POLICY_NONCANONICAL' }
    return $validated.Policy
}

function Read-HrsLegacyPolicyFile {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $Path)

    if (-not [System.IO.File]::Exists($Path)) { throw 'POLICY_FILE_MISSING' }
    $info = New-Object System.IO.FileInfo($Path)
    if ($info.Length -gt $script:HrsMaximumBridgeBytes) { throw 'POLICY_OVERSIZE' }
    $bytes = [System.IO.File]::ReadAllBytes($info.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { throw 'POLICY_BOM_FORBIDDEN' }
    return ConvertFrom-HrsLegacyPolicyJson -Json (ConvertFrom-HrsUtf8Bytes -Bytes $bytes)
}

function Write-HrsAtomicUtf8File {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [string] $AllowedRoot,
        [Parameter(Mandatory = $true)] [string] $Text,
        [scriptblock] $ReadbackValidator
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $allowed = Get-HrsCanonicalPath $AllowedRoot
    if ($allowed.StartsWith('\\', [System.StringComparison]::Ordinal) -or
        $allowed.StartsWith('\\?\', [System.StringComparison]::Ordinal) -or
        $allowed.StartsWith('\\.\', [System.StringComparison]::Ordinal)) { throw 'ATOMIC_ROOT_UNSUPPORTED' }
    if (-not [System.IO.Directory]::Exists($allowed)) { throw 'ATOMIC_ROOT_MISSING' }
    $volumeRoot = [System.IO.Path]::GetPathRoot($allowed).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    if ([string]::Equals($allowed.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar), $volumeRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'ATOMIC_ROOT_TOO_BROAD' }
    if (-not (Test-HrsPathContained -Parent $allowed -Child $fullPath)) { throw 'ATOMIC_PATH_ESCAPE' }
    $directory = [System.IO.Path]::GetDirectoryName($fullPath)
    if (-not [System.IO.Directory]::Exists($directory)) { throw 'ATOMIC_PARENT_MISSING' }
    # Keep private atomic-operation leaves short.  The shipped BAT runs under
    # Windows PowerShell 5.1, where repeating a long destination leaf here can
    # push an otherwise valid project-local path beyond legacy MAX_PATH.
    $operationId = [guid]::NewGuid().ToString('N')
    $temporary = [System.IO.Path]::Combine($directory, ".t.$operationId")
    if (Test-HrsExistingPathForReparsePoint -Path $directory) { throw 'ATOMIC_PARENT_REPARSE_POINT' }
    $backup = [System.IO.Path]::Combine($directory, ".b.$operationId")
    $destinationExisted = [System.IO.File]::Exists($fullPath)
    $bytes = Get-HrsUtf8Bytes -Text $Text
    $stream = $null
    try {
        $stream = New-Object System.IO.FileStream($temporary, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::WriteThrough)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
        $stream.Dispose()
        $stream = $null

        if ($destinationExisted) {
            [System.IO.File]::Replace($temporary, $fullPath, $backup, $true)
        }
        else {
            [System.IO.File]::Move($temporary, $fullPath)
        }

        if ($null -ne $ReadbackValidator) { & $ReadbackValidator $fullPath }
        if ([System.IO.File]::Exists($backup)) { [System.IO.File]::Delete($backup) }
    }
    catch {
        if ($null -ne $stream) { $stream.Dispose() }
        if ([System.IO.File]::Exists($backup)) {
            if ([System.IO.File]::Exists($fullPath)) { [System.IO.File]::Delete($fullPath) }
            [System.IO.File]::Move($backup, $fullPath)
        }
        elseif (-not $destinationExisted -and [System.IO.File]::Exists($fullPath)) {
            [System.IO.File]::Delete($fullPath)
        }
        throw
    }
    finally {
        if ([System.IO.File]::Exists($temporary)) { [System.IO.File]::Delete($temporary) }
    }
}

function Write-HrsPolicyFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [string] $AllowedRoot,
        [Parameter(Mandatory = $true)] [psobject] $Policy
    )

    if ($Policy.schema -cne 'hrs-policy/v2') { throw 'POLICY_WRITE_REQUIRES_V2' }
    $json = ConvertTo-HrsPolicyJson -Policy $Policy
    Write-HrsAtomicUtf8File -Path $Path -AllowedRoot $AllowedRoot -Text $json -ReadbackValidator {
        param($readbackPath)
        $readback = Read-HrsPolicyFile -Path $readbackPath
        if (-not [string]::Equals($readback.policyDigest, $Policy.policyDigest, [System.StringComparison]::Ordinal)) {
            throw 'POLICY_READBACK_MISMATCH'
        }
    }
    return Read-HrsPolicyFile -Path $Path
}

function Test-HrsResultObject {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [psobject] $Result)

    $required = @('schema', 'policyRevision', 'policyDigest', 'outcome', 'reason', 'markerState', 'observedUtc')
    $actual = @($Result.PSObject.Properties.Name)
    if ($actual.Count -ne $required.Count) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_FIELD_COUNT'; Result = $null } }
    foreach ($name in $required) { if ($actual -cnotcontains $name) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_FIELD_MISSING'; Result = $null } } }
    if (-not [string]::Equals([string]$Result.schema, $script:HrsResultSchema, [System.StringComparison]::Ordinal)) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_SCHEMA'; Result = $null } }
    if ($Result.policyRevision -isnot [UInt64]) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_REVISION'; Result = $null } }
    $revision = [UInt64]$Result.policyRevision
    $digest = ([string]$Result.policyDigest).ToUpperInvariant()
    if ($revision -eq 0) {
        if ($digest -ne ('0' * 64)) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_ZERO_REVISION_DIGEST'; Result = $null } }
    }
    elseif ($digest -notmatch '^[0-9A-F]{64}$' -or $digest -eq ('0' * 64)) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_DIGEST'; Result = $null } }
    $outcome = [string]$Result.outcome
    if ($script:HrsAllowedOutcomes -cnotcontains $outcome) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_OUTCOME'; Result = $null } }
    $reason = [string]$Result.reason
    if ($script:HrsAllowedResultReasons -cnotcontains $reason) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_REASON'; Result = $null } }
    $marker = [string]$Result.markerState
    if ($script:HrsAllowedMarkerStates -cnotcontains $marker) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_MARKER'; Result = $null } }
    if ($revision -eq 0 -and @('BYPASSED', 'RESERVED', 'COMPLETED', 'FAILED') -ccontains $outcome) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_LOGICAL_COMBINATION'; Result = $null } }
    $combinationValid = switch ($outcome) {
        'BYPASSED' { $reason -eq 'STANDARD_BYPASS' -and $marker -eq 'NOT_APPLICABLE' }
        'RESERVED' { $reason -eq 'PLACEMENT_DEFERRED' -and $marker -eq 'RESERVED' }
        'COMPLETED' { $reason -eq 'RELOCATION_COMPLETED' -and $marker -eq 'COMPLETED' }
        'INCOMPATIBLE' { $reason -in @('BUILD_MISMATCH', 'RUNTIME_LANE_UNCONFIRMED') -and $marker -eq 'NOT_APPLICABLE' }
        'REJECTED' { $marker -in @('ABSENT', 'INVALID', 'NOT_APPLICABLE') }
        'FAILED' { $marker -in @('RESERVED', 'INVALID', 'NOT_APPLICABLE') }
        default { $false }
    }
    if (-not $combinationValid) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_LOGICAL_COMBINATION'; Result = $null } }
    $observed = [datetime]::MinValue
    if (-not [datetime]::TryParseExact([string]$Result.observedUtc, 'yyyy-MM-ddTHH:mm:ss.fffZ', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$observed)) { return [pscustomobject]@{ Valid = $false; Reason = 'RESULT_TIMESTAMP'; Result = $null } }
    return [pscustomobject]@{ Valid = $true; Reason = 'RESULT_VALID'; Result = $Result }
}

function New-HrsResult {
    [CmdletBinding()]
    param(
        [UInt64] $PolicyRevision = 0,
        [string] $PolicyDigest = ('0' * 64),
        [Parameter(Mandatory = $true)] [string] $Outcome,
        [Parameter(Mandatory = $true)] [string] $Reason,
        [Parameter(Mandatory = $true)] [string] $MarkerState,
        [datetime] $ObservedUtc = ([datetime]::UtcNow)
    )

    $candidate = [pscustomobject][ordered]@{
        schema = $script:HrsResultSchema
        policyRevision = $PolicyRevision
        policyDigest = $PolicyDigest.ToUpperInvariant()
        outcome = $Outcome
        reason = $Reason
        markerState = $MarkerState
        observedUtc = $ObservedUtc.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    $validated = Test-HrsResultObject -Result $candidate
    if (-not $validated.Valid) { throw "Result is invalid: $($validated.Reason)." }
    return $validated.Result
}

function ConvertTo-HrsResultJson {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [psobject] $Result)

    $validated = Test-HrsResultObject -Result $Result
    if (-not $validated.Valid) { throw "Result is invalid: $($validated.Reason)." }
    $r = $validated.Result
    return '{"schema":' + (ConvertTo-HrsJsonString ([string]$r.schema)) +
        ',"policyRevision":' + ([UInt64]$r.policyRevision).ToString([System.Globalization.CultureInfo]::InvariantCulture) +
        ',"policyDigest":' + (ConvertTo-HrsJsonString ([string]$r.policyDigest).ToUpperInvariant()) +
        ',"outcome":' + (ConvertTo-HrsJsonString ([string]$r.outcome)) +
        ',"reason":' + (ConvertTo-HrsJsonString ([string]$r.reason)) +
        ',"markerState":' + (ConvertTo-HrsJsonString ([string]$r.markerState)) +
        ',"observedUtc":' + (ConvertTo-HrsJsonString ([string]$r.observedUtc)) + '}'
}

function ConvertFrom-HrsResultJson {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $Json)

    if ((Get-HrsUtf8Bytes -Text $Json).Length -gt $script:HrsMaximumBridgeBytes) { throw 'RESULT_OVERSIZE' }
    $shape = '^\{"schema":"(?<schema>[^"\\]*)","policyRevision":(?<policyRevision>[0-9]+),"policyDigest":"(?<policyDigest>[0-9A-Fa-f]{64})","outcome":"(?<outcome>[^"\\]*)","reason":"(?<reason>[^"\\]*)","markerState":"(?<markerState>[^"\\]*)","observedUtc":"(?<observedUtc>[^"\\]*)"\}$'
    $match = [regex]::Match($Json, $shape, [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
    if (-not $match.Success) { throw 'RESULT_JSON_SHAPE' }
    $parsed = [pscustomobject][ordered]@{
        schema = $match.Groups['schema'].Value
        policyRevision = [UInt64]::Parse($match.Groups['policyRevision'].Value, [System.Globalization.CultureInfo]::InvariantCulture)
        policyDigest = $match.Groups['policyDigest'].Value
        outcome = $match.Groups['outcome'].Value
        reason = $match.Groups['reason'].Value
        markerState = $match.Groups['markerState'].Value
        observedUtc = $match.Groups['observedUtc'].Value
    }
    $validated = Test-HrsResultObject -Result $parsed
    if (-not $validated.Valid) { throw $validated.Reason }
    return $validated.Result
}

function Read-HrsResultFile {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $Path)

    if (-not [System.IO.File]::Exists($Path)) { throw 'RESULT_FILE_MISSING' }
    $bytes = [System.IO.File]::ReadAllBytes([System.IO.Path]::GetFullPath($Path))
    if ($bytes.Length -gt $script:HrsMaximumBridgeBytes) { throw 'RESULT_OVERSIZE' }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { throw 'RESULT_BOM_FORBIDDEN' }
    return ConvertFrom-HrsResultJson -Json (ConvertFrom-HrsUtf8Bytes -Bytes $bytes)
}

function Get-HrsCanonicalPath {
    param([Parameter(Mandatory = $true)] [string] $Path)

    return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Test-HrsPathContained {
    param(
        [Parameter(Mandatory = $true)] [string] $Parent,
        [Parameter(Mandatory = $true)] [string] $Child
    )

    $parentPath = (Get-HrsCanonicalPath $Parent) + [System.IO.Path]::DirectorySeparatorChar
    $childPath = Get-HrsCanonicalPath $Child
    return $childPath.StartsWith($parentPath, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-HrsExistingPathForReparsePoint {
    param([Parameter(Mandatory = $true)] [string] $Path)

    $current = Get-HrsCanonicalPath $Path
    while (-not [string]::IsNullOrEmpty($current)) {
        if ([System.IO.Directory]::Exists($current) -or [System.IO.File]::Exists($current)) {
            $attributes = [System.IO.File]::GetAttributes($current)
            if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $current) { break }
        $current = $parent
    }
    return $false
}

function Get-HrsBridgePaths {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $GameRoot)

    $root = Get-HrsCanonicalPath $GameRoot
    $releaseRoot = [System.IO.Path]::Combine($root, 'Mods', $script:HrsReleaseFolderName)
    $bridgeRoot = [System.IO.Path]::Combine($releaseRoot, 'Bridge')
    return [pscustomobject]@{
        GameRoot = $root
        ReleaseRoot = $releaseRoot
        BridgeRoot = $bridgeRoot
        PolicyPath = [System.IO.Path]::Combine($bridgeRoot, 'policy.v2.json')
        LegacyPolicyPath = [System.IO.Path]::Combine($bridgeRoot, 'policy.v1.json')
        ResultPath = [System.IO.Path]::Combine($bridgeRoot, 'result.v1.json')
    }
}

function Test-HrsBridgePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $GameRoot,
        [switch] $RequireReleaseRoot
    )

    if ([string]::IsNullOrWhiteSpace($GameRoot) -or -not [System.IO.Path]::IsPathRooted($GameRoot)) { return [pscustomobject]@{ Valid = $false; Reason = 'GAME_ROOT_INVALID'; Paths = $null } }
    if ($GameRoot.StartsWith('\\', [System.StringComparison]::Ordinal) -or $GameRoot.StartsWith('\\?\', [System.StringComparison]::Ordinal) -or $GameRoot.StartsWith('\\.\', [System.StringComparison]::Ordinal)) { return [pscustomobject]@{ Valid = $false; Reason = 'GAME_ROOT_UNSUPPORTED'; Paths = $null } }
    $segments = $GameRoot.Split([char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar), [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($segments -contains '..' -or $segments -contains '.') { return [pscustomobject]@{ Valid = $false; Reason = 'GAME_ROOT_NONCANONICAL'; Paths = $null } }
    try { $paths = Get-HrsBridgePaths -GameRoot $GameRoot } catch { return [pscustomobject]@{ Valid = $false; Reason = 'GAME_ROOT_INVALID'; Paths = $null } }
    if (-not [System.IO.File]::Exists([System.IO.Path]::Combine($paths.GameRoot, '7DaysToDie.exe'))) { return [pscustomobject]@{ Valid = $false; Reason = 'GAME_EXECUTABLE_MISSING'; Paths = $paths } }
    if (Test-HrsExistingPathForReparsePoint -Path $paths.GameRoot) { return [pscustomobject]@{ Valid = $false; Reason = 'GAME_ROOT_REPARSE_POINT'; Paths = $paths } }
    if (-not (Test-HrsPathContained -Parent $paths.GameRoot -Child $paths.ReleaseRoot)) { return [pscustomobject]@{ Valid = $false; Reason = 'RELEASE_PATH_ESCAPE'; Paths = $paths } }
    if ($RequireReleaseRoot -and -not [System.IO.Directory]::Exists($paths.ReleaseRoot)) { return [pscustomobject]@{ Valid = $false; Reason = 'RELEASE_ROOT_MISSING'; Paths = $paths } }
    if (Test-HrsExistingPathForReparsePoint -Path $paths.ReleaseRoot) { return [pscustomobject]@{ Valid = $false; Reason = 'RELEASE_ROOT_REPARSE_POINT'; Paths = $paths } }
    if ([System.IO.Directory]::Exists($paths.BridgeRoot)) {
        if (Test-HrsExistingPathForReparsePoint -Path $paths.BridgeRoot) { return [pscustomobject]@{ Valid = $false; Reason = 'BRIDGE_ROOT_REPARSE_POINT'; Paths = $paths } }
        if ([IO.File]::Exists($paths.PolicyPath) -and [IO.File]::Exists($paths.LegacyPolicyPath)) { return [pscustomobject]@{ Valid=$false; Reason='POLICY_AMBIGUOUS'; Paths=$paths } }
        $unexpected = @([System.IO.Directory]::EnumerateFileSystemEntries($paths.BridgeRoot) | Where-Object {
            $leaf = [System.IO.Path]::GetFileName($_)
            $leaf -cne 'policy.v1.json' -and $leaf -cne 'policy.v2.json' -and $leaf -cne 'result.v1.json'
        })
        if ($unexpected.Count -gt 0) { return [pscustomobject]@{ Valid = $false; Reason = 'BRIDGE_UNKNOWN_ENTRY'; Paths = $paths } }
        foreach ($entry in [IO.Directory]::EnumerateFileSystemEntries($paths.BridgeRoot)) {
            if (![IO.File]::Exists($entry) -or (Test-HrsExistingPathForReparsePoint -Path $entry)) {
                return [pscustomobject]@{Valid=$false;Reason='BRIDGE_ENTRY_INVALID';Paths=$paths}
            }
        }
    }
    return [pscustomobject]@{ Valid = $true; Reason = 'BRIDGE_PATHS_VALID'; Paths = $paths }
}

function Get-HrsProcessState {
    [CmdletBinding()]
    param([scriptblock] $ProcessProvider)

    try {
        $processes = if ($null -ne $ProcessProvider) { @(& $ProcessProvider) } else { @(Get-Process -ErrorAction Stop) }
    }
    catch { return [pscustomobject]@{ Game = 'Unknown'; Steam = 'Unknown'; Reason = 'PROCESS_QUERY_FAILED' } }
    try {
        $names = @($processes | ForEach-Object {
            if ($_.PSObject.Properties.Name -cnotcontains 'ProcessName') { throw 'PROCESS_IDENTITY_MISSING' }
            [string]$_.ProcessName
        })
    }
    catch { return [pscustomobject]@{ Game = 'Unknown'; Steam = 'Unknown'; Reason = 'PROCESS_IDENTITY_UNCONFIRMED' } }
    $gameNames = @('7DaysToDie', '7DaysToDieServer', '7DaysToDie_EAC')
    $gameRunning = $false
    foreach ($name in $gameNames) { if ($names -contains $name) { $gameRunning = $true; break } }
    return [pscustomobject]@{
        Game = $(if ($gameRunning) { 'Running' } else { 'Closed' })
        Steam = $(if ($names -contains 'steam') { 'Running' } else { 'Closed' })
        Reason = 'PROCESS_QUERY_OK'
    }
}

function Test-HrsMutationAllowed {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [psobject] $ProcessState)

    if ($ProcessState.Game -eq 'Closed') { return [pscustomobject]@{ Allowed = $true; Reason = 'GAME_CLOSED' } }
    if ($ProcessState.Game -eq 'Running') { return [pscustomobject]@{ Allowed = $false; Reason = 'GAME_RUNNING' } }
    return [pscustomobject]@{ Allowed = $false; Reason = 'GAME_STATE_UNCONFIRMED' }
}

function Test-HrsLaunchAllowed {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [psobject] $ProcessState)

    if ($ProcessState.Game -ne 'Closed') { return [pscustomobject]@{ Allowed = $false; Reason = $(if ($ProcessState.Game -eq 'Running') { 'GAME_ALREADY_RUNNING' } else { 'GAME_STATE_UNCONFIRMED' }) } }
    if ($ProcessState.Steam -ne 'Running') { return [pscustomobject]@{ Allowed = $false; Reason = $(if ($ProcessState.Steam -eq 'Closed') { 'STEAM_NOT_RUNNING' } else { 'STEAM_STATE_UNCONFIRMED' }) } }
    return [pscustomobject]@{ Allowed = $true; Reason = 'DIRECT_USER_LAUNCH_AVAILABLE' }
}

function New-HrsCorrelationId {
    return 'hrs-' + [guid]::NewGuid().ToString('N')
}

function Get-HrsManagerStatePaths {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $ManagerRoot)

    $root = Get-HrsCanonicalPath $ManagerRoot
    $support = [System.IO.Path]::Combine($root, 'ui')
    $state = [System.IO.Path]::Combine($support, $script:HrsStateFolderName)
    return [pscustomobject]@{
        ManagerRoot = $root
        SupportRoot = $support
        StateRoot = $state
        HistoryPath = [System.IO.Path]::Combine($state, 'history.v1.jsonl')
        RecoveryIndexPath = [System.IO.Path]::Combine($state, 'recovery-index.v1.json')
        SnapshotRoot = [System.IO.Path]::Combine($state, 'snapshots')
        LogRoot = [System.IO.Path]::Combine($state, 'logs')
    }
}

function Initialize-HrsManagerState {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $ManagerRoot)

    $paths = Get-HrsManagerStatePaths -ManagerRoot $ManagerRoot
    if (-not [System.IO.Directory]::Exists($paths.SupportRoot)) { throw 'MANAGER_SUPPORT_ROOT_MISSING' }
    if (Test-HrsExistingPathForReparsePoint -Path $paths.SupportRoot) { throw 'MANAGER_SUPPORT_REPARSE_POINT' }
    if (-not (Test-HrsPathContained -Parent $paths.SupportRoot -Child $paths.StateRoot)) { throw 'MANAGER_STATE_PATH_ESCAPE' }
    if (Test-HrsExistingPathForReparsePoint -Path $paths.StateRoot) { throw 'MANAGER_STATE_REPARSE_POINT' }
    if (-not [System.IO.Directory]::Exists($paths.StateRoot)) { [void][System.IO.Directory]::CreateDirectory($paths.StateRoot) }
    return $paths
}

function Add-HrsHistoryEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $ManagerRoot,
        [Parameter(Mandatory = $true)] [ValidateSet('Install', 'Update', 'Apply', 'Blocked', 'Failed', 'Cancelled', 'Reset', 'Restore', 'LaunchRequest', 'RemoveFromGame', 'Snapshot')] [string] $Action,
        [Parameter(Mandatory = $true)] [ValidateSet('Succeeded', 'Failed', 'Blocked', 'Cancelled', 'Unavailable', 'Requested')] [string] $Outcome,
        [Parameter(Mandatory = $true)] [string] $Reason,
        [string] $CorrelationId = (New-HrsCorrelationId),
        [string] $GameName = '',
        [UInt64] $Revision = 0,
        [string] $Mode = ''
    )

    if ($Reason.Length -lt 2 -or $Reason.Length -gt 64 -or $Reason -cnotmatch '^[A-Z0-9_]+$') { throw 'HISTORY_REASON_INVALID' }
    if ($script:HrsAllowedHistoryActions -cnotcontains $Action) { throw 'HISTORY_ACTION_INVALID' }
    if (@('Succeeded', 'Failed', 'Blocked', 'Cancelled', 'Unavailable', 'Requested') -cnotcontains $Outcome) { throw 'HISTORY_OUTCOME_INVALID' }
    if ($CorrelationId -cnotmatch '^hrs-[0-9a-f]{32}$') { throw 'HISTORY_CORRELATION_INVALID' }
    if (-not [string]::IsNullOrEmpty($GameName)) {
        $nameCheck = Test-HrsExactGameName -GameName $GameName
        if (-not $nameCheck.Valid) { throw 'HISTORY_GAME_NAME_INVALID' }
    }
    if (-not [string]::IsNullOrEmpty($Mode) -and $script:HrsAllowedModes -cnotcontains $Mode) { throw 'HISTORY_MODE_INVALID' }
    $paths = Initialize-HrsManagerState -ManagerRoot $ManagerRoot
    $event = [pscustomobject][ordered]@{
        schema = $script:HrsHistorySchema
        correlationId = $CorrelationId
        observedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [System.Globalization.CultureInfo]::InvariantCulture)
        action = $Action
        outcome = $Outcome
        reason = $Reason
        gameName = $GameName
        revision = $Revision
        mode = $Mode
    }
    $line = (ConvertTo-Json -InputObject $event -Compress) + "`n"
    $bytes = Get-HrsUtf8Bytes -Text $line
    $stream = New-Object System.IO.FileStream($paths.HistoryPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read, 4096, [System.IO.FileOptions]::WriteThrough)
    try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush() } finally { $stream.Dispose() }
    return $event
}

Export-ModuleMember -Function @(
    'Test-HrsExactGameName', 'New-HrsPolicy', 'Test-HrsPolicyObject',
    'ConvertTo-HrsPolicyJson', 'ConvertFrom-HrsPolicyJson', 'Read-HrsPolicyFile',
    'Write-HrsPolicyFile', 'Write-HrsAtomicUtf8File', 'Test-HrsResultObject',
    'New-HrsResult', 'ConvertTo-HrsResultJson', 'ConvertFrom-HrsResultJson',
    'Read-HrsResultFile', 'Get-HrsBridgePaths',
    'Test-HrsBridgePaths', 'Get-HrsProcessState', 'Test-HrsMutationAllowed',
    'Test-HrsLaunchAllowed', 'New-HrsCorrelationId', 'Get-HrsManagerStatePaths',
    'Initialize-HrsManagerState', 'Add-HrsHistoryEvent'
)

# v2 readers also retain canonical v1 for explicit migration and recovery.
function Get-HrsSelectionArguments {
    param([Parameter(Mandatory=$true)] [psobject] $Policy)
    if ($Policy.schema -ceq 'hrs-policy/v1') { return @{ Selection='Any'; ChosenBiome=0; Weights=@(0,0,0,0,0) } }
    return @{ Selection=$Policy.selection; ChosenBiome=$Policy.chosenBiome; Weights=@($Policy.forest,$Policy.burntForest,$Policy.desert,$Policy.snow,$Policy.wasteland) }
}

function New-HrsPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [UInt64] $Revision,
        [Parameter(Mandatory=$true)] [string] $GameName,
        [Parameter(Mandatory=$true)] [ValidateSet('Standard','Random','RandomSafe')] [string] $Mode,
        [ValidateSet('Any','Chosen','Weighted')] [string] $Selection='Any',
        [int] $ChosenBiome=0,
        [int[]] $Weights=@(0,0,0,0,0),
        [datetime] $WrittenUtc=([datetime]::UtcNow)
    )
    $name=Test-HrsExactGameName -GameName $GameName
    if (!$name.Valid -or $Revision -lt 1) { throw 'POLICY_IDENTITY_INVALID' }
    if (@('Standard','Random','RandomSafe') -cnotcontains $Mode -or @('Any','Chosen','Weighted') -cnotcontains $Selection) { throw 'POLICY_ENUM' }
    if ($Weights.Count -ne 5 -or @($Weights | Where-Object { $_ -lt 0 -or $_ -gt 100 }).Count) { throw 'POLICY_WEIGHTS_INVALID' }
    if ($Mode -ceq 'Standard' -and $Selection -cne 'Any') { throw 'POLICY_STANDARD_SELECTION' }
    if ($Selection -ceq 'Chosen') {
        if (@(3,9,5,1,8) -notcontains $ChosenBiome) { throw 'POLICY_BIOME_INVALID' }
    } elseif ($ChosenBiome -ne 0) { throw 'POLICY_INACTIVE_BIOME' }
    $sum=($Weights | Measure-Object -Sum).Sum
    if ($Selection -ceq 'Weighted') {
        if ($sum -eq 0) { throw 'POLICY_WEIGHTS_EMPTY' }
    } elseif ($sum -ne 0) { throw 'POLICY_INACTIVE_WEIGHTS' }
    $p=[pscustomobject][ordered]@{
        schema='hrs-policy/v2'; revision=$Revision; gameName=$GameName; mode=$Mode
        enabled=($Mode -cne 'Standard'); selection=$Selection; chosenBiome=$ChosenBiome
        forest=$Weights[0]; burntForest=$Weights[1]; desert=$Weights[2]; snow=$Weights[3]; wasteland=$Weights[4]
        writtenUtc=$WrittenUtc.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ',[Globalization.CultureInfo]::InvariantCulture)
        policyDigest=''
    }
    $values=@($p.schema,$p.revision.ToString([Globalization.CultureInfo]::InvariantCulture),$p.gameName,$p.mode,
        $(if($p.enabled){'true'}else{'false'}),$p.selection,$p.chosenBiome.ToString([Globalization.CultureInfo]::InvariantCulture))
    foreach($w in $Weights) { $values+= $w.ToString([Globalization.CultureInfo]::InvariantCulture) }
    $values+=$p.writtenUtc
    $p.policyDigest=Get-HrsSha256Hex -Bytes (Get-HrsUtf8Bytes -Text ($values -join "`n"))
    return $p
}

function Test-HrsPolicyObject {
    param([Parameter(Mandatory=$true)] [psobject] $Policy)
    try {
        if ($Policy.schema -ceq 'hrs-policy/v1') { return Test-HrsLegacyPolicyObject -Policy $Policy }
        $fields=@('schema','revision','gameName','mode','enabled','selection','chosenBiome','forest','burntForest','desert','snow','wasteland','writtenUtc','policyDigest')
        if ((@($Policy.PSObject.Properties.Name) -join ',') -cne ($fields -join ',')) { throw 'POLICY_FIELDS' }
        if ($Policy.schema -cne 'hrs-policy/v2' -or $Policy.revision -isnot [UInt64] -or $Policy.enabled -isnot [bool]) { throw 'POLICY_TYPES' }
        foreach($field in @('chosenBiome','forest','burntForest','desert','snow','wasteland')) {
            if ($Policy.$field -isnot [int]) { throw 'POLICY_INTEGER_TYPE' }
        }
        if (@('Standard','Random','RandomSafe') -cnotcontains $Policy.mode -or @('Any','Chosen','Weighted') -cnotcontains $Policy.selection) { throw 'POLICY_ENUM' }
        $date=[datetime]::ParseExact($Policy.writtenUtc,'yyyy-MM-ddTHH:mm:ss.fffZ',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal)
        $args=Get-HrsSelectionArguments -Policy $Policy
        $expected=New-HrsPolicy -Revision $Policy.revision -GameName $Policy.gameName -Mode $Policy.mode -WrittenUtc $date @args
        foreach($field in $fields) { if ($Policy.$field -cne $expected.$field) { throw 'POLICY_VALUE_OR_DIGEST' } }
        return [pscustomobject]@{Valid=$true;Reason='POLICY_VALID';Policy=$expected}
    } catch { return [pscustomobject]@{Valid=$false;Reason='POLICY_REJECTED';Policy=$null} }
}

function ConvertTo-HrsPolicyJson {
    param([Parameter(Mandatory=$true)] [psobject] $Policy)
    $check=Test-HrsPolicyObject -Policy $Policy
    if (!$check.Valid) { throw $check.Reason }
    if ($Policy.schema -ceq 'hrs-policy/v1') { return ConvertTo-HrsLegacyPolicyJson -Policy $Policy }
    $p=$check.Policy
    # Exact Game Name already excludes JSON escaping characters. Preserve Unicode.
    return '{"schema":"hrs-policy/v2","revision":'+$p.revision.ToString([Globalization.CultureInfo]::InvariantCulture)+
        ',"gameName":"'+$p.gameName+'","mode":"'+$p.mode+'","enabled":'+$(if($p.enabled){'true'}else{'false'})+
        ',"selection":"'+$p.selection+'","chosenBiome":'+$p.chosenBiome+
        ',"forest":'+$p.forest+',"burntForest":'+$p.burntForest+',"desert":'+$p.desert+',"snow":'+$p.snow+',"wasteland":'+$p.wasteland+
        ',"writtenUtc":"'+$p.writtenUtc+'","policyDigest":"'+$p.policyDigest+'"}'
}

function ConvertFrom-HrsPolicyJson {
    param([Parameter(Mandatory=$true)] [string] $Json)
    if ($Json.StartsWith('{"schema":"hrs-policy/v1",',[StringComparison]::Ordinal)) { return ConvertFrom-HrsLegacyPolicyJson -Json $Json }
    if ((Get-HrsUtf8Bytes -Text $Json).Length -gt 4096) { throw 'POLICY_OVERSIZE' }
    $shape='\A\{"schema":"hrs-policy/v2","revision":(?<revision>[0-9]+),"gameName":"(?<gameName>[^"\\]*)","mode":"(?<mode>[^"\\]*)","enabled":(?<enabled>true|false),"selection":"(?<selection>[^"\\]*)","chosenBiome":(?<chosenBiome>[0-9]+),"forest":(?<forest>[0-9]+),"burntForest":(?<burntForest>[0-9]+),"desert":(?<desert>[0-9]+),"snow":(?<snow>[0-9]+),"wasteland":(?<wasteland>[0-9]+),"writtenUtc":"(?<writtenUtc>[^"\\]*)","policyDigest":"(?<policyDigest>[0-9A-F]{64})"\}\z'
    $m=[regex]::Match($Json,$shape)
    if (!$m.Success) { throw 'POLICY_JSON_SHAPE' }
    $p=[pscustomobject][ordered]@{
        schema='hrs-policy/v2'; revision=[UInt64]::Parse($m.Groups['revision'].Value,[Globalization.CultureInfo]::InvariantCulture)
        gameName=$m.Groups['gameName'].Value;mode=$m.Groups['mode'].Value;enabled=($m.Groups['enabled'].Value -ceq 'true')
        selection=$m.Groups['selection'].Value;chosenBiome=[int]::Parse($m.Groups['chosenBiome'].Value)
        forest=[int]::Parse($m.Groups['forest'].Value);burntForest=[int]::Parse($m.Groups['burntForest'].Value)
        desert=[int]::Parse($m.Groups['desert'].Value);snow=[int]::Parse($m.Groups['snow'].Value);wasteland=[int]::Parse($m.Groups['wasteland'].Value)
        writtenUtc=$m.Groups['writtenUtc'].Value;policyDigest=$m.Groups['policyDigest'].Value
    }
    $canonical=ConvertTo-HrsPolicyJson -Policy $p
    if ($canonical -cne $Json) { throw 'POLICY_NONCANONICAL' }
    return $p
}

function Read-HrsPolicyFile {
    param([Parameter(Mandatory=$true)] [string] $Path)
    $info=New-Object IO.FileInfo($Path)
    if (!$info.Exists -or $info.Length -gt 4096) { throw 'POLICY_FILE_INVALID' }
    $bytes=[IO.File]::ReadAllBytes($info.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { throw 'POLICY_BOM_FORBIDDEN' }
    return ConvertFrom-HrsPolicyJson -Json (ConvertFrom-HrsUtf8Bytes -Bytes $bytes)
}

Export-ModuleMember -Function 'New-HrsPolicy','Test-HrsPolicyObject','ConvertTo-HrsPolicyJson','ConvertFrom-HrsPolicyJson','Read-HrsPolicyFile','Get-HrsSelectionArguments'

function Read-HrsConfiguredPolicy {
    param([Parameter(Mandatory=$true)] [string] $GameRoot)
    $check=Test-HrsBridgePaths -GameRoot $GameRoot
    if (!$check.Valid) { throw $check.Reason }
    $paths=$check.Paths
    if ([IO.File]::Exists($paths.PolicyPath)) {
        $p=Read-HrsPolicyFile $paths.PolicyPath
        if($p.schema -cne 'hrs-policy/v2') { throw 'POLICY_FILENAME_SCHEMA' }
        return $p
    }
    if ([IO.File]::Exists($paths.LegacyPolicyPath)) {
        $p=Read-HrsPolicyFile $paths.LegacyPolicyPath
        if($p.schema -cne 'hrs-policy/v1') { throw 'POLICY_FILENAME_SCHEMA' }
        return $p
    }
    return $null
}

function Write-HrsAppliedPolicy {
    param([Parameter(Mandatory=$true)] [string] $GameRoot, [Parameter(Mandatory=$true)] [psobject] $Policy)
    $allowed=Test-HrsMutationAllowed -ProcessState (Get-HrsProcessState)
    if(!$allowed.Allowed){throw $allowed.Reason}
    $current=Read-HrsConfiguredPolicy -GameRoot $GameRoot
    if($null -ne $current -and $Policy.revision -le $current.revision){throw 'POLICY_REVISION_NOT_ADVANCED'}
    $paths=Get-HrsBridgePaths -GameRoot $GameRoot
    $legacy=[IO.File]::Exists($paths.LegacyPolicyPath)
    try {
        $written=Write-HrsPolicyFile -Path $paths.PolicyPath -AllowedRoot $paths.BridgeRoot -Policy $Policy
        if($legacy){[IO.File]::Delete($paths.LegacyPolicyPath)}
        return $written
    } catch {
        # The old policy remains authoritative on a failed explicit migration.
        if($legacy -and [IO.File]::Exists($paths.LegacyPolicyPath) -and [IO.File]::Exists($paths.PolicyPath)) {
            [IO.File]::Delete($paths.PolicyPath)
        }
        throw
    }
}
function Get-HrsCurrentResultState {
    param([Parameter(Mandatory=$true)][string]$GameRoot)
    $policy=Read-HrsConfiguredPolicy -GameRoot $GameRoot
    if($null -eq $policy -or $policy.schema -cne 'hrs-policy/v2') {
        return [pscustomobject]@{State='Unconfigured';Result=$null;Policy=$policy}
    }
    $paths=Get-HrsBridgePaths -GameRoot $GameRoot
    if(-not [IO.File]::Exists($paths.ResultPath)) {
        return [pscustomobject]@{State='Missing';Result=$null;Policy=$policy}
    }
    $result=Read-HrsResultFile -Path $paths.ResultPath
    if($result.policyRevision -ne $policy.revision -or
        -not [string]::Equals($result.policyDigest,$policy.policyDigest,[StringComparison]::Ordinal)) {
        return [pscustomobject]@{State='Stale';Result=$result;Policy=$policy}
    }
    return [pscustomobject]@{State='Current';Result=$result;Policy=$policy}
}
Export-ModuleMember -Function 'Read-HrsConfiguredPolicy','Write-HrsAppliedPolicy','Get-HrsCurrentResultState'
