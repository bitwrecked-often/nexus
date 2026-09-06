[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$testRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $testRoot
$toolPath = Join-Path $projectRoot 'ui\p0159.ps1'
$source = Get-Content -LiteralPath $toolPath -Raw
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $toolPath,
    [ref]$tokens,
    [ref]$parseErrors
)

if ($parseErrors.Count -ne 0) {
    foreach ($parseError in $parseErrors) {
        Write-Output "PARSE_ERROR line=$($parseError.Extent.StartLineNumber) message=$($parseError.Message)"
    }
    exit 1
}

$commandAsts = @($ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst]
}, $true))
$memberInvocationAsts = @($ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst]
}, $true))
$redirectionAsts = @($ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.RedirectionAst]
}, $true))
$typeExpressionAsts = @($ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.TypeExpressionAst]
}, $true))
$assignmentAsts = @($ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.AssignmentStatementAst]
}, $true))

$writerCommandNames = @(
    'ac',
    'Add-Content',
    'Clear-Content',
    'Compress-Archive',
    'cp',
    'Copy-Item',
    'del',
    'Expand-Archive',
    'Export-Clixml',
    'Export-Csv',
    'Export-PowerShellDataFile',
    'Invoke-WebRequest',
    'md',
    'mkdir',
    'mv',
    'Move-Item',
    'ni',
    'New-Item',
    'New-ItemProperty',
    'Out-File',
    'ri',
    'rm',
    'Remove-Item',
    'Remove-ItemProperty',
    'Rename-Item',
    'sc',
    'Set-Content',
    'Set-Item',
    'Set-ItemProperty',
    'Start-BitsTransfer',
    'Tee-Object'
)
$writerCommands = @($commandAsts | Where-Object {
    $name = $_.GetCommandName()
    $null -ne $name -and $writerCommandNames -contains $name
})

$fileWriterMemberNames = @(
    'AppendAllLines',
    'AppendAllText',
    'Copy',
    'Create',
    'CreateText',
    'CreateSubKey',
    'Delete',
    'DeleteSubKey',
    'DeleteSubKeyTree',
    'DeleteValue',
    'Move',
    'OpenWrite',
    'Replace',
    'Save',
    'SetAccessControl',
    'SetAttributes',
    'SetValue',
    'Write',
    'WriteAllBytes',
    'WriteAllLines',
    'WriteAllText',
    'WriteByte',
    'WriteLine'
)
$fileWriterMembers = @($memberInvocationAsts | Where-Object {
    $fileWriterMemberNames -contains $_.Member.Extent.Text
})

$newWriterObjects = @($commandAsts | Where-Object {
    $_.GetCommandName() -eq 'New-Object' -and
    $_.Extent.Text -match '(?i)(System\.IO\.(FileStream|StreamWriter|BinaryWriter|TextWriter)|System\.Xml\.XmlWriter|Microsoft\.Win32\.RegistryKey)'
})
$sensitiveWriterTypes = @($typeExpressionAsts | Where-Object {
    $_.TypeName.FullName -match '(?i)^(System\.IO\.(FileStream|StreamWriter|BinaryWriter|TextWriter)|System\.Xml\.XmlWriter|Microsoft\.Win32\.RegistryKey)$'
})

$allowedWriter = @($fileWriterMembers | Where-Object {
    $_.Expression.Extent.Text -eq '[System.IO.File]' -and
    $_.Member.Extent.Text -eq 'WriteAllText' -and
    $_.Arguments.Count -eq 3 -and
    $_.Arguments[0].Extent.Text -eq '$script:PersistentLogPath' -and
    $_.Arguments[1].Extent.Text -eq '$script:ActivityLogBox.Text' -and
    $_.Arguments[2].Extent.Text -eq '$utf8WithBom'
})

$allowedWriterFunctionCount = 0
foreach ($writer in $allowedWriter) {
    $ancestor = $writer.Parent
    while ($null -ne $ancestor -and $ancestor -isnot [System.Management.Automation.Language.FunctionDefinitionAst]) {
        $ancestor = $ancestor.Parent
    }
    if ($null -ne $ancestor -and $ancestor.Name -eq 'Save-ActivityLogSnapshot') {
        $functionText = $ancestor.Extent.Text
        if ($functionText -match '(?s)if\s*\(\s*-not\s+\$script:PersistentLogEnabled\s+-or' -and
            $functionText -match '\[string\]::IsNullOrWhiteSpace\(\$script:PersistentLogPath\)') {
            $allowedWriterFunctionCount++
        }
    }
}

$logCommandAsts = @($commandAsts | Where-Object {
    $_.GetCommandName() -in @('Add-Activity', 'Set-Status', 'Add-PreviewSelectionChangedActivity')
})
$rawPathLogCalls = @($logCommandAsts | Where-Object {
    $_.Extent.Text -match '(?i)\$(?:script:)?(pathBox|currentRoot|validatedGameRootKey|persistentLogPath|settingsText|confirmationText)|\.GameRoot|SelectedPath|dialog\.FileName'
})

$changeFunction = @($ast.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Get-PreviewSettingChanges'
}, $true))
$unsafePathChangeStrings = @()
if ($changeFunction.Count -eq 1) {
    $unsafePathChangeStrings = @($changeFunction[0].FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.ExpandableStringExpressionAst] -and
        $node.Extent.Text -match '(?i)(Previous|Current)\.GameRoot'
    }, $true))
}

