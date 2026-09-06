@echo off
rem Bit Wrecked Historical Random Start - Alpha 6 Method 0.0.7 player preview
rem Copyright (C) 2026 Bit Wrecked contributors
rem SPDX-License-Identifier: GPL-3.0-or-later
setlocal DisableDelayedExpansion
set "TOOL_PATH=%~dp0..\ui\p0159.ps1"

if exist "%TOOL_PATH%" goto run_tool

echo Missing design tool: %TOOL_PATH%
endlocal
exit /b 1

:run_tool
powershell.exe -NoProfile -STA -File "%TOOL_PATH%" %*
set "TOOL_EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %TOOL_EXIT_CODE%
