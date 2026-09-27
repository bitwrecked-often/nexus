@echo off
rem Historical Random Start - starting biome UX prototype
setlocal DisableDelayedExpansion
set "TOOL_PATH=%~dp0dev\ui\BiomeSelectionPrototype.ps1"

if exist "%TOOL_PATH%" goto run_tool

echo Missing prototype tool: %TOOL_PATH%
endlocal
exit /b 1

:run_tool
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%TOOL_PATH%" %*
set "TOOL_EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %TOOL_EXIT_CODE%