$dynamicCommands = @($commandAsts | Where-Object { $null -eq $_.GetCommandName() })
$allowedDynamicCommandCount = 0
foreach ($dynamicCommand in $dynamicCommands) {
    if ($dynamicCommand.Extent.Text -notin @(
        '& $script:GameRootValidator (Get-PreviewGameRootKey -GameRoot $GameRoot)',
        '& $script:PreviewDialogHandler $Text $Caption $Buttons $Icon'
    )) {
        continue
    }

    $ancestor = $dynamicCommand.Parent
    while ($null -ne $ancestor -and $ancestor -isnot [System.Management.Automation.Language.IfStatementAst]) {
        $ancestor = $ancestor.Parent
    }
    if ($null -ne $ancestor -and $ancestor.Extent.Text -match '^if\s*\(\$PreviewWorkflowTestHost\s+-and') {
        $allowedDynamicCommandCount++
    }
}

$persistentLogEnabledAssignments = @($assignmentAsts | Where-Object {
    $_.Left.Extent.Text -eq '$script:PersistentLogEnabled'
})
$persistentLogTrueAssignments = @($persistentLogEnabledAssignments | Where-Object {
    $_.Right.Extent.Text -eq '$true'
})
$persistentLogPathAssignments = @($assignmentAsts | Where-Object {
    $_.Left.Extent.Text -eq '$script:PersistentLogPath'
})
$persistentLogNonemptyPathAssignments = @($persistentLogPathAssignments | Where-Object {
    $_.Right.Extent.Text -ne "''"
})
$persistentLogConsentContract = (
    $persistentLogTrueAssignments.Count -eq 1 -and
    $persistentLogNonemptyPathAssignments.Count -eq 1 -and
    $persistentLogNonemptyPathAssignments[0].Right.Extent.Text -eq '$dialog.FileName' -and
    $source -match '(?s)if\s*\(\$persistentLogCheck\.Checked\).*?IsNullOrWhiteSpace\(\$script:PersistentLogPath\).*?return.*?\$script:PersistentLogEnabled\s*=\s*\$true' -and
    $source -match '(?s)if\s*\(\$dialog\.ShowDialog\(\$form\)\s+-eq\s+\[System\.Windows\.Forms\.DialogResult\]::OK\).*?\$script:PersistentLogPath\s*=\s*\$dialog\.FileName'
)

$startProcessCalls = @($commandAsts | Where-Object { $_.GetCommandName() -eq 'Start-Process' })
$alphaUrlAssignments = @($assignmentAsts | Where-Object {
    $_.Left.Extent.Text -eq '$script:Alpha6EvidenceUrl'
})
$documentedWebLinkContract = (
    $startProcessCalls.Count -eq 1 -and
    $startProcessCalls[0].Extent.Text -eq 'Start-Process $script:Alpha6EvidenceUrl' -and
    $alphaUrlAssignments.Count -eq 1 -and
    $alphaUrlAssignments[0].Right.Extent.Text -eq "'https://7daystodie.com/?p=1150'"
)

$fileWriteCallCount = $writerCommands.Count + $fileWriterMembers.Count + $newWriterObjects.Count + $redirectionAsts.Count + $sensitiveWriterTypes.Count
$gamePolicyWriteCallCount = $fileWriteCallCount - $allowedWriter.Count
$scanPassed = (
    $writerCommands.Count -eq 0 -and
    $newWriterObjects.Count -eq 0 -and
    $redirectionAsts.Count -eq 0 -and
    $sensitiveWriterTypes.Count -eq 0 -and
    $fileWriterMembers.Count -eq 1 -and
    $allowedWriter.Count -eq 1 -and
    $allowedWriterFunctionCount -eq 1 -and
    $gamePolicyWriteCallCount -eq 0 -and
    $rawPathLogCalls.Count -eq 0 -and
    $changeFunction.Count -eq 1 -and
    $changeFunction[0].Extent.Text -match 'paths omitted' -and
    $unsafePathChangeStrings.Count -eq 0 -and
    $dynamicCommands.Count -eq 2 -and
    $allowedDynamicCommandCount -eq 2 -and
    $persistentLogConsentContract -and
    $documentedWebLinkContract
)

Write-Output "STATIC_PARSE_ERRORS=$($parseErrors.Count)"
Write-Output "FILE_WRITE_CALLS=$fileWriteCallCount"
Write-Output "ALLOWLISTED_ACTIVITY_LOG_WRITER=$($allowedWriter.Count)"
Write-Output "GAME_POLICY_WRITE_CALLS=$gamePolicyWriteCallCount"
Write-Output "WRITER_CMDLET_CALLS=$($writerCommands.Count)"
Write-Output "REDIRECTION_WRITE_CALLS=$($redirectionAsts.Count)"
Write-Output "SENSITIVE_WRITER_TYPES=$($sensitiveWriterTypes.Count)"
Write-Output "UNAPPROVED_DYNAMIC_COMMANDS=$($dynamicCommands.Count - $allowedDynamicCommandCount)"
Write-Output "RAW_PATH_ACTIVITY_CALLS=$($rawPathLogCalls.Count)"
Write-Output "PERSISTENT_LOG_CONSENT_CONTRACT=$(if ($persistentLogConsentContract) { 'PASS' } else { 'FAIL' })"
Write-Output "DOCUMENTED_WEB_LINK_CONTRACT=$(if ($documentedWebLinkContract) { 'PASS' } else { 'FAIL' })"
Write-Output "STATIC_GAME_POLICY_WRITE_SCAN=$(if ($scanPassed) { 'PASS' } else { 'FAIL' })"

if (-not $scanPassed) {
    foreach ($call in @($writerCommands + $fileWriterMembers + $newWriterObjects + $redirectionAsts + $sensitiveWriterTypes + $rawPathLogCalls + $unsafePathChangeStrings)) {
        Write-Output "REVIEW line=$($call.Extent.StartLineNumber) text=$($call.Extent.Text)"
    }
    exit 1
}

exit 0
