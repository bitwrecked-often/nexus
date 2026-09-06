[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $LogPath
)

$ErrorActionPreference = 'Stop'
$resolved = (Resolve-Path -LiteralPath $LogPath).Path
$expectedRoot = (Resolve-Path -LiteralPath (Join-Path $env:APPDATA '7DaysToDie\logs')).Path
$prefix = $expectedRoot.TrimEnd('\') + '\'
if (-not $resolved.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Log path is outside the approved 7 Days to Die log directory.'
}

$lines = @(Select-String -LiteralPath $resolved -SimpleMatch '[HRS-P1]' | ForEach-Object {
    $index = $_.Line.IndexOf('[HRS-P1]', [System.StringComparison]::Ordinal)
    if ($index -ge 0) { $_.Line.Substring($index) }
})
$allowed = '^\[HRS-P1\] v=[A-Za-z0-9._-]+ build=[A-Za-z0-9._-]+( authority=[A-Za-z0-9_-]+ locality=[A-Za-z0-9_-]+ lifecycle=[A-Za-z0-9_-]+ entity=(true|false) count=([0-9]|[1-9][0-9]|1[01][0-9]|12[0-8]) elapsedMs=([0-9]|[1-9][0-9]{0,2}|[1-4][0-9]{3}|5000))? reason=OBS_[A-Z_]+$'
$invalid = @($lines | Where-Object { $_ -notmatch $allowed })
if ($invalid.Count -gt 0) {
    Write-Output "FAIL UNSAFE_OR_MALFORMED_HRS_LOG_LINES=$($invalid.Count)"
    exit 1
}

$lines | ForEach-Object { Write-Output $_ }
Write-Output "HRS_SANITIZED_LINE_COUNT=$($lines.Count)"
Write-Output 'HRS_SANITIZED_LOG_CHECK=PASS'
