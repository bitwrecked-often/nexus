@echo off
rem Bit Wrecked New Player Random Start - 1.3.0 manager
rem Copyright (C) 2026 Bit Wrecked contributors
rem SPDX-License-Identifier: GPL-3.0-or-later
setlocal DisableDelayedExpansion
set "TOOL_PATH=%~dp0dev\ui\p0158.ps1"

if exist "%TOOL_PATH%" goto run_tool

echo Missing HRS manager: %TOOL_PATH%
endlocal
exit /b 1

:run_tool
rem Bypass applies only to this manager process.
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%TOOL_PATH%" %*
set "TOOL_EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %TOOL_EXIT_CODE%
