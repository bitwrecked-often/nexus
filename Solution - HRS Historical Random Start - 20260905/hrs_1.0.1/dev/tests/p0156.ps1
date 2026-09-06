[CmdletBinding()]
param([Parameter(Mandatory = $true)] [string] $LogPath)

$ErrorActionPreference = 'Stop'
$resolved = (Resolve-Path -LiteralPath $LogPath).Path
$logRoot = (Resolve-Path (Join-Path $env:APPDATA '7DaysToDie\logs')).Path.TrimEnd('\')
if (-not $resolved.StartsWith($logRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Log is outside the approved game log root.'
}
$lines = @(Select-String -LiteralPath $resolved -SimpleMatch '[HRS-P1A-RELOC]' | ForEach-Object {
    $index = $_.Line.IndexOf('[HRS-P1A-RELOC]', [StringComparison]::Ordinal)
    if ($index -ge 0) { $_.Line.Substring($index) }
})
$allowed = '^\[HRS-P1A-RELOC\] v=0\.0\.1 build=b14 reason=RELOC_[A-Z_]+$'
if (@($lines | Where-Object { $_ -notmatch $allowed }).Count -gt 0) {
    throw 'Unsafe or malformed relocation log line.'
}
$lines
Write-Output "RELOCATION_SANITIZED_LINE_COUNT=$($lines.Count)"
