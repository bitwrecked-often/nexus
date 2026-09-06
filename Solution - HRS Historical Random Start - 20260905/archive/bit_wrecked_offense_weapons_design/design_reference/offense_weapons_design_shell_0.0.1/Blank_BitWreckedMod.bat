@echo off
setlocal DisableDelayedExpansion
set "TOOL_PATH=%~dp0Blank_BitWreckedMod_Tool.ps1"

if exist "%TOOL_PATH%" goto run_tool

echo Missing tool: %TOOL_PATH%
pause
endlocal
exit /b 1

:run_tool
powershell.exe -NoProfile -File "%TOOL_PATH%"
if not errorlevel 1 goto completed

echo.
echo The blank framework tool did not start successfully.
echo Open Blank_BitWreckedMod_Tool.ps1 in PowerShell to view the error.
pause

:completed
endlocal
